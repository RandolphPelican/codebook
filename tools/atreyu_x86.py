#!/usr/bin/env python3
"""
atreyu_x86.py — CBS → Bytecode Compiler
Opcodes match the bare-metal x86 VM in boot.asm exactly.
"""
import sys, struct

# === Opcodes (MUST match boot.asm %define OP_* values) ===
OP_PUSH      = 0x01  # push i64 (Pod 1.5)
OP_PUSH_STR  = 0x02  # push string (2-byte len + data + pad)
OP_ADD       = 0x10
OP_SUB       = 0x11
OP_MUL       = 0x12
OP_DIV       = 0x13
OP_EQ        = 0x14
OP_NE        = 0x15
OP_LT        = 0x16
OP_GT        = 0x17
OP_LE        = 0x18
OP_GE        = 0x19
OP_RESERVE   = 0x20
OP_JMP       = 0x40  # unconditional, signed i32 offset
OP_JIF       = 0x55  # jump if false (TOS==0), signed i32 offset
OP_JBACK     = 0x56  # jump back, unsigned offset (subtracted)
OP_RET       = 0x53
OP_LOAD      = 0x70
OP_STORE     = 0x71
OP_PRINT_NUM = 0x80
OP_EMIT      = 0x81
OP_NEWLINE   = 0x82
OP_DUP       = 0x83
OP_DROP      = 0x84
OP_SWAP      = 0x85
OP_PRINT_STR = 0x86  # pop string ref, print
OP_MOD       = 0x1A
OP_CALL      = 0x50
OP_DUP2      = 0x87
OP_GRANT_CAP = 0x90
OP_USE_CAP   = 0x91
OP_HALT      = 0xFF
# --- Sign opcodes (Pod 1.7) ---
OP_SIGN_NEW    = 0xA0
OP_SIGN_HASH   = 0xA1
OP_SIGN_LABEL  = 0xA2
OP_SIGN_ENERGY = 0xA3
# --- Energy opcodes (Pod 1.8) ---
OP_ENERGY_NEW       = 0xD0
OP_ENERGY_JOULES    = 0xD1
OP_ENERGY_SOURCE_OP = 0xD2
OP_ENERGY_FREE      = 0xD3

class Emitter:
    def __init__(self):
        self.code = bytearray()
    def pos(self): return len(self.code)
    def emit(self, b): self.code.append(b & 0xFF)
    def emit_i32(self, v): self.code.extend(struct.pack('<i', v))
    def emit_i64(self, v): self.code.extend(struct.pack('<q', v))
    def emit_u16(self, v): self.code.extend(struct.pack('<H', v))
    def patch_i32(self, off, val): self.code[off:off+4] = struct.pack('<i', val)
    def get(self): return bytes(self.code)

class AtreyuX86:
    def __init__(self):
        self.e = Emitter()
        self.vars = {}
        self.next_var = 0
        self.funcs = {}

    def var_id(self, name):
        if name not in self.vars:
            self.vars[name] = self.next_var; self.next_var += 1
        return self.vars[name]

    def compile(self, ast):
        e = self.e
        if ast.get('type') == 'program':
            # JMP over functions
            e.emit(OP_JMP); jp = e.pos(); e.emit_i32(0)
            for s in ast.get('body', []):
                if s.get('type') == 'function':
                    self.funcs[s['name']] = e.pos()
                    self._func(s)
            e.patch_i32(jp, e.pos() - (jp + 4))
            for s in ast.get('body', []):
                if s.get('type') != 'function': self._stmt(s)
        e.emit(OP_HALT)
        return e.get()

    def _func(self, n):
        for p in reversed(n.get('params', [])):
            self.e.emit(OP_STORE); self.e.emit_i32(self.var_id(p))
        cost = n.get('cost', 0)
        if cost > 0:
            self.e.emit(OP_RESERVE); self.e.emit_i64(cost)
        self._block(n['body'])
        self.e.emit(OP_PUSH); self.e.emit_i64(0)
        self.e.emit(OP_RET)

    def _block(self, n):
        for s in n.get('stmts', []): self._stmt(s)

    def _stmt(self, n):
        e = self.e; t = n['type']
        if t == 'let':
            self._expr(n['value']); e.emit(OP_STORE); e.emit_i32(self.var_id(n['name']))
        elif t == 'return':
            self._expr(n['value']); e.emit(OP_RET)
        elif t == 'print':
            v = n['value']
            if v.get('type') == 'str':
                self._push_str(v['value']); e.emit(OP_PRINT_STR)
            else:
                self._expr(v); e.emit(OP_PRINT_NUM)
            e.emit(OP_NEWLINE)
        elif t == 'if': self._if(n)
        elif t == 'while': self._while(n)
        elif t == 'block': self._block(n)
        elif t == 'expr_stmt':
            self._expr(n['value']); e.emit(OP_DROP)
        elif t == 'sign_label_print':
            self._expr(n['value']); e.emit(OP_SIGN_LABEL); e.emit(OP_PRINT_STR); e.emit(OP_NEWLINE)

    def _sign_new(self, n):
        """Emit OP_SIGN_NEW with inline hash and label data."""
        e = self.e
        # Push hash_addr: embed 32 bytes inline via PUSH_STR, drop len
        hash_data = n.get('hash', b'\x00' * 32)
        e.emit(OP_PUSH_STR); e.emit_u16(32)
        e.code.extend(hash_data[:32].ljust(32, b'\x00'))
        e.emit(OP_DROP)         # drop len, keep addr (hash_addr)
        # Push label_addr: embed 64 bytes inline (length-prefixed ASCII)
        label = n.get('label', '')[:63]
        label_data = bytearray(64)
        label_data[0] = len(label)
        label_data[1:1+len(label)] = label.encode('ascii')
        e.emit(OP_PUSH_STR); e.emit_u16(64)
        e.code.extend(label_data)
        e.emit(OP_DROP)         # drop len, keep addr (label_addr)
        # Push energy_cost, embedding_handle (0), provenance_handle (0)
        e.emit(OP_PUSH); e.emit_i64(n.get('energy', 0))
        e.emit(OP_PUSH); e.emit_i64(0)     # embedding_handle (V1.0: always 0)
        e.emit(OP_PUSH); e.emit_i64(0)     # provenance_handle (V1.0: always 0)
        e.emit(OP_SIGN_NEW)

    def _push_str(self, s):
        e = self.e; raw = s.encode('utf-8')
        e.emit(OP_PUSH_STR); e.emit_u16(len(raw))
        e.code.extend(raw)
        pad = (4 - (len(raw) % 4)) % 4
        e.code.extend(b'\x00' * pad)

    def _if(self, n):
        e = self.e
        self._expr(n['cond'])
        e.emit(OP_JIF); ep = e.pos(); e.emit_i32(0)
        self._block(n['then'])
        if n.get('else'):
            e.emit(OP_JMP); endp = e.pos(); e.emit_i32(0)
            e.patch_i32(ep, e.pos() - (ep + 4))
            el = n['else']
            if el['type'] == 'if': self._if(el)
            else: self._block(el)
            e.patch_i32(endp, e.pos() - (endp + 4))
        else:
            e.patch_i32(ep, e.pos() - (ep + 4))

    def _while(self, n):
        e = self.e
        top = e.pos()
        self._expr(n['cond'])
        e.emit(OP_JIF); ep = e.pos(); e.emit_i32(0)
        self._block(n['body'])
        e.emit(OP_JMP); e.emit_i32(top - (e.pos() + 4))
        e.patch_i32(ep, e.pos() - (ep + 4))

    def _expr(self, n):
        e = self.e; t = n['type']
        if t == 'int': e.emit(OP_PUSH); e.emit_i64(n['value'])
        elif t == 'bool': e.emit(OP_PUSH); e.emit_i64(1 if n['value'] else 0)
        elif t == 'str': self._push_str(n['value'])
        elif t == 'var': e.emit(OP_LOAD); e.emit_i32(self.var_id(n['name']))
        elif t == 'neg': self._expr(n['value']); e.emit(OP_PUSH); e.emit_i64(0); e.emit(OP_SWAP); e.emit(OP_SUB)
        elif t == 'not': self._expr(n['value']); e.emit(OP_PUSH); e.emit_i64(0); e.emit(OP_EQ)
        elif t in ('add','sub','mul','div','mod','eq','ne','lt','gt','le','ge'):
            self._expr(n['left']); self._expr(n['right'])
            m = {'add':OP_ADD,'sub':OP_SUB,'mul':OP_MUL,'div':OP_DIV,'mod':OP_MOD,
                 'eq':OP_EQ,'ne':OP_NE,'lt':OP_LT,'gt':OP_GT,'le':OP_LE,'ge':OP_GE}
            e.emit(m[t])
        elif t == 'call':
            for a in n['args']: self._expr(a)
            # Simple: inline call not supported yet, treat as error
            print(f"Warning: function calls not yet supported in bytecode", file=sys.stderr)
        elif t == 'sign_new': self._sign_new(n)
        elif t == 'sign_energy':
            self._expr(n['operand']); e.emit(OP_SIGN_ENERGY)
        elif t == 'sign_hash_first':
            self._expr(n['operand']); e.emit(OP_SIGN_HASH)
            e.emit(OP_DROP); e.emit(OP_DROP); e.emit(OP_DROP)  # drop top 3, keep slot0
        elif t == 'energy_new': self._energy_new(n)
        elif t == 'energy_joules':
            self._expr(n['operand']); e.emit(OP_ENERGY_JOULES)
        elif t == 'energy_source_op':
            self._expr(n['operand']); e.emit(OP_ENERGY_SOURCE_OP)

    def _energy_new(self, n):
        """Emit OP_ENERGY_NEW: push joules, push source_op, emit opcode."""
        e = self.e
        e.emit(OP_PUSH); e.emit_i64(n.get('joules', 0))
        e.emit(OP_PUSH); e.emit_i64(n.get('source_op', 0))
        e.emit(OP_ENERGY_NEW)

# === Demo Programs ===
def demo_full():
    return {'type':'program','body':[
        {'type':'print','value':{'type':'str','value':'=== CodebookScript VM ==='}},
        {'type':'print','value':{'type':'str','value':'Running on bare metal x86_64'}},
        {'type':'print','value':{'type':'str','value':'StableTech Enterprises LLC'}},
        {'type':'print','value':{'type':'str','value':''}},
        # Math
        {'type':'print','value':{'type':'str','value':'-- Arithmetic --'}},
        {'type':'let','name':'x','value':{'type':'int','value':42}},
        {'type':'let','name':'y','value':{'type':'mul','left':{'type':'var','name':'x'},'right':{'type':'int','value':10}}},
        {'type':'print','value':{'type':'var','name':'y'}},
        # Conditional
        {'type':'print','value':{'type':'str','value':'-- Conditional --'}},
        {'type':'if',
         'cond':{'type':'gt','left':{'type':'var','name':'y'},'right':{'type':'int','value':100}},
         'then':{'type':'block','stmts':[{'type':'print','value':{'type':'str','value':'y > 100: true'}}]},
         'else':{'type':'block','stmts':[{'type':'print','value':{'type':'str','value':'y > 100: false'}}]}},
        # Fibonacci
        {'type':'print','value':{'type':'str','value':'-- Fibonacci (20 terms) --'}},
        {'type':'let','name':'a','value':{'type':'int','value':0}},
        {'type':'let','name':'b','value':{'type':'int','value':1}},
        {'type':'let','name':'n','value':{'type':'int','value':0}},
        {'type':'while',
         'cond':{'type':'lt','left':{'type':'var','name':'n'},'right':{'type':'int','value':20}},
         'body':{'type':'block','stmts':[
             {'type':'print','value':{'type':'var','name':'a'}},
             {'type':'let','name':'t','value':{'type':'var','name':'b'}},
             {'type':'let','name':'b','value':{'type':'add','left':{'type':'var','name':'a'},'right':{'type':'var','name':'b'}}},
             {'type':'let','name':'a','value':{'type':'var','name':'t'}},
             {'type':'let','name':'n','value':{'type':'add','left':{'type':'var','name':'n'},'right':{'type':'int','value':1}}},
         ]}},
        {'type':'print','value':{'type':'str','value':''}},
        {'type':'print','value':{'type':'str','value':'=== CBS complete ==='}},
    ]}

def demo_sign():
    """Pod 1.7 Sign typed primitive test — hardcoded AST demo"""
    return {'type':'program','body':[
        {'type':'print','value':{'type':'str','value':'=== Sign Test (Pod 1.7) ==='}},
        # Create a Sign: hash = 0xAB + 31 zero bytes, label = "hello", energy = 42
        {'type':'let','name':'s','value':{
            'type':'sign_new',
            'hash': b'\xab' + b'\x00' * 31,
            'label': 'hello',
            'energy': 42,
        }},
        # Print sign_id (expect: 1)
        {'type':'print','value':{'type':'str','value':'sign_id:'}},
        {'type':'print','value':{'type':'var','name':'s'}},
        # Print energy_cost (expect: 42)
        {'type':'print','value':{'type':'str','value':'energy:'}},
        {'type':'print','value':{'type':'sign_energy','operand':{'type':'var','name':'s'}}},
        # Print label (expect: hello)
        {'type':'print','value':{'type':'str','value':'label:'}},
        {'type':'sign_label_print','value':{'type':'var','name':'s'}},
        # Print first 8 bytes of hash as u64 (expect: 171 = 0xAB little-endian)
        {'type':'print','value':{'type':'str','value':'hash[0:8]:'}},
        {'type':'print','value':{'type':'sign_hash_first','operand':{'type':'var','name':'s'}}},
        {'type':'print','value':{'type':'str','value':'=== Sign test complete ==='}},
    ]}

def demo_energy():
    """Pod 1.8 Energy typed primitive test — hardcoded AST demo"""
    return {'type':'program','body':[
        {'type':'print','value':{'type':'str','value':'=== Energy Test (Pod 1.8) ==='}},
        # Create an Energy: joules=500, source_op=0xA0 (OP_SIGN_NEW)
        {'type':'let','name':'e','value':{
            'type':'energy_new',
            'joules': 500,
            'source_op': 0xA0,
        }},
        # Print energy_id (expect: 1)
        {'type':'print','value':{'type':'str','value':'energy_id:'}},
        {'type':'print','value':{'type':'var','name':'e'}},
        # Read back joules (expect: 500)
        {'type':'print','value':{'type':'str','value':'joules:'}},
        {'type':'print','value':{'type':'energy_joules','operand':{'type':'var','name':'e'}}},
        # Read back source_op (expect: 160 = 0xA0)
        {'type':'print','value':{'type':'str','value':'source_op:'}},
        {'type':'print','value':{'type':'energy_source_op','operand':{'type':'var','name':'e'}}},
        {'type':'print','value':{'type':'str','value':'=== Energy test complete ==='}},
    ]}

if __name__ == '__main__':
    if '--build' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_full())
        out = sys.argv[sys.argv.index('--build')+1] if len(sys.argv) > sys.argv.index('--build')+1 else 'demo.cbc'
        with open(out,'wb') as f: f.write(bc)
        print(f"Compiled {len(bc)} bytes -> {out}")
        print(f"Vars: {c.vars}")
    elif '--test' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_full())
        print(f"Demo: {len(bc)} bytes, vars: {c.vars}")
        for i in range(0, min(len(bc),64), 16):
            h = ' '.join(f'{b:02X}' for b in bc[i:i+16])
            print(f"  {i:04X}: {h}")
        print(f"First: 0x{bc[0]:02X} Last: 0x{bc[-1]:02X}")
    elif '--sign-build' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_sign())
        out = sys.argv[sys.argv.index('--sign-build')+1] if len(sys.argv) > sys.argv.index('--sign-build')+1 else 'sign_test.cbc'
        with open(out,'wb') as f: f.write(bc)
        print(f"Sign test: compiled {len(bc)} bytes -> {out}")
        print(f"Vars: {c.vars}")
    elif '--sign-test' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_sign())
        print(f"Sign test: {len(bc)} bytes, vars: {c.vars}")
        for i in range(0, min(len(bc),128), 16):
            h = ' '.join(f'{b:02X}' for b in bc[i:i+16])
            print(f"  {i:04X}: {h}")
        print(f"First: 0x{bc[0]:02X} Last: 0x{bc[-1]:02X}")
    elif '--energy-build' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_energy())
        out = sys.argv[sys.argv.index('--energy-build')+1] if len(sys.argv) > sys.argv.index('--energy-build')+1 else 'test_energy.cbc'
        with open(out,'wb') as f: f.write(bc)
        print(f"Energy test: compiled {len(bc)} bytes -> {out}")
        print(f"Vars: {c.vars}")
    elif '--energy-test' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_energy())
        print(f"Energy test: {len(bc)} bytes, vars: {c.vars}")
        for i in range(0, min(len(bc),128), 16):
            h = ' '.join(f'{b:02X}' for b in bc[i:i+16])
            print(f"  {i:04X}: {h}")
        print(f"First: 0x{bc[0]:02X} Last: 0x{bc[-1]:02X}")
    else:
        print("Usage: python3 atreyu_x86.py --build [out.cbc] | --test | --sign-build [out.cbc] | --sign-test | --energy-build [out.cbc] | --energy-test")
