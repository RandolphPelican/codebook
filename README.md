# Codebook OS

---
## Context
- **CBS ASM VM:** The bytecode is executed natively by the CBS toolchain (`cbsc.cbs` calling `tools/vm.cbs`). The VM expects a 23-byte surface token header followed by bytecode payloads.
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

# Codebook OS: CBS Compiler (Phase 7)

### Pure CBS Toolchain
As of **v3.4-vm-cbsc-integration**, the CBS toolchain is fully integrated. `cbsc.cbs` handles both compilation and native execution via the CBS ASM VM.

**Usage:**
```bash
# Compile and run a .cbs surface in one step
python cbsc.cbs surfaces/hello.cbs
```

### Expected Output
- `surfaces/hello.cb` is created.
- Terminal prints: `Compiled surfaces/hello.cbs to surfaces/hello.cb`
- VM outputs: `Hello, Codebook!`

### Toolchain Dependencies
| Tool | Language | Purpose |
|------|----------|---------|
| `cbsc.cbs` | CBS / Python | Driver: Compiles `.cbs` to `.cb` and runs in `vm.cbs`. |
| `tools/vm.cbs` | CBS | VM Logic: Executes surface tokens with energy budgeting. |
| `tools/read_file.cbs` | CBS | Logic: Reads `.cbs`/`.cb` files. |
| `tools/write_file.cbs` | CBS | Logic: Writes `.cb` files. |

**Note:** Python is used only as a host for the `cbsc.cbs` and `vm.cbs` logic during development.

### Deprecation Notes
- `runtime.py` is **deprecated** and replaced by the integrated logic in `cbsc.cbs` (derived from `tools/vm.cbs`).
- All Python file I/O wrappers have been removed.

### Future Work
- Rewrite the driver (`cbsc.cbs`) entirely in CBS (bootstrapping).
- Add full SHA-256 quantum-resistant checksum implementation.
- Implement the semantic filesystem (`Morla`) on bare metal.

---

StableTech Enterprises LLC  
Randolph Pelican III  
Atreyu named it.
