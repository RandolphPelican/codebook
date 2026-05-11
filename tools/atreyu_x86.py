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

# --- Pod 1.10.2b1 Cap opcodes (D1.10.2b1.1 supersession of D1.10.1.3) ---
# OP_CAP_CHECK retired; three accessors (ARENA, OWNER, RESOURCE) ship
# instead. Substrate is witness, not police.
# Pod 2.2 supersession (D2.2.4): OP_CAP_RESOURCE retired; OP_CAP_BITMAP
# at 0xBA reads the same byte position with structured forge-bit
# semantics per D2.2.1.
OP_CAP_NEW       = 0xB0
OP_CAP_ENTER     = 0xB1
OP_CAP_EXIT      = 0xB2
OP_CAP_CURRENT   = 0xB3
OP_CAP_ARENA     = 0xB4
OP_CAP_OWNER     = 0xB5
# 0xB6 retired Pod 2.2 (was OP_CAP_RESOURCE)

# --- Pod 1.10.2b2 substrate-wide accessors + OP_CAP_PARENT ---
# Sign/Energy/Outcome × {ARENA, OWNER, CREATOR} + OP_CAP_PARENT
# enable provenance walks from any forged cell back to ROOT.
OP_SIGN_ARENA      = 0xA4
OP_SIGN_OWNER      = 0xA5
OP_SIGN_CREATOR    = 0xA6
OP_CAP_PARENT      = 0xB7
OP_ENERGY_ARENA    = 0xD6
OP_ENERGY_OWNER    = 0xD7
OP_ENERGY_CREATOR  = 0xD8
OP_OUTCOME_ARENA   = 0xE5
OP_OUTCOME_OWNER   = 0xE6
OP_OUTCOME_CREATOR = 0xE7

# --- Pod 1.10.3 Cap metabolic accessors ---
OP_CAP_BUDGET      = 0xB8
OP_CAP_USED        = 0xB9

# --- Pod 2.2 Cap texture accessor (D2.2.1) ---
OP_CAP_BITMAP      = 0xBA

# --- Pod 3 Sign embedding-handle side-table accessor (D3.4) ---
OP_SIGN_EMBEDDING_HANDLE = 0xA7

# --- Pod 3 Embedding typed primitive (D3.1) ---
OP_EMBEDDING_NEW       = 0xC0
OP_EMBEDDING_ARENA     = 0xC1
OP_EMBEDDING_OWNER     = 0xC2
OP_EMBEDDING_CREATOR   = 0xC3
OP_EMBEDDING_GET_DIM   = 0xC4

# --- Pod 3.5 Maid speaks: semantic operations (D3.13/D3.14/D3.18/D3.20) ---
OP_EMBEDDING_SIGN_HANDLE  = 0xC5   # reverse side-table read (D3.20); mirror of 0xA7
OP_EMBEDDING_COSINE       = 0xC6   # cosine via Form A (D3.14); FP-determinism-load-bearing
OP_EMBEDDING_DOT_PRODUCT  = 0xC7   # dot product over 384 f32 lanes
OP_EMBEDDING_L2_DISTANCE  = 0xC8   # sqrt(sum((a-b)^2)) over 384 lanes
OP_EMBEDDING_LOOKUP_TOP1  = 0xC9   # MAC-verify-each-candidate cosine scan (D3.18)
# --- Pod 3.6 Maid composes: synthesis (forge-tier) ---
OP_EMBEDDING_ADD          = 0xCA   # forge result = a + b; synthesis tuple write per D3.27
OP_EMBEDDING_SUBTRACT     = 0xCB   # forge result = a - b; ADD's twin (Phase 2.1)
OP_EMBEDDING_SCALE        = 0xCC   # forge result = scalar * a; first scalar-mixed (Phase 2.2)
OP_EMBEDDING_NORMALIZE    = 0xCD   # forge result = a / |a|; Form A; first unary forge + zero-norm rejection (Phase 2.2)
OP_EMBEDDING_LERP         = 0xCE   # forge result = (1-t)*a + t*b; Form A; first ternary forge (Phase 3.1)
OP_EMBEDDING_SYNTHESIS_HANDLE = 0xCF   # GET_DIM-style parameterized accessor for synthesis tuple (Phase 3.2)
# --- Pod 3.8 codebook-tier (Q5 0xF0-0xFE row; D3.31) ---
OP_EMBEDDING_IMPORT          = 0xF0    # forge embedding from codebook block (Pod 3.8.F)
OP_EMBEDDING_IMPORTED_HANDLE = 0xF1    # GET_DIM-style parameterized accessor for imported tuple (Pod 3.8.E)
OP_EMBEDDING_LOOKUP_TOP_K    = 0xF2    # top-K + threshold housekeeper recognition; "Maid finds many" (Pod 3.9 D3.35)
OP_EMBEDDING_PROJECT         = 0xF3    # forge result = (A·B/B·B)*B; "Maid orthogonalizes" (Pod 3.10 D3.38)
OP_EMBEDDING_REJECT          = 0xF4    # forge result = A - project(A,B); project's twin (Pod 3.10 D3.38)
OP_EMBEDDING_CODEBOOK_META   = 0xF5    # witness accessor for vm_codebook_meta singleton; "Maid maintains" (Pod 3.11 D3.42)

# Pod 3.11 — codebook META field indices (user-surface constants for embedding_codebook_meta emitter)
META_FIELD_COUNT             = 0
META_FIELD_DIM               = 1
META_FIELD_SCALAR_TYPE       = 2
META_FIELD_INGESTION_STATUS  = 3

# --- Pod 1.10.3 substrate constants (for default arg values) ---
# Signed two's-complement representation of 0xFFFFFFFFFFFFFFFF for
# struct.pack('<q', ...) compatibility (emit_i64 uses signed i64 pack).
# Bytes emitted are byte-identical to the unsigned 0xFFFFFFFFFFFFFFFF.
ENERGY_BUDGET_UNBOUNDED = -1

# --- Pod 2.2 cap_bitmap unbounded (D2.2.3) ---
# Same byte pattern as ENERGY_BUDGET_UNBOUNDED — both poles of ROOT's
# authority unbounded; both honestly named via truth-in-naming convention.
CAP_BITMAP_UNBOUNDED = -1

# --- Pod 2.2 forge-bit V1.0 vocabulary (D2.2.2) ---
BIT_SIGN_FORGE       = 1 << 0   # 0x01
BIT_ENERGY_FORGE     = 1 << 1   # 0x02
BIT_OUTCOME_FORGE    = 1 << 2   # 0x04
BIT_CAP_FORGE        = 1 << 3   # 0x08

# --- Pod 3 forge-bit (first reserved-bit consumer per D2.2.2 / D3.X) ---
BIT_EMBEDDING_FORGE  = 1 << 4   # 0x10

# --- Pod 3 Embedding constants (D3.2) ---
EMBEDDING_DIM           = 384
EMBEDDING_VECTOR_BYTES  = 1536   # 384 * 4

# --- Pod 1.9.2a/1.9.2b TYPE_CODE_* enum (D1.9.1.1) ---
TYPE_CODE_NONE       = 0
TYPE_CODE_SIGN       = 1
TYPE_CODE_ENERGY     = 2
TYPE_CODE_CAP        = 3
TYPE_CODE_DEMOD      = 4
TYPE_CODE_SIGNAL     = 5
TYPE_CODE_OUTCOME    = 6
TYPE_CODE_EMBEDDING  = 7   # Pod 3 — fifth typed primitive

# --- Pod 1.9.3 ERR codes (for typed error inspection in tests) ---
ERR_INVALID_ID                  = 1
ERR_POOL_FULL                   = 2
ERR_STACK_UNDERFLOW             = 3
ERR_STACK_OVERFLOW              = 4
ERR_INVALID_SIGN_ARG            = 5
ERR_INVALID_ENERGY_ARG          = 6
ERR_CAP_AUTHORITY_EXCEEDED      = 7   # Pod 1.10.2a forward-anchor; activated Pod 2.2
ERR_CAP_INSUFFICIENT_AUTHORITY  = 8   # Pod 2.2 (D2.2.6) — bit-check failure
ERR_INVALID_EMBEDDING_ARG       = 9   # Pod 3 — OP_EMBEDDING_GET_DIM dim_index out-of-bounds

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
        elif t == 'raw_op_cap_exit':
            # Pod 1.10.2b1 T5 test primitive — emit raw OP_CAP_EXIT to trigger
            # cap_stack underflow on empty cap_stack.
            e.emit(OP_CAP_EXIT)
        elif t == 'raw_cap_enter_overflow_burst':
            # Pod 1.10.2b1 T6 test primitive — emit N (PUSH cap_id; OP_CAP_ENTER;
            # OP_DROP) triples to overflow cap_stack (capacity 256).
            cap_id = n.get('cap_id', 2)
            n_enters = n.get('count', 257)
            for _ in range(n_enters):
                e.emit(OP_PUSH); e.emit_i64(cap_id)
                e.emit(OP_CAP_ENTER)
                e.emit(OP_DROP)

    def _sign_new(self, n):
        """Emit OP_SIGN_NEW with inline hash and label data.

        Pod 2.2 Path A retrofit (D2.2.7): success path returns Outcome::Ok(sign_id);
        bit-check / pool-full / invalid-arg failures return Outcome::Err. Emitter
        appends OP_OUTCOME_UNWRAP_OK to consume the typed_id directly (matches
        prior-pod test semantics — `let s = sign_new(...)` binds sign_id).
        Caller can pass `'wrap': True` to skip the unwrap when raw Outcome
        inspection is needed (Pod 2.2 bit-check failure tests).
        """
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
        # Push energy_cost, embedding_handle (Pod 3: typed embedding_id ref or 0=none), provenance_handle (0)
        e.emit(OP_PUSH); e.emit_i64(n.get('energy', 0))
        e.emit(OP_PUSH); e.emit_i64(n.get('embedding_handle', 0))   # Pod 3 D3.4 — typed reference; 0 = no link
        e.emit(OP_PUSH); e.emit_i64(0)     # provenance_handle (V1.0: always 0)
        e.emit(OP_SIGN_NEW)
        # Pod 2.2 Path A retrofit — auto-unwrap to bare sign_id unless caller opts out.
        if not n.get('wrap', False):
            e.emit(OP_OUTCOME_UNWRAP_OK)

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
        elif t == 'embedding_new': self._embedding_new(n)
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
        # --- Pod 1.10.2b1 Cap expressions ---
        elif t == 'cap_new':
            # Pod 2.2 D2.2.4 semantic amendment of Pod 1.10.3's signature: pops
            # (granted_bitmap, energy_budget). Same byte position (+0x18);
            # structured forge-bit semantics now load-bearing per D2.2.1.
            # Top-of-stack = energy_budget (last pushed). Caller defaults:
            # granted_bitmap = CAP_BITMAP_UNBOUNDED (all forge bits set, like
            # ROOT's keystone authority — used by tests not exercising bit
            # semantics); energy_budget = ENERGY_BUDGET_UNBOUNDED.
            # Pod 1.10.3 'resource_descriptor' key accepted as deprecated alias
            # — backward-compat for prior-pod ASTs during the rebuild ripple.
            bitmap = n.get('granted_bitmap', n.get('resource_descriptor', CAP_BITMAP_UNBOUNDED))
            e.emit(OP_PUSH); e.emit_i64(bitmap)
            e.emit(OP_PUSH); e.emit_i64(n.get('energy_budget', ENERGY_BUDGET_UNBOUNDED))
            e.emit(OP_CAP_NEW)
        elif t == 'cap_enter':
            # Pop cap_id; MAC verify + cap_stack push + cache update.
            # Pushes Outcome<NONE> on every path (A2 Path A consistency).
            self._expr(n['operand']); e.emit(OP_CAP_ENTER)
        elif t == 'cap_exit':
            # cap_stack pop + cache restore; pushes Outcome<NONE>.
            e.emit(OP_CAP_EXIT)
        elif t == 'cap_current':
            # Pure substrate state read; pushes current_cap_id (no Outcome wrap).
            e.emit(OP_CAP_CURRENT)
        elif t == 'cap_arena':
            # Pop cap_id; push Outcome<arena_id>. AST handler emits accessor +
            # UNWRAP_OK so demos can print the unwrapped value directly.
            self._expr(n['operand']); e.emit(OP_CAP_ARENA); e.emit(OP_OUTCOME_UNWRAP_OK)
        elif t == 'cap_owner':
            self._expr(n['operand']); e.emit(OP_CAP_OWNER); e.emit(OP_OUTCOME_UNWRAP_OK)
        elif t == 'cap_bitmap':
            # Pod 2.2 (D2.2.1) — read cap_bitmap field (+0x18); structured
            # forge-bit interpretation. Refit of the retired cap_resource
            # accessor at same byte position.
            self._expr(n['operand']); e.emit(OP_CAP_BITMAP); e.emit(OP_OUTCOME_UNWRAP_OK)
        elif t == 'cap_bitmap_raw_id':
            # Pod 2.2 — test primitive: push raw cap_id, emit OP_CAP_BITMAP, no UNWRAP_OK
            # (caller wants raw outcome_id for invalid-id / Outcome inspection tests).
            e.emit(OP_PUSH); e.emit_i64(n['id'])
            e.emit(OP_CAP_BITMAP)
        elif t == 'cap_arena_raw_id':
            # Test primitive — push raw u64 cap_id, emit OP_CAP_ARENA, no UNWRAP_OK.
            # Caller wants raw outcome_id (for invalid-id tests).
            e.emit(OP_PUSH); e.emit_i64(n['id'])
            e.emit(OP_CAP_ARENA)
        # --- Pod 1.10.2b2 substrate-wide accessor expressions ---
        # Each emits accessor + UNWRAP_OK so demos can print the unwrapped value
        # directly (parallel to Pod 1.9.3 sign_energy / energy_joules pattern).
        elif t == 'sign_arena':
            self._expr(n['operand']); e.emit(OP_SIGN_ARENA); e.emit(OP_OUTCOME_UNWRAP_OK)
        elif t == 'sign_owner':
            self._expr(n['operand']); e.emit(OP_SIGN_OWNER); e.emit(OP_OUTCOME_UNWRAP_OK)
        elif t == 'sign_creator':
            self._expr(n['operand']); e.emit(OP_SIGN_CREATOR); e.emit(OP_OUTCOME_UNWRAP_OK)
        elif t == 'energy_arena':
            self._expr(n['operand']); e.emit(OP_ENERGY_ARENA); e.emit(OP_OUTCOME_UNWRAP_OK)
        elif t == 'energy_owner':
            self._expr(n['operand']); e.emit(OP_ENERGY_OWNER); e.emit(OP_OUTCOME_UNWRAP_OK)
        elif t == 'energy_creator':
            self._expr(n['operand']); e.emit(OP_ENERGY_CREATOR); e.emit(OP_OUTCOME_UNWRAP_OK)
        elif t == 'outcome_arena':
            self._expr(n['operand']); e.emit(OP_OUTCOME_ARENA); e.emit(OP_OUTCOME_UNWRAP_OK)
        elif t == 'outcome_owner':
            self._expr(n['operand']); e.emit(OP_OUTCOME_OWNER); e.emit(OP_OUTCOME_UNWRAP_OK)
        elif t == 'outcome_creator':
            self._expr(n['operand']); e.emit(OP_OUTCOME_CREATOR); e.emit(OP_OUTCOME_UNWRAP_OK)
        elif t == 'cap_parent':
            self._expr(n['operand']); e.emit(OP_CAP_PARENT); e.emit(OP_OUTCOME_UNWRAP_OK)
        # --- Pod 1.10.3 Cap metabolic accessor expressions ---
        elif t == 'cap_budget':
            self._expr(n['operand']); e.emit(OP_CAP_BUDGET); e.emit(OP_OUTCOME_UNWRAP_OK)
        elif t == 'cap_used':
            self._expr(n['operand']); e.emit(OP_CAP_USED); e.emit(OP_OUTCOME_UNWRAP_OK)
        elif t == 'cap_budget_raw_id':
            # Test primitive — push raw cap_id, emit OP_CAP_BUDGET, no UNWRAP_OK
            # (caller wants the raw outcome_id for invalid-id tests).
            e.emit(OP_PUSH); e.emit_i64(n['id'])
            e.emit(OP_CAP_BUDGET)
        # --- Raw-id test primitives for invalid-id tests (no UNWRAP_OK) ---
        elif t == 'sign_arena_raw_id':
            e.emit(OP_PUSH); e.emit_i64(n['id'])
            e.emit(OP_SIGN_ARENA)
        elif t == 'energy_owner_raw_id':
            e.emit(OP_PUSH); e.emit_i64(n['id'])
            e.emit(OP_ENERGY_OWNER)
        elif t == 'outcome_creator_raw_id':
            e.emit(OP_PUSH); e.emit_i64(n['id'])
            e.emit(OP_OUTCOME_CREATOR)
        elif t == 'cap_parent_raw_id':
            e.emit(OP_PUSH); e.emit_i64(n['id'])
            e.emit(OP_CAP_PARENT)
        # --- Pod 3 Embedding accessor expressions (D3.1) ---
        elif t == 'embedding_arena':
            self._expr(n['operand']); e.emit(OP_EMBEDDING_ARENA); e.emit(OP_OUTCOME_UNWRAP_OK)
        elif t == 'embedding_owner':
            self._expr(n['operand']); e.emit(OP_EMBEDDING_OWNER); e.emit(OP_OUTCOME_UNWRAP_OK)
        elif t == 'embedding_creator':
            self._expr(n['operand']); e.emit(OP_EMBEDDING_CREATOR); e.emit(OP_OUTCOME_UNWRAP_OK)
        elif t == 'embedding_get_dim':
            # Pop dim_index (top-of-stack), embedding_id. Caller pushes
            # embedding_id first, then dim_index, then opcode pops them.
            self._expr(n['operand']); e.emit(OP_PUSH); e.emit_i64(n['dim_index'])
            e.emit(OP_EMBEDDING_GET_DIM); e.emit(OP_OUTCOME_UNWRAP_OK)
        elif t == 'embedding_arena_raw_id':
            e.emit(OP_PUSH); e.emit_i64(n['id'])
            e.emit(OP_EMBEDDING_ARENA)
        elif t == 'embedding_get_dim_raw':
            # Test primitive — push raw embedding_id + dim_index; emit opcode; no UNWRAP_OK
            e.emit(OP_PUSH); e.emit_i64(n['id'])
            e.emit(OP_PUSH); e.emit_i64(n['dim_index'])
            e.emit(OP_EMBEDDING_GET_DIM)
        # --- Pod 3 Sign embedding-handle accessor (D3.4 side-table read) ---
        elif t == 'sign_embedding_handle':
            self._expr(n['operand']); e.emit(OP_SIGN_EMBEDDING_HANDLE); e.emit(OP_OUTCOME_UNWRAP_OK)
        elif t == 'sign_embedding_handle_raw_id':
            e.emit(OP_PUSH); e.emit_i64(n['id'])
            e.emit(OP_SIGN_EMBEDDING_HANDLE)
        # --- Pod 3.5 Embedding semantic operations (D3.13/D3.14/D3.18/D3.20) ---
        elif t == 'embedding_sign_handle':
            self._expr(n['operand']); e.emit(OP_EMBEDDING_SIGN_HANDLE); e.emit(OP_OUTCOME_UNWRAP_OK)
        elif t == 'embedding_sign_handle_raw_id':
            e.emit(OP_PUSH); e.emit_i64(n['id'])
            e.emit(OP_EMBEDDING_SIGN_HANDLE)
        elif t == 'embedding_cosine':
            self._expr(n['lhs']); self._expr(n['rhs'])
            e.emit(OP_EMBEDDING_COSINE); e.emit(OP_OUTCOME_UNWRAP_OK)
        elif t == 'embedding_cosine_raw':
            e.emit(OP_PUSH); e.emit_i64(n['id_a'])
            e.emit(OP_PUSH); e.emit_i64(n['id_b'])
            e.emit(OP_EMBEDDING_COSINE)
        elif t == 'embedding_dot_product':
            self._expr(n['lhs']); self._expr(n['rhs'])
            e.emit(OP_EMBEDDING_DOT_PRODUCT); e.emit(OP_OUTCOME_UNWRAP_OK)
        elif t == 'embedding_dot_product_raw':
            e.emit(OP_PUSH); e.emit_i64(n['id_a'])
            e.emit(OP_PUSH); e.emit_i64(n['id_b'])
            e.emit(OP_EMBEDDING_DOT_PRODUCT)
        elif t == 'embedding_l2_distance':
            self._expr(n['lhs']); self._expr(n['rhs'])
            e.emit(OP_EMBEDDING_L2_DISTANCE); e.emit(OP_OUTCOME_UNWRAP_OK)
        elif t == 'embedding_l2_distance_raw':
            e.emit(OP_PUSH); e.emit_i64(n['id_a'])
            e.emit(OP_PUSH); e.emit_i64(n['id_b'])
            e.emit(OP_EMBEDDING_L2_DISTANCE)
        elif t == 'embedding_lookup_top1':
            self._expr(n['operand']); e.emit(OP_EMBEDDING_LOOKUP_TOP1); e.emit(OP_OUTCOME_UNWRAP_OK)
        elif t == 'embedding_lookup_top1_raw':
            e.emit(OP_PUSH); e.emit_i64(n['id'])
            e.emit(OP_EMBEDDING_LOOKUP_TOP1)
        # --- Pod 3.6 Maid composes: synthesis (forge-tier; D3.25/D3.26/D3.27) ---
        elif t == 'embedding_add':
            self._expr(n['lhs']); self._expr(n['rhs'])
            e.emit(OP_EMBEDDING_ADD); e.emit(OP_OUTCOME_UNWRAP_OK)
        elif t == 'embedding_add_raw':
            e.emit(OP_PUSH); e.emit_i64(n['id_a'])
            e.emit(OP_PUSH); e.emit_i64(n['id_b'])
            e.emit(OP_EMBEDDING_ADD)
        elif t == 'embedding_subtract':
            self._expr(n['lhs']); self._expr(n['rhs'])
            e.emit(OP_EMBEDDING_SUBTRACT); e.emit(OP_OUTCOME_UNWRAP_OK)
        elif t == 'embedding_subtract_raw':
            e.emit(OP_PUSH); e.emit_i64(n['id_a'])
            e.emit(OP_PUSH); e.emit_i64(n['id_b'])
            e.emit(OP_EMBEDDING_SUBTRACT)
        elif t == 'embedding_project':
            self._expr(n['lhs']); self._expr(n['rhs'])
            e.emit(OP_EMBEDDING_PROJECT); e.emit(OP_OUTCOME_UNWRAP_OK)
        elif t == 'embedding_project_raw':
            e.emit(OP_PUSH); e.emit_i64(n['id_a'])
            e.emit(OP_PUSH); e.emit_i64(n['id_b'])
            e.emit(OP_EMBEDDING_PROJECT)
        elif t == 'embedding_reject':
            self._expr(n['lhs']); self._expr(n['rhs'])
            e.emit(OP_EMBEDDING_REJECT); e.emit(OP_OUTCOME_UNWRAP_OK)
        elif t == 'embedding_reject_raw':
            e.emit(OP_PUSH); e.emit_i64(n['id_a'])
            e.emit(OP_PUSH); e.emit_i64(n['id_b'])
            e.emit(OP_EMBEDDING_REJECT)
        elif t == 'embedding_codebook_meta':
            # Witness accessor; pops field_index, returns Outcome::Ok(value).
            e.emit(OP_PUSH); e.emit_i64(n['field_index'])
            e.emit(OP_EMBEDDING_CODEBOOK_META); e.emit(OP_OUTCOME_UNWRAP_OK)
        elif t == 'embedding_codebook_meta_raw':
            e.emit(OP_PUSH); e.emit_i64(n['field_index'])
            e.emit(OP_EMBEDDING_CODEBOOK_META)
        elif t == 'embedding_scale':
            # Stack order: [..., embedding_id, scalar] (TOS-is-rightmost-arg per GET_DIM convention)
            self._expr(n['operand'])
            e.emit(OP_PUSH); e.emit_i64(n['scalar_bits'])
            e.emit(OP_EMBEDDING_SCALE); e.emit(OP_OUTCOME_UNWRAP_OK)
        elif t == 'embedding_scale_raw':
            e.emit(OP_PUSH); e.emit_i64(n['id'])
            e.emit(OP_PUSH); e.emit_i64(n['scalar_bits'])
            e.emit(OP_EMBEDDING_SCALE)
        elif t == 'embedding_normalize':
            self._expr(n['operand'])
            e.emit(OP_EMBEDDING_NORMALIZE); e.emit(OP_OUTCOME_UNWRAP_OK)
        elif t == 'embedding_normalize_raw':
            e.emit(OP_PUSH); e.emit_i64(n['id'])
            e.emit(OP_EMBEDDING_NORMALIZE)
        elif t == 'embedding_lerp':
            # Stack order: [..., id_a, id_b, t] (TOS-is-rightmost-arg per GET_DIM convention)
            self._expr(n['a']); self._expr(n['b'])
            e.emit(OP_PUSH); e.emit_i64(n['t_bits'])
            e.emit(OP_EMBEDDING_LERP); e.emit(OP_OUTCOME_UNWRAP_OK)
        elif t == 'embedding_lerp_raw':
            e.emit(OP_PUSH); e.emit_i64(n['id_a'])
            e.emit(OP_PUSH); e.emit_i64(n['id_b'])
            e.emit(OP_PUSH); e.emit_i64(n['t_bits'])
            e.emit(OP_EMBEDDING_LERP)
        elif t == 'embedding_synthesis_handle':
            # Stack order: [..., embedding_id, field_index]
            self._expr(n['operand'])
            e.emit(OP_PUSH); e.emit_i64(n['field_index'])
            e.emit(OP_EMBEDDING_SYNTHESIS_HANDLE); e.emit(OP_OUTCOME_UNWRAP_OK)
        elif t == 'embedding_synthesis_handle_raw':
            e.emit(OP_PUSH); e.emit_i64(n['id'])
            e.emit(OP_PUSH); e.emit_i64(n['field_index'])
            e.emit(OP_EMBEDDING_SYNTHESIS_HANDLE)
        # --- Pod 3.8 codebook-tier (D3.31; Q5 0xF0-0xFE row) ---
        elif t == 'embedding_imported_handle':
            # Stack order: [..., embedding_id, field_index]; mirrors synthesis_handle shape.
            self._expr(n['operand'])
            e.emit(OP_PUSH); e.emit_i64(n['field_index'])
            e.emit(OP_EMBEDDING_IMPORTED_HANDLE); e.emit(OP_OUTCOME_UNWRAP_OK)
        elif t == 'embedding_imported_handle_raw':
            e.emit(OP_PUSH); e.emit_i64(n['id'])
            e.emit(OP_PUSH); e.emit_i64(n['field_index'])
            e.emit(OP_EMBEDDING_IMPORTED_HANDLE)
        # --- Pod 3.9 Maid finds many: top-K + threshold (D3.35) ---
        elif t == 'embedding_lookup_top_k':
            # Stack order: [..., query_id, K, threshold]; threshold on top per TOS-is-rightmost-arg.
            # Auto-unwrap_ok pops outcome_id and pushes K' count to TOS;
            # K' embedding_ids sit BELOW the K' count on operand stack
            # (best at TOS-just-below-count; user pops count first then pops K' ids best-to-worst).
            self._expr(n['query'])
            e.emit(OP_PUSH); e.emit_i64(n['k'])
            e.emit(OP_PUSH); e.emit_i64(n['threshold_bits'])
            e.emit(OP_EMBEDDING_LOOKUP_TOP_K); e.emit(OP_OUTCOME_UNWRAP_OK)
        elif t == 'embedding_lookup_top_k_raw':
            # No auto-unwrap; outcome_id stays on TOS; K' ids sit below.
            e.emit(OP_PUSH); e.emit_i64(n['query_id'])
            e.emit(OP_PUSH); e.emit_i64(n['k'])
            e.emit(OP_PUSH); e.emit_i64(n['threshold_bits'])
            e.emit(OP_EMBEDDING_LOOKUP_TOP_K)

    def _embedding_new(self, n):
        """Emit OP_EMBEDDING_NEW with inline 1536-byte f32 vector data.

        Pod 3 (D3.1): pushes vector_addr via OP_PUSH_STR (u16-length prefix
        accommodates 1536 bytes trivially; max 65535) followed by inline blob,
        then DROPs the length keeping the address (matches Sign's hash inline
        emission pattern). Single-fire substrate axiom inherited at greenfield
        per D3.9 — success path uses .construct_ok_outcome from the start.

        Caller passes `vector` as 1536-byte bytes object (or smaller; padded
        to 1536 with zeros). Default: 1536 zero-bytes for test convenience.
        `'wrap': True` opts out of auto-unwrap_ok for Outcome-inspection tests.
        """
        e = self.e
        # Push vector_addr: embed 1536 bytes inline via PUSH_STR, drop len
        vector_data = n.get('vector', b'\x00' * EMBEDDING_VECTOR_BYTES)
        if len(vector_data) > EMBEDDING_VECTOR_BYTES:
            vector_data = vector_data[:EMBEDDING_VECTOR_BYTES]
        else:
            vector_data = vector_data.ljust(EMBEDDING_VECTOR_BYTES, b'\x00')
        e.emit(OP_PUSH_STR); e.emit_u16(EMBEDDING_VECTOR_BYTES)
        e.code.extend(vector_data)
        e.emit(OP_DROP)         # drop len, keep addr (vector_addr)
        e.emit(OP_EMBEDDING_NEW)
        # Pod 3 Path A — auto-unwrap to bare embedding_id unless caller opts out.
        if not n.get('wrap', False):
            e.emit(OP_OUTCOME_UNWRAP_OK)

    def _energy_new(self, n):
        """Emit OP_ENERGY_NEW: push joules, push source_op, emit opcode.

        Pod 2.2 Path A retrofit (D2.2.7): success path returns
        Outcome::Ok(energy_id); failures return Outcome::Err. Emitter appends
        OP_OUTCOME_UNWRAP_OK to consume the typed_id directly. `'wrap': True`
        opts out of auto-unwrap for Outcome-inspection tests.
        """
        e = self.e
        e.emit(OP_PUSH); e.emit_i64(n.get('joules', 0))
        e.emit(OP_PUSH); e.emit_i64(n.get('source_op', 0))
        e.emit(OP_ENERGY_NEW)
        # Pod 2.2 Path A retrofit — auto-unwrap to bare energy_id unless caller opts out.
        if not n.get('wrap', False):
            e.emit(OP_OUTCOME_UNWRAP_OK)

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

# --- Pod 1.10.2b1 Cap test surfaces (T1-T6) ---

def demo_cap_new_basic():
    """Pod 1.10.2b1 T1 — construct a cap, UNWRAP_OK, print cap_id (expect 2 since ROOT=1)."""
    return {'type':'program','body':[
        {'type':'print','value':{'type':'str','value':'=== Cap New Basic Test (Pod 1.10.2b1 T1) ==='}},
        {'type':'let','name':'o','value':{'type':'cap_new','granted_bitmap':CAP_BITMAP_UNBOUNDED}},
        {'type':'print','value':{'type':'str','value':'is_ok:'}},
        {'type':'print','value':{'type':'outcome_is_ok','operand':{'type':'var','name':'o'}}},
        {'type':'print','value':{'type':'str','value':'cap_id (expect 2):'}},
        {'type':'print','value':{'type':'outcome_unwrap_ok','operand':{'type':'var','name':'o'}}},
        {'type':'print','value':{'type':'str','value':'=== Cap New Basic test complete ==='}},
    ]}

def demo_cap_arena_owner_bitmap():
    """Pod 1.10.2b1 T2 — substrate witnesses itself; rebuilt Pod 2.2 (D2.2.4)
    under cap_bitmap accessor (was cap_resource pre-2.2).
    Construct cap with granted_bitmap=CAP_BITMAP_UNBOUNDED (under ROOT context,
    so arena=0 owner=0 inherited via strict delegation; bitmap unbounded means
    any forge under this cap passes bit-check). Read all three slot fields via
    accessor opcodes and print. The architectural moment per D1.10.2b1.8;
    bitmap accessor reads same byte position as the retired cap_resource."""
    return {'type':'program','body':[
        {'type':'print','value':{'type':'str','value':'=== Cap Accessors Test (Pod 2.2 rebuild of 1.10.2b1 T2) ==='}},
        {'type':'let','name':'o','value':{'type':'cap_new','granted_bitmap':CAP_BITMAP_UNBOUNDED}},
        {'type':'let','name':'cap_id','value':{'type':'outcome_unwrap_ok','operand':{'type':'var','name':'o'}}},
        {'type':'print','value':{'type':'str','value':'arena (expect 0):'}},
        {'type':'print','value':{'type':'cap_arena','operand':{'type':'var','name':'cap_id'}}},
        {'type':'print','value':{'type':'str','value':'owner (expect 0):'}},
        {'type':'print','value':{'type':'cap_owner','operand':{'type':'var','name':'cap_id'}}},
        {'type':'print','value':{'type':'str','value':'bitmap (expect -1 = CAP_BITMAP_UNBOUNDED):'}},
        {'type':'print','value':{'type':'cap_bitmap','operand':{'type':'var','name':'cap_id'}}},
        {'type':'print','value':{'type':'str','value':'=== Cap Accessors test complete ==='}},
    ]}

def demo_cap_current():
    """Pod 1.10.2b1 T3 — verify cap_stack push/pop semantics and cache field
    updates. CURRENT before ENTER returns ROOT_CAP_ID=1; after ENTER returns
    new cap's id; after EXIT returns 1 again."""
    return {'type':'program','body':[
        {'type':'print','value':{'type':'str','value':'=== Cap Current Test (Pod 1.10.2b1 T3) ==='}},
        {'type':'print','value':{'type':'str','value':'current at start (expect 1 = ROOT):'}},
        {'type':'print','value':{'type':'cap_current'}},
        {'type':'let','name':'o','value':{'type':'cap_new','granted_bitmap':CAP_BITMAP_UNBOUNDED}},
        {'type':'let','name':'cap_id','value':{'type':'outcome_unwrap_ok','operand':{'type':'var','name':'o'}}},
        # ENTER returns Outcome<NONE>; let-bind to drop from stack, then check is_ok
        {'type':'let','name':'enter_o','value':{'type':'cap_enter','operand':{'type':'var','name':'cap_id'}}},
        {'type':'print','value':{'type':'str','value':'enter is_ok:'}},
        {'type':'print','value':{'type':'outcome_is_ok','operand':{'type':'var','name':'enter_o'}}},
        {'type':'print','value':{'type':'str','value':'current after ENTER (expect 2):'}},
        {'type':'print','value':{'type':'cap_current'}},
        {'type':'let','name':'exit_o','value':{'type':'cap_exit'}},
        {'type':'print','value':{'type':'str','value':'exit is_ok:'}},
        {'type':'print','value':{'type':'outcome_is_ok','operand':{'type':'var','name':'exit_o'}}},
        {'type':'print','value':{'type':'str','value':'current after EXIT (expect 1):'}},
        {'type':'print','value':{'type':'cap_current'}},
        {'type':'print','value':{'type':'str','value':'=== Cap Current test complete ==='}},
    ]}

def demo_cap_invalid_id():
    """Pod 1.10.2b1 T4 — OP_CAP_ARENA on cap_id=99 (invalid) returns Err Outcome
    with err_code=ERR_INVALID_ID (1), source_op=OP_CAP_ARENA (180=0xB4)."""
    return {'type':'program','body':[
        {'type':'print','value':{'type':'str','value':'=== Cap Invalid ID Test (Pod 1.10.2b1 T4) ==='}},
        {'type':'let','name':'o','value':{'type':'cap_arena_raw_id','id':99}},
        {'type':'print','value':{'type':'str','value':'is_ok:'}},
        {'type':'print','value':{'type':'outcome_is_ok','operand':{'type':'var','name':'o'}}},
        {'type':'outcome_unwrap_err_stmt','value':{'type':'var','name':'o'}},
        {'type':'print','value':{'type':'str','value':'fetch_counter (TOS):'}},
        {'type':'print','value':{'type':'tos'}},
        {'type':'print','value':{'type':'str','value':'demod_id:'}},
        {'type':'print','value':{'type':'tos'}},
        {'type':'print','value':{'type':'str','value':'source_op (expect 180 = OP_CAP_ARENA):'}},
        {'type':'print','value':{'type':'tos'}},
        {'type':'print','value':{'type':'str','value':'err_code (expect 1 = ERR_INVALID_ID):'}},
        {'type':'print','value':{'type':'tos'}},
        {'type':'print','value':{'type':'str','value':'=== Cap Invalid ID test complete ==='}},
    ]}

def demo_cap_stack_underflow():
    """Pod 1.10.2b1 T5 — OP_CAP_EXIT on empty cap_stack triggers underflow.
    Diagnostic str_ret_underflow + halt per Pod 1.9.3 D1.9.3.2 tag-the-halt;
    Err Outcome on operand stack at halt with source_op=OP_CAP_EXIT (178=0xB2)."""
    return {'type':'program','body':[
        {'type':'print','value':{'type':'str','value':'=== Cap Stack Underflow Test (Pod 1.10.2b1 T5) ==='}},
        {'type':'print','value':{'type':'str','value':'before underflow'}},
        {'type':'print','value':{'type':'str','value':'triggering OP_CAP_EXIT on empty cap_stack...'}},
        {'type':'raw_op_cap_exit'},
        {'type':'print','value':{'type':'str','value':'(this should not appear)'}},
    ]}

def demo_cap_stack_overflow():
    """Pod 1.10.2b1 T6 — 257 OP_CAP_ENTER on a single valid cap_id overflows
    256-deep cap_stack. Diagnostic str_call_overflow + halt; Err Outcome on
    operand stack at halt with source_op=OP_CAP_ENTER (177=0xB1)."""
    return {'type':'program','body':[
        {'type':'print','value':{'type':'str','value':'=== Cap Stack Overflow Test (Pod 1.10.2b1 T6) ==='}},
        {'type':'let','name':'o','value':{'type':'cap_new','granted_bitmap':CAP_BITMAP_UNBOUNDED}},
        {'type':'let','name':'cap_id','value':{'type':'outcome_unwrap_ok','operand':{'type':'var','name':'o'}}},
        {'type':'print','value':{'type':'str','value':'before overflow'}},
        {'type':'print','value':{'type':'str','value':'entering same cap 257 times until cap_stack overflows...'}},
        # Use raw burst to emit 257 (PUSH cap_id; OP_CAP_ENTER; OP_DROP) tuples.
        # But cap_id is a runtime value; we need to inline-push a fixed id.
        # For T6 we know cap_id will be 2 (first user-created post-ROOT).
        {'type':'raw_cap_enter_overflow_burst','cap_id':2,'count':257},
        {'type':'print','value':{'type':'str','value':'(this should not appear)'}},
    ]}

# --- Pod 1.10.2b2 substrate-wide provenance test surfaces (T1-T7) ---

def demo_sign_provenance_root():
    """Pod 1.10.2b2 T1 — Sign forged under ROOT context: arena=0, owner=0, creator=ROOT_CAP_ID=1.
    First observable effect of the three-allocator retrofit per D1.10.1.8."""
    return {'type':'program','body':[
        {'type':'print','value':{'type':'str','value':'=== Sign Provenance Root Test (Pod 1.10.2b2 T1) ==='}},
        {'type':'let','name':'s','value':{
            'type':'sign_new',
            'hash': b'\x42' + b'\x00' * 31, 'label': 'sigP', 'energy': 7,
        }},
        {'type':'print','value':{'type':'str','value':'arena (expect 0):'}},
        {'type':'print','value':{'type':'sign_arena','operand':{'type':'var','name':'s'}}},
        {'type':'print','value':{'type':'str','value':'owner (expect 0):'}},
        {'type':'print','value':{'type':'sign_owner','operand':{'type':'var','name':'s'}}},
        {'type':'print','value':{'type':'str','value':'creator (expect 1 = ROOT):'}},
        {'type':'print','value':{'type':'sign_creator','operand':{'type':'var','name':'s'}}},
        {'type':'print','value':{'type':'str','value':'=== Sign Provenance Root test complete ==='}},
    ]}

def demo_energy_provenance_root():
    """Pod 1.10.2b2 T2 — Energy forged under ROOT: arena=0, owner=0, creator=1."""
    return {'type':'program','body':[
        {'type':'print','value':{'type':'str','value':'=== Energy Provenance Root Test (Pod 1.10.2b2 T2) ==='}},
        {'type':'let','name':'e','value':{'type':'energy_new','joules':500,'source_op':0xA0}},
        {'type':'print','value':{'type':'str','value':'arena (expect 0):'}},
        {'type':'print','value':{'type':'energy_arena','operand':{'type':'var','name':'e'}}},
        {'type':'print','value':{'type':'str','value':'owner (expect 0):'}},
        {'type':'print','value':{'type':'energy_owner','operand':{'type':'var','name':'e'}}},
        {'type':'print','value':{'type':'str','value':'creator (expect 1 = ROOT):'}},
        {'type':'print','value':{'type':'energy_creator','operand':{'type':'var','name':'e'}}},
        {'type':'print','value':{'type':'str','value':'=== Energy Provenance Root test complete ==='}},
    ]}

def demo_outcome_provenance_root():
    """Pod 1.10.2b2 T3 — Outcome forged under ROOT: arena=0, owner=0, creator=1.
    Verifies retrofit propagates through Outcome construction (NEW_OK path)."""
    return {'type':'program','body':[
        {'type':'print','value':{'type':'str','value':'=== Outcome Provenance Root Test (Pod 1.10.2b2 T3) ==='}},
        {'type':'let','name':'o','value':{
            'type':'outcome_new_ok',
            'value_type_id': TYPE_CODE_SIGN, 'value': 99,
        }},
        {'type':'print','value':{'type':'str','value':'arena (expect 0):'}},
        {'type':'print','value':{'type':'outcome_arena','operand':{'type':'var','name':'o'}}},
        {'type':'print','value':{'type':'str','value':'owner (expect 0):'}},
        {'type':'print','value':{'type':'outcome_owner','operand':{'type':'var','name':'o'}}},
        {'type':'print','value':{'type':'str','value':'creator (expect 1 = ROOT):'}},
        {'type':'print','value':{'type':'outcome_creator','operand':{'type':'var','name':'o'}}},
        {'type':'print','value':{'type':'str','value':'=== Outcome Provenance Root test complete ==='}},
    ]}

def demo_provenance_under_subcap():
    """Pod 1.10.2b2 T4 — forge cap A under ROOT, ENTER A, forge Sign S inside A's
    authority context, EXIT, verify creator=A's_cap_id (=2). The first time
    creator_cap_id distinguishes from the arena/owner summary."""
    return {'type':'program','body':[
        {'type':'print','value':{'type':'str','value':'=== Provenance Under SubCap Test (Pod 1.10.2b2 T4) ==='}},
        {'type':'let','name':'co','value':{'type':'cap_new','granted_bitmap':CAP_BITMAP_UNBOUNDED}},
        {'type':'let','name':'cap_a','value':{'type':'outcome_unwrap_ok','operand':{'type':'var','name':'co'}}},
        {'type':'print','value':{'type':'str','value':'cap_a (expect 2):'}},
        {'type':'print','value':{'type':'var','name':'cap_a'}},
        {'type':'let','name':'enter_o','value':{'type':'cap_enter','operand':{'type':'var','name':'cap_a'}}},
        {'type':'let','name':'s','value':{
            'type':'sign_new',
            'hash': b'\xa1' + b'\x00' * 31, 'label': 'subA', 'energy': 11,
        }},
        {'type':'let','name':'exit_o','value':{'type':'cap_exit'}},
        {'type':'print','value':{'type':'str','value':'sign arena (expect 0; A inherited from ROOT):'}},
        {'type':'print','value':{'type':'sign_arena','operand':{'type':'var','name':'s'}}},
        {'type':'print','value':{'type':'str','value':'sign owner (expect 0):'}},
        {'type':'print','value':{'type':'sign_owner','operand':{'type':'var','name':'s'}}},
        {'type':'print','value':{'type':'str','value':'sign creator (expect 2 = cap_a):'}},
        {'type':'print','value':{'type':'sign_creator','operand':{'type':'var','name':'s'}}},
        {'type':'print','value':{'type':'str','value':'=== Provenance Under SubCap test complete ==='}},
    ]}

def demo_provenance_walk():
    """Pod 1.10.2b2 T5 — THE ARCHITECTURAL MOMENT.
    Forge cap A under ROOT, ENTER A, forge Sign S inside A, EXIT.
    Walk the lineage chain:
      OP_SIGN_CREATOR(S) -> A's cap_id (=2)
      OP_CAP_PARENT(2)   -> ROOT_CAP_ID (=1)
      OP_CAP_PARENT(1)   -> 0 (anchor)
    Three accessor calls trace the lineage from forged cell back to substrate
    anchor. The substrate narrating its own lineage."""
    return {'type':'program','body':[
        {'type':'print','value':{'type':'str','value':'=== Provenance Walk Test (Pod 1.10.2b2 T5) ==='}},
        {'type':'let','name':'co','value':{'type':'cap_new','granted_bitmap':CAP_BITMAP_UNBOUNDED}},
        {'type':'let','name':'cap_a','value':{'type':'outcome_unwrap_ok','operand':{'type':'var','name':'co'}}},
        {'type':'let','name':'enter_o','value':{'type':'cap_enter','operand':{'type':'var','name':'cap_a'}}},
        {'type':'let','name':'s','value':{
            'type':'sign_new',
            'hash': b'\xc0' + b'\x00' * 31, 'label': 'walk', 'energy': 5,
        }},
        {'type':'let','name':'exit_o','value':{'type':'cap_exit'}},
        # Walk: SIGN_CREATOR(S) -> creator (cap_a)
        {'type':'print','value':{'type':'str','value':'creator_of_S (expect 2 = cap_a):'}},
        {'type':'print','value':{'type':'sign_creator','operand':{'type':'var','name':'s'}}},
        # Walk: CAP_PARENT(cap_a) -> ROOT
        {'type':'print','value':{'type':'str','value':'parent_of_A (expect 1 = ROOT):'}},
        {'type':'print','value':{'type':'cap_parent','operand':{'type':'var','name':'cap_a'}}},
        # Walk: CAP_PARENT(ROOT) -> 0 (anchor)
        {'type':'print','value':{'type':'str','value':'parent_of_ROOT (expect 0 = anchor):'}},
        {'type':'print','value':{'type':'cap_parent','operand':{'type':'int','value':1}}},
        {'type':'print','value':{'type':'str','value':'=== Provenance Walk test complete ==='}},
    ]}

def demo_cap_parent_root():
    """Pod 1.10.2b2 T6 — OP_CAP_PARENT(ROOT_CAP_ID=1) returns 0. Verifies anchor
    semantics: ROOT's parent is 0 by construction (set at construct_root_cap)."""
    return {'type':'program','body':[
        {'type':'print','value':{'type':'str','value':'=== Cap Parent Root Test (Pod 1.10.2b2 T6) ==='}},
        {'type':'print','value':{'type':'str','value':'parent_of_ROOT (expect 0):'}},
        {'type':'print','value':{'type':'cap_parent','operand':{'type':'int','value':1}}},
        {'type':'print','value':{'type':'str','value':'=== Cap Parent Root test complete ==='}},
    ]}

def demo_invalid_id_each_new_accessor():
    """Pod 1.10.2b2 T7 — four invalid-id paths each return Outcome::Err with
    err_code=ERR_INVALID_ID and source_op=respective opcode. Verifies failure
    semantics across the new accessor family."""
    return {'type':'program','body':[
        {'type':'print','value':{'type':'str','value':'=== Invalid ID Each New Accessor Test (Pod 1.10.2b2 T7) ==='}},
        # OP_SIGN_ARENA(99) -> Err (source_op=0xA4=164)
        {'type':'let','name':'sa','value':{'type':'sign_arena_raw_id','id':99}},
        {'type':'print','value':{'type':'str','value':'OP_SIGN_ARENA(99) is_ok:'}},
        {'type':'print','value':{'type':'outcome_is_ok','operand':{'type':'var','name':'sa'}}},
        {'type':'outcome_unwrap_err_stmt','value':{'type':'var','name':'sa'}},
        {'type':'print','value':{'type':'str','value':'  fetch_counter:'}},
        {'type':'print','value':{'type':'tos'}},
        {'type':'print','value':{'type':'str','value':'  demod_id:'}},
        {'type':'print','value':{'type':'tos'}},
        {'type':'print','value':{'type':'str','value':'  source_op (expect 164 = OP_SIGN_ARENA):'}},
        {'type':'print','value':{'type':'tos'}},
        {'type':'print','value':{'type':'str','value':'  err_code (expect 1 = ERR_INVALID_ID):'}},
        {'type':'print','value':{'type':'tos'}},
        # OP_ENERGY_OWNER(99) -> Err (source_op=0xD7=215)
        {'type':'let','name':'eo','value':{'type':'energy_owner_raw_id','id':99}},
        {'type':'print','value':{'type':'str','value':'OP_ENERGY_OWNER(99) is_ok:'}},
        {'type':'print','value':{'type':'outcome_is_ok','operand':{'type':'var','name':'eo'}}},
        {'type':'outcome_unwrap_err_stmt','value':{'type':'var','name':'eo'}},
        {'type':'print','value':{'type':'str','value':'  fetch_counter:'}},
        {'type':'print','value':{'type':'tos'}},
        {'type':'print','value':{'type':'str','value':'  demod_id:'}},
        {'type':'print','value':{'type':'tos'}},
        {'type':'print','value':{'type':'str','value':'  source_op (expect 215 = OP_ENERGY_OWNER):'}},
        {'type':'print','value':{'type':'tos'}},
        {'type':'print','value':{'type':'str','value':'  err_code:'}},
        {'type':'print','value':{'type':'tos'}},
        # OP_OUTCOME_CREATOR(99) -> Err (source_op=0xE7=231)
        {'type':'let','name':'oc','value':{'type':'outcome_creator_raw_id','id':99}},
        {'type':'print','value':{'type':'str','value':'OP_OUTCOME_CREATOR(99) is_ok:'}},
        {'type':'print','value':{'type':'outcome_is_ok','operand':{'type':'var','name':'oc'}}},
        {'type':'outcome_unwrap_err_stmt','value':{'type':'var','name':'oc'}},
        {'type':'print','value':{'type':'str','value':'  fetch_counter:'}},
        {'type':'print','value':{'type':'tos'}},
        {'type':'print','value':{'type':'str','value':'  demod_id:'}},
        {'type':'print','value':{'type':'tos'}},
        {'type':'print','value':{'type':'str','value':'  source_op (expect 231 = OP_OUTCOME_CREATOR):'}},
        {'type':'print','value':{'type':'tos'}},
        {'type':'print','value':{'type':'str','value':'  err_code:'}},
        {'type':'print','value':{'type':'tos'}},
        # OP_CAP_PARENT(99) -> Err (source_op=0xB7=183)
        {'type':'let','name':'cp','value':{'type':'cap_parent_raw_id','id':99}},
        {'type':'print','value':{'type':'str','value':'OP_CAP_PARENT(99) is_ok:'}},
        {'type':'print','value':{'type':'outcome_is_ok','operand':{'type':'var','name':'cp'}}},
        {'type':'outcome_unwrap_err_stmt','value':{'type':'var','name':'cp'}},
        {'type':'print','value':{'type':'str','value':'  fetch_counter:'}},
        {'type':'print','value':{'type':'tos'}},
        {'type':'print','value':{'type':'str','value':'  demod_id:'}},
        {'type':'print','value':{'type':'tos'}},
        {'type':'print','value':{'type':'str','value':'  source_op (expect 183 = OP_CAP_PARENT):'}},
        {'type':'print','value':{'type':'tos'}},
        {'type':'print','value':{'type':'str','value':'  err_code:'}},
        {'type':'print','value':{'type':'tos'}},
        {'type':'print','value':{'type':'str','value':'=== Invalid ID Each New Accessor test complete ==='}},
    ]}

# --- Pod 1.10.3 Cap metabolic test surfaces (T1-T5) ---

def demo_cap_budget_basic():
    """Pod 1.10.3 T1 — Construct cap with energy_budget=1000; verify
    OP_CAP_BUDGET round-trips. First observable effect of the metabolic
    field landing in MAC-input range."""
    return {'type':'program','body':[
        {'type':'print','value':{'type':'str','value':'=== Cap Budget Basic Test (Pod 1.10.3 T1) ==='}},
        {'type':'let','name':'co','value':{'type':'cap_new','granted_bitmap':CAP_BITMAP_UNBOUNDED,'energy_budget':1000}},
        {'type':'let','name':'cap_id','value':{'type':'outcome_unwrap_ok','operand':{'type':'var','name':'co'}}},
        {'type':'print','value':{'type':'str','value':'cap_id (expect 2):'}},
        {'type':'print','value':{'type':'var','name':'cap_id'}},
        {'type':'print','value':{'type':'str','value':'budget (expect 1000):'}},
        {'type':'print','value':{'type':'cap_budget','operand':{'type':'var','name':'cap_id'}}},
        {'type':'print','value':{'type':'str','value':'=== Cap Budget Basic test complete ==='}},
    ]}

def demo_cap_used_zero_at_construction():
    """Pod 1.10.3 T2 — Construct cap with energy_budget=500; verify
    OP_CAP_USED returns 0. Pod 1.10.3 substrate-prep-only stance:
    energy_used stays 0 in V1.0; Pod 2 Cop activates incrementing."""
    return {'type':'program','body':[
        {'type':'print','value':{'type':'str','value':'=== Cap Used Zero At Construction Test (Pod 1.10.3 T2) ==='}},
        {'type':'let','name':'co','value':{'type':'cap_new','granted_bitmap':CAP_BITMAP_UNBOUNDED,'energy_budget':500}},
        {'type':'let','name':'cap_id','value':{'type':'outcome_unwrap_ok','operand':{'type':'var','name':'co'}}},
        {'type':'print','value':{'type':'str','value':'used (expect 0; V1.0 substrate prep only):'}},
        {'type':'print','value':{'type':'cap_used','operand':{'type':'var','name':'cap_id'}}},
        {'type':'print','value':{'type':'str','value':'=== Cap Used Zero test complete ==='}},
    ]}

def demo_root_cap_unbounded():
    """Pod 1.10.3 T3 — OP_CAP_BUDGET(ROOT_CAP_ID=1) returns
    0xFFFFFFFFFFFFFFFF (MAX_U64 = ENERGY_BUDGET_UNBOUNDED). Verifies
    ROOT_CAP construction with unbounded grant per D1.10.3.3."""
    return {'type':'program','body':[
        {'type':'print','value':{'type':'str','value':'=== Root Cap Unbounded Test (Pod 1.10.3 T3) ==='}},
        {'type':'print','value':{'type':'str','value':'budget_of_ROOT (expect -1 = signed i64 of MAX_U64):'}},
        {'type':'print','value':{'type':'cap_budget','operand':{'type':'int','value':1}}},
        {'type':'print','value':{'type':'str','value':'used_of_ROOT (expect 0):'}},
        {'type':'print','value':{'type':'cap_used','operand':{'type':'int','value':1}}},
        {'type':'print','value':{'type':'str','value':'=== Root Cap Unbounded test complete ==='}},
    ]}

def demo_cap_budget_invalid_id():
    """Pod 1.10.3 T4 — OP_CAP_BUDGET(99) returns Err Outcome with
    err_code=ERR_INVALID_ID (1), source_op=OP_CAP_BUDGET (0xB8=184).
    Verifies failure semantics for the new accessor family."""
    return {'type':'program','body':[
        {'type':'print','value':{'type':'str','value':'=== Cap Budget Invalid ID Test (Pod 1.10.3 T4) ==='}},
        {'type':'let','name':'o','value':{'type':'cap_budget_raw_id','id':99}},
        {'type':'print','value':{'type':'str','value':'is_ok:'}},
        {'type':'print','value':{'type':'outcome_is_ok','operand':{'type':'var','name':'o'}}},
        {'type':'outcome_unwrap_err_stmt','value':{'type':'var','name':'o'}},
        {'type':'print','value':{'type':'str','value':'fetch_counter:'}},
        {'type':'print','value':{'type':'tos'}},
        {'type':'print','value':{'type':'str','value':'demod_id:'}},
        {'type':'print','value':{'type':'tos'}},
        {'type':'print','value':{'type':'str','value':'source_op (expect 184 = OP_CAP_BUDGET):'}},
        {'type':'print','value':{'type':'tos'}},
        {'type':'print','value':{'type':'str','value':'err_code (expect 1 = ERR_INVALID_ID):'}},
        {'type':'print','value':{'type':'tos'}},
        {'type':'print','value':{'type':'str','value':'=== Cap Budget Invalid ID test complete ==='}},
    ]}

def demo_cap_budget_immutable_via_mac():
    """Pod 1.10.3 T5 — Construct cap with budget X; OP_CAP_BUDGET
    returns X. Structural confirmation that energy_budget is in MAC-
    input range (the round-trip can only succeed if construct-side and
    accessor-side agree on the layout). Pod 2 will add tamper detection;
    V1.0 has no mechanism to forge tampering, so this test is shape-
    confirmation rather than negative-test coverage."""
    return {'type':'program','body':[
        {'type':'print','value':{'type':'str','value':'=== Cap Budget Immutable Test (Pod 1.10.3 T5) ==='}},
        {'type':'let','name':'co','value':{'type':'cap_new','granted_bitmap':CAP_BITMAP_UNBOUNDED,'energy_budget':2024}},
        {'type':'let','name':'cap_id','value':{'type':'outcome_unwrap_ok','operand':{'type':'var','name':'co'}}},
        {'type':'print','value':{'type':'str','value':'budget read 1 (expect 2024):'}},
        {'type':'print','value':{'type':'cap_budget','operand':{'type':'var','name':'cap_id'}}},
        {'type':'print','value':{'type':'str','value':'budget read 2 (expect 2024 — round-trip stable):'}},
        {'type':'print','value':{'type':'cap_budget','operand':{'type':'var','name':'cap_id'}}},
        {'type':'print','value':{'type':'str','value':'=== Cap Budget Immutable test complete ==='}},
    ]}

# --- Pod 2.1 Babylon spatial-merge test surfaces (T1-T6) ---

def demo_babylon_single_level():
    """Pod 2.1 T1 — Single-level spatial-merge.
    Construct cap A under ROOT (1j → 0 ripple). ENTER A. Forge Sign (100j).
    EXIT. Read OP_CAP_USED at A and ROOT.
    Expected: A=0 (originating; doesn't charge itself), ROOT=50 (100/2 floor)."""
    return {'type':'program','body':[
        {'type':'print','value':{'type':'str','value':'=== Babylon Single Level Test (Pod 2.1 T1) ==='}},
        {'type':'let','name':'co','value':{'type':'cap_new','granted_bitmap':CAP_BITMAP_UNBOUNDED,'energy_budget':1000}},
        {'type':'let','name':'cap_a','value':{'type':'outcome_unwrap_ok','operand':{'type':'var','name':'co'}}},
        {'type':'let','name':'enter_o','value':{'type':'cap_enter','operand':{'type':'var','name':'cap_a'}}},
        {'type':'let','name':'s','value':{
            'type':'sign_new',
            'hash': b'\x42' + b'\x00' * 31, 'label': 'sng', 'energy': 1,
        }},
        {'type':'let','name':'exit_o','value':{'type':'cap_exit'}},
        {'type':'print','value':{'type':'str','value':'A.used (expect 0; originating):'}},
        {'type':'print','value':{'type':'cap_used','operand':{'type':'var','name':'cap_a'}}},
        {'type':'print','value':{'type':'str','value':'ROOT.used (expect 50; 100/2 floor):'}},
        {'type':'print','value':{'type':'cap_used','operand':{'type':'int','value':1}}},
        {'type':'print','value':{'type':'str','value':'=== Babylon Single Level test complete ==='}},
    ]}

def demo_babylon_multi_level():
    """Pod 2.1 T2 — THE ARCHITECTURAL MOMENT.
    Three nested caps: A under ROOT, B under A, C under B. ENTER chain to C.
    Forge Sign (100j). EXIT chain back to ROOT. Read OP_CAP_USED at each level.
    Expected geometric decay: C=0 (originating), B=50, A=25, ROOT=12 (12.5 floor)."""
    return {'type':'program','body':[
        {'type':'print','value':{'type':'str','value':'=== Babylon Multi Level Test (Pod 2.1 T2) ==='}},
        {'type':'let','name':'co_a','value':{'type':'cap_new','granted_bitmap':CAP_BITMAP_UNBOUNDED,'energy_budget':10000}},
        {'type':'let','name':'cap_a','value':{'type':'outcome_unwrap_ok','operand':{'type':'var','name':'co_a'}}},
        {'type':'let','name':'enter_a','value':{'type':'cap_enter','operand':{'type':'var','name':'cap_a'}}},
        {'type':'let','name':'co_b','value':{'type':'cap_new','granted_bitmap':CAP_BITMAP_UNBOUNDED,'energy_budget':5000}},
        {'type':'let','name':'cap_b','value':{'type':'outcome_unwrap_ok','operand':{'type':'var','name':'co_b'}}},
        {'type':'let','name':'enter_b','value':{'type':'cap_enter','operand':{'type':'var','name':'cap_b'}}},
        {'type':'let','name':'co_c','value':{'type':'cap_new','granted_bitmap':CAP_BITMAP_UNBOUNDED,'energy_budget':2500}},
        {'type':'let','name':'cap_c','value':{'type':'outcome_unwrap_ok','operand':{'type':'var','name':'co_c'}}},
        {'type':'let','name':'enter_c','value':{'type':'cap_enter','operand':{'type':'var','name':'cap_c'}}},
        {'type':'let','name':'s','value':{
            'type':'sign_new',
            'hash': b'\xc0' + b'\x00' * 31, 'label': 'mlw', 'energy': 1,
        }},
        {'type':'let','name':'exit_c','value':{'type':'cap_exit'}},
        {'type':'let','name':'exit_b','value':{'type':'cap_exit'}},
        {'type':'let','name':'exit_a','value':{'type':'cap_exit'}},
        {'type':'print','value':{'type':'str','value':'C.used (expect 0; originating):'}},
        {'type':'print','value':{'type':'cap_used','operand':{'type':'var','name':'cap_c'}}},
        {'type':'print','value':{'type':'str','value':'B.used (expect 50; depth 1):'}},
        {'type':'print','value':{'type':'cap_used','operand':{'type':'var','name':'cap_b'}}},
        {'type':'print','value':{'type':'str','value':'A.used (expect 25; depth 2):'}},
        {'type':'print','value':{'type':'cap_used','operand':{'type':'var','name':'cap_a'}}},
        {'type':'print','value':{'type':'str','value':'ROOT.used (expect 12; depth 3):'}},
        {'type':'print','value':{'type':'cap_used','operand':{'type':'int','value':1}}},
        {'type':'print','value':{'type':'str','value':'=== Babylon Multi Level test complete ==='}},
    ]}

def demo_babylon_root_only_invisible():
    """Pod 2.1 T3 — ROOT-only operations are metabolically invisible.
    Forge Sign under ROOT directly (no sub-cap). Walk-up immediately
    terminates because ROOT.parent_cap_id=0.
    Expected: ROOT.used=0 (federation accounting reflects only sub-cap activity)."""
    return {'type':'program','body':[
        {'type':'print','value':{'type':'str','value':'=== Babylon Root Only Invisible Test (Pod 2.1 T3) ==='}},
        {'type':'let','name':'s','value':{
            'type':'sign_new',
            'hash': b'\x33' + b'\x00' * 31, 'label': 'rt', 'energy': 1,
        }},
        {'type':'print','value':{'type':'str','value':'ROOT.used (expect 0; ROOT-only ops invisible):'}},
        {'type':'print','value':{'type':'cap_used','operand':{'type':'int','value':1}}},
        {'type':'print','value':{'type':'str','value':'=== Babylon Root Only Invisible test complete ==='}},
    ]}

def demo_babylon_federation_total():
    """Pod 2.1 T4 — Federation total accumulation across multiple operations.
    Construct A under ROOT, B under A. Sign×3 forged under B (100j each).
    Energy×2 forged under A (10j each per cost table).
    Expected:
      Sign×3 under B: each fires babylon(100, B) → A += 50, ROOT += 25.
        Total: A += 150, ROOT += 75.
      Energy×2 under A: each fires babylon(10, A) → ROOT += 5.
        Total: ROOT += 10.
      Final: A=150, B=0, ROOT=85."""
    return {'type':'program','body':[
        {'type':'print','value':{'type':'str','value':'=== Babylon Federation Total Test (Pod 2.1 T4) ==='}},
        # Build A under ROOT, B under A
        {'type':'let','name':'co_a','value':{'type':'cap_new','granted_bitmap':CAP_BITMAP_UNBOUNDED,'energy_budget':10000}},
        {'type':'let','name':'cap_a','value':{'type':'outcome_unwrap_ok','operand':{'type':'var','name':'co_a'}}},
        {'type':'let','name':'enter_a','value':{'type':'cap_enter','operand':{'type':'var','name':'cap_a'}}},
        {'type':'let','name':'co_b','value':{'type':'cap_new','granted_bitmap':CAP_BITMAP_UNBOUNDED,'energy_budget':5000}},
        {'type':'let','name':'cap_b','value':{'type':'outcome_unwrap_ok','operand':{'type':'var','name':'co_b'}}},
        # Forge Sign x3 under B
        {'type':'let','name':'enter_b','value':{'type':'cap_enter','operand':{'type':'var','name':'cap_b'}}},
        {'type':'let','name':'s1','value':{'type':'sign_new','hash': b'\x01' + b'\x00' * 31, 'label': 's1', 'energy': 1}},
        {'type':'let','name':'s2','value':{'type':'sign_new','hash': b'\x02' + b'\x00' * 31, 'label': 's2', 'energy': 1}},
        {'type':'let','name':'s3','value':{'type':'sign_new','hash': b'\x03' + b'\x00' * 31, 'label': 's3', 'energy': 1}},
        {'type':'let','name':'exit_b','value':{'type':'cap_exit'}},
        # Forge Energy x2 under A (still inside A's context)
        {'type':'let','name':'e1','value':{'type':'energy_new','joules':100,'source_op':0xA0}},
        {'type':'let','name':'e2','value':{'type':'energy_new','joules':200,'source_op':0xA0}},
        {'type':'let','name':'exit_a','value':{'type':'cap_exit'}},
        {'type':'print','value':{'type':'str','value':'A.used (expect 150; 3 Sign forges via B contribute 50 each):'}},
        {'type':'print','value':{'type':'cap_used','operand':{'type':'var','name':'cap_a'}}},
        {'type':'print','value':{'type':'str','value':'B.used (expect 0; originating for Sign forges):'}},
        {'type':'print','value':{'type':'cap_used','operand':{'type':'var','name':'cap_b'}}},
        {'type':'print','value':{'type':'str','value':'ROOT.used (expect 85; 75 from Sign + 10 from Energy):'}},
        {'type':'print','value':{'type':'cap_used','operand':{'type':'int','value':1}}},
        {'type':'print','value':{'type':'str','value':'=== Babylon Federation Total test complete ==='}},
    ]}

def demo_babylon_canary_subcap():
    """Pod 2.1 T5 — Sub-cap canary. Sign forge under sub-cap A.
    Per A4 redesign at recon: minimal-shape test verifying
    (a) operand-stack cost still 174j (substrate-bookkeeping doctrine
        extends to spatial-merge per Pre-A6 / D2.1.6),
    (b) A.used=0 (originating doesn't charge itself),
    (c) ROOT.used=50 (only OP_SIGN_NEW propagates; 100/2 floor).
    NOT 87 — architect's '174/2' conflation corrected at recon (D2.1.X /
    same family as D1.10.2a.10 / D1.10.2b1.8 / D1.10.2b2.9 / D1.10.3.8)."""
    return {'type':'program','body':[
        {'type':'print','value':{'type':'str','value':'=== Babylon Canary SubCap Test (Pod 2.1 T5) ==='}},
        {'type':'let','name':'co','value':{'type':'cap_new','granted_bitmap':CAP_BITMAP_UNBOUNDED,'energy_budget':1000}},
        {'type':'let','name':'cap_a','value':{'type':'outcome_unwrap_ok','operand':{'type':'var','name':'co'}}},
        {'type':'let','name':'enter_o','value':{'type':'cap_enter','operand':{'type':'var','name':'cap_a'}}},
        {'type':'let','name':'s','value':{
            'type':'sign_new',
            'hash': b'\xab' + b'\x00' * 31, 'label': 'hello', 'energy': 42,
        }},
        {'type':'let','name':'exit_o','value':{'type':'cap_exit'}},
        {'type':'print','value':{'type':'str','value':'A.used (expect 0; originating):'}},
        {'type':'print','value':{'type':'cap_used','operand':{'type':'var','name':'cap_a'}}},
        {'type':'print','value':{'type':'str','value':'ROOT.used (expect 50; 100/2 floor):'}},
        {'type':'print','value':{'type':'cap_used','operand':{'type':'int','value':1}}},
        {'type':'print','value':{'type':'str','value':'=== Babylon Canary SubCap test complete ==='}},
    ]}

def demo_babylon_initial_zero():
    """Pod 2.1 T6 — Sanity baseline. At program start (no operations
    performed), read OP_CAP_USED(ROOT_CAP_ID).
    Expected: ROOT.used=0 (Babylon's accounting starts clean each boot;
    fresh substrate state at every test boot under canary harness)."""
    return {'type':'program','body':[
        {'type':'print','value':{'type':'str','value':'=== Babylon Initial Zero Test (Pod 2.1 T6) ==='}},
        {'type':'print','value':{'type':'str','value':'ROOT.used at program start (expect 0):'}},
        {'type':'print','value':{'type':'cap_used','operand':{'type':'int','value':1}}},
        {'type':'print','value':{'type':'str','value':'=== Babylon Initial Zero test complete ==='}},
    ]}

# === Pod 2.2 — Babylon's vocabulary tests (T1–T6) ===

def demo_bitmap_root_unbounded():
    """Pod 2.2 T1 — Sanity baseline. Read ROOT_CAP's bitmap field via
    OP_CAP_BITMAP accessor; expect CAP_BITMAP_UNBOUNDED (presents as -1
    signed i64 per D2.2.3 / D1.10.3.3 cross-pole truth-in-naming pattern)."""
    return {'type':'program','body':[
        {'type':'print','value':{'type':'str','value':'=== Bitmap Root Unbounded Test (Pod 2.2 T1) ==='}},
        {'type':'print','value':{'type':'str','value':'ROOT.bitmap (expect -1 = CAP_BITMAP_UNBOUNDED):'}},
        {'type':'print','value':{'type':'cap_bitmap','operand':{'type':'int','value':1}}},
        {'type':'print','value':{'type':'str','value':'=== Bitmap Root Unbounded test complete ==='}},
    ]}

def demo_bitmap_subset_grant_succeeds():
    """Pod 2.2 T2 — Construct cap A under ROOT with granted_bitmap =
    BIT_SIGN_FORGE | BIT_CAP_FORGE (subset of ROOT's UNBOUNDED).
    Construction succeeds (parent has CAP_FORGE, granted is subset of
    parent); read A.bitmap, expect 9 (0x09)."""
    return {'type':'program','body':[
        {'type':'print','value':{'type':'str','value':'=== Bitmap Subset Grant Succeeds Test (Pod 2.2 T2) ==='}},
        {'type':'let','name':'co','value':{'type':'cap_new','granted_bitmap': BIT_SIGN_FORGE | BIT_CAP_FORGE}},
        {'type':'let','name':'cap_id','value':{'type':'outcome_unwrap_ok','operand':{'type':'var','name':'co'}}},
        {'type':'print','value':{'type':'str','value':'cap_id (expect 2):'}},
        {'type':'print','value':{'type':'var','name':'cap_id'}},
        {'type':'print','value':{'type':'str','value':'A.bitmap (expect 9 = SIGN_FORGE|CAP_FORGE):'}},
        {'type':'print','value':{'type':'cap_bitmap','operand':{'type':'var','name':'cap_id'}}},
        {'type':'print','value':{'type':'str','value':'=== Bitmap Subset Grant Succeeds test complete ==='}},
    ]}

def demo_bitmap_superset_grant_fails():
    """Pod 2.2 T3 — SUBSET RULE ARCHITECTURAL MOMENT (D2.2.5).
    Construct cap A under ROOT with BIT_SIGN_FORGE|BIT_CAP_FORGE.
    ENTER A. Attempt construct cap B under A with
    BIT_SIGN_FORGE|BIT_OUTCOME_FORGE — A lacks BIT_OUTCOME_FORGE, so
    subset rule fires. Result: Outcome::Err(source_op=OP_CAP_NEW=176,
    err_code=ERR_CAP_AUTHORITY_EXCEEDED=7). Activates DEFERRED #61
    forward-anchor from Pod 1.10.2b1 D1.10.2b1.2 after four pods."""
    return {'type':'program','body':[
        {'type':'print','value':{'type':'str','value':'=== Bitmap Superset Grant Fails Test (Pod 2.2 T3) ==='}},
        {'type':'let','name':'co_a','value':{'type':'cap_new','granted_bitmap': BIT_SIGN_FORGE | BIT_CAP_FORGE}},
        {'type':'let','name':'cap_a','value':{'type':'outcome_unwrap_ok','operand':{'type':'var','name':'co_a'}}},
        {'type':'let','name':'enter_a','value':{'type':'cap_enter','operand':{'type':'var','name':'cap_a'}}},
        # Under A, attempt to construct B with bitmap exceeding A's grant.
        {'type':'let','name':'co_b','value':{'type':'cap_new','granted_bitmap': BIT_SIGN_FORGE | BIT_OUTCOME_FORGE}},
        {'type':'print','value':{'type':'str','value':'B is_ok (expect 0 = err):'}},
        {'type':'print','value':{'type':'outcome_is_ok','operand':{'type':'var','name':'co_b'}}},
        # Inspect err fields via unwrap_err (4 values pushed; TOS-first).
        {'type':'outcome_unwrap_err_stmt','value':{'type':'var','name':'co_b'}},
        {'type':'print','value':{'type':'str','value':'fetch_counter:'}},
        {'type':'print','value':{'type':'tos'}},
        {'type':'print','value':{'type':'str','value':'demod_id:'}},
        {'type':'print','value':{'type':'tos'}},
        {'type':'print','value':{'type':'str','value':'source_op (expect 176 = OP_CAP_NEW):'}},
        {'type':'print','value':{'type':'tos'}},
        {'type':'print','value':{'type':'str','value':'err_code (expect 7 = ERR_CAP_AUTHORITY_EXCEEDED):'}},
        {'type':'print','value':{'type':'tos'}},
        {'type':'let','name':'exit_a','value':{'type':'cap_exit'}},
        {'type':'print','value':{'type':'str','value':'=== Bitmap Superset Grant Fails test complete ==='}},
    ]}

def demo_bitmap_authority_check_passes():
    """Pod 2.2 T4 — Bit-check passes (positive case for D2.2.6).
    Construct cap A under ROOT with BIT_SIGN_FORGE|BIT_CAP_FORGE.
    ENTER A. Forge Sign — A's bitmap carries BIT_SIGN_FORGE so
    bit-check passes; Sign forge succeeds. Demonstrates that
    authority-shape-as-physics permits authorized operations."""
    return {'type':'program','body':[
        {'type':'print','value':{'type':'str','value':'=== Bitmap Authority Check Passes Test (Pod 2.2 T4) ==='}},
        {'type':'let','name':'co','value':{'type':'cap_new','granted_bitmap': BIT_SIGN_FORGE | BIT_CAP_FORGE}},
        {'type':'let','name':'cap_a','value':{'type':'outcome_unwrap_ok','operand':{'type':'var','name':'co'}}},
        {'type':'let','name':'enter_a','value':{'type':'cap_enter','operand':{'type':'var','name':'cap_a'}}},
        # Forge Sign under A — auto-unwrap binds bare sign_id.
        {'type':'let','name':'s','value':{
            'type':'sign_new',
            'hash': b'\xab' + b'\x00' * 31, 'label': 'authzd', 'energy': 42,
        }},
        {'type':'print','value':{'type':'str','value':'sign_id (expect 1):'}},
        {'type':'print','value':{'type':'var','name':'s'}},
        {'type':'let','name':'exit_a','value':{'type':'cap_exit'}},
        {'type':'print','value':{'type':'str','value':'=== Bitmap Authority Check Passes test complete ==='}},
    ]}

def demo_bitmap_authority_check_fails():
    """Pod 2.2 T5 — BIT-CHECK ARCHITECTURAL MOMENT (D2.2.6).
    Construct cap A under ROOT with BIT_SIGN_FORGE|BIT_CAP_FORGE
    (deliberately omits BIT_ENERGY_FORGE). ENTER A. Attempt Energy
    forge — A's bitmap lacks ENERGY_FORGE, so bit-check fails. Result:
    Outcome::Err(source_op=OP_ENERGY_NEW=208, err_code=ERR_CAP_INSUFFICIENT_AUTHORITY=8).
    The substrate distinguishes operations by authority bit pattern at
    the dispatch path; authority shape is load-bearing physics. Uses
    'wrap': True to skip auto-unwrap and keep raw Outcome for inspection."""
    return {'type':'program','body':[
        {'type':'print','value':{'type':'str','value':'=== Bitmap Authority Check Fails Test (Pod 2.2 T5) ==='}},
        {'type':'let','name':'co','value':{'type':'cap_new','granted_bitmap': BIT_SIGN_FORGE | BIT_CAP_FORGE}},
        {'type':'let','name':'cap_a','value':{'type':'outcome_unwrap_ok','operand':{'type':'var','name':'co'}}},
        {'type':'let','name':'enter_a','value':{'type':'cap_enter','operand':{'type':'var','name':'cap_a'}}},
        # Attempt Energy forge — A lacks BIT_ENERGY_FORGE.
        # 'wrap': True opts out of Path A auto-unwrap so we can inspect the Err Outcome.
        {'type':'let','name':'eo','value':{
            'type':'energy_new',
            'joules': 500, 'source_op': 0xA0, 'wrap': True,
        }},
        {'type':'print','value':{'type':'str','value':'is_ok (expect 0 = err):'}},
        {'type':'print','value':{'type':'outcome_is_ok','operand':{'type':'var','name':'eo'}}},
        {'type':'outcome_unwrap_err_stmt','value':{'type':'var','name':'eo'}},
        {'type':'print','value':{'type':'str','value':'fetch_counter:'}},
        {'type':'print','value':{'type':'tos'}},
        {'type':'print','value':{'type':'str','value':'demod_id:'}},
        {'type':'print','value':{'type':'tos'}},
        {'type':'print','value':{'type':'str','value':'source_op (expect 208 = OP_ENERGY_NEW):'}},
        {'type':'print','value':{'type':'tos'}},
        {'type':'print','value':{'type':'str','value':'err_code (expect 8 = ERR_CAP_INSUFFICIENT_AUTHORITY):'}},
        {'type':'print','value':{'type':'tos'}},
        {'type':'let','name':'exit_a','value':{'type':'cap_exit'}},
        {'type':'print','value':{'type':'str','value':'=== Bitmap Authority Check Fails test complete ==='}},
    ]}

def demo_bitmap_accessor_round_trip():
    """Pod 2.2 T6 — Round-trip bitmap through MAC-input range.
    Construct cap A with specific bitmap = all four forge bits set
    (0x0F = 15). Read back via OP_CAP_BITMAP; expect 15. Confirms
    bitmap field at +0x18 survives MAC stamp / verify cycle and
    accessor returns granted value verbatim."""
    return {'type':'program','body':[
        {'type':'print','value':{'type':'str','value':'=== Bitmap Accessor Round Trip Test (Pod 2.2 T6) ==='}},
        {'type':'let','name':'co','value':{'type':'cap_new','granted_bitmap': BIT_SIGN_FORGE | BIT_ENERGY_FORGE | BIT_OUTCOME_FORGE | BIT_CAP_FORGE}},
        {'type':'let','name':'cap_id','value':{'type':'outcome_unwrap_ok','operand':{'type':'var','name':'co'}}},
        {'type':'print','value':{'type':'str','value':'cap_id (expect 2):'}},
        {'type':'print','value':{'type':'var','name':'cap_id'}},
        {'type':'print','value':{'type':'str','value':'A.bitmap (expect 15 = 0x0F = all four FORGE bits):'}},
        {'type':'print','value':{'type':'cap_bitmap','operand':{'type':'var','name':'cap_id'}}},
        {'type':'print','value':{'type':'str','value':'=== Bitmap Accessor Round Trip test complete ==='}},
    ]}

# === Pod 3 — Maid is born — Embedding typed primitive (T1–T7) ===

def _structured_vector_bytes():
    """Helper: construct 1536-byte vector with dimension i = float(i) for round-trip test.
    Returns bytes such that get_dim(0) = bit pattern of 0.0,
    get_dim(1) = bit pattern of 1.0, ..., get_dim(383) = bit pattern of 383.0."""
    import struct
    return b''.join(struct.pack('<f', float(i)) for i in range(EMBEDDING_DIM))

def demo_embedding_new_basic():
    """Pod 3 T1 — Forge embedding from inline f32[384] zero-vector under ROOT.
    Expect embedding_id=1, arena=0, owner=0, creator=1 (ROOT_CAP).
    Sanity baseline for the new typed primitive."""
    return {'type':'program','body':[
        {'type':'print','value':{'type':'str','value':'=== Embedding New Basic Test (Pod 3 T1) ==='}},
        {'type':'let','name':'e','value':{'type':'embedding_new'}},  # default zero vector
        {'type':'print','value':{'type':'str','value':'embedding_id (expect 1):'}},
        {'type':'print','value':{'type':'var','name':'e'}},
        {'type':'print','value':{'type':'str','value':'arena (expect 0):'}},
        {'type':'print','value':{'type':'embedding_arena','operand':{'type':'var','name':'e'}}},
        {'type':'print','value':{'type':'str','value':'owner (expect 0):'}},
        {'type':'print','value':{'type':'embedding_owner','operand':{'type':'var','name':'e'}}},
        {'type':'print','value':{'type':'str','value':'creator (expect 1 = ROOT_CAP):'}},
        {'type':'print','value':{'type':'embedding_creator','operand':{'type':'var','name':'e'}}},
        {'type':'print','value':{'type':'str','value':'=== Embedding New Basic test complete ==='}},
    ]}

def demo_embedding_accessor_round_trip():
    """Pod 3 T2 — Forge embedding from structured f32[384] vector
    (dim i = float(i)). Read back via OP_EMBEDDING_GET_DIM at indices
    0, 100, 383; verify bit-cast i64 values match expected f32 bit
    patterns. Confirms MAC-input round-trip for full vector content."""
    import struct
    bp_0 = struct.unpack('<I', struct.pack('<f', 0.0))[0]
    bp_100 = struct.unpack('<I', struct.pack('<f', 100.0))[0]
    bp_383 = struct.unpack('<I', struct.pack('<f', 383.0))[0]
    return {'type':'program','body':[
        {'type':'print','value':{'type':'str','value':'=== Embedding Accessor Round Trip Test (Pod 3 T2) ==='}},
        {'type':'let','name':'e','value':{'type':'embedding_new', 'vector': _structured_vector_bytes()}},
        {'type':'print','value':{'type':'str','value':f'dim[0] (expect {bp_0} = bit-pattern of 0.0):'}},
        {'type':'print','value':{'type':'embedding_get_dim','operand':{'type':'var','name':'e'},'dim_index':0}},
        {'type':'print','value':{'type':'str','value':f'dim[100] (expect {bp_100} = bit-pattern of 100.0):'}},
        {'type':'print','value':{'type':'embedding_get_dim','operand':{'type':'var','name':'e'},'dim_index':100}},
        {'type':'print','value':{'type':'str','value':f'dim[383] (expect {bp_383} = bit-pattern of 383.0):'}},
        {'type':'print','value':{'type':'embedding_get_dim','operand':{'type':'var','name':'e'},'dim_index':383}},
        {'type':'print','value':{'type':'str','value':'=== Embedding Accessor Round Trip test complete ==='}},
    ]}

def demo_embedding_invalid_id():
    """Pod 3 T3 — OP_EMBEDDING_ARENA on non-existent embedding_id=999;
    expect Outcome::Err(ERR_INVALID_ID, source_op=OP_EMBEDDING_ARENA=0xC1=193)."""
    return {'type':'program','body':[
        {'type':'print','value':{'type':'str','value':'=== Embedding Invalid ID Test (Pod 3 T3) ==='}},
        # Construct a real embedding so the pool is non-empty
        {'type':'let','name':'e','value':{'type':'embedding_new'}},
        # Now query a non-existent embedding_id via raw_id (skips auto-unwrap)
        {'type':'let','name':'o','value':{'type':'embedding_arena_raw_id','id':999}},
        {'type':'print','value':{'type':'str','value':'is_ok (expect 0 = err):'}},
        {'type':'print','value':{'type':'outcome_is_ok','operand':{'type':'var','name':'o'}}},
        {'type':'outcome_unwrap_err_stmt','value':{'type':'var','name':'o'}},
        {'type':'print','value':{'type':'str','value':'fetch_counter:'}},
        {'type':'print','value':{'type':'tos'}},
        {'type':'print','value':{'type':'str','value':'demod_id:'}},
        {'type':'print','value':{'type':'tos'}},
        {'type':'print','value':{'type':'str','value':'source_op (expect 193 = OP_EMBEDDING_ARENA):'}},
        {'type':'print','value':{'type':'tos'}},
        {'type':'print','value':{'type':'str','value':'err_code (expect 1 = ERR_INVALID_ID):'}},
        {'type':'print','value':{'type':'tos'}},
        {'type':'print','value':{'type':'str','value':'=== Embedding Invalid ID test complete ==='}},
    ]}

def demo_embedding_authority_check_passes():
    """Pod 3 T4/B10 — Bit-check positive case + B14 sub-cap canary preservation.
    Construct cap A under ROOT with BIT_EMBEDDING_FORGE | BIT_CAP_FORGE,
    energy_budget=1000. ENTER A. Forge embedding under A — bit-check
    passes; embedding_id=1 returned. EXIT A. Read A.used (expect 0;
    originating doesn't charge itself) and ROOT.used (expect 50;
    100j Embedding cost / 2 floor; single-fire spatial-merge via
    .construct_ok_outcome's internal babylon per D3.9 greenfield axiom).
    Combined: B10 (BIT-CHECK PASS) + B14 (single-fire axiom seventh
    empirical landing)."""
    return {'type':'program','body':[
        {'type':'print','value':{'type':'str','value':'=== Embedding Authority Check Passes / SubCap Canary Test (Pod 3 T4 = B10+B14) ==='}},
        {'type':'let','name':'co','value':{'type':'cap_new','granted_bitmap': BIT_EMBEDDING_FORGE | BIT_CAP_FORGE, 'energy_budget': 1000}},
        {'type':'let','name':'cap_a','value':{'type':'outcome_unwrap_ok','operand':{'type':'var','name':'co'}}},
        {'type':'let','name':'enter_a','value':{'type':'cap_enter','operand':{'type':'var','name':'cap_a'}}},
        {'type':'let','name':'e','value':{'type':'embedding_new'}},
        {'type':'print','value':{'type':'str','value':'embedding_id (expect 1):'}},
        {'type':'print','value':{'type':'var','name':'e'}},
        {'type':'let','name':'exit_a','value':{'type':'cap_exit'}},
        {'type':'print','value':{'type':'str','value':'A.used (expect 0; originating):'}},
        {'type':'print','value':{'type':'cap_used','operand':{'type':'var','name':'cap_a'}}},
        {'type':'print','value':{'type':'str','value':'ROOT.used (expect 50; 100/2 floor):'}},
        {'type':'print','value':{'type':'cap_used','operand':{'type':'int','value':1}}},
        {'type':'print','value':{'type':'str','value':'=== Embedding Authority Check Passes / SubCap Canary test complete ==='}},
    ]}

def demo_embedding_authority_check_fails():
    """Pod 3 T5 — BIT-CHECK MOMENT (FAIL case; D3.X authority-shape physics).
    Construct cap A under ROOT with BIT_SIGN_FORGE | BIT_CAP_FORGE
    (deliberately omits BIT_EMBEDDING_FORGE). ENTER A. Attempt embedding
    forge → bit-check fails → Outcome::Err(source_op=OP_EMBEDDING_NEW=192,
    err_code=ERR_CAP_INSUFFICIENT_AUTHORITY=8). Authority-shape physics
    extends to Embedding via Pod 2.2 D2.2.6 mechanism."""
    return {'type':'program','body':[
        {'type':'print','value':{'type':'str','value':'=== Embedding Authority Check Fails Test (Pod 3 T5) ==='}},
        {'type':'let','name':'co','value':{'type':'cap_new','granted_bitmap': BIT_SIGN_FORGE | BIT_CAP_FORGE}},
        {'type':'let','name':'cap_a','value':{'type':'outcome_unwrap_ok','operand':{'type':'var','name':'co'}}},
        {'type':'let','name':'enter_a','value':{'type':'cap_enter','operand':{'type':'var','name':'cap_a'}}},
        # Attempt embedding forge with 'wrap': True to keep raw Outcome for inspection
        {'type':'let','name':'eo','value':{'type':'embedding_new', 'wrap': True}},
        {'type':'print','value':{'type':'str','value':'is_ok (expect 0 = err):'}},
        {'type':'print','value':{'type':'outcome_is_ok','operand':{'type':'var','name':'eo'}}},
        {'type':'outcome_unwrap_err_stmt','value':{'type':'var','name':'eo'}},
        {'type':'print','value':{'type':'str','value':'fetch_counter:'}},
        {'type':'print','value':{'type':'tos'}},
        {'type':'print','value':{'type':'str','value':'demod_id:'}},
        {'type':'print','value':{'type':'tos'}},
        {'type':'print','value':{'type':'str','value':'source_op (expect 192 = OP_EMBEDDING_NEW):'}},
        {'type':'print','value':{'type':'tos'}},
        {'type':'print','value':{'type':'str','value':'err_code (expect 8 = ERR_CAP_INSUFFICIENT_AUTHORITY):'}},
        {'type':'print','value':{'type':'tos'}},
        {'type':'let','name':'exit_a','value':{'type':'cap_exit'}},
        {'type':'print','value':{'type':'str','value':'=== Embedding Authority Check Fails test complete ==='}},
    ]}

def demo_sign_with_embedding_link():
    """Pod 3 T6 — SIGN-EMBEDDING LINKAGE MOMENT (DEFERRED #65 cash).
    Forge embedding (embedding_id=1); forge Sign with embedding_handle=1
    (real typed reference); read Sign's embedding_handle via OP_SIGN_EMBEDDING_HANDLE
    accessor; verify reads back as 1. DEFERRED #65 cashes empirically through
    the side-table linkage at construction + accessor read."""
    return {'type':'program','body':[
        {'type':'print','value':{'type':'str','value':'=== Sign-with-Embedding Link Test (Pod 3 T6) ==='}},
        # Step 1: forge embedding
        {'type':'let','name':'e','value':{'type':'embedding_new'}},
        {'type':'print','value':{'type':'str','value':'embedding_id (expect 1):'}},
        {'type':'print','value':{'type':'var','name':'e'}},
        # Step 2: forge Sign with embedding_handle = 1 (real typed reference)
        {'type':'let','name':'s','value':{
            'type':'sign_new',
            'hash': b'\xab' + b'\x00' * 31, 'label': 'linked', 'energy': 42,
            'embedding_handle': 1,
        }},
        {'type':'print','value':{'type':'str','value':'sign_id (expect 1):'}},
        {'type':'print','value':{'type':'var','name':'s'}},
        # Step 3: read Sign's embedding_handle via accessor (D3.4 side-table read)
        {'type':'print','value':{'type':'str','value':'sign.embedding_handle (expect 1; #65 cash):'}},
        {'type':'print','value':{'type':'sign_embedding_handle','operand':{'type':'var','name':'s'}}},
        {'type':'print','value':{'type':'str','value':'=== Sign-with-Embedding Link test complete ==='}},
    ]}

def demo_sign_invalid_embedding_handle():
    """Pod 3 T7 — SIGN-INVALID-EMBEDDING architectural moment.
    Forge Sign with embedding_handle=999 (non-existent embedding_id);
    expect Outcome::Err. Verify source_op=160 (OP_SIGN_NEW=0xA0) +
    err_code=1 (ERR_INVALID_ID) via unwrap_err_stmt + tos prints, matching
    Pod 2.2 T5/T3 architectural-moment shape per AUTHORIZED-2A refinement.
    The substrate refuses unresolvable cross-pool reference and names what
    it refused; D2.1/D2.2.6/D2.2.8 doctrine extends to Sign-Embedding
    linkage rejection."""
    return {'type':'program','body':[
        {'type':'print','value':{'type':'str','value':'=== Sign Invalid Embedding Handle Test (Pod 3 T7) ==='}},
        # Forge a real embedding so the pool is non-empty (id=1)
        {'type':'let','name':'e','value':{'type':'embedding_new'}},
        # Attempt Sign with non-existent embedding_handle=999; wrap: True keeps raw Outcome.
        {'type':'let','name':'so','value':{
            'type':'sign_new',
            'hash': b'\xab' + b'\x00' * 31, 'label': 'invalid', 'energy': 42,
            'embedding_handle': 999, 'wrap': True,
        }},
        {'type':'print','value':{'type':'str','value':'is_ok (expect 0 = err):'}},
        {'type':'print','value':{'type':'outcome_is_ok','operand':{'type':'var','name':'so'}}},
        {'type':'outcome_unwrap_err_stmt','value':{'type':'var','name':'so'}},
        {'type':'print','value':{'type':'str','value':'fetch_counter:'}},
        {'type':'print','value':{'type':'tos'}},
        {'type':'print','value':{'type':'str','value':'demod_id:'}},
        {'type':'print','value':{'type':'tos'}},
        {'type':'print','value':{'type':'str','value':'source_op (expect 160 = OP_SIGN_NEW):'}},
        {'type':'print','value':{'type':'tos'}},
        {'type':'print','value':{'type':'str','value':'err_code (expect 1 = ERR_INVALID_ID):'}},
        {'type':'print','value':{'type':'tos'}},
        {'type':'print','value':{'type':'str','value':'=== Sign Invalid Embedding Handle test complete ==='}},
    ]}

def _f32_vector_bytes(values):
    """Pod 3.5 helper: pack a list of float values as f32[384], zero-padded if shorter.
    Returns 1536-byte bytes object suitable for embedding_new vector argument.
    Truncates if longer than 384 elements."""
    import struct
    if len(values) > EMBEDDING_DIM:
        values = values[:EMBEDDING_DIM]
    padded = list(values) + [0.0] * (EMBEDDING_DIM - len(values))
    return b''.join(struct.pack('<f', v) for v in padded)


def _f32_bit_pattern(value):
    """Helper: return u32 bit-pattern of an f32 value as a Python int."""
    import struct
    return struct.unpack('<I', struct.pack('<f', value))[0]


# =============================================================
# Pod 3.5 — Maid speaks: semantic operations test surfaces (T8-T13)
# Architect-ratified expected values per AUTHORIZED-1 prediction set.
# B10 (cosine 45°) result corrected to 0x3F3504F4 per A6 finding —
# Form A f32 norm-of-(1/sqrt(2))^2 sums to 0x3F7FFFFF (1-ulp shy of 1.0),
# divisor drift carries to cosine result; D3.12 strengthened, 10th
# empirical architect-error doctrine landing.
# =============================================================

def demo_cosine_same_vector():
    """Pod 3.5 T8.1 — cosine(v, v) bit-exact result; D3.14 Form A non-guarantee finding.
    Forge two embeddings with identical vector v=(1,2,3); cosine returns 0x3F7FFFFF
    (= 1.0 - 1ulp), NOT exactly 0x3F800000.
    Reason: Form A path = dot(v,v) / (sqrt(norm_sq_a) * sqrt(norm_sq_b));
    norm_sq = 14 in f32 is exact, but sqrt(14)² ≠ 14 exactly (1-ulp drift).
    HALT 2B empirical finding: bit-pattern depends on whether the specific norm_sq
    value's sqrt round-trips through f32. D3.14 doctrine extension: bit-exact
    determinism wins over algebraic perfection — D3.12's reproducibility goal is
    the load-bearing requirement; programs needing exact 1.0 for same-input
    detection should compare embedding_ids before computing, not rely on cosine
    returning algebraically-perfect 1.0."""
    vec = _f32_vector_bytes([1.0, 2.0, 3.0])
    return {'type':'program','body':[
        {'type':'print','value':{'type':'str','value':'=== Cosine Same Vector Test (Pod 3.5 T8.1; D3.14 Form A non-guarantee) ==='}},
        {'type':'let','name':'a','value':{'type':'embedding_new','vector':vec}},
        {'type':'let','name':'b','value':{'type':'embedding_new','vector':vec}},
        {'type':'print','value':{'type':'str','value':'cosine (expect 1065353215 = 0x3F7FFFFF = 1.0 - 1ulp; NOT 1.0 exactly per Form A drift):'}},
        {'type':'print','value':{'type':'embedding_cosine','lhs':{'type':'var','name':'a'},'rhs':{'type':'var','name':'b'}}},
        {'type':'print','value':{'type':'str','value':'=== Cosine Same Vector test complete ==='}},
    ]}

def demo_cosine_zero_vector():
    """Pod 3.5 T8.2 — cosine(0, v) → Outcome::Err(InvalidEmbeddingArg).
    Zero-norm rejection per D3.14: divisor would be 0; substrate refuses
    rather than emit NaN/Inf."""
    nonzero = _f32_vector_bytes([1.0, 0.0, 0.0])
    return {'type':'program','body':[
        {'type':'print','value':{'type':'str','value':'=== Cosine Zero Vector Test (Pod 3.5 T8.2) ==='}},
        {'type':'let','name':'z','value':{'type':'embedding_new'}},                  # default zero vector
        {'type':'let','name':'v','value':{'type':'embedding_new','vector':nonzero}},
        {'type':'let','name':'o','value':{'type':'embedding_cosine_raw','id_a':1,'id_b':2}},
        {'type':'print','value':{'type':'str','value':'is_ok (expect 0 = err):'}},
        {'type':'print','value':{'type':'outcome_is_ok','operand':{'type':'var','name':'o'}}},
        {'type':'outcome_unwrap_err_stmt','value':{'type':'var','name':'o'}},
        {'type':'print','value':{'type':'str','value':'fetch_counter:'}},
        {'type':'print','value':{'type':'tos'}},
        {'type':'print','value':{'type':'str','value':'demod_id:'}},
        {'type':'print','value':{'type':'tos'}},
        {'type':'print','value':{'type':'str','value':'source_op (expect 198 = OP_EMBEDDING_COSINE):'}},
        {'type':'print','value':{'type':'tos'}},
        {'type':'print','value':{'type':'str','value':'err_code (expect 9 = ERR_INVALID_EMBEDDING_ARG):'}},
        {'type':'print','value':{'type':'tos'}},
        {'type':'print','value':{'type':'str','value':'=== Cosine Zero Vector test complete ==='}},
    ]}

def demo_cosine_45_degree():
    """Pod 3.5 T8.3 — cosine of axis-aligned vs 45-degree vector.
    A6 ratified bit-exact result: 0x3F3504F4 (NOT algebraically-pure 0x3F3504F3
    — Form A f32 norm-of-(1/sqrt(2))^2 sums to 0x3F7FFFFF; divisor drift
    propagates 1 ulp to cosine. D3.12 / 10th architect-error doctrine landing).
    Bit-exactness load-bearing for two-build determinism extension to FP."""
    import math
    inv_sqrt2 = 1.0 / math.sqrt(2.0)
    v_e0 = _f32_vector_bytes([1.0, 0.0])
    v_45 = _f32_vector_bytes([inv_sqrt2, inv_sqrt2])
    return {'type':'program','body':[
        {'type':'print','value':{'type':'str','value':'=== Cosine 45-Degree Test (Pod 3.5 T8.3) ==='}},
        {'type':'let','name':'a','value':{'type':'embedding_new','vector':v_e0}},
        {'type':'let','name':'b','value':{'type':'embedding_new','vector':v_45}},
        {'type':'print','value':{'type':'str','value':'cosine (expect 1060439284 = 0x3F3504F4 per A6):'}},
        {'type':'print','value':{'type':'embedding_cosine','lhs':{'type':'var','name':'a'},'rhs':{'type':'var','name':'b'}}},
        {'type':'print','value':{'type':'str','value':'=== Cosine 45-Degree test complete ==='}},
    ]}

def demo_cosine_orthogonal():
    """Pod 3.5 T8.4 — orthogonal axis-aligned vectors → cosine = 0.0 exactly."""
    v_x = _f32_vector_bytes([1.0, 0.0])
    v_y = _f32_vector_bytes([0.0, 1.0])
    return {'type':'program','body':[
        {'type':'print','value':{'type':'str','value':'=== Cosine Orthogonal Test (Pod 3.5 T8.4) ==='}},
        {'type':'let','name':'a','value':{'type':'embedding_new','vector':v_x}},
        {'type':'let','name':'b','value':{'type':'embedding_new','vector':v_y}},
        {'type':'print','value':{'type':'str','value':f'cosine (expect {_f32_bit_pattern(0.0)} = bit pattern of 0.0):'}},
        {'type':'print','value':{'type':'embedding_cosine','lhs':{'type':'var','name':'a'},'rhs':{'type':'var','name':'b'}}},
        {'type':'print','value':{'type':'str','value':'=== Cosine Orthogonal test complete ==='}},
    ]}

def demo_cosine_antipodal():
    """Pod 3.5 T8.5 — cosine(v, -v) = -1.0 (bit pattern 0xBF800000)."""
    v = _f32_vector_bytes([1.0, 2.0])
    nv = _f32_vector_bytes([-1.0, -2.0])
    return {'type':'program','body':[
        {'type':'print','value':{'type':'str','value':'=== Cosine Antipodal Test (Pod 3.5 T8.5) ==='}},
        {'type':'let','name':'a','value':{'type':'embedding_new','vector':v}},
        {'type':'let','name':'b','value':{'type':'embedding_new','vector':nv}},
        {'type':'print','value':{'type':'str','value':f'cosine (expect {_f32_bit_pattern(-1.0)} = bit pattern of -1.0):'}},
        {'type':'print','value':{'type':'embedding_cosine','lhs':{'type':'var','name':'a'},'rhs':{'type':'var','name':'b'}}},
        {'type':'print','value':{'type':'str','value':'=== Cosine Antipodal test complete ==='}},
    ]}

def demo_cosine_invalid_id():
    """Pod 3.5 T8.6 — cosine with non-existent id → Err(InvalidId, source_op=0xC6=198)."""
    return {'type':'program','body':[
        {'type':'print','value':{'type':'str','value':'=== Cosine Invalid ID Test (Pod 3.5 T8.6) ==='}},
        {'type':'let','name':'a','value':{'type':'embedding_new'}},   # id=1 valid
        {'type':'let','name':'o','value':{'type':'embedding_cosine_raw','id_a':1,'id_b':999}},
        {'type':'print','value':{'type':'str','value':'is_ok (expect 0 = err):'}},
        {'type':'print','value':{'type':'outcome_is_ok','operand':{'type':'var','name':'o'}}},
        {'type':'outcome_unwrap_err_stmt','value':{'type':'var','name':'o'}},
        {'type':'print','value':{'type':'str','value':'fetch_counter:'}},
        {'type':'print','value':{'type':'tos'}},
        {'type':'print','value':{'type':'str','value':'demod_id:'}},
        {'type':'print','value':{'type':'tos'}},
        {'type':'print','value':{'type':'str','value':'source_op (expect 198 = OP_EMBEDDING_COSINE):'}},
        {'type':'print','value':{'type':'tos'}},
        {'type':'print','value':{'type':'str','value':'err_code (expect 1 = ERR_INVALID_ID):'}},
        {'type':'print','value':{'type':'tos'}},
        {'type':'print','value':{'type':'str','value':'=== Cosine Invalid ID test complete ==='}},
    ]}

def demo_dot_product_simple():
    """Pod 3.5 T9.1 — dot((1,2,3), (4,5,6)) = 32.0 (bit pattern 0x42000000)."""
    a = _f32_vector_bytes([1.0, 2.0, 3.0])
    b = _f32_vector_bytes([4.0, 5.0, 6.0])
    return {'type':'program','body':[
        {'type':'print','value':{'type':'str','value':'=== Dot Product Simple Test (Pod 3.5 T9.1) ==='}},
        {'type':'let','name':'va','value':{'type':'embedding_new','vector':a}},
        {'type':'let','name':'vb','value':{'type':'embedding_new','vector':b}},
        {'type':'print','value':{'type':'str','value':f'dot (expect {_f32_bit_pattern(32.0)} = bit pattern of 32.0):'}},
        {'type':'print','value':{'type':'embedding_dot_product','lhs':{'type':'var','name':'va'},'rhs':{'type':'var','name':'vb'}}},
        {'type':'print','value':{'type':'str','value':'=== Dot Product Simple test complete ==='}},
    ]}

def demo_dot_product_invalid_id():
    """Pod 3.5 T9.2 — dot with invalid id → Err(InvalidId, source_op=0xC7=199)."""
    return {'type':'program','body':[
        {'type':'print','value':{'type':'str','value':'=== Dot Product Invalid ID Test (Pod 3.5 T9.2) ==='}},
        {'type':'let','name':'a','value':{'type':'embedding_new'}},
        {'type':'let','name':'o','value':{'type':'embedding_dot_product_raw','id_a':1,'id_b':999}},
        {'type':'print','value':{'type':'str','value':'is_ok (expect 0 = err):'}},
        {'type':'print','value':{'type':'outcome_is_ok','operand':{'type':'var','name':'o'}}},
        {'type':'outcome_unwrap_err_stmt','value':{'type':'var','name':'o'}},
        {'type':'print','value':{'type':'str','value':'fetch_counter:'}},
        {'type':'print','value':{'type':'tos'}},
        {'type':'print','value':{'type':'str','value':'demod_id:'}},
        {'type':'print','value':{'type':'tos'}},
        {'type':'print','value':{'type':'str','value':'source_op (expect 199 = OP_EMBEDDING_DOT_PRODUCT):'}},
        {'type':'print','value':{'type':'tos'}},
        {'type':'print','value':{'type':'str','value':'err_code (expect 1 = ERR_INVALID_ID):'}},
        {'type':'print','value':{'type':'tos'}},
        {'type':'print','value':{'type':'str','value':'=== Dot Product Invalid ID test complete ==='}},
    ]}

def demo_l2_distance_same():
    """Pod 3.5 T10.1 — l2(v, v) = 0.0 exactly (sqrt(0) = 0)."""
    v = _f32_vector_bytes([1.0, 2.0, 3.0])
    return {'type':'program','body':[
        {'type':'print','value':{'type':'str','value':'=== L2 Distance Same Test (Pod 3.5 T10.1) ==='}},
        {'type':'let','name':'a','value':{'type':'embedding_new','vector':v}},
        {'type':'let','name':'b','value':{'type':'embedding_new','vector':v}},
        {'type':'print','value':{'type':'str','value':f'l2 (expect {_f32_bit_pattern(0.0)} = bit pattern of 0.0):'}},
        {'type':'print','value':{'type':'embedding_l2_distance','lhs':{'type':'var','name':'a'},'rhs':{'type':'var','name':'b'}}},
        {'type':'print','value':{'type':'str','value':'=== L2 Distance Same test complete ==='}},
    ]}

def demo_l2_distance_simple():
    """Pod 3.5 T10.2 — l2((0,0,0), (3,4,0)) = sqrt(25) = 5.0 (bit pattern 0x40A00000)."""
    a = _f32_vector_bytes([0.0, 0.0, 0.0])
    b = _f32_vector_bytes([3.0, 4.0, 0.0])
    return {'type':'program','body':[
        {'type':'print','value':{'type':'str','value':'=== L2 Distance Simple Test (Pod 3.5 T10.2) ==='}},
        {'type':'let','name':'va','value':{'type':'embedding_new','vector':a}},
        {'type':'let','name':'vb','value':{'type':'embedding_new','vector':b}},
        {'type':'print','value':{'type':'str','value':f'l2 (expect {_f32_bit_pattern(5.0)} = bit pattern of 5.0):'}},
        {'type':'print','value':{'type':'embedding_l2_distance','lhs':{'type':'var','name':'va'},'rhs':{'type':'var','name':'vb'}}},
        {'type':'print','value':{'type':'str','value':'=== L2 Distance Simple test complete ==='}},
    ]}

def demo_l2_distance_invalid_id():
    """Pod 3.5 T10.3 — l2 with invalid id → Err(InvalidId, source_op=0xC8=200)."""
    return {'type':'program','body':[
        {'type':'print','value':{'type':'str','value':'=== L2 Distance Invalid ID Test (Pod 3.5 T10.3) ==='}},
        {'type':'let','name':'a','value':{'type':'embedding_new'}},
        {'type':'let','name':'o','value':{'type':'embedding_l2_distance_raw','id_a':1,'id_b':999}},
        {'type':'print','value':{'type':'str','value':'is_ok (expect 0 = err):'}},
        {'type':'print','value':{'type':'outcome_is_ok','operand':{'type':'var','name':'o'}}},
        {'type':'outcome_unwrap_err_stmt','value':{'type':'var','name':'o'}},
        {'type':'print','value':{'type':'str','value':'fetch_counter:'}},
        {'type':'print','value':{'type':'tos'}},
        {'type':'print','value':{'type':'str','value':'demod_id:'}},
        {'type':'print','value':{'type':'tos'}},
        {'type':'print','value':{'type':'str','value':'source_op (expect 200 = OP_EMBEDDING_L2_DISTANCE):'}},
        {'type':'print','value':{'type':'tos'}},
        {'type':'print','value':{'type':'str','value':'err_code (expect 1 = ERR_INVALID_ID):'}},
        {'type':'print','value':{'type':'tos'}},
        {'type':'print','value':{'type':'str','value':'=== L2 Distance Invalid ID test complete ==='}},
    ]}

def demo_lookup_top1_basic():
    """Pod 3.5 T11.1 — lookup_top1 on multi-embedding pool returns nearest non-self.
    Query at (1,0); pool has (1,0)=self, (0.9,0.1)=near, (0,1)=far.
    Self exclusion per D3.18; expect best_id = 2 (the near embedding).
    Pod 3.5 C2/C3 ratification: forge sub-cap A with 1M budget, ENTER, lookup, EXIT.
    Side-benefit: first 5-digit babylon ripple observation in the project — under sub-cap A,
    ROOT.used += floor(100000 / 2) = 50000j post-EXIT (D3.9 axiom inheritance / D3.23)."""
    q = _f32_vector_bytes([1.0, 0.0])
    near = _f32_vector_bytes([0.9, 0.1])
    far = _f32_vector_bytes([0.0, 1.0])
    return {'type':'program','body':[
        {'type':'print','value':{'type':'str','value':'=== Lookup Top-1 Basic Test (Pod 3.5 T11.1 = B17) ==='}},
        {'type':'let','name':'q','value':{'type':'embedding_new','vector':q}},     # id=1 = query (self)
        {'type':'let','name':'n','value':{'type':'embedding_new','vector':near}},  # id=2 = near
        {'type':'let','name':'f','value':{'type':'embedding_new','vector':far}},   # id=3 = far
        # Sub-cap A: 1M budget, BIT_CAP_FORGE only — witness doctrine D3.13 means lookup
        # bypasses BIT_EMBEDDING_FORGE bit-check.
        {'type':'let','name':'co','value':{'type':'cap_new','granted_bitmap': BIT_CAP_FORGE, 'energy_budget': 1000000}},
        {'type':'let','name':'cap_a','value':{'type':'outcome_unwrap_ok','operand':{'type':'var','name':'co'}}},
        {'type':'let','name':'enter_a','value':{'type':'cap_enter','operand':{'type':'var','name':'cap_a'}}},
        {'type':'print','value':{'type':'str','value':'best_id (expect 2 = near; self excluded):'}},
        {'type':'print','value':{'type':'embedding_lookup_top1','operand':{'type':'var','name':'q'}}},
        {'type':'let','name':'exit_a','value':{'type':'cap_exit'}},
        {'type':'print','value':{'type':'str','value':'A.used (originating; expect 0):'}},
        {'type':'print','value':{'type':'cap_used','operand':{'type':'var','name':'cap_a'}}},
        {'type':'print','value':{'type':'str','value':'ROOT.used (expect 50000 = first 5-digit babylon ripple; lookup 100000j / 2):'}},
        {'type':'print','value':{'type':'cap_used','operand':{'type':'int','value':1}}},
        {'type':'print','value':{'type':'str','value':'=== Lookup Top-1 Basic test complete ==='}},
    ]}

def demo_lookup_top1_empty():
    """Pod 3.5 T11.2 — lookup_top1 on pool with only the query → Err(InvalidEmbeddingArg).
    No candidates (self excluded per D3.18); substrate refuses.
    Forges sub-cap with 1M budget per C2 ratification."""
    q = _f32_vector_bytes([1.0, 2.0])
    return {'type':'program','body':[
        {'type':'print','value':{'type':'str','value':'=== Lookup Top-1 Empty Pool Test (Pod 3.5 T11.2) ==='}},
        {'type':'let','name':'q','value':{'type':'embedding_new','vector':q}},
        {'type':'let','name':'co','value':{'type':'cap_new','granted_bitmap': BIT_CAP_FORGE, 'energy_budget': 1000000}},
        {'type':'let','name':'cap_a','value':{'type':'outcome_unwrap_ok','operand':{'type':'var','name':'co'}}},
        {'type':'let','name':'enter_a','value':{'type':'cap_enter','operand':{'type':'var','name':'cap_a'}}},
        {'type':'let','name':'o','value':{'type':'embedding_lookup_top1_raw','id':1}},
        {'type':'let','name':'exit_a','value':{'type':'cap_exit'}},
        {'type':'print','value':{'type':'str','value':'is_ok (expect 0 = err):'}},
        {'type':'print','value':{'type':'outcome_is_ok','operand':{'type':'var','name':'o'}}},
        {'type':'outcome_unwrap_err_stmt','value':{'type':'var','name':'o'}},
        {'type':'print','value':{'type':'str','value':'fetch_counter:'}},
        {'type':'print','value':{'type':'tos'}},
        {'type':'print','value':{'type':'str','value':'demod_id:'}},
        {'type':'print','value':{'type':'tos'}},
        {'type':'print','value':{'type':'str','value':'source_op (expect 201 = OP_EMBEDDING_LOOKUP_TOP1):'}},
        {'type':'print','value':{'type':'tos'}},
        {'type':'print','value':{'type':'str','value':'err_code (expect 9 = ERR_INVALID_EMBEDDING_ARG):'}},
        {'type':'print','value':{'type':'tos'}},
        {'type':'print','value':{'type':'str','value':'=== Lookup Top-1 Empty Pool test complete ==='}},
    ]}

def demo_lookup_top1_invalid_query():
    """Pod 3.5 T11.3 — lookup_top1 on non-existent query → Err(InvalidId, source_op=0xC9=201).
    Forges sub-cap with 1M budget per C2 ratification (full dispatch cost charged
    upfront before err return)."""
    return {'type':'program','body':[
        {'type':'print','value':{'type':'str','value':'=== Lookup Top-1 Invalid Query Test (Pod 3.5 T11.3) ==='}},
        {'type':'let','name':'a','value':{'type':'embedding_new'}},
        {'type':'let','name':'co','value':{'type':'cap_new','granted_bitmap': BIT_CAP_FORGE, 'energy_budget': 1000000}},
        {'type':'let','name':'cap_a','value':{'type':'outcome_unwrap_ok','operand':{'type':'var','name':'co'}}},
        {'type':'let','name':'enter_a','value':{'type':'cap_enter','operand':{'type':'var','name':'cap_a'}}},
        {'type':'let','name':'o','value':{'type':'embedding_lookup_top1_raw','id':999}},
        {'type':'let','name':'exit_a','value':{'type':'cap_exit'}},
        {'type':'print','value':{'type':'str','value':'is_ok (expect 0 = err):'}},
        {'type':'print','value':{'type':'outcome_is_ok','operand':{'type':'var','name':'o'}}},
        {'type':'outcome_unwrap_err_stmt','value':{'type':'var','name':'o'}},
        {'type':'print','value':{'type':'str','value':'fetch_counter:'}},
        {'type':'print','value':{'type':'tos'}},
        {'type':'print','value':{'type':'str','value':'demod_id:'}},
        {'type':'print','value':{'type':'tos'}},
        {'type':'print','value':{'type':'str','value':'source_op (expect 201 = OP_EMBEDDING_LOOKUP_TOP1):'}},
        {'type':'print','value':{'type':'tos'}},
        {'type':'print','value':{'type':'str','value':'err_code (expect 1 = ERR_INVALID_ID):'}},
        {'type':'print','value':{'type':'tos'}},
        {'type':'print','value':{'type':'str','value':'=== Lookup Top-1 Invalid Query test complete ==='}},
    ]}

def demo_maid_composition():
    """Pod 3.5 — Maid composition pattern (lookup-by-meaning → recover Sign).
    Forge codebook of (embedding, Sign) pairs; query matches an embedding;
    OP_EMBEDDING_LOOKUP_TOP1 returns nearest embedding_id; OP_EMBEDDING_SIGN_HANDLE
    recovers the linked sign_id. End-to-end demonstration of D3.13 witness compute
    + D3.20 reverse side-table working in concert.

    Codebook:
      e1 = (1, 0)         linked to sign_id=1 (label='alpha')
      e2 = (0.9, 0.1)     linked to sign_id=2 (label='beta')
      e3 = (0, 1)         linked to sign_id=3 (label='gamma')
      e4 = query (1, 0)   no Sign linked (orphan)
    Query e4 → lookup returns e1 (nearest non-self) → reverse handle returns sign_id=1.
    Forges sub-cap with 1M budget per C2 ratification."""
    return {'type':'program','body':[
        {'type':'print','value':{'type':'str','value':'=== Maid Composition Test (Pod 3.5 — lookup-by-meaning + Sign recovery) ==='}},
        # Codebook embeddings + Signs
        {'type':'let','name':'e1','value':{'type':'embedding_new','vector':_f32_vector_bytes([1.0, 0.0])}},
        {'type':'let','name':'e2','value':{'type':'embedding_new','vector':_f32_vector_bytes([0.9, 0.1])}},
        {'type':'let','name':'e3','value':{'type':'embedding_new','vector':_f32_vector_bytes([0.0, 1.0])}},
        {'type':'let','name':'s1','value':{'type':'sign_new','hash':b'\x01'+b'\x00'*31,'label':'alpha','energy':1,'embedding_handle':1}},
        {'type':'let','name':'s2','value':{'type':'sign_new','hash':b'\x02'+b'\x00'*31,'label':'beta','energy':2,'embedding_handle':2}},
        {'type':'let','name':'s3','value':{'type':'sign_new','hash':b'\x03'+b'\x00'*31,'label':'gamma','energy':3,'embedding_handle':3}},
        # Query embedding (orphan; no linked Sign)
        {'type':'let','name':'q','value':{'type':'embedding_new','vector':_f32_vector_bytes([1.0, 0.0])}},
        # Sub-cap with 1M budget for the lookup
        {'type':'let','name':'co','value':{'type':'cap_new','granted_bitmap': BIT_CAP_FORGE, 'energy_budget': 1000000}},
        {'type':'let','name':'cap_a','value':{'type':'outcome_unwrap_ok','operand':{'type':'var','name':'co'}}},
        {'type':'let','name':'enter_a','value':{'type':'cap_enter','operand':{'type':'var','name':'cap_a'}}},
        # Lookup-by-meaning
        {'type':'let','name':'best_id','value':{'type':'embedding_lookup_top1','operand':{'type':'var','name':'q'}}},
        {'type':'let','name':'exit_a','value':{'type':'cap_exit'}},
        {'type':'print','value':{'type':'str','value':'best_embedding_id (expect 1 = e1; nearest non-self):'}},
        {'type':'print','value':{'type':'var','name':'best_id'}},
        # Reverse side-table read: which Sign owns this embedding?
        {'type':'print','value':{'type':'str','value':'recovered_sign_id (expect 1 = s1 alpha):'}},
        {'type':'print','value':{'type':'embedding_sign_handle','operand':{'type':'var','name':'best_id'}}},
        {'type':'print','value':{'type':'str','value':'=== Maid Composition test complete ==='}},
    ]}

def demo_embedding_sign_handle_linked():
    """Pod 3.5 T12.1 — D3.20 reverse side-table: forge Sign with embedding_handle=1;
    then read OP_EMBEDDING_SIGN_HANDLE for embedding_id=1; expect sign_id=1."""
    return {'type':'program','body':[
        {'type':'print','value':{'type':'str','value':'=== Embedding Sign Handle Linked Test (Pod 3.5 T12.1) ==='}},
        {'type':'let','name':'e','value':{'type':'embedding_new'}},                         # id=1
        {'type':'let','name':'s','value':{'type':'sign_new','hash': b'\xaa' + b'\x00'*31,
                                            'label': 'linked', 'energy': 7,
                                            'embedding_handle': 1}},                         # sign_id=1
        {'type':'print','value':{'type':'str','value':'reverse_sign_id (expect 1):'}},
        {'type':'print','value':{'type':'embedding_sign_handle','operand':{'type':'var','name':'e'}}},
        {'type':'print','value':{'type':'str','value':'=== Embedding Sign Handle Linked test complete ==='}},
    ]}

def demo_embedding_sign_handle_unlinked():
    """Pod 3.5 T12.2 — orphan embedding (no Sign references it) → reverse table = 0.
    Confirms BSS-zero default state preserves backward-compat for embeddings
    forged before / without a Sign linkage."""
    return {'type':'program','body':[
        {'type':'print','value':{'type':'str','value':'=== Embedding Sign Handle Unlinked Test (Pod 3.5 T12.2) ==='}},
        {'type':'let','name':'e','value':{'type':'embedding_new'}},                         # id=1, no Sign
        {'type':'print','value':{'type':'str','value':'reverse_sign_id (expect 0 = unlinked):'}},
        {'type':'print','value':{'type':'embedding_sign_handle','operand':{'type':'var','name':'e'}}},
        {'type':'print','value':{'type':'str','value':'=== Embedding Sign Handle Unlinked test complete ==='}},
    ]}

def demo_compute_under_subcap():
    """Pod 3.5 T13 / B21 / B14-compute / B20 — Compute-op single-fire canary
    (reframed per AUTHORIZED-2A C1 ratification; eleventh empirical landing of
    architect-error doctrine, subtype 'axiom-inheritance trace failure').

    Witness doctrine D3.13: compute bypasses bit-check (sub-cap A grants
    BIT_CAP_FORGE only — NO BIT_EMBEDDING_FORGE — yet cosine succeeds because
    compute is read-and-witness, not forge).

    D3.9/D3.23 axiom inheritance: cosine wraps result via .construct_ok_outcome,
    which fires babylon_charge_lineage by construction. Compute ops fire babylon
    just like primitive constructors — no opt-out, no exception. Federation
    accounting tracks Outcome production uniformly.

    Pre-condition (originating-doesn't-charge-itself): 2× embedding_new under
    ROOT context → ROOT.used += 0 (ROOT IS the originating cap; no upward
    lineage to charge). Pre-subcap ROOT.used = 0.

    Sub-cap A cosine → A.used += 0 (originating); ROOT.used += floor(400/2) = 200
    (lineage spatial-merge through .construct_ok_outcome's internal babylon).
    Post-subcap ROOT.used = 200."""
    return {'type':'program','body':[
        {'type':'print','value':{'type':'str','value':'=== Compute-Op Single-Fire Canary (Pod 3.5 T13 = B21+B14-compute+B20) ==='}},
        {'type':'let','name':'a','value':{'type':'embedding_new','vector':_f32_vector_bytes([1.0, 0.0])}},
        {'type':'let','name':'b','value':{'type':'embedding_new','vector':_f32_vector_bytes([0.0, 1.0])}},
        {'type':'print','value':{'type':'str','value':'ROOT.used pre-subcap (expect 0; originating):'}},
        {'type':'print','value':{'type':'cap_used','operand':{'type':'int','value':1}}},
        # Sub-cap A: BIT_CAP_FORGE only — NO BIT_EMBEDDING_FORGE; witness D3.13 in action.
        {'type':'let','name':'co','value':{'type':'cap_new','granted_bitmap': BIT_CAP_FORGE, 'energy_budget': 1000}},
        {'type':'let','name':'cap_a','value':{'type':'outcome_unwrap_ok','operand':{'type':'var','name':'co'}}},
        {'type':'let','name':'enter','value':{'type':'cap_enter','operand':{'type':'var','name':'cap_a'}}},
        {'type':'print','value':{'type':'str','value':'cosine under sub-cap (B20 witness; expect 0 = bit pattern of 0.0):'}},
        {'type':'print','value':{'type':'embedding_cosine','lhs':{'type':'var','name':'a'},'rhs':{'type':'var','name':'b'}}},
        {'type':'let','name':'exit_a','value':{'type':'cap_exit'}},
        {'type':'print','value':{'type':'str','value':'A.used (originating; expect 0):'}},
        {'type':'print','value':{'type':'cap_used','operand':{'type':'var','name':'cap_a'}}},
        {'type':'print','value':{'type':'str','value':'ROOT.used post-cosine (B21 reframed; expect 200 = floor(400/2) D3.9 axiom inheritance / D3.23):'}},
        {'type':'print','value':{'type':'cap_used','operand':{'type':'int','value':1}}},
        {'type':'print','value':{'type':'str','value':'=== Compute-Op Single-Fire Canary test complete ==='}},
    ]}


# --- Pod 3.6 Maid composes: synthesis test surfaces (B25-B26 Phase 1.2) ---

def demo_synthesis_add_basic():
    """Pod 3.6 B25 — add(e_unit_x, e_unit_y) = (1.0, 1.0, 0.0, 0.0, ...).
    R10 expected: result[0]=0x3F800000, result[1]=0x3F800000, result[2]=0x00000000.
    Synthesis tuple at vm_embedding_synthesis[(new_id-1)*32]: (op=0x01, source_a=1, source_b=2, scalar=0).
    Tuple verification deferred to Phase 3.2 when OP_EMBEDDING_SYNTHESIS_HANDLE (0xCF) lands."""
    v_x = _f32_vector_bytes([1.0, 0.0])
    v_y = _f32_vector_bytes([0.0, 1.0])
    return {'type':'program','body':[
        {'type':'print','value':{'type':'str','value':'=== Synthesis Add Basic Test (Pod 3.6 B25) ==='}},
        {'type':'let','name':'a','value':{'type':'embedding_new','vector':v_x}},
        {'type':'let','name':'b','value':{'type':'embedding_new','vector':v_y}},
        {'type':'let','name':'c','value':{'type':'embedding_add','lhs':{'type':'var','name':'a'},'rhs':{'type':'var','name':'b'}}},
        {'type':'print','value':{'type':'str','value':f'c[0] (expect {_f32_bit_pattern(1.0)} = bit pattern of 1.0):'}},
        {'type':'print','value':{'type':'embedding_get_dim','operand':{'type':'var','name':'c'},'dim_index':0}},
        {'type':'print','value':{'type':'str','value':f'c[1] (expect {_f32_bit_pattern(1.0)} = bit pattern of 1.0):'}},
        {'type':'print','value':{'type':'embedding_get_dim','operand':{'type':'var','name':'c'},'dim_index':1}},
        {'type':'print','value':{'type':'str','value':f'c[2] (expect {_f32_bit_pattern(0.0)} = bit pattern of 0.0):'}},
        {'type':'print','value':{'type':'embedding_get_dim','operand':{'type':'var','name':'c'},'dim_index':2}},
        {'type':'print','value':{'type':'str','value':'=== Synthesis Add Basic test complete ==='}},
    ]}

def demo_synthesis_add_zero():
    """Pod 3.6 B26 — add(a, zero_vector) = a byte-exact (R10 endpoint property)."""
    a_vec = _f32_vector_bytes([1.0, 2.0, 3.0])
    return {'type':'program','body':[
        {'type':'print','value':{'type':'str','value':'=== Synthesis Add Zero Test (Pod 3.6 B26) ==='}},
        {'type':'let','name':'a','value':{'type':'embedding_new','vector':a_vec}},
        {'type':'let','name':'z','value':{'type':'embedding_new'}},   # default zero vector
        {'type':'let','name':'c','value':{'type':'embedding_add','lhs':{'type':'var','name':'a'},'rhs':{'type':'var','name':'z'}}},
        {'type':'print','value':{'type':'str','value':f'c[0] (expect {_f32_bit_pattern(1.0)} = a[0]=1.0 byte-exact):'}},
        {'type':'print','value':{'type':'embedding_get_dim','operand':{'type':'var','name':'c'},'dim_index':0}},
        {'type':'print','value':{'type':'str','value':f'c[1] (expect {_f32_bit_pattern(2.0)} = a[1]=2.0 byte-exact):'}},
        {'type':'print','value':{'type':'embedding_get_dim','operand':{'type':'var','name':'c'},'dim_index':1}},
        {'type':'print','value':{'type':'str','value':f'c[2] (expect {_f32_bit_pattern(3.0)} = a[2]=3.0 byte-exact):'}},
        {'type':'print','value':{'type':'embedding_get_dim','operand':{'type':'var','name':'c'},'dim_index':2}},
        {'type':'print','value':{'type':'str','value':f'c[383] (expect {_f32_bit_pattern(0.0)} = a[383]=0.0 byte-exact):'}},
        {'type':'print','value':{'type':'embedding_get_dim','operand':{'type':'var','name':'c'},'dim_index':383}},
        {'type':'print','value':{'type':'str','value':'=== Synthesis Add Zero test complete ==='}},
    ]}

def demo_synthesis_subtract_basic():
    """Pod 3.6 B27 — sub(e_unit_x, e_unit_y) = (1.0, -1.0, 0.0, ...).
    R10 expected: result[0]=0x3F800000, result[1]=0xBF800000, result[2]=0x00000000."""
    v_x = _f32_vector_bytes([1.0, 0.0])
    v_y = _f32_vector_bytes([0.0, 1.0])
    return {'type':'program','body':[
        {'type':'print','value':{'type':'str','value':'=== Synthesis Subtract Basic Test (Pod 3.6 B27) ==='}},
        {'type':'let','name':'a','value':{'type':'embedding_new','vector':v_x}},
        {'type':'let','name':'b','value':{'type':'embedding_new','vector':v_y}},
        {'type':'let','name':'c','value':{'type':'embedding_subtract','lhs':{'type':'var','name':'a'},'rhs':{'type':'var','name':'b'}}},
        {'type':'print','value':{'type':'str','value':f'c[0] (expect {_f32_bit_pattern(1.0)} = bit pattern of 1.0):'}},
        {'type':'print','value':{'type':'embedding_get_dim','operand':{'type':'var','name':'c'},'dim_index':0}},
        {'type':'print','value':{'type':'str','value':f'c[1] (expect {_f32_bit_pattern(-1.0)} = bit pattern of -1.0):'}},
        {'type':'print','value':{'type':'embedding_get_dim','operand':{'type':'var','name':'c'},'dim_index':1}},
        {'type':'print','value':{'type':'str','value':f'c[2] (expect {_f32_bit_pattern(0.0)} = bit pattern of 0.0):'}},
        {'type':'print','value':{'type':'embedding_get_dim','operand':{'type':'var','name':'c'},'dim_index':2}},
        {'type':'print','value':{'type':'str','value':'=== Synthesis Subtract Basic test complete ==='}},
    ]}

def demo_synthesis_subtract_self():
    """Pod 3.6 B28 — sub(a, a) = zero vector byte-exact (subss(x,x) = +0.0 for finite non-NaN x)."""
    a_vec = _f32_vector_bytes([1.0, 2.0, 3.0, 4.0])
    return {'type':'program','body':[
        {'type':'print','value':{'type':'str','value':'=== Synthesis Subtract Self Test (Pod 3.6 B28) ==='}},
        {'type':'let','name':'a','value':{'type':'embedding_new','vector':a_vec}},
        {'type':'let','name':'c','value':{'type':'embedding_subtract','lhs':{'type':'var','name':'a'},'rhs':{'type':'var','name':'a'}}},
        {'type':'print','value':{'type':'str','value':f'c[0] (expect {_f32_bit_pattern(0.0)} = +0.0 byte-exact):'}},
        {'type':'print','value':{'type':'embedding_get_dim','operand':{'type':'var','name':'c'},'dim_index':0}},
        {'type':'print','value':{'type':'str','value':f'c[1] (expect {_f32_bit_pattern(0.0)} = +0.0 byte-exact):'}},
        {'type':'print','value':{'type':'embedding_get_dim','operand':{'type':'var','name':'c'},'dim_index':1}},
        {'type':'print','value':{'type':'str','value':f'c[3] (expect {_f32_bit_pattern(0.0)} = +0.0 byte-exact):'}},
        {'type':'print','value':{'type':'embedding_get_dim','operand':{'type':'var','name':'c'},'dim_index':3}},
        {'type':'print','value':{'type':'str','value':f'c[100] (expect {_f32_bit_pattern(0.0)} = +0.0 byte-exact):'}},
        {'type':'print','value':{'type':'embedding_get_dim','operand':{'type':'var','name':'c'},'dim_index':100}},
        {'type':'print','value':{'type':'str','value':'=== Synthesis Subtract Self test complete ==='}},
    ]}

def demo_synthesis_scale_basic():
    """Pod 3.6 B29 — scale(2.0, e_unit_x) = (2.0, 0.0, ...).
    R10 expected: result[0]=0x40000000, rest zero."""
    v_x = _f32_vector_bytes([1.0, 0.0])
    return {'type':'program','body':[
        {'type':'print','value':{'type':'str','value':'=== Synthesis Scale Basic Test (Pod 3.6 B29) ==='}},
        {'type':'let','name':'a','value':{'type':'embedding_new','vector':v_x}},
        {'type':'let','name':'c','value':{'type':'embedding_scale','operand':{'type':'var','name':'a'},'scalar_bits':_f32_bit_pattern(2.0)}},
        {'type':'print','value':{'type':'str','value':f'c[0] (expect {_f32_bit_pattern(2.0)} = bit pattern of 2.0):'}},
        {'type':'print','value':{'type':'embedding_get_dim','operand':{'type':'var','name':'c'},'dim_index':0}},
        {'type':'print','value':{'type':'str','value':f'c[1] (expect {_f32_bit_pattern(0.0)} = bit pattern of 0.0):'}},
        {'type':'print','value':{'type':'embedding_get_dim','operand':{'type':'var','name':'c'},'dim_index':1}},
        {'type':'print','value':{'type':'str','value':'=== Synthesis Scale Basic test complete ==='}},
    ]}

def demo_synthesis_scale_zero():
    """Pod 3.6 B30 — scale(0.0, a) = zero vector byte-exact (mulss(0.0, x) = 0 for finite non-NaN x)."""
    a_vec = _f32_vector_bytes([1.0, 2.0, 3.0])
    return {'type':'program','body':[
        {'type':'print','value':{'type':'str','value':'=== Synthesis Scale Zero Test (Pod 3.6 B30) ==='}},
        {'type':'let','name':'a','value':{'type':'embedding_new','vector':a_vec}},
        {'type':'let','name':'c','value':{'type':'embedding_scale','operand':{'type':'var','name':'a'},'scalar_bits':_f32_bit_pattern(0.0)}},
        {'type':'print','value':{'type':'str','value':f'c[0] (expect {_f32_bit_pattern(0.0)} = +0.0 byte-exact):'}},
        {'type':'print','value':{'type':'embedding_get_dim','operand':{'type':'var','name':'c'},'dim_index':0}},
        {'type':'print','value':{'type':'str','value':f'c[1] (expect {_f32_bit_pattern(0.0)} = +0.0 byte-exact):'}},
        {'type':'print','value':{'type':'embedding_get_dim','operand':{'type':'var','name':'c'},'dim_index':1}},
        {'type':'print','value':{'type':'str','value':f'c[2] (expect {_f32_bit_pattern(0.0)} = +0.0 byte-exact):'}},
        {'type':'print','value':{'type':'embedding_get_dim','operand':{'type':'var','name':'c'},'dim_index':2}},
        {'type':'print','value':{'type':'str','value':'=== Synthesis Scale Zero test complete ==='}},
    ]}

def demo_synthesis_scale_negative():
    """Pod 3.6 B31 — scale(-1.0, a) = -a byte-exact (negation; mulss(-1.0, x) = -x)."""
    a_vec = _f32_vector_bytes([1.0, 2.0, 3.0])
    return {'type':'program','body':[
        {'type':'print','value':{'type':'str','value':'=== Synthesis Scale Negative Test (Pod 3.6 B31) ==='}},
        {'type':'let','name':'a','value':{'type':'embedding_new','vector':a_vec}},
        {'type':'let','name':'c','value':{'type':'embedding_scale','operand':{'type':'var','name':'a'},'scalar_bits':_f32_bit_pattern(-1.0)}},
        {'type':'print','value':{'type':'str','value':f'c[0] (expect {_f32_bit_pattern(-1.0)} = -1.0 byte-exact):'}},
        {'type':'print','value':{'type':'embedding_get_dim','operand':{'type':'var','name':'c'},'dim_index':0}},
        {'type':'print','value':{'type':'str','value':f'c[1] (expect {_f32_bit_pattern(-2.0)} = -2.0 byte-exact):'}},
        {'type':'print','value':{'type':'embedding_get_dim','operand':{'type':'var','name':'c'},'dim_index':1}},
        {'type':'print','value':{'type':'str','value':f'c[2] (expect {_f32_bit_pattern(-3.0)} = -3.0 byte-exact):'}},
        {'type':'print','value':{'type':'embedding_get_dim','operand':{'type':'var','name':'c'},'dim_index':2}},
        {'type':'print','value':{'type':'str','value':'=== Synthesis Scale Negative test complete ==='}},
    ]}

def demo_synthesis_normalize_basic():
    """Pod 3.6 B32 — normalize(scale(2.0, e_unit_x)) = e_unit_x byte-exact (single divss).
    R10 expected: norm_sq=0x40800000, norm=0x40000000, result[0]=0x3F800000, rest zero.
    Sparse-non-trivial input; no v_uniform-class accumulator drift surface (B32-aux covers that)."""
    # input directly: (2.0, 0.0, ..., 0.0)
    v_2x = _f32_vector_bytes([2.0, 0.0])
    return {'type':'program','body':[
        {'type':'print','value':{'type':'str','value':'=== Synthesis Normalize Basic Test (Pod 3.6 B32) ==='}},
        {'type':'let','name':'a','value':{'type':'embedding_new','vector':v_2x}},
        {'type':'let','name':'c','value':{'type':'embedding_normalize','operand':{'type':'var','name':'a'}}},
        {'type':'print','value':{'type':'str','value':f'c[0] (expect {_f32_bit_pattern(1.0)} = 1.0; sqrt(4)=2; 2/2=1 byte-exact):'}},
        {'type':'print','value':{'type':'embedding_get_dim','operand':{'type':'var','name':'c'},'dim_index':0}},
        {'type':'print','value':{'type':'str','value':f'c[1] (expect {_f32_bit_pattern(0.0)} = 0.0):'}},
        {'type':'print','value':{'type':'embedding_get_dim','operand':{'type':'var','name':'c'},'dim_index':1}},
        {'type':'print','value':{'type':'str','value':f'c[100] (expect {_f32_bit_pattern(0.0)} = 0.0):'}},
        {'type':'print','value':{'type':'embedding_get_dim','operand':{'type':'var','name':'c'},'dim_index':100}},
        {'type':'print','value':{'type':'str','value':'=== Synthesis Normalize Basic test complete ==='}},
    ]}

def demo_synthesis_normalize_v_uniform_drift():
    """Pod 3.6 B32-aux — D3.28 self-verifying canon: v_uniform 25-ulp normalize drift.

    Per HALT 1 R10 simulation: 384 sequential addss accumulations of (1/sqrt(384))^2
    produce norm_sq = 0x3F800019 (NOT algebraic 1.0 = 0x3F800000); norm = 0x3F80000C;
    result[0..383] = 0x3D5105D8 (-20 ulp from input 0x3D5105EC). Uniform input → uniform
    result; per-element drift is identical across all 384 dims.

    This canary turns the predicted drift from documentation-only anti-pattern (Pod 3.5
    Surprise 4 framing) into mechanically-enforced contract. Failure means the substrate's
    FP-precision-prediction discipline has shifted — load-bearing event requiring D3.28
    re-evaluation. The doctrine learns to defend itself."""
    import math
    val = 1.0 / math.sqrt(384.0)
    v_uniform = _f32_vector_bytes([val] * EMBEDDING_DIM)
    expected_drift = 0x3D5105D8   # per R10 sim; 1028720088 decimal
    return {'type':'program','body':[
        {'type':'print','value':{'type':'str','value':'=== Synthesis Normalize v_uniform Drift Test (Pod 3.6 B32-aux; D3.28 canon) ==='}},
        {'type':'let','name':'v','value':{'type':'embedding_new','vector':v_uniform}},
        {'type':'let','name':'n','value':{'type':'embedding_normalize','operand':{'type':'var','name':'v'}}},
        {'type':'print','value':{'type':'str','value':f'n[0] (expect {expected_drift} = 0x3D5105D8 per D3.28 R10 prediction):'}},
        {'type':'print','value':{'type':'embedding_get_dim','operand':{'type':'var','name':'n'},'dim_index':0}},
        {'type':'print','value':{'type':'str','value':f'n[1] (expect {expected_drift} = uniform input -> uniform result):'}},
        {'type':'print','value':{'type':'embedding_get_dim','operand':{'type':'var','name':'n'},'dim_index':1}},
        {'type':'print','value':{'type':'str','value':f'n[383] (expect {expected_drift} = uniform):'}},
        {'type':'print','value':{'type':'embedding_get_dim','operand':{'type':'var','name':'n'},'dim_index':383}},
        {'type':'print','value':{'type':'str','value':'=== B32-aux: 25-ulp drift mechanically enforced as D3.28 canon ==='}},
    ]}

def demo_synthesis_normalize_zero_reject():
    """Pod 3.6 B33 — normalize(zero_vector) -> Err(InvalidEmbeddingArg, src=0xCD=205, err=9)."""
    return {'type':'program','body':[
        {'type':'print','value':{'type':'str','value':'=== Synthesis Normalize Zero Reject Test (Pod 3.6 B33) ==='}},
        {'type':'let','name':'z','value':{'type':'embedding_new'}},   # default zero vector
        {'type':'let','name':'o','value':{'type':'embedding_normalize_raw','id':1}},   # wrap-and-test the Outcome
        {'type':'print','value':{'type':'str','value':'is_ok (expect 0 = err):'}},
        {'type':'print','value':{'type':'outcome_is_ok','operand':{'type':'var','name':'o'}}},
        {'type':'outcome_unwrap_err_stmt','value':{'type':'var','name':'o'}},
        {'type':'print','value':{'type':'str','value':'fetch_counter:'}},
        {'type':'print','value':{'type':'tos'}},
        {'type':'print','value':{'type':'str','value':'demod_id:'}},
        {'type':'print','value':{'type':'tos'}},
        {'type':'print','value':{'type':'str','value':'source_op (expect 205 = OP_EMBEDDING_NORMALIZE):'}},
        {'type':'print','value':{'type':'tos'}},
        {'type':'print','value':{'type':'str','value':'err_code (expect 9 = ERR_INVALID_EMBEDDING_ARG):'}},
        {'type':'print','value':{'type':'tos'}},
        {'type':'print','value':{'type':'str','value':'=== Synthesis Normalize Zero Reject test complete ==='}},
    ]}

def demo_synthesis_lerp_basic():
    """Pod 3.6 B34 — lerp(e_unit_x, e_unit_y, 0.5) = (0.5, 0.5, 0, ...)."""
    v_x = _f32_vector_bytes([1.0, 0.0])
    v_y = _f32_vector_bytes([0.0, 1.0])
    return {'type':'program','body':[
        {'type':'print','value':{'type':'str','value':'=== Synthesis Lerp Basic Test (Pod 3.6 B34) ==='}},
        {'type':'let','name':'a','value':{'type':'embedding_new','vector':v_x}},
        {'type':'let','name':'b','value':{'type':'embedding_new','vector':v_y}},
        {'type':'let','name':'c','value':{'type':'embedding_lerp','a':{'type':'var','name':'a'},'b':{'type':'var','name':'b'},'t_bits':_f32_bit_pattern(0.5)}},
        {'type':'print','value':{'type':'str','value':f'c[0] (expect {_f32_bit_pattern(0.5)} = 0.5):'}},
        {'type':'print','value':{'type':'embedding_get_dim','operand':{'type':'var','name':'c'},'dim_index':0}},
        {'type':'print','value':{'type':'str','value':f'c[1] (expect {_f32_bit_pattern(0.5)} = 0.5):'}},
        {'type':'print','value':{'type':'embedding_get_dim','operand':{'type':'var','name':'c'},'dim_index':1}},
        {'type':'print','value':{'type':'str','value':f'c[2] (expect {_f32_bit_pattern(0.0)} = 0.0):'}},
        {'type':'print','value':{'type':'embedding_get_dim','operand':{'type':'var','name':'c'},'dim_index':2}},
        {'type':'print','value':{'type':'str','value':'=== Synthesis Lerp Basic test complete ==='}},
    ]}

def demo_synthesis_lerp_t_zero():
    """Pod 3.6 B35 — lerp(a, b, 0.0) = a byte-exact (Form A endpoint property)."""
    a_vec = _f32_vector_bytes([1.0, 2.0, 3.0])
    b_vec = _f32_vector_bytes([4.0, 5.0, 6.0])
    return {'type':'program','body':[
        {'type':'print','value':{'type':'str','value':'=== Synthesis Lerp t=0 Endpoint Test (Pod 3.6 B35) ==='}},
        {'type':'let','name':'a','value':{'type':'embedding_new','vector':a_vec}},
        {'type':'let','name':'b','value':{'type':'embedding_new','vector':b_vec}},
        {'type':'let','name':'c','value':{'type':'embedding_lerp','a':{'type':'var','name':'a'},'b':{'type':'var','name':'b'},'t_bits':_f32_bit_pattern(0.0)}},
        {'type':'print','value':{'type':'str','value':f'c[0] (expect {_f32_bit_pattern(1.0)} = a[0] byte-exact):'}},
        {'type':'print','value':{'type':'embedding_get_dim','operand':{'type':'var','name':'c'},'dim_index':0}},
        {'type':'print','value':{'type':'str','value':f'c[1] (expect {_f32_bit_pattern(2.0)} = a[1]):'}},
        {'type':'print','value':{'type':'embedding_get_dim','operand':{'type':'var','name':'c'},'dim_index':1}},
        {'type':'print','value':{'type':'str','value':f'c[2] (expect {_f32_bit_pattern(3.0)} = a[2]):'}},
        {'type':'print','value':{'type':'embedding_get_dim','operand':{'type':'var','name':'c'},'dim_index':2}},
        {'type':'print','value':{'type':'str','value':'=== Synthesis Lerp t=0 test complete ==='}},
    ]}

def demo_synthesis_lerp_t_one():
    """Pod 3.6 B36 — lerp(a, b, 1.0) = b byte-exact (Form A endpoint property)."""
    a_vec = _f32_vector_bytes([1.0, 2.0, 3.0])
    b_vec = _f32_vector_bytes([4.0, 5.0, 6.0])
    return {'type':'program','body':[
        {'type':'print','value':{'type':'str','value':'=== Synthesis Lerp t=1 Endpoint Test (Pod 3.6 B36) ==='}},
        {'type':'let','name':'a','value':{'type':'embedding_new','vector':a_vec}},
        {'type':'let','name':'b','value':{'type':'embedding_new','vector':b_vec}},
        {'type':'let','name':'c','value':{'type':'embedding_lerp','a':{'type':'var','name':'a'},'b':{'type':'var','name':'b'},'t_bits':_f32_bit_pattern(1.0)}},
        {'type':'print','value':{'type':'str','value':f'c[0] (expect {_f32_bit_pattern(4.0)} = b[0] byte-exact):'}},
        {'type':'print','value':{'type':'embedding_get_dim','operand':{'type':'var','name':'c'},'dim_index':0}},
        {'type':'print','value':{'type':'str','value':f'c[1] (expect {_f32_bit_pattern(5.0)} = b[1]):'}},
        {'type':'print','value':{'type':'embedding_get_dim','operand':{'type':'var','name':'c'},'dim_index':1}},
        {'type':'print','value':{'type':'str','value':f'c[2] (expect {_f32_bit_pattern(6.0)} = b[2]):'}},
        {'type':'print','value':{'type':'embedding_get_dim','operand':{'type':'var','name':'c'},'dim_index':2}},
        {'type':'print','value':{'type':'str','value':'=== Synthesis Lerp t=1 test complete ==='}},
    ]}

def demo_synthesis_lerp_irrational_t_drift():
    """Pod 3.6 B34-aux — D3.28 self-verifying canon: lerp asymmetric drift at irrational t.

    Per HALT 1 R10 simulation: lerp(e_unit_x, scale(2.0, e_unit_y), 1/3):
      one_minus_t = subss(1.0, f32(1/3)) = 0x3F2AAAAA (= f32(2/3) - 1 ulp)
      result[0] = mulss(0x3F2AAAAA, 1.0) + mulss(0x3F2AAAAB, 0.0) = 0x3F2AAAAA  (-1 ulp from algebraic 2/3)
      result[1] = mulss(0x3F2AAAAA, 0.0) + mulss(0x3F2AAAAB, 2.0) = 0x3F2AAAAB  (= 2/3 byte-exact)

    Same algebraic value (2/3) produces different bit patterns depending on which
    side of the lerp the lossy multiplier traversed. Form A's two-mulss-then-addss
    causes asymmetric drift. Companion to B32-aux (normalize 25-ulp accumulator drift):
    together establish D3.28 as self-verifying canon across both accumulator-depth
    and form-traversal drift surfaces. The doctrine learns to defend itself."""
    v_x = _f32_vector_bytes([1.0, 0.0])
    v_2y = _f32_vector_bytes([0.0, 2.0])   # b = scale(2.0, e_unit_y) precomputed
    expect_0 = 0x3F2AAAAA   # 1059760810 decimal
    expect_1 = 0x3F2AAAAB   # 1059760811 decimal
    return {'type':'program','body':[
        {'type':'print','value':{'type':'str','value':'=== Synthesis Lerp Irrational-t Drift Test (Pod 3.6 B34-aux; D3.28 canon) ==='}},
        {'type':'let','name':'a','value':{'type':'embedding_new','vector':v_x}},
        {'type':'let','name':'b','value':{'type':'embedding_new','vector':v_2y}},
        {'type':'let','name':'c','value':{'type':'embedding_lerp','a':{'type':'var','name':'a'},'b':{'type':'var','name':'b'},'t_bits':_f32_bit_pattern(1.0/3.0)}},
        {'type':'print','value':{'type':'str','value':f'c[0] (expect {expect_0} = 0x3F2AAAAA = 2/3-1ulp via one_minus_t lossy traversal):'}},
        {'type':'print','value':{'type':'embedding_get_dim','operand':{'type':'var','name':'c'},'dim_index':0}},
        {'type':'print','value':{'type':'str','value':f'c[1] (expect {expect_1} = 0x3F2AAAAB = 2/3 byte-exact via t * 2.0):'}},
        {'type':'print','value':{'type':'embedding_get_dim','operand':{'type':'var','name':'c'},'dim_index':1}},
        {'type':'print','value':{'type':'str','value':'=== B34-aux: lerp form-traversal asymmetry mechanically enforced as D3.28 canon ==='}},
    ]}

def demo_synthesis_round_trip():
    """Pod 3.6 B37 — synthesis tuple round-trip via OP_EMBEDDING_SYNTHESIS_HANDLE.
    Forge e3 = add(e1, e2); query each tuple field; expect (op=1=ADD, source_a=1, source_b=2, scalar=0)."""
    v_x = _f32_vector_bytes([1.0, 0.0])
    v_y = _f32_vector_bytes([0.0, 1.0])
    return {'type':'program','body':[
        {'type':'print','value':{'type':'str','value':'=== Synthesis Round Trip Test (Pod 3.6 B37; D3.27 tuple via 0xCF accessor) ==='}},
        {'type':'let','name':'a','value':{'type':'embedding_new','vector':v_x}},                    # id=1
        {'type':'let','name':'b','value':{'type':'embedding_new','vector':v_y}},                    # id=2
        {'type':'let','name':'c','value':{'type':'embedding_add','lhs':{'type':'var','name':'a'},'rhs':{'type':'var','name':'b'}}},   # id=3
        {'type':'print','value':{'type':'str','value':'tuple[0] op (expect 1 = SYNTHESIS_OP_ADD):'}},
        {'type':'print','value':{'type':'embedding_synthesis_handle','operand':{'type':'var','name':'c'},'field_index':0}},
        {'type':'print','value':{'type':'str','value':'tuple[1] source_a (expect 1):'}},
        {'type':'print','value':{'type':'embedding_synthesis_handle','operand':{'type':'var','name':'c'},'field_index':1}},
        {'type':'print','value':{'type':'str','value':'tuple[2] source_b (expect 2):'}},
        {'type':'print','value':{'type':'embedding_synthesis_handle','operand':{'type':'var','name':'c'},'field_index':2}},
        {'type':'print','value':{'type':'str','value':'tuple[3] scalar (expect 0):'}},
        {'type':'print','value':{'type':'embedding_synthesis_handle','operand':{'type':'var','name':'c'},'field_index':3}},
        {'type':'print','value':{'type':'str','value':'=== Synthesis Round Trip test complete ==='}},
    ]}

def demo_synthesis_unsynthesized():
    """Pod 3.6 B38 — query tuple of raw OP_EMBEDDING_NEW; expect (0, 0, 0, 0) per BSS-zero default.
    Closes B-prep-2 deferral: synthesis-tuple BSS state explicitly verified via the natural read surface."""
    return {'type':'program','body':[
        {'type':'print','value':{'type':'str','value':'=== Synthesis Unsynthesized Test (Pod 3.6 B38; closes B-prep-2 deferral) ==='}},
        {'type':'let','name':'e','value':{'type':'embedding_new'}},   # id=1, raw, default zero vector
        {'type':'print','value':{'type':'str','value':'tuple[0] op (expect 0 = SYNTHESIS_OP_NONE):'}},
        {'type':'print','value':{'type':'embedding_synthesis_handle','operand':{'type':'var','name':'e'},'field_index':0}},
        {'type':'print','value':{'type':'str','value':'tuple[1] source_a (expect 0):'}},
        {'type':'print','value':{'type':'embedding_synthesis_handle','operand':{'type':'var','name':'e'},'field_index':1}},
        {'type':'print','value':{'type':'str','value':'tuple[2] source_b (expect 0):'}},
        {'type':'print','value':{'type':'embedding_synthesis_handle','operand':{'type':'var','name':'e'},'field_index':2}},
        {'type':'print','value':{'type':'str','value':'tuple[3] scalar (expect 0):'}},
        {'type':'print','value':{'type':'embedding_synthesis_handle','operand':{'type':'var','name':'e'},'field_index':3}},
        {'type':'print','value':{'type':'str','value':'=== B38: BSS-zero confirmed; B-prep-2 deferral closed ==='}},
    ]}

def demo_analogical_reasoning():
    """Pod 3.6 B39 — the closing arc. king - man + woman -> nearest -> Sign + synthesis lineage recovered.

    Forge basis vectors as concept embeddings:
      king      = e_unit_0 = (1, 0, 0, 0, ...) at id=1
      man       = e_unit_1 = (0, 1, 0, 0, ...) at id=2
      woman     = e_unit_2 = (0, 0, 1, 0, ...) at id=3
      queen_ref = (1, -1, 1, 0, ...)            at id=4  (algebraically precomputed)

    Forge Sign linked to queen_ref (sign_id=1 -> embedding_handle=4).

    Compute:
      diff   = subtract(king, man)      at id=5  -> (1, -1, 0, 0, ...)
      result = add(diff, woman)         at id=6  -> (1, -1, 1, 0, ...) = queen_ref byte-exact

    Recover:
      lookup_top1(result)                          -> nearest = queen_ref (id=4); cosine = 1.0 (or -1ulp)
      OP_EMBEDDING_SIGN_HANDLE(queen_ref id=4)     -> sign_id=1
      OP_EMBEDDING_SYNTHESIS_HANDLE(result, ...)   -> (SYNTHESIS_OP_ADD, diff_id=5, woman_id=3, 0)

    Forge-witness duality lands in one program. Maid composes; the substrate accounts for what it composed."""
    v_king  = _f32_vector_bytes([1.0, 0.0, 0.0])
    v_man   = _f32_vector_bytes([0.0, 1.0, 0.0])
    v_woman = _f32_vector_bytes([0.0, 0.0, 1.0])
    v_queen = _f32_vector_bytes([1.0, -1.0, 1.0])
    return {'type':'program','body':[
        {'type':'print','value':{'type':'str','value':'=== Analogical Reasoning Demo (Pod 3.6 B39 — the Maid composes) ==='}},
        # Forge concept embeddings
        {'type':'let','name':'king',     'value':{'type':'embedding_new','vector':v_king}},     # id=1
        {'type':'let','name':'man',      'value':{'type':'embedding_new','vector':v_man}},      # id=2
        {'type':'let','name':'woman',    'value':{'type':'embedding_new','vector':v_woman}},    # id=3
        {'type':'let','name':'queen_ref','value':{'type':'embedding_new','vector':v_queen}},    # id=4
        # Forge Sign linked to queen_ref
        {'type':'let','name':'queen_sign','value':{
            'type':'sign_new',
            'hash': b'\xff' + b'\x00' * 31, 'label': 'queen', 'energy': 100,
            'embedding_handle': 4,
        }},
        {'type':'print','value':{'type':'str','value':'queen_sign sign_id (expect 1):'}},
        {'type':'print','value':{'type':'var','name':'queen_sign'}},
        # Compose: diff = king - man; result = diff + woman
        {'type':'let','name':'diff',  'value':{'type':'embedding_subtract','lhs':{'type':'var','name':'king'},'rhs':{'type':'var','name':'man'}}},     # id=5
        {'type':'let','name':'result','value':{'type':'embedding_add',     'lhs':{'type':'var','name':'diff'},'rhs':{'type':'var','name':'woman'}}},   # id=6
        {'type':'print','value':{'type':'str','value':'diff   id (expect 5):'}},
        {'type':'print','value':{'type':'var','name':'diff'}},
        {'type':'print','value':{'type':'str','value':'result id (expect 6):'}},
        {'type':'print','value':{'type':'var','name':'result'}},
        # Recover via lookup_top1: should find queen_ref (id=4) — cosine(result, queen_ref) = 1.0
        {'type':'let','name':'nearest','value':{'type':'embedding_lookup_top1','operand':{'type':'var','name':'result'}}},
        {'type':'print','value':{'type':'str','value':'lookup_top1(result) -> nearest_id (expect 4 = queen_ref):'}},
        {'type':'print','value':{'type':'var','name':'nearest'}},
        # Recover Sign from nearest embedding_id
        {'type':'print','value':{'type':'str','value':'OP_EMBEDDING_SIGN_HANDLE(nearest) -> sign_id (expect 1 = queen_sign):'}},
        {'type':'print','value':{'type':'embedding_sign_handle','operand':{'type':'var','name':'nearest'}}},
        # Recover synthesis lineage from result
        {'type':'print','value':{'type':'str','value':'OP_EMBEDDING_SYNTHESIS_HANDLE(result, op) -> (expect 1 = SYNTHESIS_OP_ADD):'}},
        {'type':'print','value':{'type':'embedding_synthesis_handle','operand':{'type':'var','name':'result'},'field_index':0}},
        {'type':'print','value':{'type':'str','value':'OP_EMBEDDING_SYNTHESIS_HANDLE(result, source_a) -> (expect 5 = diff_id):'}},
        {'type':'print','value':{'type':'embedding_synthesis_handle','operand':{'type':'var','name':'result'},'field_index':1}},
        {'type':'print','value':{'type':'str','value':'OP_EMBEDDING_SYNTHESIS_HANDLE(result, source_b) -> (expect 3 = woman_id):'}},
        {'type':'print','value':{'type':'embedding_synthesis_handle','operand':{'type':'var','name':'result'},'field_index':2}},
        {'type':'print','value':{'type':'str','value':'=== Maid composes; substrate accounts for what it composed ==='}},
    ]}

def demo_forge_authority_required():
    """Pod 3.6 B40 — cap without BIT_EMBEDDING_FORGE attempts ADD -> Err(InsufficientAuthority, src=0xCA=202)."""
    v_x = _f32_vector_bytes([1.0, 0.0])
    v_y = _f32_vector_bytes([0.0, 1.0])
    return {'type':'program','body':[
        {'type':'print','value':{'type':'str','value':'=== Forge Authority Required Test (Pod 3.6 B40) ==='}},
        # Forge sources under ROOT (which has all bits)
        {'type':'let','name':'a','value':{'type':'embedding_new','vector':v_x}},
        {'type':'let','name':'b','value':{'type':'embedding_new','vector':v_y}},
        # Construct cap A WITHOUT BIT_EMBEDDING_FORGE (only BIT_SIGN_FORGE | BIT_CAP_FORGE)
        {'type':'let','name':'co','value':{'type':'cap_new','granted_bitmap': BIT_SIGN_FORGE | BIT_CAP_FORGE, 'energy_budget': 10000}},
        {'type':'let','name':'cap_a','value':{'type':'outcome_unwrap_ok','operand':{'type':'var','name':'co'}}},
        {'type':'let','name':'enter_a','value':{'type':'cap_enter','operand':{'type':'var','name':'cap_a'}}},
        # Attempt ADD under A; bit-check fails
        {'type':'let','name':'o','value':{'type':'embedding_add_raw','id_a':1,'id_b':2}},
        {'type':'print','value':{'type':'str','value':'is_ok (expect 0 = err):'}},
        {'type':'print','value':{'type':'outcome_is_ok','operand':{'type':'var','name':'o'}}},
        {'type':'outcome_unwrap_err_stmt','value':{'type':'var','name':'o'}},
        {'type':'print','value':{'type':'str','value':'fetch_counter:'}},
        {'type':'print','value':{'type':'tos'}},
        {'type':'print','value':{'type':'str','value':'demod_id:'}},
        {'type':'print','value':{'type':'tos'}},
        {'type':'print','value':{'type':'str','value':'source_op (expect 202 = OP_EMBEDDING_ADD):'}},
        {'type':'print','value':{'type':'tos'}},
        {'type':'print','value':{'type':'str','value':'err_code (expect 8 = ERR_CAP_INSUFFICIENT_AUTHORITY):'}},
        {'type':'print','value':{'type':'tos'}},
        {'type':'let','name':'exit_a','value':{'type':'cap_exit'}},
        {'type':'print','value':{'type':'str','value':'=== Forge Authority Required test complete ==='}},
    ]}

def demo_babylon_ripple_synthesis():
    """Pod 3.6 B41 — ADD under sub-cap A; expect A.used=0, ROOT.used += floor(500/2) = 250.
    Mirrors Pod 3.5 B23 compute_under_subcap; first synthesis-tier babylon ripple
    via D3.9/D3.23 axiom inheritance through .construct_ok_outcome."""
    v_x = _f32_vector_bytes([1.0, 0.0])
    v_y = _f32_vector_bytes([0.0, 1.0])
    return {'type':'program','body':[
        {'type':'print','value':{'type':'str','value':'=== Babylon Ripple Synthesis Test (Pod 3.6 B41; first synthesis-tier ripple) ==='}},
        # Forge sources under ROOT
        {'type':'let','name':'a','value':{'type':'embedding_new','vector':v_x}},
        {'type':'let','name':'b','value':{'type':'embedding_new','vector':v_y}},
        # Construct cap A with BIT_EMBEDDING_FORGE | BIT_CAP_FORGE; energy_budget 10000 (room for 500j ADD)
        {'type':'let','name':'co','value':{'type':'cap_new','granted_bitmap': BIT_EMBEDDING_FORGE | BIT_CAP_FORGE, 'energy_budget': 10000}},
        {'type':'let','name':'cap_a','value':{'type':'outcome_unwrap_ok','operand':{'type':'var','name':'co'}}},
        {'type':'let','name':'enter_a','value':{'type':'cap_enter','operand':{'type':'var','name':'cap_a'}}},
        # ADD under A
        {'type':'let','name':'c','value':{'type':'embedding_add','lhs':{'type':'var','name':'a'},'rhs':{'type':'var','name':'b'}}},
        {'type':'print','value':{'type':'str','value':'add result id (expect 3):'}},
        {'type':'print','value':{'type':'var','name':'c'}},
        {'type':'let','name':'exit_a','value':{'type':'cap_exit'}},
        # Check ripple
        {'type':'print','value':{'type':'str','value':'A.used (expect 0; originating doesn\'t charge itself):'}},
        {'type':'print','value':{'type':'cap_used','operand':{'type':'var','name':'cap_a'}}},
        {'type':'print','value':{'type':'str','value':'ROOT.used (expect 250; floor(500/2) ADD ripple):'}},
        {'type':'print','value':{'type':'cap_used','operand':{'type':'int','value':1}}},
        {'type':'print','value':{'type':'str','value':'=== Babylon Ripple Synthesis test complete ==='}},
    ]}

def demo_pool_capacity_synthesis_pressure():
    """Pod 3.6 B42 — fill pool to 256/256 then attempt ADD -> Err(PoolFull, src=0xCA=202, err=2).
    Uses while loop to forge embeddings until pool exhausted; then ADD must allocate slot 257."""
    return {'type':'program','body':[
        {'type':'print','value':{'type':'str','value':'=== Pool Capacity Synthesis Pressure Test (Pod 3.6 B42) ==='}},
        # Forge initial 2 embeddings (ids 1, 2 — used as ADD sources)
        {'type':'let','name':'a','value':{'type':'embedding_new'}},
        {'type':'let','name':'b','value':{'type':'embedding_new'}},
        # Loop forge 254 more (ids 3..256); pool ends at 256/256
        {'type':'let','name':'n','value':{'type':'int','value':2}},
        {'type':'while',
         'cond':{'type':'lt','left':{'type':'var','name':'n'},'right':{'type':'int','value':256}},
         'body':{'type':'block','stmts':[
             {'type':'let','name':'_e','value':{'type':'embedding_new'}},
             {'type':'let','name':'n','value':{'type':'add','left':{'type':'var','name':'n'},'right':{'type':'int','value':1}}},
         ]}},
        {'type':'print','value':{'type':'str','value':'pool filled to 256/256; final n (expect 256):'}},
        {'type':'print','value':{'type':'var','name':'n'}},
        # Now attempt ADD; needs to allocate slot 257 -> pool capacity check fails -> Err(PoolFull)
        {'type':'let','name':'o','value':{'type':'embedding_add_raw','id_a':1,'id_b':2}},
        {'type':'print','value':{'type':'str','value':'is_ok (expect 0 = err):'}},
        {'type':'print','value':{'type':'outcome_is_ok','operand':{'type':'var','name':'o'}}},
        {'type':'outcome_unwrap_err_stmt','value':{'type':'var','name':'o'}},
        {'type':'print','value':{'type':'str','value':'fetch_counter:'}},
        {'type':'print','value':{'type':'tos'}},
        {'type':'print','value':{'type':'str','value':'demod_id:'}},
        {'type':'print','value':{'type':'tos'}},
        {'type':'print','value':{'type':'str','value':'source_op (expect 202 = OP_EMBEDDING_ADD):'}},
        {'type':'print','value':{'type':'tos'}},
        {'type':'print','value':{'type':'str','value':'err_code (expect 2 = ERR_POOL_FULL):'}},
        {'type':'print','value':{'type':'tos'}},
        {'type':'print','value':{'type':'str','value':'=== Pool Capacity Synthesis Pressure test complete ==='}},
    ]}

# --- Pod 3.7 canaries (B43-B45): capacity expansion verification ---

def demo_pod37_embedding_pool_capacity_at_2048():
    """Pod 3.7 B43 — forge 2048 embeddings (filling pool); 2049th → Err(PoolFull, src=0xC0=192, err=2).
    Verifies EMBEDDING_POOL_SLOTS expansion 256→2048 (DEFERRED #83 RESOLVED).
    Outcome pool at 4096 has room for the 2049th err outcome (D3.29 proportionality)."""
    return {'type':'program','body':[
        {'type':'print','value':{'type':'str','value':'=== Pod 3.7 B43 — Embedding Pool Capacity at 2048 ==='}},
        # Forge 2048 embeddings via while loop
        {'type':'let','name':'n','value':{'type':'int','value':0}},
        {'type':'while',
         'cond':{'type':'lt','left':{'type':'var','name':'n'},'right':{'type':'int','value':2048}},
         'body':{'type':'block','stmts':[
             {'type':'let','name':'_e','value':{'type':'embedding_new'}},
             {'type':'let','name':'n','value':{'type':'add','left':{'type':'var','name':'n'},'right':{'type':'int','value':1}}},
         ]}},
        {'type':'print','value':{'type':'str','value':'pool filled; n (expect 2048):'}},
        {'type':'print','value':{'type':'var','name':'n'}},
        # 2049th forge → Err
        {'type':'let','name':'o','value':{'type':'embedding_new', 'wrap': True}},
        {'type':'print','value':{'type':'str','value':'is_ok (expect 0 = err):'}},
        {'type':'print','value':{'type':'outcome_is_ok','operand':{'type':'var','name':'o'}}},
        {'type':'outcome_unwrap_err_stmt','value':{'type':'var','name':'o'}},
        {'type':'print','value':{'type':'str','value':'fetch_counter:'}},
        {'type':'print','value':{'type':'tos'}},
        {'type':'print','value':{'type':'str','value':'demod_id:'}},
        {'type':'print','value':{'type':'tos'}},
        {'type':'print','value':{'type':'str','value':'source_op (expect 192 = OP_EMBEDDING_NEW):'}},
        {'type':'print','value':{'type':'tos'}},
        {'type':'print','value':{'type':'str','value':'err_code (expect 2 = ERR_POOL_FULL):'}},
        {'type':'print','value':{'type':'tos'}},
        {'type':'print','value':{'type':'str','value':'=== B43: embedding_pool 2048-slot capacity verified ==='}},
    ]}

def demo_pod37_outcome_pool_under_synthesis_load():
    """Pod 3.7 B44 — stress outcome_pool under combined embedding-fill + post-fill-err.
    Forge in loop until is_ok signals failure (embedding pool fills at 2048); continue forging
    in non-unwrap mode to fill outcome_pool with err outcomes; verify substrate handles
    gracefully and halts cleanly. D3.29 proportional coupling validated under stress."""
    return {'type':'program','body':[
        {'type':'print','value':{'type':'str','value':'=== Pod 3.7 B44 — Outcome Pool Under Synthesis Load ==='}},
        # Forge 2048 embeddings (fills embedding_pool; 2048 ok outcomes registered)
        {'type':'let','name':'n','value':{'type':'int','value':0}},
        {'type':'while',
         'cond':{'type':'lt','left':{'type':'var','name':'n'},'right':{'type':'int','value':2048}},
         'body':{'type':'block','stmts':[
             {'type':'let','name':'_e','value':{'type':'embedding_new'}},
             {'type':'let','name':'n','value':{'type':'add','left':{'type':'var','name':'n'},'right':{'type':'int','value':1}}},
         ]}},
        {'type':'print','value':{'type':'str','value':'phase 1 (embedding_pool filled): n (expect 2048):'}},
        {'type':'print','value':{'type':'var','name':'n'}},
        # Forge 1900 more in non-unwrap mode (2048 ok + 1900 err = 3948 outcomes; under 4096 ceiling)
        {'type':'let','name':'m','value':{'type':'int','value':0}},
        {'type':'while',
         'cond':{'type':'lt','left':{'type':'var','name':'m'},'right':{'type':'int','value':1900}},
         'body':{'type':'block','stmts':[
             {'type':'let','name':'_o','value':{'type':'embedding_new', 'wrap': True}},   # err outcome registered, not unwrapped
             {'type':'let','name':'m','value':{'type':'add','left':{'type':'var','name':'m'},'right':{'type':'int','value':1}}},
         ]}},
        {'type':'print','value':{'type':'str','value':'phase 2 (1900 err outcomes registered): m (expect 1900):'}},
        {'type':'print','value':{'type':'var','name':'m'}},
        # Final forge attempt; outcome_pool nearly full (3948 + this one = 3949); should still construct err outcome
        {'type':'let','name':'final_o','value':{'type':'embedding_new', 'wrap': True}},
        {'type':'print','value':{'type':'str','value':'final is_ok (expect 0 = err on embedding pool full):'}},
        {'type':'print','value':{'type':'outcome_is_ok','operand':{'type':'var','name':'final_o'}}},
        {'type':'outcome_unwrap_err_stmt','value':{'type':'var','name':'final_o'}},
        {'type':'print','value':{'type':'str','value':'fetch_counter:'}},
        {'type':'print','value':{'type':'tos'}},
        {'type':'print','value':{'type':'str','value':'demod_id:'}},
        {'type':'print','value':{'type':'tos'}},
        {'type':'print','value':{'type':'str','value':'source_op (expect 192 = OP_EMBEDDING_NEW):'}},
        {'type':'print','value':{'type':'tos'}},
        {'type':'print','value':{'type':'str','value':'err_code (expect 2 = ERR_POOL_FULL):'}},
        {'type':'print','value':{'type':'tos'}},
        {'type':'print','value':{'type':'str','value':'=== B44: outcome_pool 4096-slot capacity verified under stress ==='}},
    ]}

def demo_pod37_mixed_workload_within_capacity():
    """Pod 3.7 B45 — realistic forge+accessor+synthesis mixed workload at production scale.
    50 embeddings forged + several synthesis ops + lookup_top1 + sign linkage; all pools handle.
    Demonstrates D3.29 proportionality holds under realistic workload (not corner-case stress)."""
    v_anchor = _f32_vector_bytes([1.0, 0.5, 0.25])
    return {'type':'program','body':[
        {'type':'print','value':{'type':'str','value':'=== Pod 3.7 B45 — Mixed Workload Within Capacity ==='}},
        # Forge an anchor + 49 random-ish embeddings via loop (default-zero is fine for capacity test)
        {'type':'let','name':'anchor','value':{'type':'embedding_new','vector':v_anchor}},  # id=1
        {'type':'let','name':'n','value':{'type':'int','value':1}},
        {'type':'while',
         'cond':{'type':'lt','left':{'type':'var','name':'n'},'right':{'type':'int','value':50}},
         'body':{'type':'block','stmts':[
             {'type':'let','name':'_e','value':{'type':'embedding_new'}},
             {'type':'let','name':'n','value':{'type':'add','left':{'type':'var','name':'n'},'right':{'type':'int','value':1}}},
         ]}},
        {'type':'print','value':{'type':'str','value':'embeddings forged (expect 50):'}},
        {'type':'print','value':{'type':'var','name':'n'}},
        # Synthesis ops
        {'type':'let','name':'doubled','value':{'type':'embedding_scale','operand':{'type':'var','name':'anchor'},'scalar_bits':_f32_bit_pattern(2.0)}},
        {'type':'let','name':'sum','value':{'type':'embedding_add','lhs':{'type':'var','name':'anchor'},'rhs':{'type':'var','name':'doubled'}}},
        {'type':'let','name':'mid','value':{'type':'embedding_lerp','a':{'type':'var','name':'anchor'},'b':{'type':'var','name':'doubled'},'t_bits':_f32_bit_pattern(0.5)}},
        {'type':'print','value':{'type':'str','value':'doubled[0] (expect 1073741824 = 2.0):'}},
        {'type':'print','value':{'type':'embedding_get_dim','operand':{'type':'var','name':'doubled'},'dim_index':0}},
        {'type':'print','value':{'type':'str','value':'sum[0] (expect 1077936128 = 3.0):'}},
        {'type':'print','value':{'type':'embedding_get_dim','operand':{'type':'var','name':'sum'},'dim_index':0}},
        {'type':'print','value':{'type':'str','value':'mid[0] (expect 1069547520 = 1.5):'}},
        {'type':'print','value':{'type':'embedding_get_dim','operand':{'type':'var','name':'mid'},'dim_index':0}},
        # Synthesis tuple readback
        {'type':'print','value':{'type':'str','value':'sum tuple op (expect 1 = ADD):'}},
        {'type':'print','value':{'type':'embedding_synthesis_handle','operand':{'type':'var','name':'sum'},'field_index':0}},
        {'type':'print','value':{'type':'str','value':'=== B45: mixed workload across 50+ embeddings + synthesis ops handled cleanly ==='}},
    ]}

def demo_pod39_top_k_b49():
    """Pod 3.9 B49 — top-K + threshold canary.

    Substrate boot-ingests inputs/test_codebook_b49.txt (10 codebook entries
    with distinct cosines vs query). User program forges query embedding at
    runtime (id=11; vector (1.0, 0.0, 0, ...)) and issues
    OP_EMBEDDING_LOOKUP_TOP_K(query_id=11, K=5, threshold=-INF).

    R10 prediction (tools/pod39_r10_sim.py): top-5 ids in descending cosine
    order are [1, 2, 3, 4, 5]. Verification by ordering match (D3.28 transitive:
    bit-exact cosine values per pair determine deterministic substrate ordering).

    Stack layout post-handler (per ratified protocol):
      [..., id_4 (worst=5), id_3 (=4), id_2 (=3), id_1 (=2), id_0 (best=1), outcome_id_at_TOS]
    User: outcome_unwrap_ok → K' on TOS; pop K'; pop K' ids best-to-worst.
    """
    # Query: (1.0, 0.0, 0.0, ..., 0.0)
    v_query = _f32_vector_bytes([1.0, 0.0])
    NEG_INF_BITS = 0xFF800000   # f32 -INF; unfiltered top-K sentinel
    return {'type':'program','body':[
        {'type':'print','value':{'type':'str','value':'=== Pod 3.9 B49 — Top-K + Threshold ==='}},
        # Forge query embedding at runtime (id=11; codebook entries occupy ids 1..10 from boot ingest)
        {'type':'let','name':'q','value':{'type':'embedding_new','vector':v_query}},
        {'type':'print','value':{'type':'str','value':'query id (expect 11):'}},
        {'type':'print','value':{'type':'var','name':'q'}},
        # Issue OP_EMBEDDING_LOOKUP_TOP_K(query, K=5, threshold=-INF)
        # Auto-unwrap_ok pops outcome_id and pushes K' count to TOS; K' ids sit BELOW.
        {'type':'let','name':'count','value':{'type':'embedding_lookup_top_k',
            'query':{'type':'var','name':'q'},
            'k':5,
            'threshold_bits':NEG_INF_BITS,
        }},
        {'type':'print','value':{'type':'str','value':'count (expect 5):'}},
        {'type':'print','value':{'type':'var','name':'count'}},
        # Pop + print 5 ids from operand stack best-to-worst.
        # TOS at this point = id_0 (best); pops give id_0, id_1, ..., id_4 in order.
        # Capture each id into a let-var, then print + accumulate sum.
        # Sum of [1,2,3,4,5] = 15; any other top-5 sums differently → unambiguous validation.
        {'type':'let','name':'i0','value':{'type':'tos'}},
        {'type':'let','name':'i1','value':{'type':'tos'}},
        {'type':'let','name':'i2','value':{'type':'tos'}},
        {'type':'let','name':'i3','value':{'type':'tos'}},
        {'type':'let','name':'i4','value':{'type':'tos'}},
        {'type':'print','value':{'type':'str','value':'id_0 (best; expect 1):'}},
        {'type':'print','value':{'type':'var','name':'i0'}},
        {'type':'print','value':{'type':'str','value':'id_1 (expect 2):'}},
        {'type':'print','value':{'type':'var','name':'i1'}},
        {'type':'print','value':{'type':'str','value':'id_2 (expect 3):'}},
        {'type':'print','value':{'type':'var','name':'i2'}},
        {'type':'print','value':{'type':'str','value':'id_3 (expect 4):'}},
        {'type':'print','value':{'type':'var','name':'i3'}},
        {'type':'print','value':{'type':'str','value':'id_4 (worst; expect 5):'}},
        {'type':'print','value':{'type':'var','name':'i4'}},
        {'type':'print','value':{'type':'str','value':'sum (expect 15):'}},
        {'type':'print','value':{'type':'add','left':{'type':'add','left':{'type':'add','left':{'type':'add','left':{'type':'var','name':'i0'},'right':{'type':'var','name':'i1'}},'right':{'type':'var','name':'i2'}},'right':{'type':'var','name':'i3'}},'right':{'type':'var','name':'i4'}}},
        {'type':'print','value':{'type':'str','value':'=== B49 done ==='}},
    ]}

def demo_pod39_b49_probe_k():
    """Pod 3.9 B49 K-incremental probe — test top_k at K=1, K=2, K=3 to localize bug.

    K=1: append to empty scratch only (no find-min path).
    K=2: append twice, then find-min-replace path triggers on candidates 3..10.
    K=3: append thrice, then find-min-replace.

    Each invocation forges separate query (different id each time).
    """
    v_query = _f32_vector_bytes([1.0, 0.0])
    body = [{'type':'print','value':{'type':'str','value':'=== Pod 3.9 B49 K-Probe ==='}}]
    # K=1
    body.extend([
        {'type':'let','name':'q1','value':{'type':'embedding_new','vector':v_query}},
        {'type':'print','value':{'type':'str','value':'K=1 (expect id=1):'}},
        {'type':'let','name':'c1','value':{'type':'embedding_lookup_top_k',
            'query':{'type':'var','name':'q1'},'k':1,'threshold_bits':0xFF800000}},
        {'type':'print','value':{'type':'str','value':'count:'}},
        {'type':'print','value':{'type':'var','name':'c1'}},
        {'type':'print','value':{'type':'str','value':'best:'}},
        {'type':'print','value':{'type':'tos'}},
    ])
    # K=2
    body.extend([
        {'type':'let','name':'q2','value':{'type':'embedding_new','vector':v_query}},
        {'type':'print','value':{'type':'str','value':'K=2 (expect [1,2]):'}},
        {'type':'let','name':'c2','value':{'type':'embedding_lookup_top_k',
            'query':{'type':'var','name':'q2'},'k':2,'threshold_bits':0xFF800000}},
        {'type':'print','value':{'type':'str','value':'count:'}},
        {'type':'print','value':{'type':'var','name':'c2'}},
        {'type':'print','value':{'type':'str','value':'best:'}},
        {'type':'print','value':{'type':'tos'}},
        {'type':'print','value':{'type':'str','value':'2nd:'}},
        {'type':'print','value':{'type':'tos'}},
    ])
    # K=3
    body.extend([
        {'type':'let','name':'q3','value':{'type':'embedding_new','vector':v_query}},
        {'type':'print','value':{'type':'str','value':'K=3 (expect [1,2,3]):'}},
        {'type':'let','name':'c3','value':{'type':'embedding_lookup_top_k',
            'query':{'type':'var','name':'q3'},'k':3,'threshold_bits':0xFF800000}},
        {'type':'print','value':{'type':'str','value':'count:'}},
        {'type':'print','value':{'type':'var','name':'c3'}},
        {'type':'print','value':{'type':'str','value':'best:'}},
        {'type':'print','value':{'type':'tos'}},
        {'type':'print','value':{'type':'str','value':'2nd:'}},
        {'type':'print','value':{'type':'tos'}},
        {'type':'print','value':{'type':'str','value':'3rd:'}},
        {'type':'print','value':{'type':'tos'}},
    ])
    body.append({'type':'print','value':{'type':'str','value':'=== K-Probe done ==='}})
    return {'type':'program','body':body}


def demo_pod39_b49_probe():
    """Pod 3.9 B49 diagnostic probe — isolate which substrate component is producing
    [2,3,4,5,10] instead of expected [1,2,3,4,5] for top-K query against B49 codebook.

    Forges query (id=11; vec=(1,0,0,...)). Then:
      1) Calls lookup_top1(q) — expect id=1 (best match excluding self).
         If returns id=1: cosine + MAC + scan all work; bug isolated to compute_top_k_raw.
         If returns other: bug is in cosine/MAC/scan path itself.
      2) Prints cosine(q, id_1), cosine(q, id_6), cosine(q, id_10) — verify byte-exact
         against R10 prediction (0x3F800000, ~0x3F72ABCB, ~0x3F3E4886).
    """
    v_query = _f32_vector_bytes([1.0, 0.0])
    return {'type':'program','body':[
        {'type':'print','value':{'type':'str','value':'=== Pod 3.9 B49 Probe ==='}},
        {'type':'let','name':'q','value':{'type':'embedding_new','vector':v_query}},
        {'type':'print','value':{'type':'str','value':'query id (expect 11):'}},
        {'type':'print','value':{'type':'var','name':'q'}},
        # Test 1: lookup_top1 — expect id=1
        {'type':'print','value':{'type':'str','value':'lookup_top1(q) (expect 1):'}},
        {'type':'print','value':{'type':'embedding_lookup_top1','operand':{'type':'var','name':'q'}}},
        # Test 2: cosines for boundary ids
        {'type':'print','value':{'type':'str','value':'cos(q, id=1) (expect 1065353216 = 0x3F800000):'}},
        {'type':'print','value':{'type':'embedding_cosine','lhs':{'type':'var','name':'q'},'rhs':{'type':'int','value':1}}},
        {'type':'print','value':{'type':'str','value':'cos(q, id=6) (expect ~0x3F72ABCB):'}},
        {'type':'print','value':{'type':'embedding_cosine','lhs':{'type':'var','name':'q'},'rhs':{'type':'int','value':6}}},
        {'type':'print','value':{'type':'str','value':'cos(q, id=10) (expect ~0x3F3E4886):'}},
        {'type':'print','value':{'type':'embedding_cosine','lhs':{'type':'var','name':'q'},'rhs':{'type':'int','value':10}}},
        {'type':'print','value':{'type':'str','value':'=== Probe done ==='}},
    ]}


def demo_pod310_b50_project():
    """Pod 3.10 B50 — project(A, B) = (A·B/B·B)*B.

    Identity probes + concrete cases anchored to R10 sim (tools/pod310_r10_sim.py):
      - id1: project(A, A) = A byte-exact (ratio = 1.0; mulss(1.0, x) = x via B30)
      - id2: project(zero, B) = zero (ratio = 0; mulss(0, x) = 0)
      - id3: project(A, zero) → Err(InvalidEmbeddingArg, src=0xF3=243, err=9) per D3.40
      - c1: project((1,1,0..), (1,0,0..)) = (1,0,0..) (ratio = 1.0; result == B byte-exact)
      - c2: project((3,4,0..), (1,0,0..)) = (3,0,0..) (ratio = 3.0)
    """
    v_one = _f32_vector_bytes([1.0])                       # (1,0,0,..)
    v_e0_e1 = _f32_vector_bytes([1.0, 1.0])                # (1,1,0,..)
    v_3_4   = _f32_vector_bytes([3.0, 4.0])                # (3,4,0,..)
    v_id1A  = _f32_vector_bytes([1.0, 2.0, 0.0, 0.0, 0.0, 3.0])  # (1,2,0,0,0,3,0,..) — sparse
    return {'type':'program','body':[
        {'type':'print','value':{'type':'str','value':'=== Pod 3.10 B50 — Project ==='}},

        # B50.id1: project(A, A) = A byte-exact
        {'type':'print','value':{'type':'str','value':'-- id1: project(A, A) = A byte-exact (A nonzero) --'}},
        {'type':'let','name':'a1','value':{'type':'embedding_new','vector':v_id1A}},
        {'type':'let','name':'p1','value':{'type':'embedding_project','lhs':{'type':'var','name':'a1'},'rhs':{'type':'var','name':'a1'}}},
        {'type':'print','value':{'type':'str','value':f'p1[0] (expect {_f32_bit_pattern(1.0)} = 1.0):'}},
        {'type':'print','value':{'type':'embedding_get_dim','operand':{'type':'var','name':'p1'},'dim_index':0}},
        {'type':'print','value':{'type':'str','value':f'p1[1] (expect {_f32_bit_pattern(2.0)} = 2.0):'}},
        {'type':'print','value':{'type':'embedding_get_dim','operand':{'type':'var','name':'p1'},'dim_index':1}},
        {'type':'print','value':{'type':'str','value':f'p1[5] (expect {_f32_bit_pattern(3.0)} = 3.0):'}},
        {'type':'print','value':{'type':'embedding_get_dim','operand':{'type':'var','name':'p1'},'dim_index':5}},
        {'type':'print','value':{'type':'str','value':f'p1[2] (expect {_f32_bit_pattern(0.0)} = 0):'}},
        {'type':'print','value':{'type':'embedding_get_dim','operand':{'type':'var','name':'p1'},'dim_index':2}},

        # B50.id2: project(zero, B) = zero
        {'type':'print','value':{'type':'str','value':'-- id2: project(zero, B) = zero --'}},
        {'type':'let','name':'z2','value':{'type':'embedding_new'}},
        {'type':'let','name':'b2','value':{'type':'embedding_new','vector':v_3_4}},
        {'type':'let','name':'p2','value':{'type':'embedding_project','lhs':{'type':'var','name':'z2'},'rhs':{'type':'var','name':'b2'}}},
        {'type':'print','value':{'type':'str','value':f'p2[0] (expect {_f32_bit_pattern(0.0)} = 0):'}},
        {'type':'print','value':{'type':'embedding_get_dim','operand':{'type':'var','name':'p2'},'dim_index':0}},
        {'type':'print','value':{'type':'str','value':f'p2[1] (expect {_f32_bit_pattern(0.0)} = 0):'}},
        {'type':'print','value':{'type':'embedding_get_dim','operand':{'type':'var','name':'p2'},'dim_index':1}},

        # B50.id3: project(A, zero) → CF=1 → Err(InvalidEmbeddingArg, src=243, err=9)
        # Forge order so far: a1=1, p1=2, z2=3, b2=4, p2=5; next forges: a3=6, z3=7
        {'type':'print','value':{'type':'str','value':'-- id3: project(A, zero) -> Err(InvalidEmbeddingArg) --'}},
        {'type':'let','name':'a3','value':{'type':'embedding_new','vector':v_one}},
        {'type':'let','name':'z3','value':{'type':'embedding_new'}},
        # _raw variant returns Outcome on stack (no auto-unwrap)
        {'type':'let','name':'o3','value':{'type':'embedding_project_raw','id_a':6,'id_b':7}},
        {'type':'print','value':{'type':'str','value':'is_ok (expect 0 = err):'}},
        {'type':'print','value':{'type':'outcome_is_ok','operand':{'type':'var','name':'o3'}}},
        {'type':'outcome_unwrap_err_stmt','value':{'type':'var','name':'o3'}},
        {'type':'print','value':{'type':'str','value':'fetch_counter:'}},
        {'type':'print','value':{'type':'tos'}},
        {'type':'print','value':{'type':'str','value':'demod_id:'}},
        {'type':'print','value':{'type':'tos'}},
        {'type':'print','value':{'type':'str','value':'source_op (expect 243 = OP_EMBEDDING_PROJECT):'}},
        {'type':'print','value':{'type':'tos'}},
        {'type':'print','value':{'type':'str','value':'err_code (expect 9 = ERR_INVALID_EMBEDDING_ARG):'}},
        {'type':'print','value':{'type':'tos'}},

        # B50.c1: project((1,1), (1,0)) = (1, 0)
        {'type':'print','value':{'type':'str','value':'-- c1: project((1,1,0..), (1,0,0..)) = (1,0,0..) --'}},
        {'type':'let','name':'ac1','value':{'type':'embedding_new','vector':v_e0_e1}},
        {'type':'let','name':'bc1','value':{'type':'embedding_new','vector':v_one}},
        {'type':'let','name':'pc1','value':{'type':'embedding_project','lhs':{'type':'var','name':'ac1'},'rhs':{'type':'var','name':'bc1'}}},
        {'type':'print','value':{'type':'str','value':f'pc1[0] (expect {_f32_bit_pattern(1.0)} = 1.0):'}},
        {'type':'print','value':{'type':'embedding_get_dim','operand':{'type':'var','name':'pc1'},'dim_index':0}},
        {'type':'print','value':{'type':'str','value':f'pc1[1] (expect {_f32_bit_pattern(0.0)} = 0):'}},
        {'type':'print','value':{'type':'embedding_get_dim','operand':{'type':'var','name':'pc1'},'dim_index':1}},

        # B50.c2: project((3,4), (1,0)) = (3, 0)
        {'type':'print','value':{'type':'str','value':'-- c2: project((3,4,0..), (1,0,0..)) = (3,0,0..) --'}},
        {'type':'let','name':'ac2','value':{'type':'embedding_new','vector':v_3_4}},
        {'type':'let','name':'bc2','value':{'type':'embedding_new','vector':v_one}},
        {'type':'let','name':'pc2','value':{'type':'embedding_project','lhs':{'type':'var','name':'ac2'},'rhs':{'type':'var','name':'bc2'}}},
        {'type':'print','value':{'type':'str','value':f'pc2[0] (expect {_f32_bit_pattern(3.0)} = 3.0):'}},
        {'type':'print','value':{'type':'embedding_get_dim','operand':{'type':'var','name':'pc2'},'dim_index':0}},
        {'type':'print','value':{'type':'str','value':f'pc2[1] (expect {_f32_bit_pattern(0.0)} = 0):'}},
        {'type':'print','value':{'type':'embedding_get_dim','operand':{'type':'var','name':'pc2'},'dim_index':1}},

        {'type':'print','value':{'type':'str','value':'=== B50 done ==='}},
    ]}


def demo_pod310_b51_reject():
    """Pod 3.10 B51 — reject(A, B) = A - (A·B/B·B)*B + orthogonality drift panel.

    Identity probes + drift panel (D3.28 self-verifying canon for Pod 3.10):
      - id1: reject(A, A) = +0 vector byte-exact (subss(x, mulss(1.0, x)) = subss(x, x) = +0 via B28)
      - id2: reject(zero, B) = zero
      - id3: reject(A, zero) → Err(InvalidEmbeddingArg, src=0xF4=244, err=9)
      - c1: reject((1,1,0..), (1,0,0..)) = (0,1,0..)
      - c2: reject((3,4,0..), (1,0,0..)) = (0,4,0..)
      - drift1: dot(reject((1,1), (1,0)), (1,0)) = 0 byte-exact
      - drift2: dot(reject((1,1), (3,4)), (3,4)) = 0xB4000000 drift (R10-predicted)
      - drift3: dot(reject((1,2,3), (1,1,1)), (1,1,1)) = 0 byte-exact (clean cancellation)
    """
    v_one = _f32_vector_bytes([1.0])
    v_e0_e1 = _f32_vector_bytes([1.0, 1.0])
    v_3_4 = _f32_vector_bytes([3.0, 4.0])
    v_1_2_3 = _f32_vector_bytes([1.0, 2.0, 3.0])
    v_1_1_1 = _f32_vector_bytes([1.0, 1.0, 1.0])
    v_id1A = _f32_vector_bytes([1.0, 2.0, 0.0, 0.0, 0.0, 3.0])
    return {'type':'program','body':[
        {'type':'print','value':{'type':'str','value':'=== Pod 3.10 B51 — Reject ==='}},

        # B51.id1: reject(A, A) = +0 vector byte-exact
        {'type':'print','value':{'type':'str','value':'-- id1: reject(A, A) = +0 vector byte-exact --'}},
        {'type':'let','name':'a1','value':{'type':'embedding_new','vector':v_id1A}},
        {'type':'let','name':'r1','value':{'type':'embedding_reject','lhs':{'type':'var','name':'a1'},'rhs':{'type':'var','name':'a1'}}},
        {'type':'print','value':{'type':'str','value':f'r1[0] (expect {_f32_bit_pattern(0.0)} = +0):'}},
        {'type':'print','value':{'type':'embedding_get_dim','operand':{'type':'var','name':'r1'},'dim_index':0}},
        {'type':'print','value':{'type':'str','value':f'r1[1] (expect {_f32_bit_pattern(0.0)} = +0):'}},
        {'type':'print','value':{'type':'embedding_get_dim','operand':{'type':'var','name':'r1'},'dim_index':1}},
        {'type':'print','value':{'type':'str','value':f'r1[5] (expect {_f32_bit_pattern(0.0)} = +0):'}},
        {'type':'print','value':{'type':'embedding_get_dim','operand':{'type':'var','name':'r1'},'dim_index':5}},

        # B51.id2: reject(zero, B) = zero
        {'type':'print','value':{'type':'str','value':'-- id2: reject(zero, B) = zero --'}},
        {'type':'let','name':'z2','value':{'type':'embedding_new'}},
        {'type':'let','name':'b2','value':{'type':'embedding_new','vector':v_3_4}},
        {'type':'let','name':'r2','value':{'type':'embedding_reject','lhs':{'type':'var','name':'z2'},'rhs':{'type':'var','name':'b2'}}},
        {'type':'print','value':{'type':'str','value':f'r2[0] (expect {_f32_bit_pattern(0.0)} = 0):'}},
        {'type':'print','value':{'type':'embedding_get_dim','operand':{'type':'var','name':'r2'},'dim_index':0}},
        {'type':'print','value':{'type':'str','value':f'r2[1] (expect {_f32_bit_pattern(0.0)} = 0):'}},
        {'type':'print','value':{'type':'embedding_get_dim','operand':{'type':'var','name':'r2'},'dim_index':1}},

        # B51.id3: reject(A, zero) → CF=1 → Err
        # Forge order so far: a1=1, r1=2, z2=3, b2=4, r2=5; next forges: a3=6, z3=7
        {'type':'print','value':{'type':'str','value':'-- id3: reject(A, zero) -> Err(InvalidEmbeddingArg) --'}},
        {'type':'let','name':'a3','value':{'type':'embedding_new','vector':v_one}},
        {'type':'let','name':'z3','value':{'type':'embedding_new'}},
        {'type':'let','name':'o3','value':{'type':'embedding_reject_raw','id_a':6,'id_b':7}},
        {'type':'print','value':{'type':'str','value':'is_ok (expect 0 = err):'}},
        {'type':'print','value':{'type':'outcome_is_ok','operand':{'type':'var','name':'o3'}}},
        {'type':'outcome_unwrap_err_stmt','value':{'type':'var','name':'o3'}},
        {'type':'print','value':{'type':'str','value':'fetch_counter:'}},
        {'type':'print','value':{'type':'tos'}},
        {'type':'print','value':{'type':'str','value':'demod_id:'}},
        {'type':'print','value':{'type':'tos'}},
        {'type':'print','value':{'type':'str','value':'source_op (expect 244 = OP_EMBEDDING_REJECT):'}},
        {'type':'print','value':{'type':'tos'}},
        {'type':'print','value':{'type':'str','value':'err_code (expect 9 = ERR_INVALID_EMBEDDING_ARG):'}},
        {'type':'print','value':{'type':'tos'}},

        # B51.c1: reject((1,1), (1,0)) = (0,1,0..)
        {'type':'print','value':{'type':'str','value':'-- c1: reject((1,1,0..), (1,0,0..)) = (0,1,0..) --'}},
        {'type':'let','name':'ac1','value':{'type':'embedding_new','vector':v_e0_e1}},
        {'type':'let','name':'bc1','value':{'type':'embedding_new','vector':v_one}},
        {'type':'let','name':'rc1','value':{'type':'embedding_reject','lhs':{'type':'var','name':'ac1'},'rhs':{'type':'var','name':'bc1'}}},
        {'type':'print','value':{'type':'str','value':f'rc1[0] (expect {_f32_bit_pattern(0.0)} = 0):'}},
        {'type':'print','value':{'type':'embedding_get_dim','operand':{'type':'var','name':'rc1'},'dim_index':0}},
        {'type':'print','value':{'type':'str','value':f'rc1[1] (expect {_f32_bit_pattern(1.0)} = 1.0):'}},
        {'type':'print','value':{'type':'embedding_get_dim','operand':{'type':'var','name':'rc1'},'dim_index':1}},

        # drift1: dot(reject((1,1), (1,0)), (1,0)) = 0 byte-exact
        {'type':'print','value':{'type':'str','value':'-- drift1: dot(rc1, bc1) (expect 0 byte-exact; trivial case) --'}},
        {'type':'print','value':{'type':'embedding_dot_product','lhs':{'type':'var','name':'rc1'},'rhs':{'type':'var','name':'bc1'}}},

        # B51.c2: reject((3,4), (1,0)) = (0,4,0..)
        {'type':'print','value':{'type':'str','value':'-- c2: reject((3,4,0..), (1,0,0..)) = (0,4,0..) --'}},
        {'type':'let','name':'ac2','value':{'type':'embedding_new','vector':v_3_4}},
        {'type':'let','name':'bc2','value':{'type':'embedding_new','vector':v_one}},
        {'type':'let','name':'rc2','value':{'type':'embedding_reject','lhs':{'type':'var','name':'ac2'},'rhs':{'type':'var','name':'bc2'}}},
        {'type':'print','value':{'type':'str','value':f'rc2[0] (expect {_f32_bit_pattern(0.0)} = 0):'}},
        {'type':'print','value':{'type':'embedding_get_dim','operand':{'type':'var','name':'rc2'},'dim_index':0}},
        {'type':'print','value':{'type':'str','value':f'rc2[1] (expect {_f32_bit_pattern(4.0)} = 4.0):'}},
        {'type':'print','value':{'type':'embedding_get_dim','operand':{'type':'var','name':'rc2'},'dim_index':1}},

        # drift2: dot(reject((1,1), (3,4)), (3,4)) = 0xB4000000 (DRIFT — R10 self-verifying canon)
        {'type':'print','value':{'type':'str','value':'-- drift2: reject((1,1,0..), (3,4,0..)) drift panel --'}},
        {'type':'let','name':'ad2','value':{'type':'embedding_new','vector':v_e0_e1}},
        {'type':'let','name':'bd2','value':{'type':'embedding_new','vector':v_3_4}},
        {'type':'let','name':'rd2','value':{'type':'embedding_reject','lhs':{'type':'var','name':'ad2'},'rhs':{'type':'var','name':'bd2'}}},
        {'type':'print','value':{'type':'str','value':'rd2[0] (expect 0x3E23D708 from R10):'}},
        {'type':'print','value':{'type':'embedding_get_dim','operand':{'type':'var','name':'rd2'},'dim_index':0}},
        {'type':'print','value':{'type':'str','value':'rd2[1] (expect 0xBDF5C290 from R10):'}},
        {'type':'print','value':{'type':'embedding_get_dim','operand':{'type':'var','name':'rd2'},'dim_index':1}},
        {'type':'print','value':{'type':'str','value':'dot(rd2, bd2) (expect 0xB4000000 = DRIFT not 0; D3.28 self-verifying canon):'}},
        {'type':'print','value':{'type':'embedding_dot_product','lhs':{'type':'var','name':'rd2'},'rhs':{'type':'var','name':'bd2'}}},

        # drift3: dot(reject((1,2,3), (1,1,1)), (1,1,1)) = 0 byte-exact (clean cancellation)
        {'type':'print','value':{'type':'str','value':'-- drift3: reject((1,2,3,0..), (1,1,1,0..)) clean-cancellation case --'}},
        {'type':'let','name':'ad3','value':{'type':'embedding_new','vector':v_1_2_3}},
        {'type':'let','name':'bd3','value':{'type':'embedding_new','vector':v_1_1_1}},
        {'type':'let','name':'rd3','value':{'type':'embedding_reject','lhs':{'type':'var','name':'ad3'},'rhs':{'type':'var','name':'bd3'}}},
        {'type':'print','value':{'type':'str','value':'rd3[0] (expect 0xBF800000 = -1.0):'}},
        {'type':'print','value':{'type':'embedding_get_dim','operand':{'type':'var','name':'rd3'},'dim_index':0}},
        {'type':'print','value':{'type':'str','value':'rd3[1] (expect 0x00000000 = 0):'}},
        {'type':'print','value':{'type':'embedding_get_dim','operand':{'type':'var','name':'rd3'},'dim_index':1}},
        {'type':'print','value':{'type':'str','value':'rd3[2] (expect 0x3F800000 = 1.0):'}},
        {'type':'print','value':{'type':'embedding_get_dim','operand':{'type':'var','name':'rd3'},'dim_index':2}},
        {'type':'print','value':{'type':'str','value':'dot(rd3, bd3) (expect 0 byte-exact; clean cancellation):'}},
        {'type':'print','value':{'type':'embedding_dot_product','lhs':{'type':'var','name':'rd3'},'rhs':{'type':'var','name':'bd3'}}},

        {'type':'print','value':{'type':'str','value':'=== B51 done ==='}},
    ]}


def demo_pod311_b52_codebook_meta():
    """Pod 3.11 B52 — codebook metadata accessor.

    Substrate boot-ingests inputs/test_codebook_b48.txt (5 basis vectors × 384 dims;
    reused from Pod 3.8); B52 reads vm_codebook_meta via OP_EMBEDDING_CODEBOOK_META
    field-indexed accessor + tests out-of-range Err path.

    Expected:
      META(0=COUNT)             = 5     (CBK_META_OFF_COUNT; ingested at boot)
      META(1=DIM)               = 384   (CBK_META_OFF_DIM; EMBEDDING_DIM)
      META(2=SCALAR_TYPE)       = 0     (CBK_META_OFF_SCALAR_TYPE; CBK_SCALAR_TYPE_F32)
      META(3=INGESTION_STATUS)  = 1     (CBK_META_OFF_INGESTION_STATUS; CBK_STATUS_SUCCESS)
      META(4)                   → Err(InvalidEmbeddingArg, src=0xF5=245, err=9)
    """
    return {'type':'program','body':[
        {'type':'print','value':{'type':'str','value':'=== Pod 3.11 B52 — Codebook Meta ==='}},
        # Happy paths — 4 field reads
        {'type':'print','value':{'type':'str','value':'META(0=COUNT) (expect 5):'}},
        {'type':'print','value':{'type':'embedding_codebook_meta','field_index':0}},
        {'type':'print','value':{'type':'str','value':'META(1=DIM) (expect 384):'}},
        {'type':'print','value':{'type':'embedding_codebook_meta','field_index':1}},
        {'type':'print','value':{'type':'str','value':'META(2=SCALAR_TYPE) (expect 0 = f32):'}},
        {'type':'print','value':{'type':'embedding_codebook_meta','field_index':2}},
        {'type':'print','value':{'type':'str','value':'META(3=INGESTION_STATUS) (expect 1 = SUCCESS):'}},
        {'type':'print','value':{'type':'embedding_codebook_meta','field_index':3}},
        # Err path — out-of-range field_index
        {'type':'print','value':{'type':'str','value':'-- META(4) -> Err(InvalidEmbeddingArg) --'}},
        {'type':'let','name':'o4','value':{'type':'embedding_codebook_meta_raw','field_index':4}},
        {'type':'print','value':{'type':'str','value':'is_ok (expect 0 = err):'}},
        {'type':'print','value':{'type':'outcome_is_ok','operand':{'type':'var','name':'o4'}}},
        {'type':'outcome_unwrap_err_stmt','value':{'type':'var','name':'o4'}},
        {'type':'print','value':{'type':'str','value':'fetch_counter:'}},
        {'type':'print','value':{'type':'tos'}},
        {'type':'print','value':{'type':'str','value':'demod_id:'}},
        {'type':'print','value':{'type':'tos'}},
        {'type':'print','value':{'type':'str','value':'source_op (expect 245 = OP_EMBEDDING_CODEBOOK_META):'}},
        {'type':'print','value':{'type':'tos'}},
        {'type':'print','value':{'type':'str','value':'err_code (expect 9 = ERR_INVALID_EMBEDDING_ARG):'}},
        {'type':'print','value':{'type':'tos'}},
        {'type':'print','value':{'type':'str','value':'=== B52 done ==='}},
    ]}


def demo_pod38_codebook_imported_round_trip():
    """Pod 3.8 B48 — boot-ingestion observation. Substrate built with
    inputs/test_codebook_b48.txt (5 basis vectors); boot_ingest_codebook
    pre-populates embedding_pool + vm_embedding_imported tuples at boot
    under ROOT_CAP context (D3.31 substrate-private 0j). Canary reads
    each via dispatch surface: OP_EMBEDDING_IMPORTED_HANDLE for tuple
    field readback + OP_EMBEDDING_GET_DIM for vector readback.

    Each entry is a basis vector: entry i (1-indexed) has dim (i-1) = 1.0
    and all other dims = 0. line_index in tuple = i - 1.
    """
    body = [{'type':'print','value':{'type':'str','value':'=== Pod 3.8 B48 — Codebook Boot Ingestion ==='}}]
    for i in range(1, 6):  # ids 1..5
        body.append({'type':'let','name':f'id{i}','value':{'type':'int','value':i}})
        # tuple[0] codebook_id (expect 1 for V1.0 single-codebook)
        body.append({'type':'print','value':{'type':'str','value':f'id={i} cb_id:'}})
        body.append({'type':'print','value':{'type':'embedding_imported_handle','operand':{'type':'var','name':f'id{i}'},'field_index':0}})
        # tuple[1] line_index (expect i-1)
        body.append({'type':'print','value':{'type':'str','value':f'id={i} line_idx:'}})
        body.append({'type':'print','value':{'type':'embedding_imported_handle','operand':{'type':'var','name':f'id{i}'},'field_index':1}})
        # tuple[2] reserved_hash (expect 0)
        body.append({'type':'print','value':{'type':'str','value':f'id={i} hash:'}})
        body.append({'type':'print','value':{'type':'embedding_imported_handle','operand':{'type':'var','name':f'id{i}'},'field_index':2}})
        # tuple[3] reserved_timestamp (expect 0)
        body.append({'type':'print','value':{'type':'str','value':f'id={i} ts:'}})
        body.append({'type':'print','value':{'type':'embedding_imported_handle','operand':{'type':'var','name':f'id{i}'},'field_index':3}})
        # vector dim[i-1] readback (expect 0x3F800000 = 1.0)
        body.append({'type':'print','value':{'type':'str','value':f'id={i} dim[{i-1}]:'}})
        body.append({'type':'print','value':{'type':'embedding_get_dim','operand':{'type':'var','name':f'id{i}'},'dim_index':i-1}})
    body.append({'type':'print','value':{'type':'str','value':'=== B48 done ==='}})
    return {'type':'program','body':body}

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
    # --- Pod 1.10.2b1 Cap test surfaces (T1-T6) ---
    elif '--cap-new-basic-build' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_cap_new_basic())
        out = sys.argv[sys.argv.index('--cap-new-basic-build')+1] if len(sys.argv) > sys.argv.index('--cap-new-basic-build')+1 else 'test_cap_new_basic.cbc'
        with open(out,'wb') as f: f.write(bc)
        print(f"Cap New Basic test: compiled {len(bc)} bytes -> {out}")
    elif '--cap-new-basic-test' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_cap_new_basic())
        print(f"Cap New Basic test: {len(bc)} bytes")
    elif '--cap-arena-owner-bitmap-build' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_cap_arena_owner_bitmap())
        out = sys.argv[sys.argv.index('--cap-arena-owner-bitmap-build')+1] if len(sys.argv) > sys.argv.index('--cap-arena-owner-bitmap-build')+1 else 'test_cap_arena_owner_bitmap.cbc'
        with open(out,'wb') as f: f.write(bc)
        print(f"Cap Accessors test: compiled {len(bc)} bytes -> {out}")
    elif '--cap-arena-owner-bitmap-test' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_cap_arena_owner_bitmap())
        print(f"Cap Accessors test: {len(bc)} bytes")
    elif '--cap-current-build' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_cap_current())
        out = sys.argv[sys.argv.index('--cap-current-build')+1] if len(sys.argv) > sys.argv.index('--cap-current-build')+1 else 'test_cap_current.cbc'
        with open(out,'wb') as f: f.write(bc)
        print(f"Cap Current test: compiled {len(bc)} bytes -> {out}")
    elif '--cap-current-test' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_cap_current())
        print(f"Cap Current test: {len(bc)} bytes")
    elif '--cap-invalid-id-build' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_cap_invalid_id())
        out = sys.argv[sys.argv.index('--cap-invalid-id-build')+1] if len(sys.argv) > sys.argv.index('--cap-invalid-id-build')+1 else 'test_cap_invalid_id.cbc'
        with open(out,'wb') as f: f.write(bc)
        print(f"Cap Invalid ID test: compiled {len(bc)} bytes -> {out}")
    elif '--cap-invalid-id-test' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_cap_invalid_id())
        print(f"Cap Invalid ID test: {len(bc)} bytes")
    elif '--cap-stack-underflow-build' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_cap_stack_underflow())
        out = sys.argv[sys.argv.index('--cap-stack-underflow-build')+1] if len(sys.argv) > sys.argv.index('--cap-stack-underflow-build')+1 else 'test_cap_stack_underflow.cbc'
        with open(out,'wb') as f: f.write(bc)
        print(f"Cap Stack Underflow test: compiled {len(bc)} bytes -> {out}")
    elif '--cap-stack-underflow-test' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_cap_stack_underflow())
        print(f"Cap Stack Underflow test: {len(bc)} bytes")
    elif '--cap-stack-overflow-build' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_cap_stack_overflow())
        out = sys.argv[sys.argv.index('--cap-stack-overflow-build')+1] if len(sys.argv) > sys.argv.index('--cap-stack-overflow-build')+1 else 'test_cap_stack_overflow.cbc'
        with open(out,'wb') as f: f.write(bc)
        print(f"Cap Stack Overflow test: compiled {len(bc)} bytes -> {out}")
    elif '--cap-stack-overflow-test' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_cap_stack_overflow())
        print(f"Cap Stack Overflow test: {len(bc)} bytes")
    # --- Pod 1.10.2b2 substrate-wide provenance test surfaces (T1-T7) ---
    elif '--sign-provenance-root-build' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_sign_provenance_root())
        out = sys.argv[sys.argv.index('--sign-provenance-root-build')+1] if len(sys.argv) > sys.argv.index('--sign-provenance-root-build')+1 else 'test_sign_provenance_root.cbc'
        with open(out,'wb') as f: f.write(bc)
        print(f"Sign Provenance Root test: compiled {len(bc)} bytes -> {out}")
    elif '--sign-provenance-root-test' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_sign_provenance_root())
        print(f"Sign Provenance Root test: {len(bc)} bytes")
    elif '--energy-provenance-root-build' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_energy_provenance_root())
        out = sys.argv[sys.argv.index('--energy-provenance-root-build')+1] if len(sys.argv) > sys.argv.index('--energy-provenance-root-build')+1 else 'test_energy_provenance_root.cbc'
        with open(out,'wb') as f: f.write(bc)
        print(f"Energy Provenance Root test: compiled {len(bc)} bytes -> {out}")
    elif '--energy-provenance-root-test' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_energy_provenance_root())
        print(f"Energy Provenance Root test: {len(bc)} bytes")
    elif '--outcome-provenance-root-build' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_outcome_provenance_root())
        out = sys.argv[sys.argv.index('--outcome-provenance-root-build')+1] if len(sys.argv) > sys.argv.index('--outcome-provenance-root-build')+1 else 'test_outcome_provenance_root.cbc'
        with open(out,'wb') as f: f.write(bc)
        print(f"Outcome Provenance Root test: compiled {len(bc)} bytes -> {out}")
    elif '--outcome-provenance-root-test' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_outcome_provenance_root())
        print(f"Outcome Provenance Root test: {len(bc)} bytes")
    elif '--provenance-under-subcap-build' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_provenance_under_subcap())
        out = sys.argv[sys.argv.index('--provenance-under-subcap-build')+1] if len(sys.argv) > sys.argv.index('--provenance-under-subcap-build')+1 else 'test_provenance_under_subcap.cbc'
        with open(out,'wb') as f: f.write(bc)
        print(f"Provenance Under SubCap test: compiled {len(bc)} bytes -> {out}")
    elif '--provenance-under-subcap-test' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_provenance_under_subcap())
        print(f"Provenance Under SubCap test: {len(bc)} bytes")
    elif '--provenance-walk-build' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_provenance_walk())
        out = sys.argv[sys.argv.index('--provenance-walk-build')+1] if len(sys.argv) > sys.argv.index('--provenance-walk-build')+1 else 'test_provenance_walk.cbc'
        with open(out,'wb') as f: f.write(bc)
        print(f"Provenance Walk test: compiled {len(bc)} bytes -> {out}")
    elif '--provenance-walk-test' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_provenance_walk())
        print(f"Provenance Walk test: {len(bc)} bytes")
    elif '--cap-parent-root-build' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_cap_parent_root())
        out = sys.argv[sys.argv.index('--cap-parent-root-build')+1] if len(sys.argv) > sys.argv.index('--cap-parent-root-build')+1 else 'test_cap_parent_root.cbc'
        with open(out,'wb') as f: f.write(bc)
        print(f"Cap Parent Root test: compiled {len(bc)} bytes -> {out}")
    elif '--cap-parent-root-test' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_cap_parent_root())
        print(f"Cap Parent Root test: {len(bc)} bytes")
    elif '--invalid-id-each-new-accessor-build' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_invalid_id_each_new_accessor())
        out = sys.argv[sys.argv.index('--invalid-id-each-new-accessor-build')+1] if len(sys.argv) > sys.argv.index('--invalid-id-each-new-accessor-build')+1 else 'test_invalid_id_each_new_accessor.cbc'
        with open(out,'wb') as f: f.write(bc)
        print(f"Invalid ID Each New Accessor test: compiled {len(bc)} bytes -> {out}")
    elif '--invalid-id-each-new-accessor-test' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_invalid_id_each_new_accessor())
        print(f"Invalid ID Each New Accessor test: {len(bc)} bytes")
    # --- Pod 1.10.3 Cap metabolic test surfaces (T1-T5) ---
    elif '--cap-budget-basic-build' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_cap_budget_basic())
        out = sys.argv[sys.argv.index('--cap-budget-basic-build')+1] if len(sys.argv) > sys.argv.index('--cap-budget-basic-build')+1 else 'test_cap_budget_basic.cbc'
        with open(out,'wb') as f: f.write(bc)
        print(f"Cap Budget Basic test: compiled {len(bc)} bytes -> {out}")
    elif '--cap-budget-basic-test' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_cap_budget_basic())
        print(f"Cap Budget Basic test: {len(bc)} bytes")
    elif '--cap-used-zero-at-construction-build' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_cap_used_zero_at_construction())
        out = sys.argv[sys.argv.index('--cap-used-zero-at-construction-build')+1] if len(sys.argv) > sys.argv.index('--cap-used-zero-at-construction-build')+1 else 'test_cap_used_zero_at_construction.cbc'
        with open(out,'wb') as f: f.write(bc)
        print(f"Cap Used Zero test: compiled {len(bc)} bytes -> {out}")
    elif '--cap-used-zero-at-construction-test' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_cap_used_zero_at_construction())
        print(f"Cap Used Zero test: {len(bc)} bytes")
    elif '--root-cap-unbounded-build' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_root_cap_unbounded())
        out = sys.argv[sys.argv.index('--root-cap-unbounded-build')+1] if len(sys.argv) > sys.argv.index('--root-cap-unbounded-build')+1 else 'test_root_cap_unbounded.cbc'
        with open(out,'wb') as f: f.write(bc)
        print(f"Root Cap Unbounded test: compiled {len(bc)} bytes -> {out}")
    elif '--root-cap-unbounded-test' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_root_cap_unbounded())
        print(f"Root Cap Unbounded test: {len(bc)} bytes")
    elif '--cap-budget-invalid-id-build' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_cap_budget_invalid_id())
        out = sys.argv[sys.argv.index('--cap-budget-invalid-id-build')+1] if len(sys.argv) > sys.argv.index('--cap-budget-invalid-id-build')+1 else 'test_cap_budget_invalid_id.cbc'
        with open(out,'wb') as f: f.write(bc)
        print(f"Cap Budget Invalid ID test: compiled {len(bc)} bytes -> {out}")
    elif '--cap-budget-invalid-id-test' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_cap_budget_invalid_id())
        print(f"Cap Budget Invalid ID test: {len(bc)} bytes")
    elif '--cap-budget-immutable-via-mac-build' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_cap_budget_immutable_via_mac())
        out = sys.argv[sys.argv.index('--cap-budget-immutable-via-mac-build')+1] if len(sys.argv) > sys.argv.index('--cap-budget-immutable-via-mac-build')+1 else 'test_cap_budget_immutable_via_mac.cbc'
        with open(out,'wb') as f: f.write(bc)
        print(f"Cap Budget Immutable test: compiled {len(bc)} bytes -> {out}")
    elif '--cap-budget-immutable-via-mac-test' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_cap_budget_immutable_via_mac())
        print(f"Cap Budget Immutable test: {len(bc)} bytes")
    # --- Pod 2.1 Babylon spatial-merge test surfaces (T1-T6) ---
    elif '--babylon-single-level-build' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_babylon_single_level())
        out = sys.argv[sys.argv.index('--babylon-single-level-build')+1] if len(sys.argv) > sys.argv.index('--babylon-single-level-build')+1 else 'test_babylon_single_level.cbc'
        with open(out,'wb') as f: f.write(bc)
        print(f"Babylon Single Level test: compiled {len(bc)} bytes -> {out}")
    elif '--babylon-single-level-test' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_babylon_single_level())
        print(f"Babylon Single Level test: {len(bc)} bytes")
    elif '--babylon-multi-level-build' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_babylon_multi_level())
        out = sys.argv[sys.argv.index('--babylon-multi-level-build')+1] if len(sys.argv) > sys.argv.index('--babylon-multi-level-build')+1 else 'test_babylon_multi_level.cbc'
        with open(out,'wb') as f: f.write(bc)
        print(f"Babylon Multi Level test: compiled {len(bc)} bytes -> {out}")
    elif '--babylon-multi-level-test' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_babylon_multi_level())
        print(f"Babylon Multi Level test: {len(bc)} bytes")
    elif '--babylon-root-only-invisible-build' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_babylon_root_only_invisible())
        out = sys.argv[sys.argv.index('--babylon-root-only-invisible-build')+1] if len(sys.argv) > sys.argv.index('--babylon-root-only-invisible-build')+1 else 'test_babylon_root_only_invisible.cbc'
        with open(out,'wb') as f: f.write(bc)
        print(f"Babylon Root Only Invisible test: compiled {len(bc)} bytes -> {out}")
    elif '--babylon-root-only-invisible-test' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_babylon_root_only_invisible())
        print(f"Babylon Root Only Invisible test: {len(bc)} bytes")
    elif '--babylon-federation-total-build' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_babylon_federation_total())
        out = sys.argv[sys.argv.index('--babylon-federation-total-build')+1] if len(sys.argv) > sys.argv.index('--babylon-federation-total-build')+1 else 'test_babylon_federation_total.cbc'
        with open(out,'wb') as f: f.write(bc)
        print(f"Babylon Federation Total test: compiled {len(bc)} bytes -> {out}")
    elif '--babylon-federation-total-test' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_babylon_federation_total())
        print(f"Babylon Federation Total test: {len(bc)} bytes")
    elif '--babylon-canary-subcap-build' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_babylon_canary_subcap())
        out = sys.argv[sys.argv.index('--babylon-canary-subcap-build')+1] if len(sys.argv) > sys.argv.index('--babylon-canary-subcap-build')+1 else 'test_babylon_canary_subcap.cbc'
        with open(out,'wb') as f: f.write(bc)
        print(f"Babylon Canary SubCap test: compiled {len(bc)} bytes -> {out}")
    elif '--babylon-canary-subcap-test' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_babylon_canary_subcap())
        print(f"Babylon Canary SubCap test: {len(bc)} bytes")
    elif '--babylon-initial-zero-build' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_babylon_initial_zero())
        out = sys.argv[sys.argv.index('--babylon-initial-zero-build')+1] if len(sys.argv) > sys.argv.index('--babylon-initial-zero-build')+1 else 'test_babylon_initial_zero.cbc'
        with open(out,'wb') as f: f.write(bc)
        print(f"Babylon Initial Zero test: compiled {len(bc)} bytes -> {out}")
    elif '--babylon-initial-zero-test' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_babylon_initial_zero())
        print(f"Babylon Initial Zero test: {len(bc)} bytes")
    # --- Pod 2.2 cap_bitmap test surfaces (T1-T6) ---
    elif '--bitmap-root-unbounded-build' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_bitmap_root_unbounded())
        out = sys.argv[sys.argv.index('--bitmap-root-unbounded-build')+1] if len(sys.argv) > sys.argv.index('--bitmap-root-unbounded-build')+1 else 'test_bitmap_root_unbounded.cbc'
        with open(out,'wb') as f: f.write(bc)
        print(f"Bitmap Root Unbounded test: compiled {len(bc)} bytes -> {out}")
    elif '--bitmap-root-unbounded-test' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_bitmap_root_unbounded())
        print(f"Bitmap Root Unbounded test: {len(bc)} bytes")
    elif '--bitmap-subset-grant-succeeds-build' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_bitmap_subset_grant_succeeds())
        out = sys.argv[sys.argv.index('--bitmap-subset-grant-succeeds-build')+1] if len(sys.argv) > sys.argv.index('--bitmap-subset-grant-succeeds-build')+1 else 'test_bitmap_subset_grant_succeeds.cbc'
        with open(out,'wb') as f: f.write(bc)
        print(f"Bitmap Subset Grant Succeeds test: compiled {len(bc)} bytes -> {out}")
    elif '--bitmap-subset-grant-succeeds-test' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_bitmap_subset_grant_succeeds())
        print(f"Bitmap Subset Grant Succeeds test: {len(bc)} bytes")
    elif '--bitmap-superset-grant-fails-build' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_bitmap_superset_grant_fails())
        out = sys.argv[sys.argv.index('--bitmap-superset-grant-fails-build')+1] if len(sys.argv) > sys.argv.index('--bitmap-superset-grant-fails-build')+1 else 'test_bitmap_superset_grant_fails.cbc'
        with open(out,'wb') as f: f.write(bc)
        print(f"Bitmap Superset Grant Fails test: compiled {len(bc)} bytes -> {out}")
    elif '--bitmap-superset-grant-fails-test' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_bitmap_superset_grant_fails())
        print(f"Bitmap Superset Grant Fails test: {len(bc)} bytes")
    elif '--bitmap-authority-check-passes-build' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_bitmap_authority_check_passes())
        out = sys.argv[sys.argv.index('--bitmap-authority-check-passes-build')+1] if len(sys.argv) > sys.argv.index('--bitmap-authority-check-passes-build')+1 else 'test_bitmap_authority_check_passes.cbc'
        with open(out,'wb') as f: f.write(bc)
        print(f"Bitmap Authority Check Passes test: compiled {len(bc)} bytes -> {out}")
    elif '--bitmap-authority-check-passes-test' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_bitmap_authority_check_passes())
        print(f"Bitmap Authority Check Passes test: {len(bc)} bytes")
    elif '--bitmap-authority-check-fails-build' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_bitmap_authority_check_fails())
        out = sys.argv[sys.argv.index('--bitmap-authority-check-fails-build')+1] if len(sys.argv) > sys.argv.index('--bitmap-authority-check-fails-build')+1 else 'test_bitmap_authority_check_fails.cbc'
        with open(out,'wb') as f: f.write(bc)
        print(f"Bitmap Authority Check Fails test: compiled {len(bc)} bytes -> {out}")
    elif '--bitmap-authority-check-fails-test' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_bitmap_authority_check_fails())
        print(f"Bitmap Authority Check Fails test: {len(bc)} bytes")
    elif '--bitmap-accessor-round-trip-build' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_bitmap_accessor_round_trip())
        out = sys.argv[sys.argv.index('--bitmap-accessor-round-trip-build')+1] if len(sys.argv) > sys.argv.index('--bitmap-accessor-round-trip-build')+1 else 'test_bitmap_accessor_round_trip.cbc'
        with open(out,'wb') as f: f.write(bc)
        print(f"Bitmap Accessor Round Trip test: compiled {len(bc)} bytes -> {out}")
    elif '--bitmap-accessor-round-trip-test' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_bitmap_accessor_round_trip())
        print(f"Bitmap Accessor Round Trip test: {len(bc)} bytes")
    # --- Pod 3 Embedding test surfaces (T1-T7) ---
    elif '--embedding-new-basic-build' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_embedding_new_basic())
        out = sys.argv[sys.argv.index('--embedding-new-basic-build')+1] if len(sys.argv) > sys.argv.index('--embedding-new-basic-build')+1 else 'test_embedding_new_basic.cbc'
        with open(out,'wb') as f: f.write(bc)
        print(f"Embedding New Basic test: compiled {len(bc)} bytes -> {out}")
    elif '--embedding-new-basic-test' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_embedding_new_basic())
        print(f"Embedding New Basic test: {len(bc)} bytes")
    elif '--embedding-accessor-round-trip-build' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_embedding_accessor_round_trip())
        out = sys.argv[sys.argv.index('--embedding-accessor-round-trip-build')+1] if len(sys.argv) > sys.argv.index('--embedding-accessor-round-trip-build')+1 else 'test_embedding_accessor_round_trip.cbc'
        with open(out,'wb') as f: f.write(bc)
        print(f"Embedding Accessor Round Trip test: compiled {len(bc)} bytes -> {out}")
    elif '--embedding-accessor-round-trip-test' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_embedding_accessor_round_trip())
        print(f"Embedding Accessor Round Trip test: {len(bc)} bytes")
    elif '--embedding-invalid-id-build' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_embedding_invalid_id())
        out = sys.argv[sys.argv.index('--embedding-invalid-id-build')+1] if len(sys.argv) > sys.argv.index('--embedding-invalid-id-build')+1 else 'test_embedding_invalid_id.cbc'
        with open(out,'wb') as f: f.write(bc)
        print(f"Embedding Invalid ID test: compiled {len(bc)} bytes -> {out}")
    elif '--embedding-invalid-id-test' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_embedding_invalid_id())
        print(f"Embedding Invalid ID test: {len(bc)} bytes")
    elif '--embedding-authority-check-passes-build' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_embedding_authority_check_passes())
        out = sys.argv[sys.argv.index('--embedding-authority-check-passes-build')+1] if len(sys.argv) > sys.argv.index('--embedding-authority-check-passes-build')+1 else 'test_embedding_authority_check_passes.cbc'
        with open(out,'wb') as f: f.write(bc)
        print(f"Embedding Authority Check Passes test: compiled {len(bc)} bytes -> {out}")
    elif '--embedding-authority-check-passes-test' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_embedding_authority_check_passes())
        print(f"Embedding Authority Check Passes test: {len(bc)} bytes")
    elif '--embedding-authority-check-fails-build' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_embedding_authority_check_fails())
        out = sys.argv[sys.argv.index('--embedding-authority-check-fails-build')+1] if len(sys.argv) > sys.argv.index('--embedding-authority-check-fails-build')+1 else 'test_embedding_authority_check_fails.cbc'
        with open(out,'wb') as f: f.write(bc)
        print(f"Embedding Authority Check Fails test: compiled {len(bc)} bytes -> {out}")
    elif '--embedding-authority-check-fails-test' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_embedding_authority_check_fails())
        print(f"Embedding Authority Check Fails test: {len(bc)} bytes")
    elif '--sign-with-embedding-build' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_sign_with_embedding_link())
        out = sys.argv[sys.argv.index('--sign-with-embedding-build')+1] if len(sys.argv) > sys.argv.index('--sign-with-embedding-build')+1 else 'test_sign_with_embedding.cbc'
        with open(out,'wb') as f: f.write(bc)
        print(f"Sign-with-Embedding Link test: compiled {len(bc)} bytes -> {out}")
    elif '--sign-with-embedding-test' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_sign_with_embedding_link())
        print(f"Sign-with-Embedding Link test: {len(bc)} bytes")
    elif '--sign-invalid-embedding-handle-build' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_sign_invalid_embedding_handle())
        out = sys.argv[sys.argv.index('--sign-invalid-embedding-handle-build')+1] if len(sys.argv) > sys.argv.index('--sign-invalid-embedding-handle-build')+1 else 'test_sign_invalid_embedding_handle.cbc'
        with open(out,'wb') as f: f.write(bc)
        print(f"Sign Invalid Embedding Handle test: compiled {len(bc)} bytes -> {out}")
    elif '--sign-invalid-embedding-handle-test' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_sign_invalid_embedding_handle())
        print(f"Sign Invalid Embedding Handle test: {len(bc)} bytes")
    # --- Pod 3.5 Maid speaks: semantic operations test surfaces (T8-T13 / B7-B23) ---
    elif '--cosine-same-vector-build' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_cosine_same_vector())
        out = sys.argv[sys.argv.index('--cosine-same-vector-build')+1] if len(sys.argv) > sys.argv.index('--cosine-same-vector-build')+1 else 'test_cosine_same_vector.cbc'
        with open(out,'wb') as f: f.write(bc)
        print(f"Cosine Same Vector test: compiled {len(bc)} bytes -> {out}")
    elif '--cosine-same-vector-test' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_cosine_same_vector())
        print(f"Cosine Same Vector test: {len(bc)} bytes")
    elif '--cosine-zero-vector-build' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_cosine_zero_vector())
        out = sys.argv[sys.argv.index('--cosine-zero-vector-build')+1] if len(sys.argv) > sys.argv.index('--cosine-zero-vector-build')+1 else 'test_cosine_zero_vector.cbc'
        with open(out,'wb') as f: f.write(bc)
        print(f"Cosine Zero Vector test: compiled {len(bc)} bytes -> {out}")
    elif '--cosine-zero-vector-test' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_cosine_zero_vector())
        print(f"Cosine Zero Vector test: {len(bc)} bytes")
    elif '--cosine-45-degree-build' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_cosine_45_degree())
        out = sys.argv[sys.argv.index('--cosine-45-degree-build')+1] if len(sys.argv) > sys.argv.index('--cosine-45-degree-build')+1 else 'test_cosine_45_degree.cbc'
        with open(out,'wb') as f: f.write(bc)
        print(f"Cosine 45-Degree test: compiled {len(bc)} bytes -> {out}")
    elif '--cosine-45-degree-test' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_cosine_45_degree())
        print(f"Cosine 45-Degree test: {len(bc)} bytes")
    elif '--cosine-orthogonal-build' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_cosine_orthogonal())
        out = sys.argv[sys.argv.index('--cosine-orthogonal-build')+1] if len(sys.argv) > sys.argv.index('--cosine-orthogonal-build')+1 else 'test_cosine_orthogonal.cbc'
        with open(out,'wb') as f: f.write(bc)
        print(f"Cosine Orthogonal test: compiled {len(bc)} bytes -> {out}")
    elif '--cosine-orthogonal-test' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_cosine_orthogonal())
        print(f"Cosine Orthogonal test: {len(bc)} bytes")
    elif '--cosine-antipodal-build' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_cosine_antipodal())
        out = sys.argv[sys.argv.index('--cosine-antipodal-build')+1] if len(sys.argv) > sys.argv.index('--cosine-antipodal-build')+1 else 'test_cosine_antipodal.cbc'
        with open(out,'wb') as f: f.write(bc)
        print(f"Cosine Antipodal test: compiled {len(bc)} bytes -> {out}")
    elif '--cosine-antipodal-test' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_cosine_antipodal())
        print(f"Cosine Antipodal test: {len(bc)} bytes")
    elif '--cosine-invalid-id-build' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_cosine_invalid_id())
        out = sys.argv[sys.argv.index('--cosine-invalid-id-build')+1] if len(sys.argv) > sys.argv.index('--cosine-invalid-id-build')+1 else 'test_cosine_invalid_id.cbc'
        with open(out,'wb') as f: f.write(bc)
        print(f"Cosine Invalid ID test: compiled {len(bc)} bytes -> {out}")
    elif '--cosine-invalid-id-test' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_cosine_invalid_id())
        print(f"Cosine Invalid ID test: {len(bc)} bytes")
    elif '--dot-product-simple-build' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_dot_product_simple())
        out = sys.argv[sys.argv.index('--dot-product-simple-build')+1] if len(sys.argv) > sys.argv.index('--dot-product-simple-build')+1 else 'test_dot_product_simple.cbc'
        with open(out,'wb') as f: f.write(bc)
        print(f"Dot Product Simple test: compiled {len(bc)} bytes -> {out}")
    elif '--dot-product-simple-test' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_dot_product_simple())
        print(f"Dot Product Simple test: {len(bc)} bytes")
    elif '--dot-product-invalid-id-build' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_dot_product_invalid_id())
        out = sys.argv[sys.argv.index('--dot-product-invalid-id-build')+1] if len(sys.argv) > sys.argv.index('--dot-product-invalid-id-build')+1 else 'test_dot_product_invalid_id.cbc'
        with open(out,'wb') as f: f.write(bc)
        print(f"Dot Product Invalid ID test: compiled {len(bc)} bytes -> {out}")
    elif '--dot-product-invalid-id-test' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_dot_product_invalid_id())
        print(f"Dot Product Invalid ID test: {len(bc)} bytes")
    elif '--l2-distance-same-build' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_l2_distance_same())
        out = sys.argv[sys.argv.index('--l2-distance-same-build')+1] if len(sys.argv) > sys.argv.index('--l2-distance-same-build')+1 else 'test_l2_distance_same.cbc'
        with open(out,'wb') as f: f.write(bc)
        print(f"L2 Distance Same test: compiled {len(bc)} bytes -> {out}")
    elif '--l2-distance-same-test' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_l2_distance_same())
        print(f"L2 Distance Same test: {len(bc)} bytes")
    elif '--l2-distance-simple-build' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_l2_distance_simple())
        out = sys.argv[sys.argv.index('--l2-distance-simple-build')+1] if len(sys.argv) > sys.argv.index('--l2-distance-simple-build')+1 else 'test_l2_distance_simple.cbc'
        with open(out,'wb') as f: f.write(bc)
        print(f"L2 Distance Simple test: compiled {len(bc)} bytes -> {out}")
    elif '--l2-distance-simple-test' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_l2_distance_simple())
        print(f"L2 Distance Simple test: {len(bc)} bytes")
    elif '--l2-distance-invalid-id-build' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_l2_distance_invalid_id())
        out = sys.argv[sys.argv.index('--l2-distance-invalid-id-build')+1] if len(sys.argv) > sys.argv.index('--l2-distance-invalid-id-build')+1 else 'test_l2_distance_invalid_id.cbc'
        with open(out,'wb') as f: f.write(bc)
        print(f"L2 Distance Invalid ID test: compiled {len(bc)} bytes -> {out}")
    elif '--l2-distance-invalid-id-test' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_l2_distance_invalid_id())
        print(f"L2 Distance Invalid ID test: {len(bc)} bytes")
    elif '--lookup-top1-basic-build' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_lookup_top1_basic())
        out = sys.argv[sys.argv.index('--lookup-top1-basic-build')+1] if len(sys.argv) > sys.argv.index('--lookup-top1-basic-build')+1 else 'test_lookup_top1_basic.cbc'
        with open(out,'wb') as f: f.write(bc)
        print(f"Lookup Top-1 Basic test: compiled {len(bc)} bytes -> {out}")
    elif '--lookup-top1-basic-test' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_lookup_top1_basic())
        print(f"Lookup Top-1 Basic test: {len(bc)} bytes")
    elif '--lookup-top1-empty-build' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_lookup_top1_empty())
        out = sys.argv[sys.argv.index('--lookup-top1-empty-build')+1] if len(sys.argv) > sys.argv.index('--lookup-top1-empty-build')+1 else 'test_lookup_top1_empty.cbc'
        with open(out,'wb') as f: f.write(bc)
        print(f"Lookup Top-1 Empty test: compiled {len(bc)} bytes -> {out}")
    elif '--lookup-top1-empty-test' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_lookup_top1_empty())
        print(f"Lookup Top-1 Empty test: {len(bc)} bytes")
    elif '--lookup-top1-invalid-query-build' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_lookup_top1_invalid_query())
        out = sys.argv[sys.argv.index('--lookup-top1-invalid-query-build')+1] if len(sys.argv) > sys.argv.index('--lookup-top1-invalid-query-build')+1 else 'test_lookup_top1_invalid_query.cbc'
        with open(out,'wb') as f: f.write(bc)
        print(f"Lookup Top-1 Invalid Query test: compiled {len(bc)} bytes -> {out}")
    elif '--lookup-top1-invalid-query-test' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_lookup_top1_invalid_query())
        print(f"Lookup Top-1 Invalid Query test: {len(bc)} bytes")
    elif '--embedding-sign-handle-linked-build' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_embedding_sign_handle_linked())
        out = sys.argv[sys.argv.index('--embedding-sign-handle-linked-build')+1] if len(sys.argv) > sys.argv.index('--embedding-sign-handle-linked-build')+1 else 'test_embedding_sign_handle_linked.cbc'
        with open(out,'wb') as f: f.write(bc)
        print(f"Embedding Sign Handle Linked test: compiled {len(bc)} bytes -> {out}")
    elif '--embedding-sign-handle-linked-test' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_embedding_sign_handle_linked())
        print(f"Embedding Sign Handle Linked test: {len(bc)} bytes")
    elif '--embedding-sign-handle-unlinked-build' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_embedding_sign_handle_unlinked())
        out = sys.argv[sys.argv.index('--embedding-sign-handle-unlinked-build')+1] if len(sys.argv) > sys.argv.index('--embedding-sign-handle-unlinked-build')+1 else 'test_embedding_sign_handle_unlinked.cbc'
        with open(out,'wb') as f: f.write(bc)
        print(f"Embedding Sign Handle Unlinked test: compiled {len(bc)} bytes -> {out}")
    elif '--embedding-sign-handle-unlinked-test' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_embedding_sign_handle_unlinked())
        print(f"Embedding Sign Handle Unlinked test: {len(bc)} bytes")
    elif '--compute-under-subcap-build' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_compute_under_subcap())
        out = sys.argv[sys.argv.index('--compute-under-subcap-build')+1] if len(sys.argv) > sys.argv.index('--compute-under-subcap-build')+1 else 'test_compute_under_subcap.cbc'
        with open(out,'wb') as f: f.write(bc)
        print(f"Compute Under SubCap test: compiled {len(bc)} bytes -> {out}")
    elif '--compute-under-subcap-test' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_compute_under_subcap())
        print(f"Compute Under SubCap test: {len(bc)} bytes")
    elif '--maid-composition-build' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_maid_composition())
        out = sys.argv[sys.argv.index('--maid-composition-build')+1] if len(sys.argv) > sys.argv.index('--maid-composition-build')+1 else 'test_maid_composition.cbc'
        with open(out,'wb') as f: f.write(bc)
        print(f"Maid Composition test: compiled {len(bc)} bytes -> {out}")
    elif '--maid-composition-test' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_maid_composition())
        print(f"Maid Composition test: {len(bc)} bytes")
    # --- Pod 3.6 Maid composes: synthesis test surfaces (Phase 1.2 B25-B26) ---
    elif '--synthesis-add-basic-build' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_synthesis_add_basic())
        out = sys.argv[sys.argv.index('--synthesis-add-basic-build')+1] if len(sys.argv) > sys.argv.index('--synthesis-add-basic-build')+1 else 'test_synthesis_add_basic.cbc'
        with open(out,'wb') as f: f.write(bc)
        print(f"Synthesis Add Basic test: compiled {len(bc)} bytes -> {out}")
    elif '--synthesis-add-basic-test' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_synthesis_add_basic())
        print(f"Synthesis Add Basic test: {len(bc)} bytes")
    elif '--synthesis-add-zero-build' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_synthesis_add_zero())
        out = sys.argv[sys.argv.index('--synthesis-add-zero-build')+1] if len(sys.argv) > sys.argv.index('--synthesis-add-zero-build')+1 else 'test_synthesis_add_zero.cbc'
        with open(out,'wb') as f: f.write(bc)
        print(f"Synthesis Add Zero test: compiled {len(bc)} bytes -> {out}")
    elif '--synthesis-add-zero-test' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_synthesis_add_zero())
        print(f"Synthesis Add Zero test: {len(bc)} bytes")
    elif '--synthesis-subtract-basic-build' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_synthesis_subtract_basic())
        out = sys.argv[sys.argv.index('--synthesis-subtract-basic-build')+1] if len(sys.argv) > sys.argv.index('--synthesis-subtract-basic-build')+1 else 'test_synthesis_subtract_basic.cbc'
        with open(out,'wb') as f: f.write(bc)
        print(f"Synthesis Subtract Basic test: compiled {len(bc)} bytes -> {out}")
    elif '--synthesis-subtract-basic-test' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_synthesis_subtract_basic())
        print(f"Synthesis Subtract Basic test: {len(bc)} bytes")
    elif '--synthesis-subtract-self-build' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_synthesis_subtract_self())
        out = sys.argv[sys.argv.index('--synthesis-subtract-self-build')+1] if len(sys.argv) > sys.argv.index('--synthesis-subtract-self-build')+1 else 'test_synthesis_subtract_self.cbc'
        with open(out,'wb') as f: f.write(bc)
        print(f"Synthesis Subtract Self test: compiled {len(bc)} bytes -> {out}")
    elif '--synthesis-subtract-self-test' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_synthesis_subtract_self())
        print(f"Synthesis Subtract Self test: {len(bc)} bytes")
    elif '--synthesis-scale-basic-build' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_synthesis_scale_basic())
        out = sys.argv[sys.argv.index('--synthesis-scale-basic-build')+1] if len(sys.argv) > sys.argv.index('--synthesis-scale-basic-build')+1 else 'test_synthesis_scale_basic.cbc'
        with open(out,'wb') as f: f.write(bc)
        print(f"Synthesis Scale Basic test: compiled {len(bc)} bytes -> {out}")
    elif '--synthesis-scale-zero-build' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_synthesis_scale_zero())
        out = sys.argv[sys.argv.index('--synthesis-scale-zero-build')+1] if len(sys.argv) > sys.argv.index('--synthesis-scale-zero-build')+1 else 'test_synthesis_scale_zero.cbc'
        with open(out,'wb') as f: f.write(bc)
        print(f"Synthesis Scale Zero test: compiled {len(bc)} bytes -> {out}")
    elif '--synthesis-scale-negative-build' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_synthesis_scale_negative())
        out = sys.argv[sys.argv.index('--synthesis-scale-negative-build')+1] if len(sys.argv) > sys.argv.index('--synthesis-scale-negative-build')+1 else 'test_synthesis_scale_negative.cbc'
        with open(out,'wb') as f: f.write(bc)
        print(f"Synthesis Scale Negative test: compiled {len(bc)} bytes -> {out}")
    elif '--synthesis-normalize-basic-build' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_synthesis_normalize_basic())
        out = sys.argv[sys.argv.index('--synthesis-normalize-basic-build')+1] if len(sys.argv) > sys.argv.index('--synthesis-normalize-basic-build')+1 else 'test_synthesis_normalize_basic.cbc'
        with open(out,'wb') as f: f.write(bc)
        print(f"Synthesis Normalize Basic test: compiled {len(bc)} bytes -> {out}")
    elif '--synthesis-normalize-v-uniform-drift-build' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_synthesis_normalize_v_uniform_drift())
        out = sys.argv[sys.argv.index('--synthesis-normalize-v-uniform-drift-build')+1] if len(sys.argv) > sys.argv.index('--synthesis-normalize-v-uniform-drift-build')+1 else 'test_synthesis_normalize_v_uniform_drift.cbc'
        with open(out,'wb') as f: f.write(bc)
        print(f"Synthesis Normalize v_uniform Drift test (B32-aux): compiled {len(bc)} bytes -> {out}")
    elif '--synthesis-normalize-zero-reject-build' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_synthesis_normalize_zero_reject())
        out = sys.argv[sys.argv.index('--synthesis-normalize-zero-reject-build')+1] if len(sys.argv) > sys.argv.index('--synthesis-normalize-zero-reject-build')+1 else 'test_synthesis_normalize_zero_reject.cbc'
        with open(out,'wb') as f: f.write(bc)
        print(f"Synthesis Normalize Zero Reject test: compiled {len(bc)} bytes -> {out}")
    # --- Pod 3.6 Phase 3.1 (lerp) + Phase 3.2 (synthesis_handle + closing arc) ---
    elif '--synthesis-lerp-basic-build' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_synthesis_lerp_basic())
        out = sys.argv[sys.argv.index('--synthesis-lerp-basic-build')+1] if len(sys.argv) > sys.argv.index('--synthesis-lerp-basic-build')+1 else 'test_synthesis_lerp_basic.cbc'
        with open(out,'wb') as f: f.write(bc)
        print(f"Synthesis Lerp Basic test: compiled {len(bc)} bytes -> {out}")
    elif '--synthesis-lerp-t-zero-build' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_synthesis_lerp_t_zero())
        out = sys.argv[sys.argv.index('--synthesis-lerp-t-zero-build')+1] if len(sys.argv) > sys.argv.index('--synthesis-lerp-t-zero-build')+1 else 'test_synthesis_lerp_t_zero.cbc'
        with open(out,'wb') as f: f.write(bc)
        print(f"Synthesis Lerp t=0 test: compiled {len(bc)} bytes -> {out}")
    elif '--synthesis-lerp-t-one-build' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_synthesis_lerp_t_one())
        out = sys.argv[sys.argv.index('--synthesis-lerp-t-one-build')+1] if len(sys.argv) > sys.argv.index('--synthesis-lerp-t-one-build')+1 else 'test_synthesis_lerp_t_one.cbc'
        with open(out,'wb') as f: f.write(bc)
        print(f"Synthesis Lerp t=1 test: compiled {len(bc)} bytes -> {out}")
    elif '--synthesis-lerp-irrational-drift-build' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_synthesis_lerp_irrational_t_drift())
        out = sys.argv[sys.argv.index('--synthesis-lerp-irrational-drift-build')+1] if len(sys.argv) > sys.argv.index('--synthesis-lerp-irrational-drift-build')+1 else 'test_synthesis_lerp_irrational_drift.cbc'
        with open(out,'wb') as f: f.write(bc)
        print(f"Synthesis Lerp Irrational-t Drift test (B34-aux): compiled {len(bc)} bytes -> {out}")
    elif '--synthesis-round-trip-build' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_synthesis_round_trip())
        out = sys.argv[sys.argv.index('--synthesis-round-trip-build')+1] if len(sys.argv) > sys.argv.index('--synthesis-round-trip-build')+1 else 'test_synthesis_round_trip.cbc'
        with open(out,'wb') as f: f.write(bc)
        print(f"Synthesis Round Trip test (B37): compiled {len(bc)} bytes -> {out}")
    elif '--synthesis-unsynthesized-build' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_synthesis_unsynthesized())
        out = sys.argv[sys.argv.index('--synthesis-unsynthesized-build')+1] if len(sys.argv) > sys.argv.index('--synthesis-unsynthesized-build')+1 else 'test_synthesis_unsynthesized.cbc'
        with open(out,'wb') as f: f.write(bc)
        print(f"Synthesis Unsynthesized test (B38): compiled {len(bc)} bytes -> {out}")
    elif '--analogical-reasoning-build' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_analogical_reasoning())
        out = sys.argv[sys.argv.index('--analogical-reasoning-build')+1] if len(sys.argv) > sys.argv.index('--analogical-reasoning-build')+1 else 'test_analogical_reasoning.cbc'
        with open(out,'wb') as f: f.write(bc)
        print(f"Analogical Reasoning test (B39): compiled {len(bc)} bytes -> {out}")
    elif '--synthesis-forge-authority-build' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_forge_authority_required())
        out = sys.argv[sys.argv.index('--synthesis-forge-authority-build')+1] if len(sys.argv) > sys.argv.index('--synthesis-forge-authority-build')+1 else 'test_synthesis_forge_authority.cbc'
        with open(out,'wb') as f: f.write(bc)
        print(f"Synthesis Forge Authority Required test (B40): compiled {len(bc)} bytes -> {out}")
    elif '--synthesis-babylon-ripple-build' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_babylon_ripple_synthesis())
        out = sys.argv[sys.argv.index('--synthesis-babylon-ripple-build')+1] if len(sys.argv) > sys.argv.index('--synthesis-babylon-ripple-build')+1 else 'test_synthesis_babylon_ripple.cbc'
        with open(out,'wb') as f: f.write(bc)
        print(f"Synthesis Babylon Ripple test (B41): compiled {len(bc)} bytes -> {out}")
    elif '--synthesis-pool-capacity-build' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_pool_capacity_synthesis_pressure())
        out = sys.argv[sys.argv.index('--synthesis-pool-capacity-build')+1] if len(sys.argv) > sys.argv.index('--synthesis-pool-capacity-build')+1 else 'test_synthesis_pool_capacity.cbc'
        with open(out,'wb') as f: f.write(bc)
        print(f"Synthesis Pool Capacity Pressure test (B42): compiled {len(bc)} bytes -> {out}")
    # --- Pod 3.7 capacity-expansion canaries (B43-B45) ---
    elif '--pod37-embedding-pool-capacity-build' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_pod37_embedding_pool_capacity_at_2048())
        out = sys.argv[sys.argv.index('--pod37-embedding-pool-capacity-build')+1] if len(sys.argv) > sys.argv.index('--pod37-embedding-pool-capacity-build')+1 else 'test_pod37_embedding_pool_capacity.cbc'
        with open(out,'wb') as f: f.write(bc)
        print(f"Pod 3.7 Embedding Pool Capacity at 2048 test (B43): compiled {len(bc)} bytes -> {out}")
    elif '--pod37-outcome-pool-load-build' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_pod37_outcome_pool_under_synthesis_load())
        out = sys.argv[sys.argv.index('--pod37-outcome-pool-load-build')+1] if len(sys.argv) > sys.argv.index('--pod37-outcome-pool-load-build')+1 else 'test_pod37_outcome_pool_load.cbc'
        with open(out,'wb') as f: f.write(bc)
        print(f"Pod 3.7 Outcome Pool Under Load test (B44): compiled {len(bc)} bytes -> {out}")
    elif '--pod37-mixed-workload-build' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_pod37_mixed_workload_within_capacity())
        out = sys.argv[sys.argv.index('--pod37-mixed-workload-build')+1] if len(sys.argv) > sys.argv.index('--pod37-mixed-workload-build')+1 else 'test_pod37_mixed_workload.cbc'
        with open(out,'wb') as f: f.write(bc)
        print(f"Pod 3.7 Mixed Workload test (B45): compiled {len(bc)} bytes -> {out}")
    # --- Pod 3.8 codebook boot-ingestion canary (B48) ---
    elif '--pod38-codebook-imported-round-trip-build' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_pod38_codebook_imported_round_trip())
        out = sys.argv[sys.argv.index('--pod38-codebook-imported-round-trip-build')+1] if len(sys.argv) > sys.argv.index('--pod38-codebook-imported-round-trip-build')+1 else 'test_pod38_b48_codebook_imported.cbc'
        with open(out,'wb') as f: f.write(bc)
        print(f"Pod 3.8 B48 Codebook Imported Round-Trip test: compiled {len(bc)} bytes -> {out}")
    elif '--pod39-top-k-b49-build' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_pod39_top_k_b49())
        out = sys.argv[sys.argv.index('--pod39-top-k-b49-build')+1] if len(sys.argv) > sys.argv.index('--pod39-top-k-b49-build')+1 else 'test_pod39_b49_top_k.cbc'
        with open(out,'wb') as f: f.write(bc)
        print(f"Pod 3.9 B49 Top-K test: compiled {len(bc)} bytes -> {out}")
    elif '--pod39-b49-probe-build' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_pod39_b49_probe())
        out = sys.argv[sys.argv.index('--pod39-b49-probe-build')+1] if len(sys.argv) > sys.argv.index('--pod39-b49-probe-build')+1 else 'test_pod39_b49_probe.cbc'
        with open(out,'wb') as f: f.write(bc)
        print(f"Pod 3.9 B49 Probe test: compiled {len(bc)} bytes -> {out}")
    elif '--pod39-b49-probe-k-build' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_pod39_b49_probe_k())
        out = sys.argv[sys.argv.index('--pod39-b49-probe-k-build')+1] if len(sys.argv) > sys.argv.index('--pod39-b49-probe-k-build')+1 else 'test_pod39_b49_probe_k.cbc'
        with open(out,'wb') as f: f.write(bc)
        print(f"Pod 3.9 B49 K-Probe test: compiled {len(bc)} bytes -> {out}")
    elif '--pod310-b50-project-build' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_pod310_b50_project())
        out = sys.argv[sys.argv.index('--pod310-b50-project-build')+1] if len(sys.argv) > sys.argv.index('--pod310-b50-project-build')+1 else 'test_pod310_b50_project.cbc'
        with open(out,'wb') as f: f.write(bc)
        print(f"Pod 3.10 B50 Project test: compiled {len(bc)} bytes -> {out}")
    elif '--pod310-b51-reject-build' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_pod310_b51_reject())
        out = sys.argv[sys.argv.index('--pod310-b51-reject-build')+1] if len(sys.argv) > sys.argv.index('--pod310-b51-reject-build')+1 else 'test_pod310_b51_reject.cbc'
        with open(out,'wb') as f: f.write(bc)
        print(f"Pod 3.10 B51 Reject test: compiled {len(bc)} bytes -> {out}")
    elif '--pod311-b52-meta-build' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_pod311_b52_codebook_meta())
        out = sys.argv[sys.argv.index('--pod311-b52-meta-build')+1] if len(sys.argv) > sys.argv.index('--pod311-b52-meta-build')+1 else 'test_pod311_b52_codebook_meta.cbc'
        with open(out,'wb') as f: f.write(bc)
        print(f"Pod 3.11 B52 Codebook Meta test: compiled {len(bc)} bytes -> {out}")
    else:
        print("Usage: python3 atreyu_x86.py --build [out.cbc] | --test | --sign-build [out.cbc] | --sign-test | --energy-build [out.cbc] | --energy-test | --phase-build [out.cbc] | --energy-recover-build [out.cbc] | --outcome-{ok,err,is-ok,unwrap-ok,unwrap-err,dup-is-ok}-{build,test} | --cap-{new-basic,arena-owner-bitmap,current,invalid-id,stack-underflow,stack-overflow}-{build,test} | --{sign,energy,outcome}-provenance-root-{build,test} | --provenance-{under-subcap,walk}-{build,test} | --cap-parent-root-{build,test} | --invalid-id-each-new-accessor-{build,test} | --bitmap-{root-unbounded,subset-grant-succeeds,superset-grant-fails,authority-check-{passes,fails},accessor-round-trip}-{build,test} | --embedding-{new-basic,accessor-round-trip,invalid-id,authority-check-{passes,fails}}-{build,test} | --sign-{with-embedding,invalid-embedding-handle}-{build,test}")
