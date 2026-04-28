#!/usr/bin/env python3
"""
atreyu_x86.py — CBS → Bytecode Compiler
Opcodes match the bare-metal x86 VM in boot.asm exactly.
"""
import sys, struct

# === Opcodes (MUST match boot.asm %define OP_* values) ===
OP_PUSH      = 0x01  # push i32
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
    else:
        print("Usage: python3 atreyu_x86.py --build [out.cbc] | --test")
