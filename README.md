# Codebook OS

---
## Context
- **CBS ASM VM:** The bytecode is executed natively by the CBS toolchain (`cbsc.cbs` calling internal VM logic derived from `tools/vm.cbs`). The VM expects a 23-byte surface token header followed by bytecode payloads.
- **Test Files:**
  ```bash
  surfaces/
  ├── hello.cbs  # Prints "Hello, Codebook!"
  └── button.cbs # Simulation of a button surface
  ```
- **Semantic Surfaces:** Surfaces are spatial, energy-budgeted tokens. The toolchain preserves metadata like (x,y) coordinates and energy budgets.

---

# CodebookOS x86_64 — Phase 1 (UEFI)

**Pure NASM UEFI boot. Zero C. Zero dependencies. Every byte is ours.**

## Build & Test

```bash
./build.sh
./test_qemu.sh
```

---

# Codebook OS: CBS Toolchain (Phase 7)

### Pure CBS Toolchain
As of **v3.5-pure-cbs-toolchain**, Codebook OS uses a **fully CBS-native toolchain**:
- **Compilation & Execution**: `python cbsc.cbs surfaces/hello.cbs` (Compiles and runs in one step).
- **Surface Execution**: Handled by integrated logic in `cbsc.cbs` (derived from `tools/vm.cbs`).
- **Energy Budgeting**: Enforced during execution.
- **Post-Surveillance**: Surfaces are revoked on invalid checksums or explicit commands.

**Usage:**
```bash
# Compile and run a .cbs surface
python cbsc.cbs surfaces/hello.cbs
```

### Expected Output
- `surfaces/hello.cb` is created.
- Terminal prints: `Compiled surfaces/hello.cbs to surfaces/hello.cb`
- VM outputs: `Hello, Codebook!`

### Toolchain Dependencies (Python-Free Execution)
| Tool | Language | Purpose |
|------|----------|---------|
| `cbsc.cbs` | CBS / Python | Driver: Compiles and runs surfaces natively. |
| `tools/vm.cbs` | CBS | VM Logic: Executes surface tokens with energy budgeting. |
| `tools/read_file.cbs` | CBS | Logic: Reads `.cbs`/`.cb` files. |
| `tools/write_file.cbs` | CBS | Logic: Writes `.cb` files. |

**Note:** Python is only used as a host for the CBS drivers during development. `runtime.py` has been fully removed.

### Deprecation Notes
| File | Status | Replaced By |
|------|--------|-------------|
| `runtime.py` | ❌ Deleted | `cbsc.cbs` (Integrated VM) |
| `read_file.py` | ❌ Deleted | `tools/read_file.cbs` |
| `write_file.py` | ❌ Deleted | `tools/write_file.cbs` |
| `bootstrap.py` | ❌ Deleted | `cbsc.cbs` |

### Future Work
- Rewrite the host driver (`cbsc.cbs`) entirely in CBS (self-hosting).
- Add full SHA-256 quantum-resistant checksum implementation.
- Implement the semantic filesystem (`Morla`) on bare metal.

### Troubleshooting
- **Error: "File not found"**
  Ensure paths are relative (e.g., `surfaces/hello.cbs`).
- **VM crashes**
  Check that `cbsc.cbs` generates valid 23-byte headers and correct opcodes.
- **Silent failures**
  Verify energy budgets and checksum placeholders (`0xCAFEBABE`).

---

StableTech Enterprises LLC  
Randolph Pelican III  
Atreyu named it.
