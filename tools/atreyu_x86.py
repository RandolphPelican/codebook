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
# --- Pod 1.8.5c Move 6 / Move 7 ---
OP_ENERGY_RECOVER   = 0xD4
OP_PHASE_QUERY      = 0xD5
# --- Pod 1.9.2b Outcome opcodes (D1.9.1.4) ---
OP_OUTCOME_NEW_OK     = 0xE0
OP_OUTCOME_NEW_ERR    = 0xE1
OP_OUTCOME_IS_OK      = 0xE2
OP_OUTCOME_UNWRAP_OK  = 0xE3
OP_OUTCOME_UNWRAP_ERR = 0xE4

# --- Pod 1.9.2a/1.9.2b TYPE_CODE_* enum (D1.9.1.1) ---
TYPE_CODE_NONE     = 0
TYPE_CODE_SIGN     = 1
TYPE_CODE_ENERGY   = 2
TYPE_CODE_CAP      = 3
TYPE_CODE_DEMOD    = 4
TYPE_CODE_SIGNAL   = 5
TYPE_CODE_OUTCOME  = 6

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
        elif t == 'energy_recover':
            # Pod 1.8.5c Move 6 — push u64 arg, fire OP_ENERGY_RECOVER (V1.0 no-op-with-log)
            e.emit(OP_PUSH); e.emit_i64(n.get('arg', 0))
            e.emit(OP_ENERGY_RECOVER)
        elif t == 'outcome_unwrap_err_stmt':
            # Pod 1.9.2b — push operand, emit OP_OUTCOME_UNWRAP_ERR.
            # Leaves 4 values on stack (err_code at bottom, err_fetch_counter at TOS per A1).
            # Test programs follow with print {'type':'tos'} statements to consume in TOS-pop order.
            self._expr(n['value']); e.emit(OP_OUTCOME_UNWRAP_ERR)
        elif t == 'raw_op_ret':
            # Pod 1.9.3 T5 test primitive — emit raw OP_RET to trigger
            # ret_underflow on empty return stack.
            e.emit(OP_RET)
        elif t == 'raw_call_overflow_burst':
            # Pod 1.9.3 T6 test primitive — emit N pairs of (PUSH 0; CALL).
            # Each pair fills one vm_ret_stack slot; offset 0 means r12 += 0
            # (next instruction continues normally). After vm_ret_stack capacity
            # (256) is exhausted, next CALL hits .call_overflow.
            n_calls = n.get('count', 300)
            for _ in range(n_calls):
                e.emit(OP_PUSH); e.emit_i64(0)
                e.emit(OP_CALL)

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
            # Pod 1.9.3 (S7): OP_SIGN_ENERGY now returns Outcome<u64>.
            # AST handler emits accessor + UNWRAP_OK so demo_sign() body stays unchanged.
            self._expr(n['operand']); e.emit(OP_SIGN_ENERGY); e.emit(OP_OUTCOME_UNWRAP_OK)
        elif t == 'sign_hash_first':
            # Pod 1.9.3 A1: OP_SIGN_HASH refit deferred (multi-value accessor;
            # see DEFERRED note). Handler unchanged — pushes 4 hash qwords on success;
            # null path still pushes 4 zeros (legacy, pending multi-value Outcome design).
            self._expr(n['operand']); e.emit(OP_SIGN_HASH)
            e.emit(OP_DROP); e.emit(OP_DROP); e.emit(OP_DROP)  # drop top 3, keep slot0
        elif t == 'energy_new': self._energy_new(n)
        elif t == 'energy_joules':
            # Pod 1.9.3 (S7): OP_ENERGY_JOULES now returns Outcome<u64>.
            self._expr(n['operand']); e.emit(OP_ENERGY_JOULES); e.emit(OP_OUTCOME_UNWRAP_OK)
        elif t == 'energy_source_op':
            # Pod 1.9.3 (S7): OP_ENERGY_SOURCE_OP now returns Outcome<u64>.
            self._expr(n['operand']); e.emit(OP_ENERGY_SOURCE_OP); e.emit(OP_OUTCOME_UNWRAP_OK)
        elif t == 'phase_query':
            # Pod 1.8.5c Move 7 — read vm_phase u64 onto operand stack
            e.emit(OP_PHASE_QUERY)
        elif t == 'sign_energy_raw_id':
            # Pod 1.9.3 T3 test primitive — push raw u64 id, emit OP_SIGN_ENERGY.
            # NO UNWRAP_OK — caller wants the raw outcome_id (Err on invalid).
            e.emit(OP_PUSH); e.emit_i64(n['id'])
            e.emit(OP_SIGN_ENERGY)
        elif t == 'energy_joules_raw_id':
            # Pod 1.9.3 T4 test primitive — push raw u64 id, emit OP_ENERGY_JOULES.
            # NO UNWRAP_OK — caller wants the raw outcome_id.
            e.emit(OP_PUSH); e.emit_i64(n['id'])
            e.emit(OP_ENERGY_JOULES)
        # --- Pod 1.9.2b Outcome expressions ---
        elif t == 'tos':
            # No-op: value is already on operand stack (used with 'print' to
            # pop-and-print an existing TOS without re-pushing)
            pass
        elif t == 'outcome_new_ok':
            # Stack effect: push value_type_id, push value, emit OP_OUTCOME_NEW_OK
            # Handler pops value (TOS), then value_type_id, then pushes outcome_id.
            e.emit(OP_PUSH); e.emit_i64(n.get('value_type_id', 0))
            e.emit(OP_PUSH); e.emit_i64(n.get('value', 0))
            e.emit(OP_OUTCOME_NEW_OK)
        elif t == 'outcome_new_err':
            # Stack effect: push value_type_id, err_code, err_source_op, err_demod_id, err_fetch_counter, emit
            # Handler pops top-down: err_fetch_counter, err_demod_id, err_source_op, err_code, value_type_id.
            e.emit(OP_PUSH); e.emit_i64(n.get('value_type_id', 0))
            e.emit(OP_PUSH); e.emit_i64(n.get('err_code', 0))
            e.emit(OP_PUSH); e.emit_i64(n.get('err_source_op', 0))
            e.emit(OP_PUSH); e.emit_i64(n.get('err_demod_id', 0))
            e.emit(OP_PUSH); e.emit_i64(n.get('err_fetch_counter', 0))
            e.emit(OP_OUTCOME_NEW_ERR)
        elif t == 'outcome_is_ok':
            self._expr(n['operand']); e.emit(OP_OUTCOME_IS_OK)
        elif t == 'outcome_unwrap_ok':
            self._expr(n['operand']); e.emit(OP_OUTCOME_UNWRAP_OK)
        elif t == 'outcome_unwrap_err':
            self._expr(n['operand']); e.emit(OP_OUTCOME_UNWRAP_ERR)

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

def demo_phase():
    """Pod 1.8.5c Move 7 OP_PHASE_QUERY smoke test"""
    return {'type':'program','body':[
        {'type':'print','value':{'type':'str','value':'=== Phase Query Test (Pod 1.8.5c) ==='}},
        {'type':'print','value':{'type':'str','value':'vm_phase:'}},
        {'type':'print','value':{'type':'phase_query'}},
        {'type':'print','value':{'type':'str','value':'=== Phase test complete ==='}},
    ]}

def demo_energy_recover():
    """Pod 1.8.5c Move 6 OP_ENERGY_RECOVER smoke test (V1.0 no-op)"""
    return {'type':'program','body':[
        {'type':'print','value':{'type':'str','value':'=== Energy Recover Test (Pod 1.8.5c) ==='}},
        {'type':'print','value':{'type':'str','value':'before recover'}},
        {'type':'energy_recover','arg':1234},
        {'type':'print','value':{'type':'str','value':'after recover (no crash)'}},
        {'type':'print','value':{'type':'str','value':'=== Energy recover test complete ==='}},
    ]}

def demo_outcome_ok():
    """Pod 1.9.2b T1 — construct OK Outcome, verify discriminant + value"""
    return {'type':'program','body':[
        {'type':'print','value':{'type':'str','value':'=== Outcome OK Test (Pod 1.9.2b) ==='}},
        {'type':'let','name':'o','value':{
            'type':'outcome_new_ok',
            'value_type_id': TYPE_CODE_SIGN,
            'value': 42,
        }},
        {'type':'print','value':{'type':'str','value':'outcome_id:'}},
        {'type':'print','value':{'type':'var','name':'o'}},
        {'type':'print','value':{'type':'str','value':'is_ok:'}},
        {'type':'print','value':{'type':'outcome_is_ok','operand':{'type':'var','name':'o'}}},
        {'type':'print','value':{'type':'str','value':'value:'}},
        {'type':'print','value':{'type':'outcome_unwrap_ok','operand':{'type':'var','name':'o'}}},
        {'type':'print','value':{'type':'str','value':'=== Outcome OK test complete ==='}},
    ]}

def demo_outcome_err():
    """Pod 1.9.2b T2 — construct ERR Outcome, verify all 4 inline err fields via UNWRAP_ERR"""
    return {'type':'program','body':[
        {'type':'print','value':{'type':'str','value':'=== Outcome ERR Test (Pod 1.9.2b) ==='}},
        {'type':'let','name':'o','value':{
            'type':'outcome_new_err',
            'value_type_id': TYPE_CODE_SIGN,
            'err_code': 99,
            'err_source_op': 0xA0,
            'err_demod_id': 1,
            'err_fetch_counter': 12345,
        }},
        {'type':'print','value':{'type':'str','value':'outcome_id:'}},
        {'type':'print','value':{'type':'var','name':'o'}},
        {'type':'print','value':{'type':'str','value':'is_ok:'}},
        {'type':'print','value':{'type':'outcome_is_ok','operand':{'type':'var','name':'o'}}},
        # UNWRAP_ERR per A1 (verbatim D1.9.1.4): pushes err_code (bottom),
        # err_source_op, err_demod_id, err_fetch_counter (TOS). Print pop-by-pop.
        {'type':'outcome_unwrap_err_stmt','value':{'type':'var','name':'o'}},
        {'type':'print','value':{'type':'str','value':'fetch_counter (TOS):'}},
        {'type':'print','value':{'type':'tos'}},
        {'type':'print','value':{'type':'str','value':'demod_id:'}},
        {'type':'print','value':{'type':'tos'}},
        {'type':'print','value':{'type':'str','value':'source_op:'}},
        {'type':'print','value':{'type':'tos'}},
        {'type':'print','value':{'type':'str','value':'err_code (bottom):'}},
        {'type':'print','value':{'type':'tos'}},
        {'type':'print','value':{'type':'str','value':'=== Outcome ERR test complete ==='}},
    ]}

def demo_outcome_is_ok():
    """Pod 1.9.2b T3 — IS_OK on OK returns 1, IS_OK on ERR returns 0"""
    return {'type':'program','body':[
        {'type':'print','value':{'type':'str','value':'=== IS_OK Test (Pod 1.9.2b) ==='}},
        {'type':'let','name':'a','value':{
            'type':'outcome_new_ok',
            'value_type_id': TYPE_CODE_SIGN, 'value': 1,
        }},
        {'type':'print','value':{'type':'str','value':'is_ok(OK):'}},
        {'type':'print','value':{'type':'outcome_is_ok','operand':{'type':'var','name':'a'}}},
        {'type':'let','name':'b','value':{
            'type':'outcome_new_err',
            'value_type_id': TYPE_CODE_SIGN,
            'err_code': 1, 'err_source_op': 0, 'err_demod_id': 0, 'err_fetch_counter': 0,
        }},
        {'type':'print','value':{'type':'str','value':'is_ok(ERR):'}},
        {'type':'print','value':{'type':'outcome_is_ok','operand':{'type':'var','name':'b'}}},
        {'type':'print','value':{'type':'str','value':'=== IS_OK test complete ==='}},
    ]}

def demo_outcome_unwrap_ok():
    """Pod 1.9.2b T4 — UNWRAP_OK on OK returns value; UNWRAP_OK on ERR returns sentinel + log"""
    return {'type':'program','body':[
        {'type':'print','value':{'type':'str','value':'=== UNWRAP_OK Test (Pod 1.9.2b) ==='}},
        {'type':'let','name':'a','value':{
            'type':'outcome_new_ok',
            'value_type_id': TYPE_CODE_SIGN, 'value': 77,
        }},
        {'type':'print','value':{'type':'str','value':'unwrap_ok(OK):'}},
        {'type':'print','value':{'type':'outcome_unwrap_ok','operand':{'type':'var','name':'a'}}},
        {'type':'let','name':'b','value':{
            'type':'outcome_new_err',
            'value_type_id': TYPE_CODE_SIGN,
            'err_code': 1, 'err_source_op': 0, 'err_demod_id': 0, 'err_fetch_counter': 0,
        }},
        {'type':'print','value':{'type':'str','value':'unwrap_ok(ERR) -- log line + sentinel below:'}},
        {'type':'print','value':{'type':'outcome_unwrap_ok','operand':{'type':'var','name':'b'}}},
        {'type':'print','value':{'type':'str','value':'=== UNWRAP_OK test complete ==='}},
    ]}

def demo_outcome_unwrap_err():
    """Pod 1.9.2b T5 — UNWRAP_ERR on ERR returns 4 fields; UNWRAP_ERR on OK returns 4 sentinels + log"""
    return {'type':'program','body':[
        {'type':'print','value':{'type':'str','value':'=== UNWRAP_ERR Test (Pod 1.9.2b) ==='}},
        # Part (a): UNWRAP_ERR on err
        {'type':'let','name':'a','value':{
            'type':'outcome_new_err',
            'value_type_id': TYPE_CODE_SIGN,
            'err_code': 42, 'err_source_op': 0xA0, 'err_demod_id': 1, 'err_fetch_counter': 99,
        }},
        {'type':'print','value':{'type':'str','value':'unwrap_err(ERR) -- 4 values TOS-first:'}},
        {'type':'outcome_unwrap_err_stmt','value':{'type':'var','name':'a'}},
        {'type':'print','value':{'type':'str','value':'fetch_counter:'}},
        {'type':'print','value':{'type':'tos'}},
        {'type':'print','value':{'type':'str','value':'demod_id:'}},
        {'type':'print','value':{'type':'tos'}},
        {'type':'print','value':{'type':'str','value':'source_op:'}},
        {'type':'print','value':{'type':'tos'}},
        {'type':'print','value':{'type':'str','value':'err_code:'}},
        {'type':'print','value':{'type':'tos'}},
        # Part (b): UNWRAP_ERR on ok
        {'type':'let','name':'b','value':{
            'type':'outcome_new_ok',
            'value_type_id': TYPE_CODE_SIGN, 'value': 0,
        }},
        {'type':'print','value':{'type':'str','value':'unwrap_err(OK) -- log line + 4 sentinels below:'}},
        {'type':'outcome_unwrap_err_stmt','value':{'type':'var','name':'b'}},
        {'type':'print','value':{'type':'str','value':'sentinel_TOS:'}},
        {'type':'print','value':{'type':'tos'}},
        {'type':'print','value':{'type':'str','value':'sentinel_3:'}},
        {'type':'print','value':{'type':'tos'}},
        {'type':'print','value':{'type':'str','value':'sentinel_2:'}},
        {'type':'print','value':{'type':'tos'}},
        {'type':'print','value':{'type':'str','value':'sentinel_bot:'}},
        {'type':'print','value':{'type':'tos'}},
        {'type':'print','value':{'type':'str','value':'=== UNWRAP_ERR test complete ==='}},
    ]}

def demo_sign_invalid_id():
    """Pod 1.9.3 T3 — OP_SIGN_ENERGY on invalid sign_id returns Err Outcome.
    Construct valid Sign (sign_id=1), then call OP_SIGN_ENERGY with sign_id=99 (invalid).
    Verify is_ok=0 and unwrap_err returns 4 fields per A1 verbatim."""
    return {'type':'program','body':[
        {'type':'print','value':{'type':'str','value':'=== Sign Invalid ID Test (Pod 1.9.3 T3) ==='}},
        # Construct a valid Sign so the pool has something
        {'type':'let','name':'s','value':{
            'type':'sign_new',
            'hash': b'\xab' + b'\x00' * 31, 'label': 'hello', 'energy': 42,
        }},
        # Now call OP_SIGN_ENERGY with invalid sign_id=99 → Err Outcome
        # Use raw emission via let-bound int + outcome handler shape
        {'type':'let','name':'o','value':{'type':'sign_energy_raw_id','id':99}},
        {'type':'print','value':{'type':'str','value':'is_ok:'}},
        {'type':'print','value':{'type':'outcome_is_ok','operand':{'type':'var','name':'o'}}},
        {'type':'outcome_unwrap_err_stmt','value':{'type':'var','name':'o'}},
        {'type':'print','value':{'type':'str','value':'fetch_counter (TOS):'}},
        {'type':'print','value':{'type':'tos'}},
        {'type':'print','value':{'type':'str','value':'demod_id:'}},
        {'type':'print','value':{'type':'tos'}},
        {'type':'print','value':{'type':'str','value':'source_op (expect 163 = OP_SIGN_ENERGY):'}},
        {'type':'print','value':{'type':'tos'}},
        {'type':'print','value':{'type':'str','value':'err_code (expect 1 = ERR_INVALID_ID):'}},
        {'type':'print','value':{'type':'tos'}},
        {'type':'print','value':{'type':'str','value':'=== Sign Invalid ID test complete ==='}},
    ]}

def demo_energy_invalid_id():
    """Pod 1.9.3 T4 — OP_ENERGY_JOULES on invalid energy_id returns Err Outcome."""
    return {'type':'program','body':[
        {'type':'print','value':{'type':'str','value':'=== Energy Invalid ID Test (Pod 1.9.3 T4) ==='}},
        {'type':'let','name':'e','value':{
            'type':'energy_new', 'joules': 500, 'source_op': 0xA0,
        }},
        # Call OP_ENERGY_JOULES with invalid energy_id=99 → Err Outcome
        {'type':'let','name':'o','value':{'type':'energy_joules_raw_id','id':99}},
        {'type':'print','value':{'type':'str','value':'is_ok:'}},
        {'type':'print','value':{'type':'outcome_is_ok','operand':{'type':'var','name':'o'}}},
        {'type':'outcome_unwrap_err_stmt','value':{'type':'var','name':'o'}},
        {'type':'print','value':{'type':'str','value':'fetch_counter (TOS):'}},
        {'type':'print','value':{'type':'tos'}},
        {'type':'print','value':{'type':'str','value':'demod_id:'}},
        {'type':'print','value':{'type':'tos'}},
        {'type':'print','value':{'type':'str','value':'source_op (expect 209 = OP_ENERGY_JOULES):'}},
        {'type':'print','value':{'type':'tos'}},
        {'type':'print','value':{'type':'str','value':'err_code (expect 1 = ERR_INVALID_ID):'}},
        {'type':'print','value':{'type':'tos'}},
        {'type':'print','value':{'type':'str','value':'=== Energy Invalid ID test complete ==='}},
    ]}

def demo_stack_underflow():
    """Pod 1.9.3 T5 — trigger OP_RET on empty return stack.
    Pre-violation marker shows program reached the trigger; post-violation
    diagnostic in screen output proves Err Outcome construction completed
    before halt (per S6 layering: Err push → diagnostic → halt)."""
    return {'type':'program','body':[
        {'type':'print','value':{'type':'str','value':'=== Stack Underflow Test (Pod 1.9.3 T5) ==='}},
        {'type':'print','value':{'type':'str','value':'before underflow'}},
        {'type':'print','value':{'type':'str','value':'triggering OP_RET on empty return stack...'}},
        {'type':'raw_op_ret'},   # triggers underflow → diagnostic + Err on stack + halt
        # Anything below here will not execute (VM halted)
        {'type':'print','value':{'type':'str','value':'(this should not appear)'}},
    ]}

def demo_stack_overflow():
    """Pod 1.9.3 T6 — fill return stack via recursive OP_CALL until overflow.
    256-entry vm_ret_stack (per vmdata.asm); test uses a self-call loop."""
    # Simplest approach: emit a function that calls itself recursively without ever
    # returning. Recursion depth = vm_ret_stack capacity = 256 frames before overflow.
    return {'type':'program','body':[
        {'type':'print','value':{'type':'str','value':'=== Stack Overflow Test (Pod 1.9.3 T6) ==='}},
        {'type':'print','value':{'type':'str','value':'before overflow'}},
        {'type':'print','value':{'type':'str','value':'calling self until vm_ret_stack overflows...'}},
        {'type':'raw_call_overflow_burst'},   # emit 300 (PUSH 0; CALL) pairs to overflow vm_ret_stack
        {'type':'print','value':{'type':'str','value':'(this should not appear)'}},
    ]}

def demo_outcome_dup_is_ok():
    """Pod 1.9.2b T6 — DUP-IS_OK pattern: keep outcome_id available for subsequent UNWRAP"""
    # Custom approach: use var(o) for the IS_OK pop (consumes copy from var-table re-push),
    # then var(o) again for UNWRAP_OK. This validates the consume-not-peek convention works
    # with the var-table idiom (functionally equivalent to DUP for stack-based callers).
    return {'type':'program','body':[
        {'type':'print','value':{'type':'str','value':'=== DUP-IS_OK Test (Pod 1.9.2b T6) ==='}},
        {'type':'let','name':'o','value':{
            'type':'outcome_new_ok',
            'value_type_id': TYPE_CODE_SIGN, 'value': 33,
        }},
        {'type':'print','value':{'type':'str','value':'is_ok (consumes one copy):'}},
        {'type':'print','value':{'type':'outcome_is_ok','operand':{'type':'var','name':'o'}}},
        {'type':'print','value':{'type':'str','value':'value (var-retained outcome_id still unwraps):'}},
        {'type':'print','value':{'type':'outcome_unwrap_ok','operand':{'type':'var','name':'o'}}},
        {'type':'print','value':{'type':'str','value':'=== DUP-IS_OK test complete ==='}},
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
    elif '--phase-build' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_phase())
        out = sys.argv[sys.argv.index('--phase-build')+1] if len(sys.argv) > sys.argv.index('--phase-build')+1 else 'test_phase.cbc'
        with open(out,'wb') as f: f.write(bc)
        print(f"Phase test: compiled {len(bc)} bytes -> {out}")
    elif '--phase-test' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_phase())
        print(f"Phase test: {len(bc)} bytes")
    elif '--energy-recover-build' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_energy_recover())
        out = sys.argv[sys.argv.index('--energy-recover-build')+1] if len(sys.argv) > sys.argv.index('--energy-recover-build')+1 else 'test_energy_recover.cbc'
        with open(out,'wb') as f: f.write(bc)
        print(f"Energy recover test: compiled {len(bc)} bytes -> {out}")
    elif '--energy-recover-test' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_energy_recover())
        print(f"Energy recover test: {len(bc)} bytes")
    # --- Pod 1.9.2b Outcome demos (6 build/test pairs) ---
    elif '--outcome-ok-build' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_outcome_ok())
        out = sys.argv[sys.argv.index('--outcome-ok-build')+1] if len(sys.argv) > sys.argv.index('--outcome-ok-build')+1 else 'test_outcome_ok.cbc'
        with open(out,'wb') as f: f.write(bc)
        print(f"Outcome OK test: compiled {len(bc)} bytes -> {out}")
    elif '--outcome-ok-test' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_outcome_ok())
        print(f"Outcome OK test: {len(bc)} bytes")
    elif '--outcome-err-build' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_outcome_err())
        out = sys.argv[sys.argv.index('--outcome-err-build')+1] if len(sys.argv) > sys.argv.index('--outcome-err-build')+1 else 'test_outcome_err.cbc'
        with open(out,'wb') as f: f.write(bc)
        print(f"Outcome ERR test: compiled {len(bc)} bytes -> {out}")
    elif '--outcome-err-test' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_outcome_err())
        print(f"Outcome ERR test: {len(bc)} bytes")
    elif '--outcome-is-ok-build' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_outcome_is_ok())
        out = sys.argv[sys.argv.index('--outcome-is-ok-build')+1] if len(sys.argv) > sys.argv.index('--outcome-is-ok-build')+1 else 'test_outcome_is_ok.cbc'
        with open(out,'wb') as f: f.write(bc)
        print(f"IS_OK test: compiled {len(bc)} bytes -> {out}")
    elif '--outcome-is-ok-test' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_outcome_is_ok())
        print(f"IS_OK test: {len(bc)} bytes")
    elif '--outcome-unwrap-ok-build' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_outcome_unwrap_ok())
        out = sys.argv[sys.argv.index('--outcome-unwrap-ok-build')+1] if len(sys.argv) > sys.argv.index('--outcome-unwrap-ok-build')+1 else 'test_outcome_unwrap_ok.cbc'
        with open(out,'wb') as f: f.write(bc)
        print(f"UNWRAP_OK test: compiled {len(bc)} bytes -> {out}")
    elif '--outcome-unwrap-ok-test' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_outcome_unwrap_ok())
        print(f"UNWRAP_OK test: {len(bc)} bytes")
    elif '--outcome-unwrap-err-build' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_outcome_unwrap_err())
        out = sys.argv[sys.argv.index('--outcome-unwrap-err-build')+1] if len(sys.argv) > sys.argv.index('--outcome-unwrap-err-build')+1 else 'test_outcome_unwrap_err.cbc'
        with open(out,'wb') as f: f.write(bc)
        print(f"UNWRAP_ERR test: compiled {len(bc)} bytes -> {out}")
    elif '--outcome-unwrap-err-test' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_outcome_unwrap_err())
        print(f"UNWRAP_ERR test: {len(bc)} bytes")
    elif '--outcome-dup-is-ok-build' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_outcome_dup_is_ok())
        out = sys.argv[sys.argv.index('--outcome-dup-is-ok-build')+1] if len(sys.argv) > sys.argv.index('--outcome-dup-is-ok-build')+1 else 'test_outcome_dup_is_ok.cbc'
        with open(out,'wb') as f: f.write(bc)
        print(f"DUP-IS_OK test: compiled {len(bc)} bytes -> {out}")
    elif '--outcome-dup-is-ok-test' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_outcome_dup_is_ok())
        print(f"DUP-IS_OK test: {len(bc)} bytes")
    # --- Pod 1.9.3 test surfaces (T3-T6) ---
    elif '--sign-invalid-id-build' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_sign_invalid_id())
        out = sys.argv[sys.argv.index('--sign-invalid-id-build')+1] if len(sys.argv) > sys.argv.index('--sign-invalid-id-build')+1 else 'test_sign_invalid_id.cbc'
        with open(out,'wb') as f: f.write(bc)
        print(f"Sign Invalid ID test: compiled {len(bc)} bytes -> {out}")
    elif '--sign-invalid-id-test' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_sign_invalid_id())
        print(f"Sign Invalid ID test: {len(bc)} bytes")
    elif '--energy-invalid-id-build' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_energy_invalid_id())
        out = sys.argv[sys.argv.index('--energy-invalid-id-build')+1] if len(sys.argv) > sys.argv.index('--energy-invalid-id-build')+1 else 'test_energy_invalid_id.cbc'
        with open(out,'wb') as f: f.write(bc)
        print(f"Energy Invalid ID test: compiled {len(bc)} bytes -> {out}")
    elif '--energy-invalid-id-test' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_energy_invalid_id())
        print(f"Energy Invalid ID test: {len(bc)} bytes")
    elif '--stack-underflow-build' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_stack_underflow())
        out = sys.argv[sys.argv.index('--stack-underflow-build')+1] if len(sys.argv) > sys.argv.index('--stack-underflow-build')+1 else 'test_stack_underflow.cbc'
        with open(out,'wb') as f: f.write(bc)
        print(f"Stack Underflow test: compiled {len(bc)} bytes -> {out}")
    elif '--stack-underflow-test' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_stack_underflow())
        print(f"Stack Underflow test: {len(bc)} bytes")
    elif '--stack-overflow-build' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_stack_overflow())
        out = sys.argv[sys.argv.index('--stack-overflow-build')+1] if len(sys.argv) > sys.argv.index('--stack-overflow-build')+1 else 'test_stack_overflow.cbc'
        with open(out,'wb') as f: f.write(bc)
        print(f"Stack Overflow test: compiled {len(bc)} bytes -> {out}")
    elif '--stack-overflow-test' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_stack_overflow())
        print(f"Stack Overflow test: {len(bc)} bytes")
    else:
        print("Usage: python3 atreyu_x86.py --build [out.cbc] | --test | --sign-build [out.cbc] | --sign-test | --energy-build [out.cbc] | --energy-test | --phase-build [out.cbc] | --energy-recover-build [out.cbc] | --outcome-{ok,err,is-ok,unwrap-ok,unwrap-err,dup-is-ok}-{build,test}")
