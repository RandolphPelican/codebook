# CBS Language Reference

CBS is CodebookOS's bytecode language. Custom syntax, custom compiler (`tools/atreyu_x86.py`), custom stack-VM (`boot/cbs_vm.asm`). Every opcode is energy-accounted; every primitive operation is byte-exact reproducible.

---

## Authoring CBS programs

At V1.0, CBS programs are authored as **Python AST functions** in `tools/atreyu_x86.py`. Each demo function returns an AST tree (`{'type': 'program', 'body': [...]}`) which the compiler walks to emit bytecode. The compiled `.cbc` file is what runs on the substrate; the Python AST is the source representation.

The substrate also includes a parser for textual CBS source (`.cbs` files like `surfaces/hello.cbs` and the self-hosted compiler chain in `surfaces/parser.cbs` + `surfaces/lexer.cbs`), but the AST-based authoring path is the canonical credential-tier path used by all 6 canary demos.

---

## Language surface (V1.0)

### Statement types

| Type | Purpose | Example |
|---|---|---|
| `print` | Emit value or string to framebuffer via auryn | `{'type':'print','value':{...}}` |
| `let` | Bind expression result to variable | `{'type':'let','name':'x','value':{...}}` |
| `if` | Conditional branching (optional `else`) | `{'type':'if','cond':{...},'then':{...},'else':{...}}` |
| `while` | Bounded loop with cond + body block | `{'type':'while','cond':{...},'body':{...}}` |
| `block` | Statement sequence | `{'type':'block','stmts':[...]}` |
| `return` | Exit program with value | `{'type':'return','value':{...}}` |

### Expression types

Primitive literals:
- `{'type':'int','value':42}` — i64 literal
- `{'type':'bool','value':True}` — true=1, false=0
- `{'type':'str','value':"hello"}` — string ref
- `{'type':'var','name':'x'}` — variable load
- `{'type':'tos'}` — pop top-of-stack (used after lookup_top_k returns multiple ids)

Arithmetic + comparison:
- `add`, `sub`, `mul`, `div`, `mod` — i64 arithmetic
- `eq`, `ne`, `lt`, `gt`, `le`, `ge` — i64 comparison; returns 0 or 1
- `neg`, `not` — unary

Typed primitive forging + accessors (each documented in `tools/atreyu_x86.py`):
- **Sign**: `sign_new`, `sign_energy`, `sign_hash_first`, `sign_embedding_handle`
- **Energy**: `energy_new`, `energy_joules`, `energy_source_op`, `energy_recover`
- **Outcome**: `outcome_new_ok`, `outcome_new_err`, `outcome_is_ok`, `outcome_unwrap_ok`, `outcome_unwrap_err`
- **Cap**: `cap_new`, `cap_enter`, `cap_exit`, `cap_current`, `cap_bitmap`, `cap_budget`, `cap_used`, `cap_arena`, `cap_owner`, `cap_parent`
- **Embedding**: `embedding_new`, `embedding_get_dim`, `embedding_cosine`, `embedding_dot_product`, `embedding_l2_distance`, `embedding_lookup_top1`, `embedding_lookup_top_k`, `embedding_add`, `embedding_subtract`, `embedding_scale`, `embedding_normalize`, `embedding_lerp`, `embedding_project`, `embedding_reject`, `embedding_imported_handle`, `embedding_synthesis_handle`, `embedding_codebook_meta`

Substrate I/O (D4.2 capability-tokenized I/O surface):
- `{'type':'use_cap','token':<u64>,'cmd':<i64>,'args':[<int>...]}` — dispatch to substrate service

---

## Capability-tokenized I/O (D4.2)

CBS programs interact with substrate services via `OP_USE_CAP(token, cmd)`. The substrate dispatches on token to the appropriate handler:

| Token | Value | Service | Operations |
|---|---|---|---|
| `CAP_AURYN_DISPLAY` | 0xCA000001 | Framebuffer | cmd=1 putc; cmd=2 fill (args: color) |
| `CAP_GMORK_CONIN` | 0xCA000002 | Keyboard | cmd=1 non-blocking read → unicode (0 if none) |
| `CAP_MORLA_FS` | 0xCA000003 | Filesystem | cmd=1 ls; cmd=2 write |
| `CAP_ROCKBITER` | 0xCA000004 | Energy introspection | cmd=1 budget; cmd=2 used |

### Polling for blocking input

Keyboard reads are non-blocking. To wait for a keypress, poll in a while loop:

```python
# From surfaces/test_pod40f_b57_press_x.cbc (B57 demo)
{'type':'let','name':'key','value':{'type':'int','value':0}},
{'type':'let','name':'done','value':{'type':'int','value':0}},
{'type':'while',
 'cond':{'type':'eq','left':{'type':'var','name':'done'},'right':{'type':'int','value':0}},
 'body':{'type':'block','stmts':[
    {'type':'let','name':'key','value':{'type':'use_cap','token':CAP_GMORK_CONIN,'cmd':1}},
    {'type':'if','cond':{'type':'eq','left':{'type':'var','name':'key'},'right':{'type':'int','value':120}},  # 'x'
     'then':{'type':'block','stmts':[{'type':'let','name':'done','value':{'type':'int','value':1}}]}},
 ]}},
```

Each poll iteration consumes substrate cost-table joules (D3.17). The press-X demo uses ~29 joules per iteration; 5000 polls = ~145,080j tracked empirically.

---

## Walked example 1: Fibonacci with energy trace (B53)

`surfaces/demo_fib_energy.cbs` (human-readable representation):

```
const FIB_TARGET     = 12
const ENERGY_INITIAL = 100000

func fib(n) {
    if n < 2 {
        return n
    }
    return fib(n - 1) + fib(n - 2)
}

let result = fib(FIB_TARGET)
print("fib(12) = ")
print(result)
let used = energy_used()
print(" joules used: ")
print(used)
```

`tools/atreyu_x86.py:demo_pod40f_b53_fib_energy()` is the compiled-AST version that actually runs. It uses iterative fib (recursion via `func`/`return` is parsed but not end-to-end-verified at V1.0). Output from runtime:

```
fib(0) = 0
fib(1) = 1
fib(2) = 1   joules used: 87
fib(3) = 2   joules used: 115
fib(4) = 3   joules used: 151
...
fib(12) = 144   joules used: 407
Energy: 445j used, 999555j remaining
```

The substrate's per-opcode cost-table makes energy accounting visible **per iteration** — D3.17 anticipated-worst-case empirical at user-program scale.

---

## Walked example 2: Vector composer (B55)

5-doctrine cross-composition. From `tools/atreyu_x86.py:demo_pod40f_b55_vector_composer()`:

```python
# Forge source vectors: A=(1,0), B=(0,1), C=(1,0), D=(1,1)
{'type':'let','name':'a','value':{'type':'embedding_new','vector':v_X}},
{'type':'let','name':'b','value':{'type':'embedding_new','vector':v_Y}},
{'type':'let','name':'c','value':{'type':'embedding_new','vector':v_X}},
{'type':'let','name':'d','value':{'type':'embedding_new','vector':v_diag}},

# Step 1: ADD A + B → (1,1)
{'type':'let','name':'s1','value':{'type':'embedding_add',
    'lhs':{'type':'var','name':'a'}, 'rhs':{'type':'var','name':'b'}}},

# Step 2: SCALE S1 by 0.5 → (0.5, 0.5)
{'type':'let','name':'s2','value':{'type':'embedding_scale',
    'operand':{'type':'var','name':'s1'}, 'scalar_bits':0x3F000000}},

# Step 3: PROJECT S2 onto C → (0.5, 0)
{'type':'let','name':'s3','value':{'type':'embedding_project',
    'lhs':{'type':'var','name':'s2'}, 'rhs':{'type':'var','name':'c'}}},

# Step 4: REJECT S3 from D → (0.25, -0.25)
{'type':'let','name':'s4','value':{'type':'embedding_reject',
    'lhs':{'type':'var','name':'s3'}, 'rhs':{'type':'var','name':'d'}}},

# Orthogonality verification: dot(S4, D) should be byte-exact 0
{'type':'print','value':{'type':'embedding_dot_product',
    'lhs':{'type':'var','name':'s4'}, 'rhs':{'type':'var','name':'d'}}},
```

Halving magnitudes-squared cascade: 2.0 → 0.5 → 0.25 → 0.125. Final `dot(S4, D) = 0` byte-exact (clean-cancellation regime of D3.40 hybrid IEEE-degeneracy convention).

13 byte-exact predictions match per the B55 canary. Energy: 5,647 joules for the full chain (substrate cost-table sum is internally consistent at the composition layer).

---

## Walked example 3: Capability lifecycle (B56)

From `tools/atreyu_x86.py:demo_pod40f_b56_cap_lifecycle()`:

```python
# ORIGIN — observe ROOT_CAP
{'type':'let','name':'root_id','value':{'type':'cap_current'}},        # = 1
{'type':'cap_bitmap','operand':{'type':'var','name':'root_id'}},        # = -1 (UNBOUNDED)
{'type':'cap_budget','operand':{'type':'var','name':'root_id'}},        # = -1 (UNBOUNDED)

# GRANT — forge subcap (subset-on-grant per D2.2.5)
BIT_OUTCOME_FORGE = 0x04
{'type':'let','name':'child_outcome','value':{'type':'cap_new',
    'granted_bitmap': BIT_OUTCOME_FORGE, 'energy_budget': 50000}},
{'type':'let','name':'child','value':{'type':'outcome_unwrap_ok',
    'operand':{'type':'var','name':'child_outcome'}}},                  # cap_id = 2

# USE — cap_enter + observe + cap_exit
{'type':'let','name':'enter_outcome','value':{'type':'cap_enter',
    'operand':{'type':'var','name':'child'}}},                         # current_cap → 2
# ... operations under child auth ...
{'type':'let','name':'exit_outcome','value':{'type':'cap_exit'}},      # current_cap → 1
```

V1.0 cap surface: grant + use + accounting + lineage. Revocation deferred to V2.0 per RECONSTITUTION cap_graph design. Demo proves the substrate's *actual* discipline, not aspirational design.

---

## Per-opcode energy cost table (excerpt; full table in `boot/energy_costs.asm`)

```
0x01 OP_PUSH                    1j        Push i64 literal
0x10 OP_ADD                     1j        i64 add
0x11 OP_SUB                     1j        i64 sub
0x12 OP_MUL                     2j        i64 mul
0x13 OP_DIV                     3j        i64 div
0x40 OP_JMP                     1j        Unconditional jump
0x55 OP_JIF                     1j        Jump if false
0x70 OP_LOAD                    1j        Variable load
0x71 OP_STORE                   1j        Variable store
0x80 OP_PRINT_NUM               2j        Print integer (I/O)
0x91 OP_USE_CAP                 1j        Dispatch to capability service
0xA0 OP_SIGN_NEW              100j        Forge typed Sign primitive
0xB0 OP_CAP_NEW               100j        Forge typed Cap primitive
0xC0 OP_EMBEDDING_NEW         100j        Forge typed Embedding primitive
0xC6 OP_EMBEDDING_COSINE      400j        f32 cosine compute (D3.14 Form A)
0xC9 OP_EMBEDDING_LOOKUP_TOP1 100000j     Pool-bounded scan (D3.17 anticipated worst-case)
0xCA OP_EMBEDDING_ADD         500j        f32 vector add (D3.6 synthesis)
0xCC OP_EMBEDDING_SCALE       500j        f32 vector scale by scalar
0xCD OP_EMBEDDING_NORMALIZE   700j        f32 normalize with zero-norm rejection
0xCE OP_EMBEDDING_LERP        800j        f32 linear interpolation (ternary)
0xE0 OP_OUTCOME_NEW_OK          1j        Forge Outcome::Ok
0xE1 OP_OUTCOME_NEW_ERR         1j        Forge Outcome::Err
0xF2 OP_EMBEDDING_LOOKUP_TOP_K 100000j   Top-K cosine ranking (D3.35)
0xF3 OP_EMBEDDING_PROJECT    1500j        f32 geometric project (D3.38)
0xF4 OP_EMBEDDING_REJECT     1500j        f32 geometric reject (D3.38)
0xF5 OP_EMBEDDING_CODEBOOK_META  1j      Codebook metadata witness (D3.42)
0xFF OP_HALT                    0j        Termination
```

All values are **anticipated worst-case** per D3.17 — not measured machine work. The substrate's `r14` register enforces budget, not cost-accuracy. Substrate-doctrine prefers fixed pricing decisions over per-pod cost-table re-tuning. (Pod 3.6 synthesis ops landed with SEAL-calibrated 500/500/500/700/800j; B53 fib trace verifies the per-iteration accumulation matches.)

---

## Compiling and running a CBS demo

```bash
# Compile a demo to bytecode
python3 tools/atreyu_x86.py --pod40f-b53-fib-energy-build surfaces/my_fib.cbc

# Run via the canary harness (auto-launches QEMU)
bash tools/pod35_canary_test.sh my_fib my_fib_output
# → build/my_fib_output.png captures the canary's framebuffer
```

The canary harness boots the substrate, runs your CBS program via Gmork's `load` command, captures a screen dump, and exits. Subsequent canary runs are byte-exact reproducible if the substrate sha is unchanged.

---

## Substrate determinism

Two-build determinism: assembling `boot/boot.asm` twice produces byte-exact identical `BOOTX64.EFI`. The V1.0 SEAL contract sha is `c9923b8cf9fb6caf4c195e2d0d0ea2ed4a8e51e4e9f827b1fc24dd0b28c1d900`. Any code change that affects substrate behavior shifts this sha; pure documentation changes do not.

F32 IEEE 754 byte-exact determinism: every f32 computation in the Maid V1.0 surface (cosine, project, reject, etc.) uses Form A canonical evaluation order (per D3.14). The same input vector produces the same f32 bit pattern across two runs, two builds, two architectures (when ported).

---

## What CBS doesn't do at V1.0

- **Floating-point arithmetic at the user-program level**: f32 ops are accessible via typed-Embedding helpers (Maid V1.0 surface), not as scalar arithmetic. `let x = 1.5` is not valid CBS at V1.0; the substrate's f32 path is for vector operations only.
- **Strings beyond literals**: `print(<string literal>)` works; runtime string concatenation / formatting / parsing does not.
- **Dynamic memory allocation at user-program level**: substrate uses pre-allocated pools; user programs share pool slots across the boot session.
- **Recursion (end-to-end verified)**: `func` + `return` parse, but recursive demos are iterative at V1.0 for canary stability.
- **Floating-point conversion ops**: explicit f32-to-i64 and i64-to-f32 conversion outside the typed Embedding interface.

V2.0 carry-forward features are tracked in [DEFERRED.md](DEFERRED.md) and framework-tested per D3.43 at activation time.

---

## Reading the bytecode

Compiled `.cbc` files are flat bytecode. Read them with a hex editor:

```bash
xxd surfaces/test_pod40f_b53_fib_energy.cbc | head -10
```

Each opcode is 1 byte; operands follow per opcode shape (most are 8-byte i64 or 4-byte i32). The dispatch loop in `boot/cbs_vm.asm:.fetch` reads one opcode, dispatches via opcode-table lookup, executes, decrements `r14` (energy budget) by the cost-table entry, and loops to the next opcode. Energy depleted → graceful HALT.

---

## Reference

- AST emitter source: `tools/atreyu_x86.py` (~4,200 lines; the canonical definition of every CBS expression and statement type)
- Bytecode dispatch: `boot/cbs_vm.asm` (~3,900 lines; per-opcode handlers + cost-table integration + capability dispatch)
- Energy cost table: `boot/energy_costs.asm` (every opcode's joule price + doctrine reference comment)
- Typed primitive specs: `boot/defines.asm` (slot layouts + offsets + token constants + opcode constants)

Walked CBS examples live in:
- `surfaces/hello.cbs` — minimal example (4 lines)
- `surfaces/parser.cbs` / `surfaces/lexer.cbs` — self-hosted compiler chain (advanced)
- `surfaces/demo_fib_energy.cbs` — Fibonacci with energy trace (B53 representation)
- `tools/atreyu_x86.py:demo_pod40f_*` functions — 6 canary demos as Python AST source

The Python AST source for each demo is the authoritative, runtime-verified version. The `.cbs` text source is a human-readable mirror; AST is what the compiler walks.

---

*Every opcode declares its cost. CBS makes that promise compile-time visible and runtime empirical.*
