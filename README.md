# Codebook OS

## Where to start

- **[RECONSTITUTION.md](RECONSTITUTION.md)** — current architecture (layers, types, pod arc)
- **[ARCHAEOLOGY.md](ARCHAEOLOGY.md)** / **[ARCHAEOLOGY_REPO_RECORD.md](ARCHAEOLOGY_REPO_RECORD.md)** — project history
- **[RECON_PROTOCOL.md](RECON_PROTOCOL.md)** — verify-before-build discipline
- **[ROADMAP.md](ROADMAP.md)** — 14-week calendar, surfaces, pricing
- **[DEFERRED.md](DEFERRED.md)** — known gaps logged for future pods
- `prompts/` — pod-by-pod build prompts
- `recon/` — recon reports from each pod

---
## Context
- **CBS ASM VM:** The bytecode is executed natively by the CBS toolchain (`tools/cbsc.cbs` calling internal VM logic derived from `tools/vm.cbs`). The VM expects a 23-byte surface token header followed by bytecode payloads.
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

# Codebook OS: CBS Toolchain (Phase 8)

### Pure CBS Toolchain
As of **v4.0-reorganized-structure**, the CBS toolchain is organized for Codebook OS v1.0. `tools/cbsc.cbs` is the central driver for compilation and native execution.

**Usage:**
```bash
# Compile and run a .cbs surface
python tools/cbsc.cbs hello.cbs
# OR
python tools/cbsc.cbs surfaces/hello.cbs
```

### Expected Output
- `surfaces/hello.cb` is created.
- Terminal prints: `Compiled surfaces/hello.cbs to hello.cb`
- VM outputs: `Hello, Codebook!`

### Toolchain Dependencies (Python-Free Execution)
| Tool | Language | Purpose |
|------|----------|---------|
| `tools/cbsc.cbs` | CBS / Python | Driver: Compiles and runs surfaces natively. |
| `tools/vm.cbs` | CBS | VM Logic: Executes surface tokens with energy budgeting. |
| `tools/read_file.cbs` | CBS | Logic: Reads `.cbs`/`.cb` files. |
| `tools/write_file.cbs` | CBS | Logic: Writes `.cb` files. |

**Note:** Python is used only as a host for the CBS drivers during development.

### Deprecation Notes
| File | Status | Replaced By |
|------|--------|-------------|
| `runtime.py` | ❌ Deleted | `tools/cbsc.cbs` (Integrated VM) |
| `cbsc.cbs` (root) | ❌ Moved | `tools/cbsc.cbs` |

---

StableTech Enterprises LLC  
Randolph Pelican III  
Atreyu named it.
