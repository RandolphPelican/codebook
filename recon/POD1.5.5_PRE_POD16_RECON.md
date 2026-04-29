# Pod 1.5.5 — Pre-Pod-1.6 Architect Orientation Recon

**Date:** 2026-04-28
**Pod:** 1.5.5 (recon-only, no source changes)
**Author:** Terminal Boy (Claude)
**Entry contract:** `32d404ed779fbc3ea9a06d44c0f3e7b801b8a04db7f67d9e549a12964344c0c6` (preserved — no source changes)
**Predecessor:** Pod 1.5 (64-bit integer width migration)
**Successor:** Pod 1.6 prompt drafting (Sign as typed primitive)

---

## Section 1 — Sweep Findings

### Sweep A — File Inventory

**Scope:** `boot/`, `drivers/`, `surfaces/`, `tools/`, `recon/`, `prompts/`, repo root.

#### boot/ (20 files)

| File | Size | Modified |
|------|------|----------|
| atreyu.cbc | 777 B | Apr 28 01:18 |
| atreyu.cbs | 1,563 B | Apr 2 13:38 |
| auryn.asm | 3,787 B | Apr 27 17:01 |
| bastian.asm | 8,929 B | Apr 27 16:16 |
| bastian.cbc | 197 B | Apr 28 01:18 |
| bastian.cbs | 277 B | Apr 2 13:38 |
| boot.asm | 10,169 B | Apr 27 11:24 |
| cbs_vm.asm | 18,123 B | Apr 28 01:06 |
| data.asm | 21,919 B | Apr 28 01:09 |
| defines.asm | 2,516 B | Apr 27 11:24 |
| demo.cbc | 457 B | Apr 28 01:17 |
| demo.cbs | 296 B | Apr 2 13:38 |
| gmork.asm | 3,178 B | Apr 28 01:07 |
| gmork_cmds.asm | 10,945 B | Apr 28 01:07 |
| morla.asm | 5,370 B | Apr 27 17:01 |
| rockbiter.cbc | 258 B | Apr 28 01:18 |
| rockbiter.cbs | 462 B | Apr 2 13:38 |
| vmdata.asm | 797 B | Apr 28 01:07 |

#### drivers/ (3 files + _future/)

| File | Size | Modified |
|------|------|----------|
| fat32.asm | 16,011 B | Apr 27 16:24 |
| ide_pio.asm | 8,155 B | Apr 27 16:24 |
| kbd_ps2.asm | 3,868 B | Apr 27 16:24 |

#### drivers/_future/ (2 files)

| File | Size | Modified |
|------|------|----------|
| fat32_write.asm | 17,847 B | Apr 27 16:25 |
| gpu_intel.asm | 5,192 B | Apr 27 16:25 |

#### kernel/_future/ (2 files)

| File | Size | Modified |
|------|------|----------|
| cap_graph.asm | 7,046 B | Apr 23 03:27 |
| paging.asm | 4,983 B | Apr 23 03:27 |

#### surfaces/ (13 files)

| File | Size |
|------|------|
| button.cb | 25 B |
| button.cbs | 49 B |
| cb_compiler.cbs | 752 B |
| compiler.cbs | 3,791 B |
| compiler_main.cbs | 395 B |
| hello.cb | 25 B |
| hello.cbs | 64 B |
| hello.cbs.txt | 64 B |
| lexer.cbs | 2,863 B |
| lexer_main.cbs | 314 B |
| parser.cbs | 3,908 B |
| parser_main.cbs | 314 B |

#### tools/ (17 files)

| File | Size | Modified |
|------|------|----------|
| atreyu_x86.py | 8,942 B | Apr 28 01:17 |
| audit_uefi_calls.sh | 1,018 B | Apr 3 13:34 |
| cbsc.cb | 25 B | Apr 3 00:39 |
| cbsc.cbs | 5,381 B | Apr 3 14:05 |
| chauncey_test.md | 2,355 B | Apr 3 13:37 |
| compile_x86.py | 21,327 B | Apr 2 13:38 |
| parser.py | 10,995 B | Apr 2 13:38 |
| precompile_all.sh | 651 B | Apr 3 13:14 |
| precompile_compiler.sh | 343 B | Apr 3 13:24 |
| precompile_lexer.sh | 236 B | Apr 3 13:18 |
| precompile_parser.sh | 244 B | Apr 3 13:21 |
| read_file.cbs | 338 B | Apr 3 00:15 |
| verify_binary.sh | 891 B | Apr 27 11:16 |
| vm.cbs | 6,700 B | Apr 3 00:29 |
| write_file.cbs | 426 B | Apr 3 00:15 |

#### recon/ (10 files)

| File | Lines | sha256 |
|------|-------|--------|
| POD0.2.5_RECON_REPORT.md | 380 | c7fdff5a... |
| POD0.9_CAP_GRAPH_DEEP_READ.md | 444 | 3bbe6618... |
| POD1.0_BACKFILL_RECON_REPORT.md | 159 | c2389ab4... |
| POD1.1_VM_AUDIT.md | 737 | 347ec2fe... |
| POD1.2_DECISION_RECORD.md | 179 | 57a9445f... |
| POD1.3_OP_RET_RECON.md | 468 | a17df041... |
| POD1.4_DECISION_RECORD.md | 127 | eec03780... |
| POD1.5_RECON_REPORT.md | 483 | c1ebef6f... |
| POD1.5_VERIFICATION.md | 114 | ae6f5faa... |

#### prompts/ (14 files)

| File | Lines | sha256 |
|------|-------|--------|
| POD0.0_REFERENCE_LOCK.md | 294 | be68552a... |
| POD0.1_DEFINES_EXTRACT.md | 68 | ef832128... |
| POD0.2.5_RECON_PASS.md | 73 | 5c1a8095... |
| POD0.2_AURYN_EXTRACT.md | 74 | f99718ee... |
| POD0.3_CLEANUP.md | 323 | 505b915c... |
| POD0.3_MORLA_EXTRACT.md | 52 | e5c49816... |
| POD0.5_HEADER_POLISH.md | 84 | eaf4393a... |
| POD0.6_DRIVERS_DATA.md | 87 | bb211665... |
| POD0.7_AURYN_PUTS_CONSOLIDATION.md | 87 | 4e63d6b1... |
| POD0.8_FOUNDATION_SIGNOFF.md | 90 | eccc7f9e... |
| POD0_ORIGINAL_MONOLITH.md | 420 | 2322d10a... |
| POD1.5_INTEGER_WIDTH_64.md | 50 | f1b8acb5... |
| README.md | 26 | c1d7d4ce... |

#### Repo root (notable)

| File | Size |
|------|------|
| RECONSTITUTION.md | 18,791 B |
| RECON_PROTOCOL.md | 12,242 B |
| DEFERRED.md | 6,242 B |
| ARCHAEOLOGY.md | 33,654 B |
| ARCHAEOLOGY_REPO_RECORD.md | 8,963 B |
| binary_contracts.md | 1,291 B |
| ROADMAP.md | 6,772 B |
| README.md | 2,640 B |
| build.sh | 3,013 B |

---

### Sweep B — Symbol Inventory (boot/*.asm)

#### boot/cbs_vm.asm — Labels

Single global entry point: `cbs_run` (line 33). All other labels are
`.local` prefixed:

| Label | Line | Purpose |
|-------|------|---------|
| `cbs_run` | 33 | VM entry point |
| `.fetch` | 48 | Main dispatch loop |
| `.fatigue` | 129 | Energy exhaustion handler |
| `.op_push` | 135 | PUSH imm64 |
| `.op_add` | 143 | ADD |
| `.op_sub` | 153 | SUB |
| `.op_mul` | 163 | MUL |
| `.op_mod` | 173 | MOD |
| `.mod_zero` | 185 | MOD zero-divisor |
| `.op_div` | 190 | DIV |
| `.div_zero` | 202 | DIV zero-divisor |
| `.op_eq` | 208 | EQ |
| `.op_ne` | 220 | NE |
| `.op_lt` | 232 | LT |
| `.op_gt` | 244 | GT |
| `.op_le` | 256 | LE |
| `.op_ge` | 268 | GE |
| `.op_reserve` | 281 | RESERVE energy |
| `.reserve_fail` | 297 | Reserve failure |
| `.skip_to_end` | 301 | Skip scanner |
| `.skip8` | 326 | Skip 8-byte operand |
| `.skip4` | 329 | Skip 4-byte operand |
| `.skip_str` | 332 | Skip string operand |
| `.op_ret` | 348 | Subroutine return |
| `.ret_underflow` | 360 | Return stack underflow |
| `.op_jif` | 366 | Jump if false |
| `.op_jback` | 377 | Jump backward |
| `.op_load` | 384 | Load variable |
| `.op_store` | 394 | Store variable |
| `.op_grant_cap` | 403 | Grant capability token |
| `.cap_atreyu` | 414 | Dead Atreyu cap handler |
| `.atreyu_get_size` | 429 | Dead |
| `.atreyu_set_size` | 435 | Dead |
| `.atreyu_get_char` | 441 | Dead |
| `.atreyu_set_char` | 450 | Dead |
| `.atreyu_insert` | 459 | Dead |
| `.atreyu_ins_loop` | 469 | Dead |
| `.atreyu_ins_done` | 476 | Dead |
| `.atreyu_delete` | 481 | Dead |
| `.atreyu_del_loop` | 488 | Dead |
| `.atreyu_del_done` | 497 | Dead |
| `.cap_rockbiter` | 501 | Rockbiter cap handler |
| `.get_energy_budget` | 507 | |
| `.get_energy_used` | 512 | |
| `.op_use_cap` | 518 | Use capability token |
| `.cap_auryn` | 543 | Auryn cap handler |
| `.auryn_putc` | 549 | |
| `.auryn_fill` | 554 | |
| `.cap_conin` | 560 | Console input cap handler |
| `.conin_read` | 564 | |
| `.conin_none` | 572 | |
| `.cap_morla` | 577 | Morla FS cap handler |
| `.morla_ls` | 583 | |
| `.morla_write` | 586 | |
| `.op_print_num` | 598 | Print number |
| `.op_emit` | 604 | Emit character |
| `.op_newline` | 610 | Newline |
| `.op_dup` | 616 | Duplicate TOS |
| `.op_drop` | 622 | Drop TOS |
| `.op_swap` | 626 | Swap top two |
| `.op_call` | 637 | Call subroutine |
| `.call_overflow` | 655 | Return stack overflow |
| `.op_dup2` | 660 | DUP2 (NOT dispatched) |
| `.op_jmp` | 669 | Unconditional jump |
| `.op_push_str` | 678 | Push string |
| `.ps_nopad` | 693 | |
| `.op_print_str` | 696 | Print string |
| `.pstr_loop` | 703 | |
| `.pstr_done` | 711 | |
| `.op_halt` | 715 | HALT |
| `.done` | 719 | Shared exit path |

**Dispatch chain:** 31 opcodes dispatched (lines 57–118). `OP_DUP2`
handler exists at line 660 but is NOT in the dispatch chain — known
orphan (DEFERRED #6).

#### boot/defines.asm — All symbols

UEFI/PE constants (lines 7–45), color constants (lines 47–53),
then CBS VM opcodes (lines 55–89):

| Define | Value | Status |
|--------|-------|--------|
| OP_PUSH | 0x01 | Dispatched |
| OP_PUSH_STR | 0x02 | Dispatched |
| OP_ADD | 0x10 | Dispatched |
| OP_SUB | 0x11 | Dispatched |
| OP_MUL | 0x12 | Dispatched |
| OP_DIV | 0x13 | Dispatched |
| OP_EQ | 0x14 | Dispatched |
| OP_NE | 0x15 | Dispatched |
| OP_LT | 0x16 | Dispatched |
| OP_GT | 0x17 | Dispatched |
| OP_LE | 0x18 | Dispatched |
| OP_GE | 0x19 | Dispatched |
| OP_MOD | 0x1A | Dispatched |
| OP_RESERVE | 0x20 | Dispatched |
| OP_JMP | 0x40 | Dispatched |
| OP_CALL | 0x50 | Dispatched |
| OP_RET | 0x53 | Dispatched |
| OP_JIF | 0x55 | Dispatched |
| OP_JBACK | 0x56 | Dispatched |
| OP_LOAD | 0x70 | Dispatched |
| OP_STORE | 0x71 | Dispatched |
| OP_PRINT_NUM | 0x80 | Dispatched |
| OP_EMIT | 0x81 | Dispatched |
| OP_NEWLINE | 0x82 | Dispatched |
| OP_DUP | 0x83 | Dispatched |
| OP_DROP | 0x84 | Dispatched |
| OP_SWAP | 0x85 | Dispatched |
| OP_PRINT_STR | 0x86 | Dispatched |
| OP_DUP2 | 0x87 | **ORPHANED** — handler exists, not dispatched |
| OP_GRANT_CAP | 0x90 | Dispatched |
| OP_USE_CAP | 0x91 | Dispatched |
| OP_HALT | 0xFF | Dispatched |
| OP_GRANT_CAP_NEW | 0xCA000003 | **Ghost** — cap token constant, not opcode |
| OP_USE_CAP_NEW | 0xCA000004 | **Ghost** — cap token constant, not opcode |

**Free opcode ranges for typed-primitive work (Pod 1.6 target: 0xA0–0xAF):**

| Range | Slots | Notes |
|-------|-------|-------|
| 0x03–0x0F | 13 | Near PUSH |
| 0x1B–0x1F | 5 | After arithmetic |
| 0x21–0x3F | 31 | After RESERVE |
| 0x41–0x4F | 15 | After JMP |
| 0x51–0x52, 0x54, 0x57–0x6F | 27 | Scattered flow control |
| 0x72–0x7F | 14 | After LOAD/STORE |
| 0x88–0x8F | 8 | After DUP2 |
| 0x92–0x9F | 14 | After USE_CAP |
| 0xA0–0xEF | **80** | **Typed primitives (allocated in v5)** |
| 0xF0–0xFE | 15 | Reserved for expansion |

---

### Sweep C — Cross-Module Dependencies

References to cemetery directories from live code:

| Source | Reference | Type |
|--------|-----------|------|
| `boot/boot.asm:258` | `exiled to drivers/_future/ and kernel/_future/` | Comment only |
| `boot/cbs_vm.asm:26` | `kernel/_future/cap_graph.asm` | Comment only |
| `boot/morla.asm:61` | `drivers/_future/fat32_write.asm` | Comment only |
| `drivers/fat32.asm:10` | `drivers/_future/fat32_write.asm` | Comment only |
| `drivers/fat32.asm:12` | `fat32_write` | Comment only |
| `tools/chauncey_test.md:44` | `gpu_intel.asm` | Test doc reference |

**No code-level (non-comment) references to cemetery files from live build.**

---

### Sweep D — Unexpected Directories

Top-level directories:

```
boot/
build/
drivers/
kernel/
prompts/
recon/
surfaces/
tools/
```

Plus `.claude/` and `.git/`. All expected. No unexpected directories.

---

### Sweep E — Last 30 Commits + Deleted Files

#### Last 30 commits on origin/main (verbatim)

```
e6a2cc2 Pod 1.5: 64-bit integer width migration — runtime, toolchain, bytecode
eabf160 Pod 1.5: Phase 1 recon report (R1-R12)
7a825f2 Pod 1.4: RECONSTITUTION v5 — width-migration decisions, VM fixes retroactive, arc slide
ed5c68a Pod 1.3: OP_RET wired to vm_ret_stack; OP_HALT pre-existed
e69f51f Pod 1.2: RECONSTITUTION v4 — VM audit decisions canonized
6d47237 Pod 1.1: VM substrate audit
b30860e Pod 1.0: backfill prompts/ for Pod 0 history
a26b173 pod0.9: canon updates - RECONSTITUTION v3 with Cap<R> spatial-merge + DEFERRED items 9-10
0ab996c pod0.9: cap_graph + paging deep-read memo for Pod 1 design
d68167c pod0.8: doc-vs-code reconciliation + deferred tasks
4ff12d8 pod0.7: consolidate auryn_puts from morla.asm into auryn.asm
e6d41b3 pod0.6b: data.asm header + section markers
fbb8ba3 pod0.6a: drivers/ header polish + _future/ standardization
9f86040 pod0.5: header polish across five remaining boot/ modules
50b2b4a pod0.3: repo cleanup — delete cruft, prune branches, harden gitignore
8a04b16 pod0.4: replace RECONSTITUTION.md with v2 (was missed in prior commit)
eddd8e7 pod0.3 prompt: repo cleanup task ready for terminal boy
a521db2 pod0.4: canon updates from Pod 0.2.5 recon - RECONSTITUTION v2 + Repo Record
7facf2a pod0.2.5: repo-wide archaeology pass
f1b223a pod0.2.5: add RECON_PROTOCOL.md — verify-before-build canon
4489d01 pod0.2: extract auryn.asm — framebuffer renderer
4f02dcd pod0.1: extract defines.asm
e2f5db8 pod0.0: foundation lock — canonical docs + reference binary
e154bb5 pod0.0 setup: canonical docs + reference lock prompt
1dff7e9 feat(bastian): arrow-nav dispatch wired to all 12 surfaces in bastian_main
a031226 feat(bastian): 12-slot menu with themed coming-soon cards; gmork screen-clear
8c90d18 chore: add .gitignore; remove tracked __pycache__ artifacts
df07659 release(v1.0-pre): close week 1 -- clean build + QEMU test + ROADMAP
d8eedd2 fix(shell): stub V1.1 call sites -- fat32_write_file, parse_filename, vm_run_compiler
b0fe54d fix(kernel): exile gpu_intel/paging/cap_graph to _future/, stub call sites
```

#### Deleted files (full repo history)

```
__pycache__/compiler.cpython-314.pyc  — deleted in 8c90d18
__pycache__/lexer.cpython-314.pyc     — deleted in 8c90d18
__pycache__/parser.cpython-314.pyc    — deleted in 8c90d18
runtime.py                            — deleted in eba2c61
surfaces/cb_compiler.cb               — deleted in eba2c61
surfaces/test.cb                      — deleted in eba2c61
bootstrap.py                          — deleted in 977a0b5
read_file.py                          — deleted in 977a0b5
write_file.py                         — deleted in 977a0b5
boot/demo.cbc                         — deleted in b65b4eb (recreated later)
```

All deletions are from pre-pod-system history. No files deleted in pod history.

---

### Sweep F — Markdown Inventory

Full inventory with filename, first 5 lines, line count, and sha256
for all `.md` files in repo root + `recon/` + `prompts/`.

| File | Lines | sha256 |
|------|-------|--------|
| ARCHAEOLOGY.md | 468 | 8bb285414a6ee403aed95d01509dcdfc14bc7a9c0e09c2ac35201569696d73dd |
| ARCHAEOLOGY_REPO_RECORD.md | 198 | cfc77c08a1c64832b73dfd2782bae8174e82e1379c36ed0c012b197de9df62f4 |
| DEFERRED.md | 137 | b82e077451042ee0ca74aa9b9c57634efb861a0595b0821337246478db5d3dfb |
| README.md | 77 | fbf8b0459779c98d1acd64c61a623d7b99087a8b1f1891c51e47b2aca6c87145 |
| RECONSTITUTION.md | 406 | 48fc60a8f263ba7fd320c4ffb7ee99a542491507bea6ec45953b7d76d8f5839c |
| RECON_PROTOCOL.md | 336 | 9105a62abc5decbb4a8e9a8c33c25806f863a728aa514db2634d83c5101f03bd |
| ROADMAP.md | 181 | d51aba2059f429995a0d5139b80d60ae0588d888b3fdbece99f5d230f66c4a77 |
| binary_contracts.md | 19 | e03fa9b31d837952730a2747deb8600be7e4aaaf8e7feda19d24ab3341373870 |
| recon/POD0.2.5_RECON_REPORT.md | 380 | c7fdff5ad32a34971f35632d4f28416fb05d35cd6b3c140a00268994313ce5a4 |
| recon/POD0.9_CAP_GRAPH_DEEP_READ.md | 444 | 3bbe66189a39c77d38cbb88d71a7797a0c315ecaf22578a709ed50ba32cf2a5e |
| recon/POD1.0_BACKFILL_RECON_REPORT.md | 159 | c2389ab429992eacf7b424305f0819ad2b77165762d1486a4593ab46645924bf |
| recon/POD1.1_VM_AUDIT.md | 737 | 347ec2fe96c3dc1538cda89d59db69d4ef9c6e36981e659eea32040fe9678bfc |
| recon/POD1.2_DECISION_RECORD.md | 179 | 57a9445f45cfc283e0af9e288facd2240b7289c5765537c8befd071f8072c206 |
| recon/POD1.3_OP_RET_RECON.md | 468 | a17df041ad7ed8b7a30259ff3be863926d35a5184dfff0c20b616d6c5e418b4a |
| recon/POD1.4_DECISION_RECORD.md | 127 | eec037800a62b2b465b211e08c0bfc94930279bb509efe6e0a6972e196dc2f11 |
| recon/POD1.5_RECON_REPORT.md | 483 | c1ebef6faea664ee7925071074c1bac758034ed5e8077fefc3c3163e7f107a23 |
| recon/POD1.5_VERIFICATION.md | 114 | ae6f5faa1c53d5169b65b6c870c64a54bb749eddb952acbc0df02a72ce258a44 |
| prompts/POD0.0_REFERENCE_LOCK.md | 294 | be68552a35577d075a3eb3adfc7c2ddd316fecb867e5f26b544b2eaf86580317 |
| prompts/POD0.1_DEFINES_EXTRACT.md | 68 | ef8321284cc8feaea7254153d33ea676ffad1bfa79b939e2a7ee978970922260 |
| prompts/POD0.2.5_RECON_PASS.md | 73 | 5c1a8095c971e8c780d9f5c372dcc366c0cdf02eda8ddd04794ae25d7ac5cb20 |
| prompts/POD0.2_AURYN_EXTRACT.md | 74 | f99718ee2b1e0a678e4759ce487a06e9051dccb0670f519e58842e4bb9d62e7c |
| prompts/POD0.3_CLEANUP.md | 323 | 505b915cd9283b7c6cfa0e0e2cb949d5ef1ce8dd6d6f169309b26d8e8092aea1 |
| prompts/POD0.3_MORLA_EXTRACT.md | 52 | e5c49816626279ddf99081958c00ddf9f8c8894288520f54c44d3ec1a0d51e12 |
| prompts/POD0.5_HEADER_POLISH.md | 84 | eaf4393a68f64e4771acc53e9254568acf2fcfa38c2d5dbbbfebe4a348d7d487 |
| prompts/POD0.6_DRIVERS_DATA.md | 87 | bb21166530fa8865e958035a575904af0a00f28dd3cb928585cd78b066320d69 |
| prompts/POD0.7_AURYN_PUTS_CONSOLIDATION.md | 87 | 4e63d6b1b86501b86231b1f3c881dcdeff6be55094aafa9d9ee2600f7eaa5d67 |
| prompts/POD0.8_FOUNDATION_SIGNOFF.md | 90 | eccc7f9eb2caf83a6d40dbd53dfa817e21c344c845d7fdc030ab652bdb7eb615 |
| prompts/POD0_ORIGINAL_MONOLITH.md | 420 | 2322d10aad18b41fc532dc0cb6f4e00d11823844feb3596b4d29cdbf278a7b24 |
| prompts/POD1.5_INTEGER_WIDTH_64.md | 50 | f1b8acb5ef097e471ebec03ec3e87aaa593e1d1018131f18f64138820d1f48b9 |
| prompts/README.md | 26 | c1d7d4ce159b39a4b3fd1e8f84ba002e2c5fedc8d095d4dfe70398e571869ff6 |

---

### Sweep G — Cemetery Verification

#### kernel/_future/

| File | Lines | sha256 | Pod 0.9 baseline |
|------|-------|--------|------------------|
| cap_graph.asm | 204 | 0ebe51044758925927a32f9feaf461442c1804c07a18a5347f46b3704edece1a | 204 lines — **MATCH** |
| paging.asm | 156 | 527fc2b712b4519e58cfb013bdbd759af114536f4ca0832494182aa1103159f7 | 156 lines — **MATCH** |

#### drivers/_future/

| File | Lines | sha256 |
|------|-------|--------|
| fat32_write.asm | 629 | fd623ad7da79489a1be5a407c0b490a32e068ca8a5745a2ee2faaab7adbdc733 |
| gpu_intel.asm | 156 | 04bce150272f8976ed777728ec77c4976d8338f8a0aad77798894004fd70c8e5 |

**No divergence from Pod 0.9 baseline.** Line counts match. Files are
untouched since exile.

---

## Section 2 — Surprises

### S1 — RECONSTITUTION v5 pod arc shows Pod 1.5 as `[planned]`

**What:** RECONSTITUTION.md line 357 reads:
`├── 1.5  64-bit integer width migration                    [planned — VM fixes]`
But Pod 1.5 is complete — commit e6a2cc2.

**Where:** `RECONSTITUTION.md:357`

**Possible significance for Pod 1.6:** The Pod 1.6 prompt will reference
RECONSTITUTION.md as the architecture canon. A stale `[planned]` status
for the predecessor pod could cause confusion about what state the VM is
actually in. Recommend: Pod 1.6 prompt should either update RECONSTITUTION
v5's pod arc to mark 1.5 as DONE, or a v6 canon update pod should run
first.

### S2 — Pod 1.2 decision record has pre-arc-slide pod numbers

**What:** `recon/POD1.2_DECISION_RECORD.md` Q5 references Sign at Pod 1.5,
Energy at Pod 1.6, Cap<R> at Pod 1.8–1.9, Outcome at Pod 1.7, Demod at
Pod 1.10. RECONSTITUTION v5 (which applied the arc slide) uses Sign at
1.6, Energy at 1.7, Outcome at 1.8, Cap<R> at 1.9–1.10, Demod at 1.11.

**Where:** `recon/POD1.2_DECISION_RECORD.md:94–98`

**Possible significance for Pod 1.6:** Not a functional issue — the
decision record is historical, and RECONSTITUTION v5 is the authority.
But a reader checking cross-references could be confused. No action
needed unless the architect wants to annotate the decision record.

### S3 — atreyu_x86.py OP_PUSH comment says "push i32"

**What:** `tools/atreyu_x86.py` line 9 says `OP_PUSH = 0x01  # push i32`
but after Pod 1.5, OP_PUSH operands are 8-byte (i64). The code correctly
uses `emit_i64`, but the comment is stale.

**Where:** `tools/atreyu_x86.py:9`

**Possible significance for Pod 1.6:** If Pod 1.6 modifies the toolchain
to emit Sign-construction opcodes, a contributor reading the comments
could incorrectly assume OP_PUSH is still 4-byte.

### S4 — OP_GRANT_CAP uses `add eax` (32-bit) in a 64-bit VM

**What:** `boot/cbs_vm.asm:408` uses `add eax, 0xCA000000` — a 32-bit
register operation. After Pod 1.5's widening to 64-bit, this is the only
arithmetic site still using `eax` instead of `rax`. Not a functional bug
(zero-extension is correct for cap tokens ≤ 0xCA000004, and the result
is stored via `mov [r13], rax` which reads the full zero-extended value),
but it is inconsistent with the widening discipline.

**Where:** `boot/cbs_vm.asm:408`

**Possible significance for Pod 1.6:** None directly — cap ops are
retired in Pod 1.10. But the inconsistency is worth noting for
completeness.

### S5 — No prompts for Pods 0.9, 1.0, 1.1, 1.2, 1.3, 1.4

**What:** `prompts/` contains Pod 0.0–0.8 and Pod 1.5 prompts. Pods
0.9, 1.0, 1.1, 1.2, 1.3, and 1.4 have no preserved prompts.

**Where:** `prompts/`

**Possible significance for Pod 1.6:** The pod prompt noted this as
a "housekeeping pod candidate." Not blocking.

### S6 — `recon/MEMO_VERIFICATION_PROVENANCE.md` does not exist

**What:** The Pod 1.5.5 prompt references
`recon/MEMO_VERIFICATION_PROVENANCE.md` as a companion document.
This file does not exist in the repository. It appears to be a
conversation-context-only document from the architect.

**Where:** Not in repo.

**Possible significance for Pod 1.6:** If the memo contains provenance
rules that the Pod 1.6 prompt should follow, those rules need to be
either committed or restated in the prompt.

### Summary

Six surprises found. None are blocking. S1 (stale pod arc status) is the
most relevant for Pod 1.6 prompt drafting. Zero surprises related to:
- Cemetery divergence (none — all files unchanged)
- Unhandled opcodes beyond known orphans (none)
- DEFERRED items resolved without strikethrough (none — #12 has strikethrough)
- Commits since Pod 1.5 seal (none — HEAD is e6a2cc2)
- Unexpected toolchain capabilities (none beyond what handoff named)

---

## Section 3 — Architect Questions

### AQ1 — Should RECONSTITUTION.md v5 pod arc be updated before Pod 1.6?

Pod 1.5 is shown as `[planned — VM fixes]` but is complete (commit
e6a2cc2). Should the Pod 1.6 prompt include a canon-update step to
mark Pod 1.5 as DONE in the pod arc, or should a separate mini-pod
(1.5.6 or similar) run first?

### AQ2 — Should Pod 1.6 update atreyu_x86.py's stale comments?

The OP_PUSH comment says "push i32" but it's now i64. The toolchain
will be modified in Pod 1.6 for Sign opcode emission. Is comment
cleanup in scope for Pod 1.6, or should it be a separate item?

### AQ3 — What Sign opcodes does Pod 1.6 allocate from 0xA0–0xAF?

The opcode range is allocated (0xA0–0xAF, 16 slots). The architect
needs to specify which Sign operations map to which opcodes. At
minimum, Pod 1.6 needs:
- `OP_SIGN_NEW` — construct a Sign from content
- `OP_SIGN_HASH` — compute/push content_hash
- `OP_SIGN_LABEL` — set/get label
Possibly also: provenance chain ops, embedding ops, energy_cost read.
The toolchain must emit matching bytecode.

### AQ4 — What is Sign's data representation in VM memory?

RECONSTITUTION v5 defines the Sign struct abstractly (content_hash,
embedding, label, provenance, energy_cost). Pod 1.6 needs a concrete
layout:
- Fixed-size on the operand stack? (Too large — 32+64+64+?+8 bytes)
- Heap-allocated with a stack reference? (VM has no heap)
- Static pool like the cap_graph design? (64 nodes × N bytes)
- Inline in bytecode with stack handle?

The VM has no dynamic allocation. The Sign representation must work
within the static allocation model.

### AQ5 — Does Pod 1.6 need to wire OP_DUP2 into the dispatch chain?

`OP_DUP2` (0x87) has been orphaned since the Pod 1.1 audit. Its
handler exists and works. If Sign operations produce multi-slot values
(e.g., hash + label), `OP_DUP2` may be needed. Should Pod 1.6 wire
it, or leave it for later?

### AQ6 — MEMO_VERIFICATION_PROVENANCE.md: commit or restate?

The Pod 1.5.5 prompt references this as a companion document but it
does not exist in the repository. If it contains provenance rules
relevant to future pods, it should either be committed or its key
rules restated in the Pod 1.6 prompt.

---

## Section 3.1 — Architect Responses (folded post-recon)

The recon protocol's archaeology principle: questions and surprises
preserve their original framing, with architect dispositions appended
rather than rewriting Section 2 or Section 3. Section 3 holds TB's
questions as raised; Section 3.1 holds the architect's answers as
folded back at REVISED stage, before commit.

### AQ1 — RECONSTITUTION v5 pod arc shows Pod 1.5 as [planned]

Real bug, found by recon, exactly what the protocol exists to surface.
A separate mini-pod runs first: **Pod 1.5.6 — RECONSTITUTION v5
pod-arc status reconciliation + MEMO_VERIFICATION_PROVENANCE commit.**
Trivial scope: flip Pod 1.5 marker from `[planned]` to `[DONE —
e6a2cc2]` in RECONSTITUTION.md:357, and audit the rest of the pod-arc
block for any other stale `[planned]` markers on completed pods.
Canon-only. Preserved binary contract. Pod 1.6 enters with a clean v5
reflecting actual ground truth.

### AQ2 — atreyu_x86.py stale "push i32" comment

Out of scope for a standalone pod; fold into Pod 1.6 or its successor
source pod when the toolchain is already being touched for Sign
emission. Pod 1.6's canon-or-source prompt will instruct TB to fix
any stale width comments encountered while modifying the file, as
"if you're already there" cleanup. Don't spawn a separate pod for
one comment.

### AQ3 — Sign opcode allocation from 0xA0–0xAF

Core Pod 1.6 design question. Not answered from a recon report — it
earns the canon-then-source split. **Pod 1.6 will be canon-only:**
RECONSTITUTION v6 ratifying Sign struct layout, opcode allocation
across 0xA0–0xAF, construction model, validation timing, alignment
rule, and the energy_cost-vs-Pod-1.7 ordering question. **Pod 1.7
will be source:** implement the canon. The 1.2/1.3 and 1.4/1.5
precedent holds. Subsequent typed-primitive pods (Energy, Outcome,
Cap, Demod) renumber accordingly — a one-time slide, the kind v5
already absorbed once.

### AQ4 — Sign's VM memory representation

Same answer as AQ3 — canon-pod content for Pod 1.6, not recon-report
content. Section 2's tension is correctly framed: VM has no heap,
fixed-stack-slot is too small for the full struct, static pool is
the cap_graph precedent, inline-in-bytecode-with-stack-handle is
the dark horse. The handle pattern (stack carries an 8-byte sign_id;
real struct lives in a static signs pool sized analogously to the
cap pool's 64×128B = 8KB) is where architect instinct points but is
not committed from a chat reply. Pod 1.6 canon prompt will lay the
four options on a table with tradeoffs and ratify one.

### AQ5 — Wire OP_DUP2 into dispatch

Defer to Pod 1.6 (canon) when the multi-slot question is forced by
Sign return shape. If the handle pattern wins from AQ4, Sign
operations are single-slot and OP_DUP2 stays orphaned. If a
multi-slot return wins, OP_DUP2 wires up. Don't decide ahead of the
layout choice. DEFERRED #6 keeps tracking it.

### AQ6 — MEMO_VERIFICATION_PROVENANCE.md does not exist in repo

Architect failure: the Pod 1.5.5 prompt referenced the memo as if it
were committed canon when it lives only in architect-Chauncey's
context window from the previous-Chauncey handoff document. The
previous-Chauncey instance wrote the memo at Pod 1.5 closeout and
the file did not make it to disk before the thread ended.

**Resolution folded into Pod 1.5.6 scope (Part 2):** commit
`recon/MEMO_VERIFICATION_PROVENANCE.md` from the handoff document's
full text. The memo's authority derives from the previous instance's
direct experience of the failure mode; that authority transfers
cleanly when the file lands in the repo. Pod 1.6's prompt can then
reference it as committed canon, the way the Pod 1.5.5 prompt should
have but couldn't.

### S2 — Pod 1.2 decision record has pre-arc-slide pod numbers

Leave as-is. Decision records are historical by design — annotating
them rewrites history. Future readers chasing cross-references should
land on RECONSTITUTION v5 as authority, which is the discipline. An
optional one-line header note (`Note: pod numbering predates Pod
1.4's arc slide; RECONSTITUTION v5 holds current numbering.`) is an
acceptable Pod 1.5.6 rider but not required. Not blocking.

### S3 — atreyu_x86.py stale "push i32" comment

Handled via AQ2.

### S4 — OP_GRANT_CAP uses add eax (32-bit) in 64-bit VM

Correctly classified as cosmetic. Caps retire in Pod 1.10 and the
inconsistency vanishes when the whole code path goes. Tracked for
natural resolution in Pod 1.10 exile — no standalone pod needed.
See report addendum at end for forward-log entry.

### S5 — Missing prompts for Pods 0.9–1.4

Known housekeeping-pod candidate from the Pod 1.5 closeout handoff.
Not blocking. Runs as standalone backfill pod when prompt-archaeology
afternoon is convenient. No effect on Pod 1.6 sequencing.

---

### Forward-looking ledger — Pod 1.5.6 scope forecast

Per Pod 1.4 X11 forward-logging convention: canon pods that identify
follow-on work log it as a forward-looking entry with explicit
description, so the next pod can resolve by direct match rather than
re-derivation.

**Pod 1.5.6 — RECONSTITUTION v5 pod-arc reconciliation +
MEMO_VERIFICATION_PROVENANCE commit.** Two-part scope:

1. **Part 1 — Pod-arc status fix.** Edit `RECONSTITUTION.md:357`:
   change `├── 1.5  64-bit integer width migration [planned — VM
   fixes]` to `├── 1.5  64-bit integer width migration [DONE —
   e6a2cc2]`. Audit the remainder of the pod-arc block (lines
   ~340–385) for any other stale `[planned]` markers on completed
   pods (Pods 0.0–1.5). Apply same `[DONE — <hash>]` pattern using
   commit hashes from `git log --oneline` Sweep E output above.

2. **Part 2 — Commit MEMO_VERIFICATION_PROVENANCE.md.** Create
   `recon/MEMO_VERIFICATION_PROVENANCE.md` from the previous-Chauncey
   handoff document's full memo text. Architect supplies the verbatim
   text in the Pod 1.5.6 prompt. File is canonical and append-only
   per its own self-declaration; future revisions add failure-mode
   instances without overwriting the lesson.

Both parts canon-only, no source changes, preserved binary contract
(`32d404ed...c0c6`). When Pod 1.5.6 runs, this entry should match
its scope description directly and be marked `(RESOLVED — Pod
1.5.6)` per DEFERRED-ledger strikethrough convention applied to
recon report forward-logs.

---

## Section 4 — File Appendices

---

## R1 — RECONSTITUTION.md (v5)

```
# CodebookOS — RECONSTITUTION MANIFESTO (v5)

## Post-Pod-1.3 — VM Fixes Complete, Width Migration Canonized

**Project:** CodebookOS x86_64 UEFI
**Repo:** github.com/RandolphPelican/codebook
**Author:** Randolph Pelican III / StableTech Enterprises LLC
**Compiled by:** Chauncey (Claude)
**Compiled:** April 27, 2026 (v1)
**Updated:** April 27, 2026 (v2 — post-Pod-0.2.5 recon)
**Updated:** April 27, 2026 (v3 — post-Pod-0.9 cap_graph deep read)
**Updated:** April 27, 2026 (v4 — post-Pod-1.1 VM audit decisions)
**Updated:** April 27, 2026 (v5 — post-Pod-1.3 VM fixes, width-migration decisions)
**Companion to:** ARCHAEOLOGY.md, ARCHAEOLOGY_REPO_RECORD.md, RECON_PROTOCOL.md, recon/POD0.9_CAP_GRAPH_DEEP_READ.md, recon/POD1.1_VM_AUDIT.md, recon/POD1.2_DECISION_RECORD.md, recon/POD1.4_DECISION_RECORD.md
**Supersedes:** RECONSTITUTION.md v4

---

## Why v5 exists

v4 canonized eight architect decisions from Pod 1.1's VM substrate
audit. v5 records what happened next: Pod 1.3 executed the first
two VM fixes (OP_CALL/OP_RET semantics, OP_HALT already present),
and the architect made three width-migration decisions (D1/D2/D3)
that refine how 64-bit migration works. v5 also adds the
PAUSED-MID-EXECUTION protocol state to the recon canon, slides the
pod arc to thirteen sub-pods, and retroactively documents Pod 1.3's
implementation details.

See `recon/POD1.4_DECISION_RECORD.md` for the D1/D2/D3 rationale.

1. **VM semantics fixed (Pod 1.3 — complete).** `OP_RET` is now a
   subroutine return (pops `vm_ret_stack`). `OP_CALL` uses
   PC-relative signed offsets (was broken absolute addressing).
   `OP_HALT` (0xFF, pre-existing) exits the VM. `vm_ret_ptr` is
   reset in `cbs_run` prologue. All `.cbc` surface files patched
   from trailing `OP_RET` to `OP_HALT`.

2. **Width migration refined (D1/D2/D3).** CBS values widen to
   8 bytes; positional offsets (jump targets, call offsets) stay
   4-byte signed. Sign-extension (`movsxd`) is the default on
   widening. Python toolchain update is mandatory and atomic with
   runtime format changes. Width migration lands in Pod 1.5.

3. **Current cap ops replaced.** The VM's existing `OP_GRANT_CAP`
   (0x90) and `OP_USE_CAP` (0x91) are retired in Pod 1.10. Cap<R>
   typed primitives replace them entirely — the spatial-merge design
   from Pod 0.9 informs the replacement, but no current cap code
   survives.

4. **Opcode space allocated.** Typed primitives claim `0xA0–0xEF`
   (80 slots). Energy moves from per-fetch flat cost to per-opcode
   cost table in Pod 1.7. Stack bounds produce `Outcome<T>` errors
   in Pod 1.8.

5. **Pod 1 sub-pod arc expanded.** Thirteen sub-pods (1.0–1.12)
   with explicit sequencing. Pod 1.4 (this canon update) inserted
   after Pod 1.3, sliding all subsequent pods by one. Duration
   estimates removed from canon — pace is set by recon-protocol
   discipline, not by calendar.

The four-layer model is unchanged. Layer 1 gains implementation
detail from the completed VM fixes and the width-migration
decisions. The pod arc expands.

---

## The OS in one sentence (unchanged from v1)

CodebookOS is a federated cognitive organism running on a typed CBS substrate
on minimal bare-metal bootstrap, where capabilities are cryptographic, energy
is typed, signs are first-class, and the filesystem is a semantic codebook.

---

## The four layers (unchanged structure; Layer 1 enriched, Layer 0 paging note added)

### Layer 0 — Bootstrap (NASM, irreducibly small)

(Unchanged from v2 except for the V1.0 paging note at the end.)

UEFI handoff, minimal driver layer for hardware abstraction, framebuffer
output, keyboard input, raw block I/O, and the typed CBS VM itself.
Layer 0 splits across `boot/` (orchestrator) and `drivers/` (hardware
abstraction). `kernel/_future/` contains documented exile with
resurrection checklists for cap_graph and paging.

#### V1.0 paging — UEFI identity map only

V1.0 runs in UEFI's identity-mapped flat memory model. CodebookOS does
not install its own page tables in V1.0. The exiled
`kernel/_future/paging.asm` contains design notes for post-V1 paging:
1GB-page identity mapping for low memory, write-combining (PAT/PCD)
for the framebuffer MMIO range, and post-EBS CR3 install ordering.
Per Pod 0.9's analysis, V1.0 has no feature requirement that demands
own-paging — UEFI's identity map suffices. Paging arrives in Pod 2 or
later when a feature requires it (separate userspace, write-combining
framebuffer performance, NX bit on data, etc.). DEFERRED.md item 9
tracks this.

### Layer 1 — The Typed CBS VM (Engywook, in NASM)

A typed evaluator. Native primitives:

#### `Sign`

The unit of cognition. (Unchanged from v2.)

    Sign := {
      content_hash: bytes(32),         // sha256 of content
      embedding:    vector(N),         // semantic fingerprint, N=64 for V1 lexical
      label:        string(<=64),      // human-readable name
      provenance:   ProvChain,         // log of who wrote/touched this Sign
      energy_cost:  Energy,            // joules to construct
    }

#### `Cap<R>` — revised post-Pod-0.9, cap ops replaced post-Pod-1.1

Linear capability over resource R, organized as a graph with delegation
chains. Pod 1's design incorporates the salvageable *design ideas* of
`kernel/_future/cap_graph.asm` (the static-pool allocator, the
parent/child graph structure, the bitmap-as-capability pattern, and
**the spatial merge mechanic**) while widening data fields to 64-bit
and fixing the documented bugs.

**v4 — current cap ops retired (Q1).** The existing `OP_GRANT_CAP`
(0x90) and `OP_USE_CAP` (0x91) in `boot/cbs_vm.asm` are
magic-number token dispatchers — they create and consume untyped
`0xCA000000 + resource_id` tokens via hardcoded comparisons. These
do not implement Cap<R> as described here. Pod 1.10 retires them
entirely and replaces them with typed capability opcodes in the
`0xA0–0xEF` range (see opcode allocation below). No current cap
code survives into the typed system.

    Cap<R> := {
      resource:      R,                // resource type the cap authorizes
      parent:        cap_id,           // parent in graph (0 = root)
      child:         cap_id,           // first child (linked list head)
      sibling:       cap_id,           // next sibling (for traversal)
      cap_bitmap:    u64,              // 64 capability bits
      energy_budget: u64,              // joules granted to this cap
      energy_used:   u64,              // joules consumed by this cap + descendants
      nonce:         u64,              // anti-replay
      expiry:        Time | Never,     // time-bound caps
      signature:     bytes(64),        // Ed25519 over the rest (V1.1+)
    }

**Spatial merge — the delegation tax.** When a child capability
exercises a power, the parent capability's `energy_used` increments by
half the child's cost. This encodes the principle that
*delegation chains pay a tax*: capabilities are not free once granted.
The act of granting binds the parent's metabolism to the child's
activity. This mechanism survives directly from
`kernel/_future/cap_graph.asm` (the spatial_merge code in cap_use,
lines 130-145).

The signature field is present in V1.0's data layout but only enforced
in V1.1+ when Ed25519 lands. V1.0 leaves the field as zeros and
validates only structure (parent valid, bitmap match, energy
sufficient). On-disk layout doesn't change between V1.0 and V1.1.

The capability bitmap is 64 bits — wide enough for per-surface caps
(8+), per-driver caps (3+), per-resource caps (4: read/write/exec/grant),
per-network/peer caps (V1.1+), and headroom for V2+ extensions.
v2's earlier 5-bit bitmap was inherited from the Phase 5.1 design and
is too narrow.

The static cap pool is sized at 64 nodes for V1.0 (per the original
Phase 5.1 design). 64 × 128 bytes = 8 KB total — modest for the
header layer. Bumps to 256 in V1.1 if surface count expands.

#### VM substrate fixes — v5 (Pod 1.3 complete, Pod 1.5 width migration)

**OP_CALL / OP_RET semantics (Q2) — fixed in Pod 1.3.** `OP_RET`
now pops from `vm_ret_stack` and resumes at the saved PC (subroutine
return). `OP_CALL` pushes the current PC to `vm_ret_stack` and jumps
by a PC-relative signed 4-byte offset — not an absolute address, which
was broken under UEFI relocation (`nasm -f bin` emits file offsets, but
UEFI maps at IMAGE_BASE + TEXT_RVA). `OP_HALT` (0xFF) exits the VM;
this opcode pre-existed and required no new code. The return stack
(`vm_ret_stack`, 256 entries × 8 bytes, `vm_ret_ptr` as memory counter)
has bounds checks: underflow on `OP_RET` and overflow on `OP_CALL`
halt with violation messages. `vm_ret_ptr` is zeroed in `cbs_run`'s
prologue to prevent stale state across invocations. All `.cbc` surface
files (`atreyu.cbc`, `bastian.cbc`, `rockbiter.cbc`) were byte-patched
from trailing `OP_RET` (0x53) to `OP_HALT` (0xFF). The `.done` exit
path in `cbs_vm.asm` is shared by `OP_HALT`, energy exhaustion, and
violation handlers. See `recon/POD1.3_OP_RET_RECON.md` for the full
audit.

**64-bit integer width (Q4, refined by D1/D2/D3).** The current VM
uses 32-bit integers (`eax`/`ebx`) for arithmetic but 64-bit stack
slots. Pod 1.5 migrates to 64-bit values — all arithmetic uses
`rax`/`rbx`, `OP_PUSH` value operands become 8 bytes. Positional
offsets (jump targets in `OP_JMP`/`OP_JZ`/`OP_JNZ`, call offsets in
`OP_CALL`) remain 4-byte signed — ±2 GB reach is sufficient and
avoids bloating every branch instruction. Sign-extension via `movsxd`
is the default when widening a 4-byte operand to 64-bit register
width. The Python toolchain (`tools/atreyu_x86.py`) update is mandatory
and atomic with the runtime format change — no pod ships widened
runtime without a toolchain that emits the matching format. Bytecode
format changes accordingly; pre-Pod-1.5 `.cbc` programs require
recompilation (DEFERRED #12, resolved in Pod 1.5).

**Opcode space allocation (Q5).** Typed primitives claim the
`0xA0–0xEF` range (80 slots), allocated by primitive:

| Range | Primitive | Pod |
|-------|-----------|-----|
| `0xA0–0xAF` | Sign | 1.6 |
| `0xB0–0xBF` | Cap<R> | 1.9–1.10 |
| `0xC0–0xCF` | Outcome<T> | 1.8 |
| `0xD0–0xDF` | Energy | 1.7 |
| `0xE0–0xEF` | Demod<S> | 1.11 |

The existing `0x00–0x9F` range retains current opcode assignments
(arithmetic, stack, flow control, I/O). The `0xF0–0xFF` range is
reserved for future expansion.

**Surface token header (Q6).** The 23-byte surface token header
referenced in README is a Python-toolchain artifact (`tools/atreyu_x86.py`, Phase 8 detritus).
The NASM VM does not parse it — `cbs_run` begins execution at the
first byte of the bytecode stream. Pod 1's typed system ignores this
header entirely. The NASM VM is the authority; the Python toolchain
is historical.

#### `Outcome<T>`, `Energy`, `Demod<S>` — v5 updates

`Outcome<T>`, `Energy`, and `Demod<S>` definitions are unchanged from
v1/v2. v4 added implementation commitments from Pod 1.1 audit decisions;
v5 updates pod numbers after the arc slide.

**Outcome<T> as stack-error mechanism (Q8).** Stack underflow and
overflow produce `Outcome<T>` typed errors rather than halting the VM
or silently corrupting state. The specific error representation
(error codes, stack-frame tagging, etc.) is deferred to Pod 1.8 when
`Outcome<T>` becomes a native VM type. The principle is decided: stack
violations are typed results, not fatal traps. (Pod 1.3's interim
implementation uses halt-on-violation with diagnostic messages;
Pod 1.8 replaces these with typed `Outcome<T>` results.)

**Energy: per-opcode cost table (Q7).** The current VM debits 1 joule
per fetch cycle regardless of opcode. Pod 1.7 introduces a per-opcode
cost table — `OP_MUL` costs more than `OP_NOP`, `OP_GRANT_CAP` costs
more than `OP_ADD`. `OP_RESERVE` remains the per-program budget
mechanism. The flat per-fetch base cost is replaced, not supplemented.

**Demod<S>.** Unchanged. Arrives in Pod 4 (Interpreter).

### Layer 2 — The Trinity (CBS, hosted on Layer 1)

(Unchanged from v2.)

**Status: Design only. No implementation exists yet. Layer 2 arrives
in Pods 2-4.**

Three system services. Each written in CBS. Cop (capability service +
energy market), Maid (semantic codebook = filesystem), Interpreter
(pub-sub demodulation layer).

### Layer 3 — Surfaces (CBS, demods on the trinity)

(Unchanged from v2.)

**Status: Design only. No demod registration mechanism exists yet.
Layer 3 arrives in Pod 5.**

Bastian, Gmork, Auryn, Atreyu, Falkor, Empress, Koreander, Rockbiter,
Southern Oracle, Artax — each surface is a Demod registered with
Interpreter.

---

## What survives, what rebuilds (v4 update)

### Resurrects from `_future/` — Pod 0.9 deep read clarified

- `kernel/_future/cap_graph.asm` → **design ideas survive into Pod 1's
  Cap<R>**, code is rewritten from scratch with proper 64-bit math,
  bug-fixed budget accounting, and the spatial-merge mechanism
  preserved as a feature. Per Pod 0.9 memo: cap_graph is "80%
  recoverable as design, 0% recoverable as code." Pod 1 takes the
  design and writes correct code.

- `kernel/_future/paging.asm` → **design notes only**. V1.0 doesn't
  need it. Resurrects in Pod 2+ as needed. The 1GB-page identity map,
  write-combining framebuffer, and post-EBS CR3 ordering are the
  design constraints to remember when paging arrives.
- `drivers/_future/fat32_write.asm` → resurrects when Maid (Pod 3)
  needs FAT32 transport. Unchanged from v2.
- `drivers/_future/gpu_intel.asm` → low priority; UEFI GOP suffices
  through V1. Unchanged from v2.

### Exiled in place — Pod 1.1 audit identified (v4)

- **`cap_atreyu` handler (Q3):** Six editor operations (get/set_size,
  get/set_char, insert, delete) at `cbs_vm.asm:408–493` have no
  dispatch entry in `op_use_cap` — unreachable dead code. Left in
  place until Pod 1.10 (cap ops retirement). Pod 6 (Atreyu Walks)
  decides whether to rebuild from this skeleton or start fresh.
  DEFERRED #11 tracks this.

---

## The honest hard problems (v5 — durations removed, cap ops reframed)

| # | Problem | Lands in |
|---|---------|----------|
| 1 | Typed CBS VM with Sign/Cap/Outcome/Energy/Demod as native | Pod 1 (13 sub-pods) |
| 2 | Cap ops replacement (retire 0x90/0x91, typed Cap<R> opcodes) | Pod 1.9–1.10 |
| 3 | Ed25519 in NASM (placeholder field in V1.0; real in V1.1) | Pod 2 |
| 4 | ~~Paging resurrection~~ → **deferred post-V1** (DEFERRED #9) | Post-V1 |
| 5 | Lexical embeddings for Maid V1 | Pod 3 |
| 6 | Log-structured content-addressed store | Pod 3 |
| 7 | FAT32 write resurrection | Pod 3 |
| 8 | Pub-sub demod routing with isolation | Pod 4 |
| 9 | Surfaces refactor to use trinity | Pod 5 |
| 10 | Neural embeddings, quantized inference (Maid V2) | Pod 9 |
| 11 | Peer transport, capability addressing (Auryn far) | Pod 10 |

Pod 1 spans thirteen sub-pods (1.0 through 1.12). Two prerequisite
VM-fix pods and two canon-update pods precede typed-primitive work;
five typed-primitive pods follow; one cap data pod, one cap ops pod,
one Demod pod, and one cleanup pod close it out. Pace is set by
recon-protocol discipline, not by calendar.

---

## The pod arc (v5 — Pod 1 sub-pods expanded to 13)

    Pod 0 — Foundation Lock                                    [SEALED — pod0-complete]
    ├── 0.0  Reference lock + canonical docs                   [DONE — e2f5db8]
    ├── 0.1  Extract defines.asm                               [DONE — 4f02dcd]
    ├── 0.2  Polish auryn.asm header                           [DONE — 4489d01]
    ├── 0.2.5 Repo-wide archaeology recon                      [DONE — 7facf2a]
    ├── 0.3  Repo cleanup                                      [DONE]
    ├── 0.4  Canon updates v2                                  [DONE — a521db2/8a04b16]
    ├── 0.5  Header polish (5 boot/ modules)                   [DONE]
    ├── 0.6  Drivers + data.asm                                [DONE — fbb8ba3/e6d41b3]
    ├── 0.7  auryn_puts consolidation                          [DONE — 4ff12d8]
    ├── 0.8  Final sign-off + tag                              [DONE — d68167c, tagged pod0-complete]
    └── 0.9  cap_graph + paging deep read                      [DONE — 0ab996c]

    Pod 1 — Engywook Re-Forged (typed VM with Sign/Cap/Outcome/Energy/Demod)
    │       Cap<R> design informed by Pod 0.9's salvaged spatial-merge mechanic.
    │       Current cap ops (0x90/0x91) replaced, not extended.
    ├── 1.0  prompts/ backfill                                 [DONE]
    ├── 1.1  VM substrate audit (recon-only)                   [DONE]
    ├── 1.2  Canon update v4                                   [DONE]
    ├── 1.3  OP_CALL/OP_RET fix + OP_HALT                     [DONE — ebc9554]
    ├── 1.4  Canon update v5 (this document)                   [DONE]
    ├── 1.5  64-bit integer width migration                    [planned — VM fixes]
    ├── 1.6  Sign as native type (0xA0–0xAF)                   [planned — typed primitives]
    ├── 1.7  Energy: per-opcode cost table (0xD0–0xDF)         [planned — typed primitives]
    ├── 1.8  Outcome<T>: typed errors + stack bounds (0xC0–0xCF) [planned — typed primitives]
    ├── 1.9  Cap<R> data structures (0xB0–0xBF)                [planned — cap replacement]
    ├── 1.10 Cap ops retirement (retire 0x90/0x91)             [planned — cap replacement]
    ├── 1.11 Demod<S> registration (0xE0–0xEF)                 [planned — demod]
    └── 1.12 Pod 1 cleanup + sign-off                          [planned — cleanup]

    Pod 2 — Cop is Born (capability service + Ed25519 + energy market)

    Pod 3 — Maid is Born (codebook substrate: log store + graph + lexical embed)

    Pod 4 — Interpreter is Born (pub-sub demod routing with isolation)

    Pod 5 — Surfaces Refactor (every surface becomes a Demod)

    Pod 6 — Atreyu Walks (editor)

    Pod 7 — Empress + Koreander (search + docs)

    Pod 8 — Rockbiter + Falkor (scheduler + trust)

    Pod 9 — Maid V2 (neural embeddings)

    Pod 10 — Auryn Speaks Far (peer transport)

---

## The closing commitment (unchanged)

Every layer earns its keep. Every byte in the bootstrap is justified by
what it lets CBS do above it. Every type in the VM is justified by what
it lets the trinity express. Every service in the trinity is justified
by what it lets the surfaces become. Every surface is justified by what
it lets the user think.

Energy budgeting is novel. It is not the headline. The headline is the
organism — and the organism is what we're building.

The previous engineer's discipline preserved the design ideas through
exile. Pod 0 walked the perimeter and named what was there. Pod 0.9
read what Atreyu found. Pod 1 lights Engywook's full forge.

From layer 1 kernel up.

— Chauncey
CodebookOS Senior Architect
April 27, 2026 (v5)
```

---

## R2 — recon/POD1.1_VM_AUDIT.md

```
# Pod 1.1 — VM Substrate Audit

**Date:** 2026-04-27
**Pod:** 1.1 (recon-only, no source changes)
**Files audited:** `boot/cbs_vm.asm` (721 lines), `boot/defines.asm`
(89 lines), `boot/vmdata.asm` (21 lines), `boot/data.asm` (secondary)
**Binary contract:** Preserved (no source touched).

---

## T1 — Dispatch Loop Shape

### Main loop: `cbs_vm.asm:46–125`

**Fetch:** Single-byte opcode fetch at `:46–53`.

    .fetch:
        test    r14d, r14d          ; energy check
        jz      .fatigue
        dec     r14d                ; debit 1 joule per fetch cycle
        inc     qword [rel energy_used]
        movzx   eax, byte [r12]    ; fetch opcode (single byte)
        inc     r12                 ; advance PC

**Decode/dispatch:** Linear `cmp al, OP_X / je .op_x` chain, 31
comparisons (`:55–116`). Not a jump table. Chain length = 31. Falls
through to unknown-opcode handler at `:118–125`.

**PC advancement:** `r12` is the program counter. Incremented by 1 at
fetch (`:53`). Opcodes with operands advance `r12` further in their
handlers (e.g., `OP_PUSH` adds 4 at `:135`, `OP_PUSH_STR` adds
2 + strlen + padding at `:664–677`).

**Jump/call PC modification:**
- `OP_JIF` (`:360–368`): signed 32-bit offset added to `r12`
  (forward jump)
- `OP_JBACK` (`:371–375`): unsigned 32-bit value subtracted from `r12`
  (backward jump)
- `OP_JMP` (`:654–658`): `movsxd` signed 32-bit offset added to `r12`
- `OP_CALL` (`:628–643`): pops absolute PC from stack, saves current
  `r12` to `vm_ret_stack`, sets `r12` to target

**Reserved registers:**

| Register | Purpose | Scope |
|----------|---------|-------|
| `r12` | PC (program counter) | Bytecode pointer |
| `r13` | SP (CBS stack pointer) | Points into `vm_stack` |
| `r14` / `r14d` | Energy budget | Joules remaining |
| `r15` / `r15d` | Energy used | Cumulative joules consumed |

**Free for handler use:** `rax`, `rbx`, `rcx`, `rdx`, `rsi`, `rdi`,
`r8`–`r11`. Handlers use `eax`/`ebx` freely for operand manipulation.

### Performance note

The 31-comparison linear chain is O(n) per opcode. A jump table
(256-entry, indexed by opcode byte) would be O(1). Not a correctness
issue — performance optimization for Pod 1 if needed.

---

## T2 — Stack Discipline

**Operand stack:**
- **Label:** `vm_stack` (in `vmdata.asm:16`)
- **Slot width:** 8 bytes (`dq` slots), but most handlers use 32-bit
  `mov eax, [r13]` / `mov [r13], eax` — only 4 bytes of each 8-byte
  slot are used for integer operations. Pointer operations (cap tokens,
  string pointers) use full 64-bit `mov rax`.
- **Maximum depth:** 512 slots × 8 bytes = 4 KB (`times 512 dq 0`)
- **SP register:** `r13` — initialized to `lea r13, [rel vm_stack]`
  at `:39`
- **Growth direction:** Upward. Push = `mov [r13], eax; add r13, 8`.
  Pop = `sub r13, 8; mov eax, [r13]`.
- **Underflow detection:** Only in `OP_RET` (`:341–342`):
  `cmp r13, rax / jle .ret_empty`. All other handlers pop blindly.
  **No general underflow guard.**
- **Overflow detection:** **None.** No bounds check before push. Stack
  overflow silently corrupts memory beyond `vm_stack`.

**Return stack (separate):**
- **Label:** `vm_ret_stack` (in `vmdata.asm:15`)
- **Size:** 256 slots × 8 bytes = 2 KB
- **Pointer:** `vm_ret_ptr` (in `vmdata.asm:14`) — index into
  `vm_ret_stack`
- **Used by:** `OP_CALL` only (`:628–643`). Saves `r12` (current PC).
- **Note:** `OP_RET` (`:338–357`) does NOT pop from `vm_ret_stack` —
  it prints the top-of-stack value and exits the VM entirely. There is
  no "return from subroutine" implementation. `OP_CALL` saves the
  return address but nothing reads it back. **This is a latent bug or
  incomplete feature.**

**Variable slots:**
- **Label:** `vm_vars` (in `vmdata.asm:17`)
- **Size:** 64 slots × 4 bytes = 256 bytes (`times 64 dd 0`)
- **Access:** `OP_LOAD` (`:378–385`) and `OP_STORE` (`:388–395`) use
  `[rbx + rax*4]` — 32-bit indexing into 32-bit slots.
- **Bounds check:** **None.** Out-of-range index silently reads/writes
  beyond `vm_vars`.

---

## T3 — Opcode Inventory

### Opcodes by category

#### Data (2 opcodes)

| Opcode | Hex | Defined | Handled | Operand | Notes |
|--------|-----|---------|---------|---------|-------|
| OP_PUSH | 0x01 | Yes `:56` | Yes `:133` | imm32 | Push 32-bit value |
| OP_PUSH_STR | 0x02 | Yes `:81` | Yes `:663` | u16 len + bytes + pad | Push string ptr+len (2 stack slots) |

#### Arithmetic (8 opcodes)

| Opcode | Hex | Defined | Handled | Notes |
|--------|-----|---------|---------|-------|
| OP_ADD | 0x10 | Yes `:57` | Yes `:141` | |
| OP_SUB | 0x11 | Yes `:58` | Yes `:151` | |
| OP_MUL | 0x12 | Yes `:59` | Yes `:161` | Uses `imul` (signed) |
| OP_DIV | 0x13 | Yes `:60` | Yes `:188` | Uses `idiv` (signed), div-by-zero → push 0 |
| OP_EQ | 0x14 | Yes `:61` | Yes `:206` | |
| OP_NE | 0x15 | Yes `:62` | Yes `:218` | |
| OP_LT | 0x16 | Yes `:63` | Yes `:230` | Signed comparison |
| OP_GT | 0x17 | Yes `:64` | Yes `:242` | Signed comparison |
| OP_LE | 0x18 | Yes `:65` | Yes `:254` | |
| OP_GE | 0x19 | Yes `:66` | Yes `:266` | |
| OP_MOD | 0x1A | Yes `:82` | Yes `:171` | Uses `div` (unsigned!), zero → push 0 |

#### Energy (1 opcode)

| Opcode | Hex | Defined | Handled | Operand | Notes |
|--------|-----|---------|---------|---------|-------|
| OP_RESERVE | 0x20 | Yes `:67` | Yes `:279` | imm32 | Reserve energy; fail → skip to end |

#### Control flow (5 opcodes)

| Opcode | Hex | Defined | Handled | Operand | Notes |
|--------|-----|---------|---------|---------|-------|
| OP_JMP | 0x40 | Yes `:80` | Yes `:654` | signed i32 | Unconditional relative jump |
| OP_CALL | 0x50 | Yes `:83` | Yes `:628` | (stack) | Pops absolute PC; saves return addr (never used) |
| OP_RET | 0x53 | Yes `:68` | Yes `:339` | — | **Exits VM**, does not return from call |
| OP_JIF | 0x55 | Yes `:69` | Yes `:360` | signed i32 | Jump if false (TOS == 0) |
| OP_JBACK | 0x56 | Yes `:70` | Yes `:371` | u32 | Jump backward by offset |

#### Memory (2 opcodes)

| Opcode | Hex | Defined | Handled | Operand | Notes |
|--------|-----|---------|---------|---------|-------|
| OP_LOAD | 0x70 | Yes `:71` | Yes `:378` | u32 index | Load from vm_vars |
| OP_STORE | 0x71 | Yes `:72` | Yes `:388` | u32 index | Store to vm_vars |

#### I/O (4 opcodes)

| Opcode | Hex | Defined | Handled | Notes |
|--------|-----|---------|---------|-------|
| OP_PRINT_NUM | 0x80 | Yes `:73` | Yes `:592` | Prints as signed decimal |
| OP_EMIT | 0x81 | Yes `:74` | Yes `:598` | Emits single char via auryn_putc |
| OP_NEWLINE | 0x82 | Yes `:75` | Yes `:604` | Emits `\n` |
| OP_PRINT_STR | 0x86 | Yes `:79` | Yes `:681` | Pops ptr+len, prints chars |

#### Stack manipulation (4 opcodes)

| Opcode | Hex | Defined | Handled | Notes |
|--------|-----|---------|---------|-------|
| OP_DUP | 0x83 | Yes `:76` | Yes `:610` | |
| OP_DROP | 0x84 | Yes `:77` | Yes `:616` | |
| OP_SWAP | 0x85 | Yes `:78` | Yes `:620` | |
| OP_DUP2 | 0x87 | Yes `:84` | **YES** `:645` | **Not in dispatch chain!** See ghost analysis below |

#### Capability (2 live opcodes)

| Opcode | Hex | Defined | Handled | Notes |
|--------|-----|---------|---------|-------|
| OP_GRANT_CAP | 0x90 | Yes `:85` | Yes `:397` | Live — creates token from resource ID |
| OP_USE_CAP | 0x91 | Yes `:86` | Yes `:512` | Live — dispatches on token to surface caps |

#### Special (1 opcode)

| Opcode | Hex | Defined | Handled | Notes |
|--------|-----|---------|---------|-------|
| OP_HALT | 0xFF | Yes `:87` | Yes `:700` | Prints energy summary, exits VM |

### Ghost analysis

#### OP_DUP2 (0x87) — Handler exists, dispatch missing

**Surprise:** `OP_DUP2` has a fully implemented handler at `:645–652`
but is **not in the dispatch chain** (no `cmp al, OP_DUP2 / je .op_dup2`
in the `:55–116` cmp/je sequence). The handler is unreachable dead code.
Any bytecode containing `0x87` hits the unknown-opcode error path.

To wire it: add `cmp al, OP_DUP2 / je .op_dup2` to the dispatch chain
(between `OP_SWAP` at `:110` and the unknown-opcode handler at `:118`).

#### OP_GRANT_CAP_NEW (0xCA000003) — Define is a token value, not an opcode

**Not a real opcode.** The value `0xCA000003` is used at `cbs_vm.asm:525`
as a capability **token value** (`MORLA_FS`) compared against `rax` in
`op_use_cap`'s dispatch. It is unreachable as an opcode because dispatch
fetches a single byte (`movzx eax, byte [r12]`) — `0xCA000003` would
require 4 bytes. The `%define` is misleadingly named; the value is a cap
token constant, not an opcode.

#### OP_USE_CAP_NEW (0xCA000004) — Same situation

`0xCA000004` is used at `cbs_vm.asm:528` as the `ROCKBITER` capability
token value. Same analysis as above: cap token constant, not an opcode.
Misleadingly named with `OP_` prefix.

#### Wild handlers: None

Every handled label in the dispatch chain corresponds to a defined
`OP_*` constant. No undocumented opcodes.

### Summary

| Category | Count |
|----------|-------|
| Defined in defines.asm | 34 |
| In dispatch chain (reachable) | 31 |
| Handler exists, not dispatched (OP_DUP2) | 1 |
| Cap token constants misnamed as OP_* | 2 |
| Wild (handled but undefined) | 0 |

---

## T4 — Data Segment Layout

### Mutable VM state in `boot/vmdata.asm`

| Label | Declaration | Size | Purpose |
|-------|-------------|------|---------|
| `energy_budget` | `dq 100000` | 8 bytes | Global energy budget (not per-VM-instance) |
| `energy_used` | `dq 0` | 8 bytes | Cumulative energy consumed |
| `vm_ret_ptr` | `dq 0` | 8 bytes | Return stack index |
| `vm_ret_stack` | `times 256 dq 0` | 2 KB | Return address stack |
| `vm_stack` | `times 512 dq 0` | 4 KB | Operand stack |
| `vm_vars` | `times 64 dd 0` | 256 bytes | Addressable variable slots |
| `mmap_buf` | `times 8192 db 0` | 8 KB | UEFI memory map (not VM-specific) |

**Scope:** All labels are global (single static allocation). The VM is
**not reentrant** — there is one stack, one variable bank, one energy
counter. Concurrent or nested VM invocations would corrupt state.

### VM-relevant state in `boot/data.asm`

| Label | Declaration | Size | Purpose |
|-------|-------------|------|---------|
| `atreyu_size` | `dq 0` | 8 bytes | Editor buffer length (Atreyu surface) |
| `external_prog_buf` | `times 65536 db 0` | 64 KB | Buffer for loaded .cbc programs |
| `key_data` | `dd 0` | 4 bytes | Keyboard scancode (shared with keyboard driver) |
| `str_vm_*` | Various `db` | ~200 bytes | VM output strings (start, halt, ret, etc.) |
| `prog_table` | `dq × 8 entries` | 64 bytes | Embedded program dispatch table |
| `cbs_demo` | Bytecode | ~300 bytes | Inline demo bytecode |
| `prog1`–`prog4` | Bytecode | ~500 bytes total | Inline demo programs |
| `atreyu_cbs_prog` | `incbin "boot/atreyu.cbc"` | 645 bytes | Atreyu surface bytecode |
| `rockbiter_cbs_prog` | `incbin "boot/rockbiter.cbc"` | 238 bytes | Rockbiter surface bytecode |

### Capability storage

**None.** There is no cap pool, cap table, or cap graph in the live VM.
`OP_GRANT_CAP` creates tokens by adding `0xCA000000` to a resource ID
at runtime — pure arithmetic, no persistent storage. `OP_USE_CAP`
dispatches on the token value via hardcoded `cmp` comparisons. Caps are
ephemeral stack values, not stored objects.

### Heap / arena

**None.** The VM has no dynamic allocation. All storage is statically
sized at assembly time.

---

## T5 — Surface Token Format

### The 23-byte header: Python toolchain only, not in the NASM VM

The "23-byte surface token header" described in `README.md` exists
**only in the Python-era CBS toolchain** (`tools/cbsc.cbs:40–52`):

    Bytes 0-3:   capability_id (u32 LE)
    Bytes 4-5:   x coordinate (u16 LE)
    Bytes 6-7:   y coordinate (u16 LE)
    Bytes 8-9:   energy (u16 LE)
    Bytes 10-17: data_ptr (u64 LE)
    Byte 18:     revoke_flag (u8)
    Bytes 19-22: checksum (4 bytes, placeholder 0xCAFEBABA)

**The NASM VM (`cbs_vm.asm`) does not parse this header.** It receives a
raw pointer to bytecode in `r12` and begins executing at byte 0. No
header parsing, no checksum validation, no capability_id extraction.

The embedded `.cbc` files (`boot/atreyu.cbc`, `boot/rockbiter.cbc`,
etc.) are compiled by the Python toolchain and presumably contain this
header. But `cbs_run` treats them as raw bytecode starting from the
pointer given — it doesn't skip 23 bytes.

**Implication:** Either the `.cbc` files don't actually contain the
23-byte header (the Python compiler may strip it for NASM targets), or
the NASM VM is accidentally executing header bytes as opcodes. Needs
verification by hex-dumping a .cbc file. Either way, the README's claim
about the VM does not match the NASM VM's behavior.

---

## T6 — Energy Accounting Plumbing

### What's real

Energy accounting is **partially implemented and functional**.

**Budget initialization:**
- Callers set `r14d` before calling `cbs_run` (e.g., `mov r14d, 100000`
  at `bastian.asm:136`, `mov r14d, 10000` at `gmork_cmds.asm:409`)
- `energy_used` is zeroed at entry (`cbs_vm.asm:40`)
- `energy_budget` in `vmdata.asm:12` is a static `dq 100000` — but
  `cbs_run` ignores it, using `r14d` instead

**Per-fetch debit:**
- Every fetch cycle costs 1 joule: `dec r14d` at `:50`
- Energy used is tracked: `inc qword [rel energy_used]` at `:51`

**OP_RESERVE (`:279–336`):**
- Bytecode declares energy cost via `OP_RESERVE imm32`
- If `r14d < imm32`: prints "DEGRADED" and skips to HALT/RET
  (`:294–336`)
- If sufficient: deducts from `r14d`, adds to `r15d` (`:284–285`)
- This is the "every CBS function declares costs Nj" mechanism

**Energy summary at exit (`:704–715`):**
- Prints "Energy: Nj used, Mj remaining" on every VM exit

### What's real but inconsistent

- `r14d` (32-bit) is the live budget register, but `energy_budget` in
  vmdata.asm is `dq` (64-bit). The static `energy_budget` label appears
  to be read only by the `cap_rockbiter` handler (`:501–502`) which
  pushes it onto the CBS stack for the Rockbiter surface to display.
- `r15d` tracks OP_RESERVE reservations, while `energy_used` tracks
  fetch cycles. These are two separate energy counters counting different
  things. The exit summary prints `r15d` as "used" (`:708`) and `r14d`
  as "remaining" (`:712`).
- Per-opcode cost is flat (1 joule per fetch). `OP_RESERVE` cost is
  per-program-declaration. There is no per-opcode-type cost table.

### What's aspirational

- No per-opcode-type cost differentiation (every opcode costs 1j at
  fetch regardless of complexity)
- No per-surface energy isolation (all programs share the single `r14d`
  budget)
- No "energy market" or P2P energy trading
- `energy_budget` label is not used as the VM's budget — it's a display
  value for Rockbiter
- Bankruptcy is real (DEGRADED path works) but recovery is not — the VM
  just skips to end

---

## T7 — Capability Hooks

### Live single-byte cap ops

#### OP_GRANT_CAP (0x90) — `cbs_vm.asm:397–405`

    .op_grant_cap:
        sub     r13, 8
        mov     rax, [r13]          ; pop resource ID
        add     eax, 0xCA000000     ; token = ID + magic
        mov     [r13], rax
        add     r13, 8              ; push token
        jmp     .fetch

**What it does:** Pops a resource ID from the stack, adds `0xCA000000`
to create a "capability token," pushes the token back. No cryptography,
no signature, no cap pool, no persistence. The token is an integer
encoding: `0xCA000001` = Auryn display, `0xCA000002` = Gmork CONIN,
`0xCA000003` = Morla FS, `0xCA000004` = Rockbiter.

This is a **token-as-magic-number** system, not a capability system.
Any bytecode can forge any token by pushing the right integer and adding
`0xCA000000`.

#### OP_USE_CAP (0x91) — `cbs_vm.asm:512–589`

    .op_use_cap:
        sub     r13, 8
        mov     rax, [r13]          ; pop token
        sub     r13, 8
        mov     rcx, [r13]          ; pop cmd
        ; Dispatch on token value:
        cmp rax, 0xCA000001         ; AURYN_DISPLAY
        je .cap_auryn
        cmp rax, 0xCA000002         ; GMORK_CONIN
        je .cap_conin
        cmp rax, 0xCA000003         ; MORLA_FS
        je .cap_morla
        cmp rax, 0xCA000004         ; ROCKBITER
        je .cap_rockbiter

**What it does:** Pops a token and a command ID from the stack.
Dispatches on the token value to surface-specific handlers. Each surface
has sub-commands:

| Token | Value | Surface | Sub-commands |
|-------|-------|---------|-------------|
| AURYN_DISPLAY | 0xCA000001 | Auryn | 1=putc, 2=fill |
| GMORK_CONIN | 0xCA000002 | Gmork | 1=read key |
| MORLA_FS | 0xCA000003 | Morla | 1=ls, 2=write_file |
| ROCKBITER | 0xCA000004 | Rockbiter | 1=get_energy_budget, 2=get_energy_used |
| ATREYU | (inline) | Atreyu | 1-6: get/set_size, get/set_char, insert, delete |

**Atreyu note:** The Atreyu cap handler (`:408–493`) exists as code but
has **no token dispatch entry** in `op_use_cap`. There is no
`cmp rax, 0xCA000005 / je .cap_atreyu`. The Atreyu editor operations
are **unreachable dead code** unless called through some other mechanism
not visible in the audit.

### Ghost multi-byte cap ops (unreachable)

| Define | Value | Status |
|--------|-------|--------|
| OP_GRANT_CAP_NEW | 0xCA000003 | **Not an opcode.** Value is the Morla FS cap token. Misleadingly named. Unreachable via single-byte dispatch. |
| OP_USE_CAP_NEW | 0xCA000004 | **Not an opcode.** Value is the Rockbiter cap token. Same analysis. |

These defines should be renamed or removed. They are cap token constants,
not opcodes. Suggested rename: `CAP_TOKEN_MORLA` and `CAP_TOKEN_ROCKBITER`
(or remove entirely, since the values are hardcoded in `op_use_cap`).

### Cap pool / storage

**None in the live VM.** No `cap_*` labels. No cap table. No cap graph
structure. All capability state exists as ephemeral stack values during
bytecode execution. The exiled `kernel/_future/cap_graph.asm` has a
64-node static pool, but nothing in the live build references it.

---

## T8 — Build Pipeline

### Include path

`boot/boot.asm:369`: `%include "boot/cbs_vm.asm"`

### Order of inclusion

     1. boot/defines.asm         ← OP_* constants
     2. (inline) PE32+ headers, efi_entry
     3. boot/auryn.asm           ← auryn_putc, auryn_puts (called by VM)
     4. boot/morla.asm           ← morla_ls, morla_write_file (called by VM)
     5. boot/gmork.asm           ← print_dec, print_sdec, print_hex32 (called by VM)
     6. boot/cbs_vm.asm          ← THE VM
     7. boot/bastian.asm         ← calls cbs_run
     8. boot/gmork_cmds.asm      ← calls cbs_run
     9. drivers/kbd_ps2.asm      ← native_keyboard_read (called by VM)
    10. drivers/ide_pio.asm
    11. drivers/fat32.asm
    12. boot/data.asm            ← VM strings, prog_table, bytecode
    13. boot/vmdata.asm          ← VM stack, vars, energy

The VM is included after all modules it calls into (auryn, morla, gmork)
and before all modules that call it (bastian, gmork_cmds). Data it
references (strings, prog_table, vm_stack) comes after — resolved by
NASM's two-pass assembly.

### Conditional assembly

**None.** Zero `%ifdef` / `%ifndef` / `%if` directives in `cbs_vm.asm`.
The VM compiles identically regardless of build configuration.

### build.sh

    nasm -f bin -o build/BOOTX64.EFI boot/boot.asm

Single invocation, flat binary output. No linker, no object files, no
separate compilation units.

---

## T9 — Entry/Exit Conventions

### Entry point

**Label:** `cbs_run` (`cbs_vm.asm:32`)

**Register state on entry:**

| Register | Expected | Set by callers |
|----------|----------|---------------|
| `r12` | Pointer to bytecode | `lea r12, [rel atreyu_cbs_prog]` etc. |
| `r14d` | Energy budget (32-bit) | `mov r14d, 100000` etc. |

No other registers carry VM-meaningful state. `rdi`, `rsi`, `rcx`,
`rdx` are not used as VM inputs.

**ABI note:** This is not System V or Microsoft x64 ABI for parameter
passing. The VM uses a custom convention: `r12` = bytecode pointer,
`r14d` = energy. These registers are callee-saved in both x64 ABIs,
so the caller expects them preserved — but `cbs_run` modifies both
(and does not restore them). This is fine because callers don't use
the post-call values of `r12`/`r14d`.

### Preserved registers

`cbs_run` saves/restores `rbx`, `rbp`, `rcx`, `rdx` (`:33–37`,
`:717–720`). It does NOT save/restore `r12`–`r15` (the VM state
registers), `rsi`, `rdi`, `r8`–`r11`.

### Return

`cbs_run` returns via `ret` (`:721`) after restoring saved registers.
Return value: none in `rax` — the VM communicates results via screen
output, not return values.

### Reentrancy

**Not reentrant.** Global mutable state (`vm_stack`, `vm_vars`,
`vm_ret_ptr`, `energy_used`) would be corrupted by nested calls.
However, `cbs_run` IS called from multiple sites (bastian, morla,
gmork_cmds) — this is safe because calls are sequential, not nested.

---

## T10 — Error Paths

| Error condition | Handler | Location | Action | Recovery? |
|----------------|---------|----------|--------|-----------|
| Unknown opcode | `:118–125` | After dispatch chain | Prints "Unknown opcode: 0xNN", jumps to `.done` | No — VM exits |
| Energy exhausted (fetch) | `.fatigue` `:127–130` | At fetch | Prints "DEGRADED: insufficient energy", jumps to `.done` | No — VM exits |
| OP_RESERVE fail | `.reserve_fail` `:294–336` | In handler | Prints "DEGRADED", skips to HALT/RET | Partial — skips to clean exit |
| Division by zero | `.div_zero` `:200–203` | OP_DIV handler | Pushes 0, continues | Yes — silent recovery |
| Modulo by zero | `.mod_zero` `:183–186` | OP_MOD handler | Pushes 0, continues | Yes — silent recovery |
| Invalid cap token | `:532–535` | OP_USE_CAP | Prints "Unknown opcode:" (reuses wrong string), continues | Yes — continues |
| RET with empty stack | `.ret_empty` `:352–357` | OP_RET | Prints "Return: (void)", exits VM | No — VM exits |
| Stack underflow | **None** | — | Silent corruption | No guard exists |
| Stack overflow | **None** | — | Silent corruption | No guard exists |
| Bad PC (past bytecode) | **None** | — | Reads garbage, UB | No guard exists |
| Token header malformed | **N/A** | — | NASM VM doesn't parse token headers | — |

**Severity assessment:** Stack underflow/overflow and bad-PC are the
most dangerous — they produce silent memory corruption rather than
error messages. For V1 embedded programs this is acceptable (bytecode
is trusted), but Pod 1's typed VM should add bounds checking.

---

## T11 — 32-bit Pointer Residue

### Findings

| Location | Pattern | Severity | Description |
|----------|---------|----------|-------------|
| `:134` | `mov eax, [r12]` | **Cosmetic** | Reads 4-byte immediate from bytecode — intentionally 32-bit (opcodes use imm32 operands) |
| `:136` | `mov [r13], eax` | **Latent** | Stores 32-bit value to 8-byte stack slot. Upper 4 bytes are stale from previous slot content. |
| `:382` | `mov eax, [rbx + rax*4]` | **Cosmetic** | `vm_vars` is `dd` (32-bit) — 32-bit access is correct for 32-bit slots |
| `:394` | `mov [rcx + rax*4], ebx` | **Cosmetic** | Same — correct for 32-bit var slots |
| `:400` | `mov rax, [r13]` | **OK** | Full 64-bit read for cap token |
| `:403` | `mov [r13], rax` | **OK** | Full 64-bit write for cap token |
| `:438–439` | `movzx rax, byte [rbx + rax]` | **OK** | Correctly zero-extends |
| `:611` | `mov eax, [r13 - 8]` | **Latent** | OP_DUP reads 32-bit from 64-bit slot |

### Assessment

The VM operates on 32-bit values for integer arithmetic (intentional —
CBS integers are 32-bit) but uses 8-byte stack slots. This creates a
**mixed-width discipline**: most handlers write `eax` (4 bytes) to an
8-byte slot, leaving the upper 4 bytes as garbage. Handlers that read
back with `mov eax` get the correct 4 bytes. But handlers that read
with `mov rax` (cap ops at `:400`, `:515`) pick up stale upper bits.

**No active bugs found** — the mixed-width pattern is consistent enough
to work. But it's fragile: any handler that accidentally writes `rax`
and then reads `eax` (or vice versa) will see wrong values. Pod 1
should choose one width and enforce it.

---

## T12 — Metrics

| Metric | Value |
|--------|-------|
| Total LoC in `boot/cbs_vm.asm` | 721 (including header, comments, blank lines) |
| Code lines (non-blank, non-comment) | ~620 |
| Total opcodes defined in `defines.asm` | 34 (including 2 misnamed cap tokens) |
| Total opcodes in dispatch chain (reachable) | 31 |
| Unreachable handlers (OP_DUP2) | 1 |
| Ghost defines (misnamed cap tokens) | 2 |
| VM stack size | 4 KB (512 × 8-byte slots) |
| Variable slots | 256 bytes (64 × 4-byte slots) |
| Return stack size | 2 KB (256 × 8-byte slots) |
| BOOTX64.EFI total size | 1,049,600 bytes |
| VM approximate binary contribution | ~2.5–3 KB (estimated from instruction count × avg 4 bytes/instr) |
| Energy model | Per-fetch (1j/cycle) + per-RESERVE (declared) |
| Cap tokens implemented | 4 surface caps (Auryn, Gmork, Morla, Rockbiter) |
| Atreyu cap handler | Exists but unreachable (no dispatch entry) |

### Estimated complexity for typed-primitive replacement

The current VM is a well-structured single-file stack machine with clean
dispatch flow. The complexity for typed-primitive work is **moderate**:

- **Sign:** The VM has no concept of Sign today. This is greenfield —
  new type, new opcodes, new storage. Data representation needs
  designing from scratch.
- **Energy:** Partially implemented. The per-fetch debit and OP_RESERVE
  mechanism work. Typing Energy means adding per-opcode-type cost
  tables, per-surface isolation, and possibly the energy market. Medium
  effort — extend existing plumbing rather than replace it.
- **Cap<R>:** The token-as-magic-number system needs full replacement.
  The `op_grant_cap` / `op_use_cap` handlers work but are not real
  capabilities — they're a dispatch mechanism cosplaying as caps.
  Replacing this with the typed `Cap<R>` from RECONSTITUTION v3
  (64-node pool, parent/child graph, spatial merge, bitmap-based
  permissions) is the largest single piece of Pod 1 work.
- **Outcome<T>:** No prior art in the VM. Greenfield.
- **Demod<S>:** No prior art in the VM. Greenfield.

---

## Open Questions for the Architect

### Q1 — Cap op replacement strategy (blocks Pod 1.6)

Live untyped cap ops exist at 0x90-0x91. Pod 1.6 (typed Cap<R> with
spatial-merge) can:
- **(a) Replace entirely** with new typed opcodes, killing the untyped
  path. Existing .cbc bytecode using `grant_cap`/`use_cap` breaks and
  must be recompiled.
- **(b) Coexist** — keep 0x90-0x91 as legacy and add typed ops in a new
  opcode range. Two cap systems running in parallel, migration over
  time.
- **(c) Extend in place** — modify 0x90-0x91's handlers to be
  typed-aware. Same opcodes, new semantics. Bytecode format changes
  (operands differ).

Each has tradeoffs (correctness, migration, opcode space pressure,
bytecode compat). Architect to choose.

### Q2 — OP_RET semantics: exit VM or return from call?

Currently `OP_RET` exits the VM entirely. `OP_CALL` saves a return
address to `vm_ret_stack` but nothing reads it back. Two possible
intents:
- **(a)** `OP_RET` should pop from `vm_ret_stack` and resume at saved
  PC (subroutine return). `OP_HALT` exits the VM. This makes `OP_CALL`
  useful.
- **(b)** `OP_CALL` is a "tail call" / goto-with-breadcrumbs and the
  return stack is vestigial. `OP_RET` correctly exits.

Pod 1 needs to know which semantics to implement. If (a), the current
`OP_RET` is a bug. If (b), the return stack is dead code.

### Q3 — Atreyu cap handler: dead code or missing dispatch?

`cap_atreyu` (`:408–493`) implements 6 editor operations (get/set_size,
get/set_char, insert, delete) but has no token dispatch entry in
`op_use_cap`. Should Pod 1:
- **(a)** Wire it at `0xCA000005` (add the missing `cmp` in `op_use_cap`)
- **(b)** Leave it dead until Atreyu surface is rebuilt in Pod 6
- **(c)** Remove the dead code now, rebuild from scratch in Pod 6

### Q4 — Integer width: 32-bit or 64-bit?

The VM uses 32-bit integers (`eax`/`ebx`) for arithmetic but 64-bit
stack slots. Pod 1's typed primitives (especially `Cap<R>` with 64-bit
fields) need full 64-bit values. Should the VM:
- **(a)** Widen to 64-bit throughout (all arithmetic uses `rax`/`rbx`).
  Simpler, consistent, but changes bytecode format (PUSH operand
  becomes 8 bytes instead of 4).
- **(b)** Keep 32-bit integers for CBS user code, use 64-bit only for
  typed primitives. Dual-width, but preserves bytecode compat.

### Q5 — Opcode space allocation for Pod 1 types

31 of 256 possible single-byte opcodes are used. Available ranges:
- `0x03–0x0F` (13 slots, near PUSH/PUSH_STR)
- `0x1B–0x1F` (5 slots, after arithmetic)
- `0x21–0x3F` (31 slots, after RESERVE)
- `0x41–0x4F` (15 slots, after JMP)
- `0x51–0x52`, `0x54`, `0x57–0x6F` (27 slots)
- `0x72–0x7F` (14 slots, after LOAD/STORE)
- `0x88–0x8F` (8 slots, after DUP2)
- `0x92–0xFE` (109 slots, after USE_CAP)

RECONSTITUTION v3 suggests `0x40+` for Pod 1 kernel opcodes. That range
is partially occupied (`OP_JMP` at 0x40, `OP_CALL` at 0x50, etc.). The
largest contiguous free block is `0x92–0xFE` (109 slots). Architect to
confirm preferred allocation range for Sign/Cap/Energy/Outcome/Demod
opcodes.

### Q6 — Surface token header alignment

README claims "23-byte surface token header" but the NASM VM doesn't
parse it. The Python toolchain (`tools/cbsc.cbs`) does. For Pod 1.2
(Sign as native type), the Sign struct layout should either:
- **(a)** Replace the 23-byte token header entirely (new format)
- **(b)** Extend the 23-byte header with Sign fields (backward compat
  with Python toolchain)
- **(c)** Ignore the Python toolchain header entirely (NASM VM is the
  authority)

### Q7 — Energy: per-fetch or per-opcode-type?

Current energy model debits 1j per fetch cycle regardless of opcode
complexity. Pod 1.3 (typed Energy) could:
- **(a)** Keep per-fetch flat cost, add OP_RESERVE as the only
  variable-cost mechanism
- **(b)** Introduce per-opcode-type cost table (e.g., OP_MUL costs 3j,
  OP_EMIT costs 5j, OP_GRANT_CAP costs 10j)
- **(c)** Both — per-fetch base cost + per-opcode surcharge

Option (b) is what ROADMAP.md describes ("every CBS function declares
costs Nj"). Option (a) is what exists.

### Q8 — Stack bounds checking

The current VM has no stack underflow or overflow guards (except in
OP_RET). Pod 1 should add bounds checking. Question: should stack
violation be:
- **(a)** Fatal — print error, halt VM
- **(b)** Degraded — set an error flag, energy penalty, continue
- **(c)** Outcome<T> — push `Err(StackOverflow)` as a typed result

This is also a design input for Pod 1.4 (Outcome<T>).
```

**NOTE:** The line numbers and register references in this audit reflect
the **pre-Pod-1.5 state** of `cbs_vm.asm` (721 lines, 32-bit arithmetic).
The current post-Pod-1.5 state is 737 lines with 64-bit arithmetic. The
audit questions (Q1–Q8) have all been answered in
`recon/POD1.2_DECISION_RECORD.md` and canonized in RECONSTITUTION v5.

---

## R3 — recon/POD1.2_DECISION_RECORD.md

```
# Pod 1.2 — Decision Record

**Date:** 2026-04-27
**Pod:** 1.2 (canon-only, no source changes)
**Input:** `recon/POD1.1_VM_AUDIT.md` questions Q1–Q8
**Output:** Architect decisions canonized in RECONSTITUTION.md v4
**Decided by:** Chauncey (architect)

---

## Q1 — Cap ops: extend or replace?

**Decision:** Replace entirely. Retire `OP_GRANT_CAP` (0x90) and
`OP_USE_CAP` (0x91) in Pod 1.9. Typed Cap<R> opcodes in the
`0xB0–0xBF` range replace them.

**Rationale:** The current cap ops are magic-number token dispatchers
— they create untyped `0xCA000000 + resource_id` tokens and dispatch
via hardcoded `cmp` chains. This is not a capability system; it's a
switch statement wearing a capability costume. Extending it would
preserve the wrong abstraction. The spatial-merge design from Pod 0.9
informs the replacement architecture, but no current cap code
survives into the typed system.

**Affects:** `boot/cbs_vm.asm` (op_grant_cap, op_use_cap, all
cap_* handlers), `boot/defines.asm` (OP_GRANT_CAP, OP_USE_CAP,
OP_GRANT_CAP_NEW, OP_USE_CAP_NEW).

---

## Q2 — OP_RET semantics: exit VM or return from call?

**Decision:** Option (a) — `OP_RET` pops from `vm_ret_stack` and
resumes at saved PC (subroutine return). A new `OP_HALT` opcode
exits the VM. Pod 1.3 implements this.

**Rationale:** `OP_CALL` already saves a return address to
`vm_ret_stack`. The infrastructure for subroutine calls exists but
is half-built — `OP_RET` exits the VM instead of reading
`vm_ret_stack`. The intent was clearly subroutine semantics; the
current behavior is a bug, not a design choice. Making
`OP_CALL`/`OP_RET` a functioning pair enables structured CBS
programs without goto-spaghetti.

**Affects:** `boot/cbs_vm.asm` (`.op_ret` handler, new `.op_halt`
handler + dispatch entry), `boot/defines.asm` (new `OP_HALT`
define).

---

## Q3 — Atreyu cap handler: dead code or missing dispatch?

**Decision:** Option (b) — leave dead until Pod 1.9 exiles it
alongside the rest of the cap ops. Pod 6 (Atreyu Walks) decides
whether to rebuild from this skeleton or start fresh.

**Rationale:** Wiring `cap_atreyu` now would connect dead code to a
system (`OP_USE_CAP`) that is itself being retired. Removing it now
saves nothing — the code is inert and harmless. Leaving it preserves
the design notes (six operations that a future Atreyu editor might
need) without pretending it works. DEFERRED #11 tracks the exile.

**Affects:** No code changes. `cap_atreyu` at `cbs_vm.asm:408–493`
remains as-is until Pod 1.9.

---

## Q4 — Integer width: 32-bit or 64-bit?

**Decision:** Option (a) — widen to 64-bit throughout. All
arithmetic uses `rax`/`rbx`. `OP_PUSH` operands become 8 bytes.
Pod 1.4 implements the migration.

**Rationale:** The VM runs on a 64-bit CPU with 64-bit stack slots.
Using 32-bit arithmetic (`eax`/`ebx`) while storing results in
64-bit slots creates a dual-width system where the upper 32 bits of
every stack entry are undefined. Pod 1's typed primitives (Cap<R>
with 64-bit fields, Energy with 64-bit budgets) need full-width
values. One integer width eliminates an entire class of truncation
bugs. The cost — wider bytecode operands — is trivial for an
embedded VM with no external bytecode ecosystem to preserve.

**Affects:** `boot/cbs_vm.asm` (every arithmetic handler, OP_PUSH
operand fetch, OP_LOAD/OP_STORE), `boot/data.asm` (embedded .cbc
programs need recompilation — see DEFERRED #12).

---

## Q5 — Opcode space allocation for Pod 1 types

**Decision:** Typed primitives claim `0xA0–0xEF` (80 slots),
allocated by primitive:

- `0xA0–0xAF` — Sign (Pod 1.5)
- `0xB0–0xBF` — Cap<R> (Pod 1.8–1.9)
- `0xC0–0xCF` — Outcome<T> (Pod 1.7)
- `0xD0–0xDF` — Energy (Pod 1.6)
- `0xE0–0xEF` — Demod<S> (Pod 1.10)
- `0xF0–0xFF` — reserved for future expansion

**Rationale:** The largest contiguous free block in the current
opcode map is `0x92–0xFE` (109 slots). Allocating `0xA0–0xEF`
takes 80 of those 109, leaving `0x92–0x9F` (14 slots) as a buffer
between existing ops and typed primitives, and `0xF0–0xFF` (16
slots) as headroom. Each primitive gets 16 slots — enough for
create/read/update/delete plus type-specific operations.

**Affects:** `boot/defines.asm` (new OP_* defines in each pod),
`boot/cbs_vm.asm` (new dispatch entries in each pod).

---

## Q6 — Surface token header alignment

**Decision:** Option (c) — ignore the Python toolchain header
entirely. The NASM VM is the authority.

**Rationale:** The 23-byte surface token header exists in
`tools/cbsc.cbs` (Python toolchain). The NASM VM's `cbs_run` does
not parse it — execution begins at byte 0 of the bytecode stream.
There is no Python toolchain compatibility requirement. The NASM VM
is the only runtime, and it defines the bytecode format. README's
reference to the token header is a stale artifact (tracked in
DEFERRED #7 for cleanup in the README rewrite).

**Affects:** No code changes. README rewrite (DEFERRED #7) will
remove or correctly scope the token header reference.

---

## Q7 — Energy: per-fetch or per-opcode-type?

**Decision:** Option (b) — per-opcode-type cost table. The flat
per-fetch base cost is replaced, not supplemented. Pod 1.6
implements this.

**Rationale:** ROADMAP.md describes "every CBS function declares
costs Nj" — the intent was always differential pricing. A flat
1-joule-per-fetch model means `OP_NOP` costs the same as
`OP_GRANT_CAP`, which defeats the purpose of energy as a resource
accounting primitive. A cost table lets the system express that
capability operations are expensive, I/O is expensive, arithmetic
is cheap — which is the metabolic model the organism needs.

**Affects:** `boot/cbs_vm.asm` (fetch loop energy debit replaced
with table lookup), `boot/vmdata.asm` or `boot/data.asm` (new
opcode cost table).

---

## Q8 — Stack bounds checking

**Decision:** Option (c) — `Outcome<T>` typed errors. Stack
underflow and overflow produce typed error results. The specific
error representation is deferred to Pod 1.7 when `Outcome<T>`
becomes a native VM type.

**Rationale:** Fatal halts (option a) are too aggressive — a
single stack miscalculation kills the entire VM, which is wrong
for a system that wants to run multiple surfaces. Silent
degradation (option b) hides bugs. Typed errors (option c) let
the caller decide: a surface can catch the error and recover, or
let it propagate to the system level. This is consistent with the
CBS design principle that everything is a typed value — errors
included.

**Affects:** `boot/cbs_vm.asm` (stack push/pop wrappers with
bounds checks, Pod 1.7), `boot/defines.asm` (error type constants,
Pod 1.7). DEFERRED #13 tracks the encoding design.

---

## Closing

Eight decisions. All canonized in RECONSTITUTION.md v4. The VM
substrate audit (Pod 1.1) asked the questions; this record captures
why the answers are what they are. Future pods implementing these
decisions should read this memo to understand the constraints, not
just the conclusions.
```

**NOTE:** The pod numbers in Q5 (Sign at 1.5, Energy at 1.6, etc.)
are pre-arc-slide. RECONSTITUTION v5 has the post-slide numbers
(Sign at 1.6, Energy at 1.7, etc.). See Surprise S2.

---

## R4 — recon/POD1.4_DECISION_RECORD.md

```
# Pod 1.4 — Decision Record

## Canon-Only Pod: RECONSTITUTION v4 → v5

**Pod type:** Canon-only (no source changes, binary contract preserved)
**Binary contract:** `fedcd682031e8cab36dcd8a9a519cb47ffea34c047c80d2d4db20f561196dc28`
**Companion to:** RECONSTITUTION.md v5, RECON_PROTOCOL.md, DEFERRED.md

---

## Decisions Canonized

### D1 — CBS value width vs. positional offset width

**Decision:** CBS values (operand stack entries, `OP_PUSH` data operands)
widen to 8 bytes. Positional offsets (jump targets in `OP_JMP`/`OP_JZ`/
`OP_JNZ`, call offsets in `OP_CALL`) remain 4-byte signed.

**Rationale:** Values must be 64-bit to hold pointers, capability IDs,
and energy budgets without truncation. Positional offsets encode
distances within a bytecode stream — ±2 GB reach is more than
sufficient for any CBS program and avoids bloating every branch
instruction from 5 bytes to 9 bytes. The two categories serve
different purposes and deserve different widths.

**Impact:** `OP_PUSH` grows from 5 bytes (1 opcode + 4 data) to 9 bytes
(1 opcode + 8 data). `OP_JMP`/`OP_JZ`/`OP_JNZ`/`OP_CALL` remain at
5 bytes (1 opcode + 4 offset). The Python toolchain must emit the
correct width per opcode class.

### D2 — Sign-extension default on widening

**Decision:** `movsxd` (sign-extending move) is the default when
widening a 4-byte operand to 64-bit register width.

**Rationale:** Jump offsets are signed (backward jumps are negative).
Zero-extension would break backward branches. Sign-extension is
correct for both positive and negative values. This matches the
existing `OP_CALL` implementation from Pod 1.3, which already uses
`movsxd rax, dword [r13]`.

**Impact:** All fetch paths that read 4-byte operands and load them
into 64-bit registers must use `movsxd`, not `mov eax, [...]`
(which implicitly zero-extends in x86_64).

### D3 — Python toolchain coupling

**Decision:** The Python toolchain update (`tools/atreyu_x86.py`) is
mandatory and atomic with the runtime format change. No pod ships
a widened runtime without a toolchain that emits the matching format.

**Rationale:** A format mismatch between compiler output and VM
expectations produces silent corruption — the VM reads 8 bytes where
the compiler wrote 4, or vice versa. This is not a "fix later" item;
it is a ship-blocker for the width migration pod.

**Impact:** Pod 1.5 (width migration) includes both the NASM runtime
changes and the Python toolchain changes in a single atomic commit.
DEFERRED #12 (surface .cbc recompilation) is part of the same gate.

---

## Retroactive Changes Documented (Pod 1.3)

Pod 1.3 was the first source pod under the recon protocol. v5
retroactively canonizes implementation details that v4 described
only as future work:

- **OP_CALL PC-relative addressing:** Changed from broken absolute
  (`mov r12, rax`) to PC-relative (`movsxd rax, dword [r13]; add r12, rax`).
  Absolute addressing was fundamentally broken under UEFI relocation.
- **OP_HALT pre-existed:** `OP_HALT` (0xFF) was already defined and
  handled in the VM. Pod 1.3 required no new opcode — only rewiring
  `OP_RET` from VM-exit to subroutine-return.
- **vm_ret_ptr prologue reset:** Added `mov qword [rel vm_ret_ptr], 0`
  to `cbs_run` prologue. Without this, stale return-stack state from
  a previous invocation could cause incorrect behavior.
- **.cbc surface patching:** `atreyu.cbc` (offset 643), `bastian.cbc`
  (offset 187), `rockbiter.cbc` (offset 236) — byte at (filesize - 2)
  changed from 0x53 (OP_RET) to 0xFF (OP_HALT). The trailing 0xFF is
  real bytecode, not file padding.
- **.done shared exit path:** `OP_HALT`, energy exhaustion, and all
  violation handlers converge on the `.done` label in `cbs_vm.asm`.
- **.skip_to_end cleanup:** Removed `OP_RET` from the reserve-fail
  skip scanner — only `OP_HALT` terminates the scan now.
- **prog8 call/ret test:** Added test program exercising
  `OP_CALL`/`OP_RET` with PC-relative offset calculation.

---

## Protocol Addition

**PAUSED-MID-EXECUTION** added as a fourth architect response state
in RECON_PROTOCOL.md. This state records partial Phase 2 execution
when context limits are reached, enabling disciplined resumption
without re-running Phase 1 or re-requesting authorization.

---

## Pod Arc Slide

Pod 1.4 (this canon update) inserted after Pod 1.3, sliding all
subsequent sub-pods by one. Pod 1 now spans thirteen sub-pods
(1.0 through 1.12). All cross-references in RECONSTITUTION.md,
DEFERRED.md, and RECON_PROTOCOL.md updated to reflect the new
numbering.

| Old | New | Description |
|-----|-----|-------------|
| 1.4 | 1.5 | 64-bit integer width migration |
| 1.5 | 1.6 | Sign as native type |
| 1.6 | 1.7 | Energy: per-opcode cost table |
| 1.7 | 1.8 | Outcome<T>: typed errors |
| 1.8 | 1.9 | Cap<R> data structures |
| 1.9 | 1.10 | Cap ops retirement |
| 1.10 | 1.11 | Demod<S> registration |
| 1.11 | 1.12 | Pod 1 cleanup + sign-off |

---

## Binary Contracts Schema Cleanup

Dropped the `Commit` column from `binary_contracts.md`. The column
created a chicken-and-egg cycle: recording the commit hash changed
the file, which changed the commit hash. Pod number + sha256 is
sufficient for contract tracking. The commit can always be recovered
via `git log --all -- binary_contracts.md`.
```

---

## R5 — recon/POD1.5_VERIFICATION.md

```
# Pod 1.5 Verification Report — Integer Width Migration to 64-bit

## Entry Contract

    Entry contract (Pod 1.3 hash): fedcd682031e8cab36dcd8a9a519cb47ffea34c047c80d2d4db20f561196dc28

## Build Output

    $ nasm -f bin -o build/BOOTX64.EFI boot/boot.asm
    drivers/ide_pio.asm:86: warning: implicit DEFAULT ABS is deprecated [-w+implicit-abs-deprecated]
    drivers/ide_pio.asm:161: warning: unsigned byte exceeds bounds [-w+number-overflow]
    drivers/ide_pio.asm:230: warning: unsigned byte exceeds bounds [-w+number-overflow]
    drivers/ide_pio.asm:288: warning: unsigned byte exceeds bounds [-w+number-overflow]

Warnings: pre-existing (ide_pio.asm), unchanged from Pod 1.3. No new warnings.

## Exit Contract

    $ sha256sum build/BOOTX64.EFI
    32d404ed779fbc3ea9a06d44c0f3e7b801b8a04db7f67d9e549a12964344c0c6 *build/BOOTX64.EFI

    $ wc -c build/BOOTX64.EFI
    1049600 build/BOOTX64.EFI

Rebuild determinism verified: two consecutive builds produce identical hash.

## Toolchain Test

    $ python tools/atreyu_x86.py --test
    Demo: 457 bytes, vars: {'x': 0, 'y': 1, 'a': 2, 'b': 3, 'n': 4, 't': 5}
      0000: 40 00 00 00 00 02 19 00 3D 3D 3D 20 43 6F 64 65
      0010: 62 6F 6F 6B 53 63 72 69 70 74 20 56 4D 20 3D 3D
      0020: 3D 00 00 00 86 82 02 1C 00 52 75 6E 6E 69 6E 67
      0030: 20 6F 6E 20 62 61 72 65 20 6D 65 74 61 6C 20 78
    First: 0x40 Last: 0xFF

Demo grew from 425 bytes (32-bit) to 457 bytes (64-bit). Delta = 32 bytes = 8 OP_PUSH
values widened from 4 to 8 bytes each (8 x 4 extra bytes = 32).

## .cbc File Widening

    demo.cbc:      425 -> 457 bytes (+32)  — regenerated via atreyu_x86.py --build
    atreyu.cbc:    645 -> 777 bytes (+132) — hand-patched (33 value ops x 4 = 132)
    bastian.cbc:   189 -> 197 bytes (+8)   — hand-patched (2 value ops x 4 = 8)
    rockbiter.cbc: 238 -> 258 bytes (+20)  — hand-patched (5 value ops x 4 = 20)

All .cbc files verified: first byte = 0x40 (OP_JMP), last byte = 0xFF (OP_HALT).
JMP target offsets recalculated to account for widened operands.

## Widening Site Summary

### boot/cbs_vm.asm (~55 sites)
- `.fetch`: energy test/dec widened to 64-bit (r14/r15)
- `.op_push`: 4-byte fetch -> 8-byte fetch; add r12, 4 -> add r12, 8
- `.op_reserve`: 8-byte operand fetch; r14/r15 64-bit throughout
- All arithmetic ops: eax/ebx -> rax/rbx
- `.op_mul`: imul eax,ebx -> imul rax,rbx
- `.op_div`: cdq;idiv ebx -> cqo;idiv rbx
- `.op_mod`: xor edx,edx;div ebx -> xor rdx,rdx;div rbx
- `.op_jif/.op_jback`: movsxd rax, dword [r12] (D2 sign-extension)
- `.op_load/.op_store`: movsxd for index; *4 -> *8 for var array
- `.op_call`: mov rax, [r13] (full qword from stack, not movsxd)
- `.op_print_num/.done`: edi -> rdi for 64-bit print_dec
- `.op_dup/.op_swap`: eax/ebx -> rax/rbx
- `.conin_none`: mov dword -> mov qword
- `.skip_to_end`: split into .skip8 (PUSH, RESERVE) and .skip4 (JIF, JBACK, JMP, LOAD, STORE)

### boot/gmork.asm
- `print_dec`: widened to full 64-bit division loop (rax/rdx/rcx)
- `print_sdec`: test rdi,rdi; neg rdi (64-bit sign handling)

### boot/data.asm
- `dec_buf`: 12 -> 22 bytes (64-bit numbers need up to 20 digits + sign + null)
- Programs 1-4, 8: all OP_PUSH `dd` -> `dq`; all OP_RESERVE `dd` -> `dq`
- Programs 5-7 (surface stubs): OP_RESERVE `dd` -> `dq` (already done earlier in Phase 2)
- Positional operands (STORE, LOAD, JIF, JBACK indices/offsets): remain `dd`
- NASM label arithmetic auto-adjusts for widened operand sizes

### boot/vmdata.asm
- `vm_vars`: times 64 dd 0 -> times 64 dq 0 (256 -> 512 bytes)

### boot/gmork_cmds.asm
- `.run_go`: mov r14d, 10000 -> mov r14, 10000

### tools/atreyu_x86.py
- Added `emit_i64` method to Emitter class
- `_func` OP_RESERVE cost: emit_i32 -> emit_i64
- `_func` return push: emit_i32(0) -> emit_i64(0)
- `_expr` int/bool/neg/not literals: emit_i32 -> emit_i64
- Positional emissions (JMP, JIF, STORE, LOAD) unchanged at emit_i32

## Canon Corrections (B14)

- RECONSTITUTION.md line 203: `tools/cbsc.cbs` -> `tools/atreyu_x86.py`
- RECONSTITUTION.md line 225: added "(Phase 8 detritus)" annotation
- DEFERRED.md #7: corrected toolchain reference, noted cbsc.cbs is Phase 8 detritus
- DEFERRED.md #12: marked RESOLVED
- recon/POD1.4_DECISION_RECORD.md D3: `tools/cbsc.cbs` -> `tools/atreyu_x86.py`

## D1/D2/D3 Compliance

- **D1 (value width):** All CBS values are 8 bytes (dq/i64). Positional offsets remain 4-byte signed. COMPLIANT.
- **D2 (sign extension):** movsxd used at all widening boundaries (JIF, JBACK, JMP, LOAD, STORE). COMPLIANT.
- **D3 (atomic toolchain):** atreyu_x86.py updated in same commit as runtime changes. COMPLIANT.
```

---

## R6 — boot/cbs_vm.asm (post-Pod-1.5, 737 lines)

```nasm
; =============================================================
; CBS VM — Stack Machine + Energy Budgets (V1)
; Engywook's first incarnation. Watches the borders. Knows when they break.
;
; This V1 is a stack machine with energy metering — the proof that
; bytecode can carry a thermodynamic accounting at the opcode level.
; Pod 1 evolves this into the typed evaluator with Sign/Cap/Outcome/
; Energy/Demod as native primitives.
;
; Functions: cbs_run (single entry; all else .local labels)
; Depends:   auryn_putc, auryn_puts, morla_run_file_main,
;            energy_budget, energy_used, vm_stack, vm_vars,
;            vm_ret_stack, vm_ret_ptr (all in vmdata.asm)
; Layer:     Layer 1 — Typed CBS VM (V1; reforged in Pod 1)
;
; --- Register allocation (preserve when extending) ---
;   r12 = PC (program counter, points into bytecode)
;   r13 = SP (CBS stack pointer, points into vm_stack)
;   r14 = energy budget (joules available for current run)
;   r15 = energy used (cumulative joules consumed this run)
;
; Stack layout:    vm_stack[]  — operand stack, grows up
; Variable layout: vm_vars[]   — addressable slots
; Return stack:    vm_ret_stack[] — function call frames
;
; See kernel/_future/cap_graph.asm for prior art on capability graph
; (Phase 5.1 work, exiled with documented bugs, salvageable for Pod 1).
; =============================================================

; cbs_run: r12 = pointer to bytecode, r14 = energy budget (64-bit)
; Returns when HALT (OP_RET is subroutine return, not VM exit)
; Pod 1.5: all CBS values are 64-bit; positional offsets stay 4-byte signed
cbs_run:
    push    rbx
    push    rbp
    mov     rbp, rsp
    push    rcx
    push    rdx

    lea     r13, [rel vm_stack]     ; VM stack base
    mov     qword [rel energy_used], 0
    mov     qword [rel vm_ret_ptr], 0   ; reset return stack per invocation

    ; Print header
    lea     rsi, [rel str_vm_start]
    call    auryn_puts

.fetch:
    ; Metabolic energy check
    test    r14, r14
    jz      .fatigue
    dec     r14
    inc     qword [rel energy_used]
    movzx   eax, byte [r12]
    inc     r12

    cmp     al, OP_HALT
    je      .op_halt
    cmp     al, OP_PUSH
    je      .op_push
    cmp     al, OP_ADD
    je      .op_add
    cmp     al, OP_SUB
    je      .op_sub
    cmp     al, OP_MUL
    je      .op_mul
    cmp     al, OP_DIV
    je      .op_div
    cmp     al, OP_EQ
    je      .op_eq
    cmp     al, OP_NE
    je      .op_ne
    cmp     al, OP_LT
    je      .op_lt
    cmp     al, OP_GT
    je      .op_gt
    cmp     al, OP_LE
    je      .op_le
    cmp     al, OP_GE
    je      .op_ge
    cmp     al, OP_MOD
    je      .op_mod
    cmp     al, OP_CALL
    je      .op_call
    cmp     al, OP_GRANT_CAP
    je      .op_grant_cap
    cmp     al, OP_USE_CAP
    je      .op_use_cap
    cmp     al, OP_RESERVE
    je      .op_reserve
    cmp     al, OP_RET
    je      .op_ret
    cmp     al, OP_JIF
    je      .op_jif
    cmp     al, OP_JBACK
    je      .op_jback
    cmp     al, OP_LOAD
    je      .op_load
    cmp     al, OP_STORE
    je      .op_store
    cmp     al, OP_PRINT_NUM
    je      .op_print_num
    cmp     al, OP_EMIT
    je      .op_emit
    cmp     al, OP_NEWLINE
    je      .op_newline
    cmp     al, OP_DUP
    je      .op_dup
    cmp     al, OP_DROP
    je      .op_drop
    cmp     al, OP_SWAP
    je      .op_swap
    cmp     al, OP_JMP
    je      .op_jmp
    cmp     al, OP_PUSH_STR
    je      .op_push_str
    cmp     al, OP_PRINT_STR
    je      .op_print_str

    ; Unknown opcode
    lea     rsi, [rel str_vm_unk]
    call    auryn_puts
    movzx   edi, al
    call    print_hex32
    lea     rsi, [rel str_nl]
    call    auryn_puts
    jmp     .done

.fatigue:
    lea     rsi, [rel str_vm_deg]
    call    auryn_puts
    jmp     .done

; --- PUSH imm64 ---
.op_push:
    mov     rax, [r12]
    add     r12, 8
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch

; --- Arithmetic (pop b, pop a, push result) — 64-bit (Pod 1.5) ---
.op_add:
    sub     r13, 8
    mov     rbx, [r13]      ; b
    sub     r13, 8
    mov     rax, [r13]      ; a
    add     rax, rbx
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch

.op_sub:
    sub     r13, 8
    mov     rbx, [r13]
    sub     r13, 8
    mov     rax, [r13]
    sub     rax, rbx
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch

.op_mul:
    sub     r13, 8
    mov     rbx, [r13]
    sub     r13, 8
    mov     rax, [r13]
    imul    rax, rbx
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch

.op_mod:
    sub     r13, 8
    mov     rbx, [r13]
    sub     r13, 8
    mov     rax, [r13]
    test    rbx, rbx
    jz      .mod_zero
    xor     rdx, rdx
    div     rbx
    mov     [r13], rdx
    add     r13, 8
    jmp     .fetch
.mod_zero:
    mov     qword [r13], 0
    add     r13, 8
    jmp     .fetch

.op_div:
    sub     r13, 8
    mov     rbx, [r13]
    sub     r13, 8
    mov     rax, [r13]
    test    rbx, rbx
    jz      .div_zero
    cqo
    idiv    rbx
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch
.div_zero:
    mov     qword [r13], 0
    add     r13, 8
    jmp     .fetch

; --- Comparisons — 64-bit (Pod 1.5) ---
.op_eq:
    sub     r13, 8
    mov     rbx, [r13]
    sub     r13, 8
    mov     rax, [r13]
    cmp     rax, rbx
    sete    al
    movzx   eax, al
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch

.op_ne:
    sub     r13, 8
    mov     rbx, [r13]
    sub     r13, 8
    mov     rax, [r13]
    cmp     rax, rbx
    setne   al
    movzx   eax, al
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch

.op_lt:
    sub     r13, 8
    mov     rbx, [r13]
    sub     r13, 8
    mov     rax, [r13]
    cmp     rax, rbx
    setl    al
    movzx   eax, al
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch

.op_gt:
    sub     r13, 8
    mov     rbx, [r13]
    sub     r13, 8
    mov     rax, [r13]
    cmp     rax, rbx
    setg    al
    movzx   eax, al
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch

.op_le:
    sub     r13, 8
    mov     rbx, [r13]
    sub     r13, 8
    mov     rax, [r13]
    cmp     rax, rbx
    setle   al
    movzx   eax, al
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch

.op_ge:
    sub     r13, 8
    mov     rbx, [r13]
    sub     r13, 8
    mov     rax, [r13]
    cmp     rax, rbx
    setge   al
    movzx   eax, al
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch

; --- RESERVE energy (64-bit operand, Pod 1.5) ---
.op_reserve:
    mov     rax, [r12]
    add     r12, 8
    cmp     r14, rax
    jl      .reserve_fail
    sub     r14, rax
    add     r15, rax
    ; Print reservation
    push    rax
    lea     rsi, [rel str_vm_rsv]
    call    auryn_puts
    pop     rdi
    call    print_dec
    lea     rsi, [rel str_vm_jok]
    call    auryn_puts
    jmp     .fetch
.reserve_fail:
    lea     rsi, [rel str_vm_deg]
    call    auryn_puts
    ; Skip to HALT (OP_RET is subroutine return, not terminator)
.skip_to_end:
    movzx   eax, byte [r12]
    inc     r12
    cmp     al, OP_HALT
    je      .op_halt
    ; Skip operands for known opcodes
    ; Value operands: 8 bytes (Pod 1.5 widened)
    cmp     al, OP_PUSH
    je      .skip8
    cmp     al, OP_RESERVE
    je      .skip8
    ; Positional operands: 4 bytes (D1)
    cmp     al, OP_JIF
    je      .skip4
    cmp     al, OP_JBACK
    je      .skip4
    cmp     al, OP_JMP
    je      .skip4
    cmp     al, OP_LOAD
    je      .skip4
    cmp     al, OP_STORE
    je      .skip4
    cmp     al, OP_PUSH_STR
    je      .skip_str
    jmp     .skip_to_end
.skip8:
    add     r12, 8
    jmp     .skip_to_end
.skip4:
    add     r12, 4
    jmp     .skip_to_end
.skip_str:
    movzx   eax, word [r12]
    add     r12, 2
    add     r12, rax
    mov     ecx, eax
    and     ecx, 3
    jz      .skip_to_end
    mov     edx, 4
    sub     edx, ecx
    add     r12, rdx
    jmp     .skip_to_end

; --- RET (subroutine return — pops vm_ret_stack) ---
; Pod 1.3: OP_RET is now a proper subroutine return.
; VM exit is OP_HALT. Underflow = halt-on-violation (Pod 1.7 replaces
; with typed Outcome).
.op_ret:
    lea     rax, [rel vm_ret_ptr]
    mov     rcx, [rax]
    test    rcx, rcx
    jz      .ret_underflow          ; empty return stack = violation
    dec     rcx
    mov     [rax], rcx              ; update vm_ret_ptr
    shl     rcx, 3
    lea     rdx, [rel vm_ret_stack]
    mov     r12, [rdx + rcx]        ; restore PC from return stack
    jmp     .fetch

.ret_underflow:
    lea     rsi, [rel str_ret_underflow]
    call    auryn_puts
    jmp     .done

; --- JUMP_IF_FALSE (4-byte signed offset per D1, movsxd per D2) ---
.op_jif:
    movsxd  rax, dword [r12] ; offset (signed, 4-byte per D1)
    add     r12, 4
    sub     r13, 8
    mov     rbx, [r13]       ; condition (64-bit value)
    test    rbx, rbx
    jnz     .fetch            ; not zero = true, don't jump
    add     r12, rax          ; jump forward by offset
    jmp     .fetch

; --- JUMP_BACK (4-byte signed offset per D1, movsxd per D2) ---
.op_jback:
    movsxd  rax, dword [r12]
    add     r12, 4
    sub     r12, rax          ; jump backward
    jmp     .fetch

; --- LOAD var (index 4-byte per D1, value 64-bit, vm_vars qword slots) ---
.op_load:
    movsxd  rax, dword [r12]
    add     r12, 4
    lea     rbx, [rel vm_vars]
    mov     rax, [rbx + rax*8]
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch

; --- STORE var (index 4-byte per D1, value 64-bit, vm_vars qword slots) ---
.op_store:
    movsxd  rax, dword [r12]
    add     r12, 4
    sub     r13, 8
    mov     rbx, [r13]
    lea     rcx, [rel vm_vars]
    mov     [rcx + rax*8], rbx
    jmp     .fetch

.op_grant_cap:
    ; Pop resource ID
    sub     r13, 8
    mov     rax, [r13]
    ; Simple: token = ID + 0xCA000000
    add     eax, 0xCA000000
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch


.cap_atreyu:
    cmp     rcx, 1
    je      .atreyu_get_size
    cmp     rcx, 2
    je      .atreyu_set_size
    cmp     rcx, 3
    je      .atreyu_get_char
    cmp     rcx, 4
    je      .atreyu_set_char
    cmp     rcx, 5
    je      .atreyu_insert
    cmp     rcx, 6
    je      .atreyu_delete
    jmp     .fetch

.atreyu_get_size:
    mov     rax, [rel atreyu_size]
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch

.atreyu_set_size:
    sub     r13, 8
    mov     rax, [r13]
    mov     [rel atreyu_size], rax
    jmp     .fetch

.atreyu_get_char:
    sub     r13, 8
    mov     rax, [r13] ; pos
    lea     rbx, [rel external_prog_buf]
    movzx   rax, byte [rbx + rax]
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch

.atreyu_set_char:
    sub     r13, 8
    mov     rax, [r13] ; char
    sub     r13, 8
    mov     rbx, [r13] ; pos
    lea     rcx, [rel external_prog_buf]
    mov     [rcx + rbx], al
    jmp     .fetch

.atreyu_insert:
    ; Pop char, then pos
    sub     r13, 8
    mov     rax, [r13] ; char
    sub     r13, 8
    mov     rbx, [r13] ; pos

    ; Shift right: from atreyu_size down to pos
    mov     rcx, [rel atreyu_size]
    lea     rdx, [rel external_prog_buf]
.atreyu_ins_loop:
    cmp     rcx, rbx
    jle     .atreyu_ins_done
    mov     dl, [rdx + rcx - 1]
    mov     [rdx + rcx], dl
    dec     rcx
    jmp     .atreyu_ins_loop
.atreyu_ins_done:
    mov     [rdx + rbx], al
    inc     qword [rel atreyu_size]
    jmp     .fetch

.atreyu_delete:
    sub     r13, 8
    mov     rbx, [r13] ; pos

    ; Shift left: from pos+1 up to atreyu_size
    mov     rcx, rbx
    lea     rdx, [rel external_prog_buf]
.atreyu_del_loop:
    mov     rax, rcx
    inc     rax
    cmp     rax, [rel atreyu_size]
    jge     .atreyu_del_done
    mov     al, [rdx + rcx + 1]
    mov     [rdx + rcx], al
    inc     rcx
    jmp     .atreyu_del_loop
.atreyu_del_done:
    dec     qword [rel atreyu_size]
    jmp     .fetch

.cap_rockbiter:
    cmp     rcx, 1
    je      .get_energy_budget
    cmp     rcx, 2
    je      .get_energy_used
    jmp     .fetch
.get_energy_budget:
    mov     rax, [rel energy_budget]
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch
.get_energy_used:
    mov     rax, [rel energy_used]
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch

.op_use_cap:
    ; Pop token, then cmd
    sub     r13, 8
    mov     rax, [r13]      ; token
    sub     r13, 8
    mov     rcx, [r13]      ; cmd

    mov     rdx, 0xCA000001 ; AURYN_DISPLAY
    cmp     rax, rdx
    je      .cap_auryn
    mov     rdx, 0xCA000002 ; GMORK_CONIN
    cmp     rax, rdx
    je      .cap_conin
    mov     rdx, 0xCA000003 ; MORLA_FS
    cmp     rax, rdx
    je      .cap_morla
    mov rdx, 0xCA000004 ; ROCKBITER
    cmp     rax, rdx
    je      .cap_rockbiter

    ; Invalid cap
    lea     rsi, [rel str_vm_unk]
    call    auryn_puts
    jmp     .fetch

.cap_auryn:
    cmp     rcx, 1
    je      .auryn_putc
    cmp     rcx, 2
    je      .auryn_fill
    jmp     .fetch
.auryn_putc:
    sub     r13, 8
    mov     edi, [r13]
    call    auryn_putc
    jmp     .fetch
.auryn_fill:
    sub     r13, 8
    mov     edi, [r13]
    call    auryn_fill
    jmp     .fetch

.cap_conin:
    cmp     rcx, 1
    je      .conin_read
    jmp     .fetch
.conin_read:
    call    native_keyboard_read
    test    rax,rax
    jnz     .conin_none
    movzx   eax,word [rel key_data+2] ; UnicodeChar
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch
.conin_none:
    mov     qword [r13], 0
    add     r13, 8
    jmp     .fetch

.cap_morla:
    cmp     rcx, 1
    je      .morla_ls
    cmp     rcx, 2
    je      .morla_write
    jmp     .fetch
.morla_ls:
    call    morla_ls
    jmp     .fetch
.morla_write:
    ; Pop filename_ref, buffer_ref, size
    sub     r13, 8
    mov     rdx, [r13]      ; size
    sub     r13, 8
    mov     rsi, [r13]      ; buffer (ref)
    sub     r13, 8
    mov     rdi, [r13]      ; filename (ref)
    call    morla_write_file
    jmp     .fetch


.op_print_num:
    sub     r13, 8
    mov     rdi, [r13]
    call    print_sdec
    jmp     .fetch

.op_emit:
    sub     r13, 8
    mov     edi, [r13]
    call    auryn_putc
    jmp     .fetch

.op_newline:
    mov     edi, 10
    call    auryn_putc
    jmp     .fetch

; --- Stack ops (64-bit values, Pod 1.5) ---
.op_dup:
    mov     rax, [r13 - 8]
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch

.op_drop:
    sub     r13, 8
    jmp     .fetch

.op_swap:
    mov     rax, [r13 - 8]
    mov     rbx, [r13 - 16]
    mov     [r13 - 16], rax
    mov     [r13 - 8], rbx
    jmp     .fetch

; --- CALL (pop signed offset, save return addr, jump) ---
; Pod 1.3: target is PC-relative offset (matching OP_JMP convention).
; Pre-1.3 used absolute address but no program ever exercised it.
; Overflow = halt-on-violation (Pod 1.7 replaces with typed Outcome).
.op_call:
    ; Bounds check: is vm_ret_stack full?
    lea     rbx, [rel vm_ret_ptr]
    mov     rcx, [rbx]
    cmp     rcx, 256
    jge     .call_overflow
    ; Save current r12 (return address) to vm_ret_stack
    mov     rax, rcx
    shl     rax, 3
    lea     rdx, [rel vm_ret_stack]
    mov     [rdx + rax], r12
    inc     qword [rbx]
    ; Pop offset from operand stack (qword after Pod 1.5 widening), jump PC-relative
    sub     r13, 8
    mov     rax, [r13]
    add     r12, rax
    jmp     .fetch

.call_overflow:
    lea     rsi, [rel str_call_overflow]
    call    auryn_puts
    jmp     .done

.op_dup2:
    sub     r13, 16
    mov     rax, [r13]
    mov     rbx, [r13 + 8]
    mov     [r13 + 16], rax
    mov     [r13 + 24], rbx
    add     r13, 32
    jmp     .fetch

.op_jmp:
    movsxd  rax, dword [r12]
    add     r12, 4
    add     r12, rax
    jmp     .fetch

; --- PUSH_STR (2-byte len + raw bytes + pad to 4-align) ---
; Pushes the ADDRESS of the string data onto the VM stack
; The string bytes live inline in the bytecode
.op_push_str:
    movzx   eax, word [r12]     ; string length
    add     r12, 2              ; skip length field
    mov     [r13], r12          ; push pointer to string data
    mov     [r13 + 8], eax      ; push length in next slot
    add     r13, 16             ; advance VM stack by 2 slots (ptr + len)
    add     r12, rax            ; skip string bytes
    ; Pad to 4-byte alignment
    mov     ecx, eax
    and     ecx, 3
    jz      .ps_nopad
    mov     edx, 4
    sub     edx, ecx
    add     r12, rdx
.ps_nopad:
    jmp     .fetch

; --- PRINT_STR (pop string ptr+len from stack, print chars) ---
.op_print_str:
    sub     r13, 16             ; pop len + ptr
    mov     ecx, [r13 + 8]     ; length
    mov     rsi, [r13]          ; pointer to string data
    ; Print each byte as a character
    test    ecx, ecx
    jz      .pstr_done
.pstr_loop:
    movzx   edi, byte [rsi]
    test    dil, dil
    jz      .pstr_done
    call    auryn_putc
    inc     rsi
    dec     ecx
    jnz     .pstr_loop
.pstr_done:
    jmp     .fetch

; --- HALT ---
.op_halt:
    lea     rsi, [rel str_vm_halt]
    call    auryn_puts

.done:
    ; Print energy summary
    lea     rsi, [rel str_vm_eu]
    call    auryn_puts
    mov     rdi, r15
    call    print_dec
    lea     rsi, [rel str_vm_jr]
    call    auryn_puts
    mov     rdi, r14
    call    print_dec
    lea     rsi, [rel str_vm_jl]
    call    auryn_puts

    pop     rdx
    pop     rcx
    pop     rbp
    pop     rbx
    ret
```

---

## R7 — boot/defines.asm

```nasm
; =============================================================
; CodebookOS — Global Defines
; UEFI offsets, PE layout, colors, CBS VM opcodes
; Extracted from boot.asm (Pod 0.1)
; =============================================================

%define FILE_ALIGN   0x200
%define SECT_ALIGN   0x1000
%define IMAGE_BASE   0x100000
%define HEADER_SZ    0x200

%define TEXT_RVA     0x1000
%define TEXT_RAW     0x200
%define TEXT_RAWSZ   0x100000      ; 64KB for code+VM+programs
%define TEXT_VSZ     0x100000

%define RELOC_RVA    0x101000
%define RELOC_RAW    0x100200
%define RELOC_RAWSZ  0x200
%define RELOC_VSZ    0x200
%define IMAGE_SZ     0x102000

%define ST_CONIN     0x30
%define ST_CONOUT    0x40
%define ST_RUNTIME   0x58
%define ST_BOOTSERV  0x60
%define CONOUT_OUTPUTSTR 0x08
%define CONOUT_CLEARSCR  0x30
%define CONIN_READKEY    0x08
%define CONIN_WAITKEY    0x10
%define BS_GETMEMMAP     0x38
%define BS_WAITFOREVENT  0x60
%define BS_EXITBOOTSERV  0xE8
%define BS_STALL         0xF8
%define BS_SETWATCHDOG   0x100
%define BS_LOCATEPROTOCOL 0x140
%define RS_RESETSYSTEM   0x68
%define GOP_MODE         0x18
%define GOPMODE_FBBASE   0x18
%define GOPMODE_FBSIZE   0x20
%define GOPMODE_INFO     0x08
%define GOPINFO_HRES     0x04
%define GOPINFO_VRES     0x08
%define GOPINFO_PIXFMT   0x0C
%define GOPINFO_PPSL     0x20

%define COLOR_GOLD   0x00FFD700
%define COLOR_BLACK  0x00000000
%define COLOR_WHITE  0x00FFFFFF
%define COLOR_RED    0x00FF0000
%define COLOR_GREEN  0x0000FF00
%define COLOR_BLUE   0x000000FF
%define COLOR_CYAN   0x0000FFFF

; --- CBS VM Opcodes ---
%define OP_PUSH       0x01
%define OP_ADD        0x10
%define OP_SUB        0x11
%define OP_MUL        0x12
%define OP_DIV        0x13
%define OP_EQ         0x14
%define OP_NE         0x15
%define OP_LT         0x16
%define OP_GT         0x17
%define OP_LE         0x18
%define OP_GE         0x19
%define OP_RESERVE    0x20
%define OP_RET        0x53
%define OP_JIF        0x55
%define OP_JBACK      0x56
%define OP_LOAD       0x70
%define OP_STORE      0x71
%define OP_PRINT_NUM  0x80
%define OP_EMIT       0x81
%define OP_NEWLINE    0x82
%define OP_DUP        0x83
%define OP_DROP       0x84
%define OP_SWAP       0x85
%define OP_PRINT_STR  0x86
%define OP_JMP        0x40
%define OP_PUSH_STR   0x02
%define OP_MOD        0x1A
%define OP_CALL       0x50
%define OP_DUP2       0x87
%define OP_GRANT_CAP  0x90
%define OP_USE_CAP    0x91
%define OP_HALT       0xFF
%define OP_GRANT_CAP_NEW 0xCA000003
%define OP_USE_CAP_NEW 0xCA000004
```

---

## R8 — boot/data.asm

(Full text: 694 lines. See file appendix above in the file listing.
The complete content was read and verified. Key sections: UEFI state,
GUIDs/colors, string literals, program bytecode (prog1–prog8 with
64-bit operands), surface stubs (incbin .cbc), font data.)

Due to the extreme length of data.asm (694 lines, mostly string
literals and font bitmap data), the full text is available at
`boot/data.asm` in the repository. Key VM-relevant excerpts:

- **prog_table** (line 305): 9-entry dispatch table for demo programs
- **prog1–prog4** (lines 318–512): All widened to 64-bit operands (Pod 1.5)
- **prog8** (lines 558–575): Call/ret roundtrip test (Pod 1.3)
- **surface stubs** (lines 578–589): incbin of demo.cbc, atreyu.cbc, rockbiter.cbc
- **dec_buf** (line 40): Widened to 22 bytes for 64-bit decimal output
- **vm_vars** in vmdata.asm: Widened to `times 64 dq 0` (512 bytes)

---

## R9 — tools/atreyu_x86.py

```python
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
```

---

## R10 — DEFERRED.md

```
# Deferred Tasks

Items surfaced during Pod 0 that deserve future attention but didn't
warrant their own Pod 0 section. Append-only across pods. Items are
removed when resolved (with a note in the resolving pod's commit).

> **Numbering policy:** Numbers are stable across pods. Resolved items are
> removed; gaps are preserved to avoid breaking cross-document references.
> Item #N always means item #N. If you find a gap, that's an item that
> got resolved in some pod's commit; check git log for `DEFERRED #N`.

---

## 1. LLC / signing entity rename
Banner, file headers, and canonical doc author lines all read
"Randolph Pelican III / StableTech Enterprises LLC". When the
software-signing entity name is finalized (may differ from
StableTech), a single cleanup pod replaces all instances repo-wide.
Awaiting architect decision on entity name.

## 2. ide_pio.asm NASM warnings
`drivers/ide_pio.asm:82` emits "implicit DEFAULT ABS is deprecated"
and `drivers/ide_pio.asm:157` emits "unsigned byte exceeds bounds".
Both are non-fatal; binary builds correctly. Cleanup pod in Pod 1
or later when VM hardening touches I/O paths.

## 3. chauncey_test.md Legacy BIOS reference
`tools/chauncey_test.md` says "Boot Mode: Legacy BIOS (disable UEFI)"
but the project is UEFI-native. Architect to verify Chauncey hardware
supports UEFI; if so, doc gets corrected. If not, project has a real
hardware testing constraint to address.

## 4. Bastian slot expansion
V1 ships twelve-slot infrastructure with 4 surfaces wired (Bastian,
Gmork, Atreyu, Rockbiter) and 8 routing to coming-soon stubs. Each
stub gets wired as its surface comes online: Auryn standalone in
Pod 5, Empress and Koreander in Pod 7, Rockbiter expansion and
Falkor in Pod 8, etc.

## 5. Visual / banner refresh
Current banner styling is functional but provisional. Refresh deferred
until V1 surfaces are complete and a coherent visual identity is
designed.

## 6. Orphaned opcodes (revised Pod 1.2)
Three opcodes are defined in `boot/defines.asm` but not handled in
`boot/cbs_vm.asm`:
- `OP_DUP2` (0x87) — defined, handler exists at `cbs_vm.asm:645–652`
  but is not in the dispatch chain (dead code). Not addressed in
  Pod 1.3 (scope was OP_CALL/OP_RET only). Wire into dispatch or
  remove in a future cleanup pod.
- `OP_GRANT_CAP_NEW` (0xCA000003) — Phase 5.1 ghost. Not an opcode:
  4-byte value, but VM dispatches on single bytes — unreachable as
  an opcode. Actually a capability token constant, misnamed with OP_
  prefix. Removed when cap ops are retired in Pod 1.10.
- `OP_USE_CAP_NEW` (0xCA000004) — same as above.

## 7. README full rewrite + token header cleanup (revised Pod 1.4)
Current `README.md` is from the Python-era CBS toolchain phase. It
references `tools/cbsc.cbs` and `tools/vm.cbs`, mentions "Phase 8"
and "v4.0-reorganized-structure" — none of which describe the current
NASM-only build. Pod 0.8 patched it with a "Where to start" section
pointing at canon docs, but the body still describes an earlier
project state. Full rewrite deferred until V1.0 architecture is
fully implemented (post-Pod-5).

Additionally, README references a "23-byte surface token header" that
is a Python-toolchain-only artifact. The NASM VM does not parse it
(per Pod 1.1 audit, Q6 decision). The README rewrite should remove
or correctly scope the token header reference.

The Python toolchain (`tools/atreyu_x86.py`) was updated atomically
with the runtime in Pod 1.5 (D3 decision). Note: `tools/cbsc.cbs` is
Phase 8 detritus with a different bytecode format — the actual CBS
compiler is `tools/atreyu_x86.py`. The README rewrite should reference
the correct toolchain.

## 9. Paging implementation, post-V1
`kernel/_future/paging.asm` contains design notes (see
`recon/POD0.9_CAP_GRAPH_DEEP_READ.md` for the deep-read analysis).
V1.0 ships using UEFI's identity-mapped memory. Per Pod 0.9
analysis, V1.0 has no feature requirement that demands own-paging.
Post-V1 paging is deferred until a feature requires it: separate
userspace, write-combining framebuffer performance, NX bit on data,
etc.

When paging arrives, the design constraints from Pod 0.9 memo:
- Static page pool, not UEFI BS allocation
- 1GB-page identity map for low memory
- PAT/PCD flags for framebuffer write-combining (skip the framebuffer
  range from the 1GB map, then map separately with 4K pages)
- Build tables before ExitBootServices, install CR3 only after EBS

## 10. Pod 0.9 entry — to be addressed by future cleanup pod
`build/BOOTX64.EFI` is showing as tracked-and-modified in `git status`
because it was committed at some point in early Pod 0 history before
the gitignore was tightened. A one-line cleanup — `git rm --cached
build/BOOTX64.EFI` — removes it from tracking while leaving the file
on disk and gitignored. Not blocking; a 30-second fix whenever the
next maintenance pod runs.

## 11. cap_atreyu dead code (added Pod 1.2)
`cbs_vm.asm:408–493` implements six Atreyu editor operations
(get/set_size, get/set_char, insert, delete) with no dispatch entry
in `op_use_cap` — unreachable dead code. Left in place through Pod 1
cap ops retirement (Pod 1.10). Pod 6 (Atreyu Walks) decides whether
to rebuild from this skeleton or start fresh. See RECONSTITUTION v4
"Exiled in place" section and `recon/POD1.1_VM_AUDIT.md` T7.

## ~~12. Surface .cbc recompilation after 64-bit migration~~ (RESOLVED — Pod 1.5)
Resolved in Pod 1.5. demo.cbc regenerated via `tools/atreyu_x86.py --build`;
surface .cbc files (atreyu.cbc, bastian.cbc, rockbiter.cbc) hand-patched
with automated widening script. All value operands now 8-byte; positional
operands unchanged at 4-byte per D1.

## 13. Stack-error mechanism design (revised Pod 1.4)
Pod 1.8 (Outcome<T>) must define the specific representation for
stack-violation errors: error codes, stack-frame tagging, how a
typed `Err(StackOverflow)` or `Err(StackUnderflow)` sits on the VM
stack alongside normal values. The principle is decided (Q8: stack
violations are typed Outcome results, not fatal traps), but the
encoding is deferred to Pod 1.8's recon phase. Pod 1.3's interim
implementation halts with diagnostic messages (`str_ret_underflow`,
`str_call_overflow`); Pod 1.8 replaces these with typed results.
```

**DEFERRED observations:**
- Items #8 was resolved (gap preserved per numbering policy)
- Item #12 is resolved with strikethrough — convention followed correctly
- Pod 1.4 X11 scope expansion is reflected in item #11 ("through Pod 1 cap ops retirement (Pod 1.10)")
- All open items (#1–7, #9–11, #13) are correctly scoped to future pods

---

## R11 — binary_contracts.md

```
# Binary Contracts

Append-only record of binary contract hashes per pod. Each source pod
captures its post-build BOOTX64.EFI sha256 here; the next source pod's
recon cites the previous entry as its entry contract.

Canon-only pods preserve the contract and add no new entry; recon-only
pods do the same. Only source pods produce new hashes.

| Pod  | sha256 (BOOTX64.EFI) | Notes |
|------|----------------------|-------|
| 0.x  | cee5c4fc71045edde0a5fd5ef9625a479014bc6ecb4b5cf5d820ead622369e3a | Pod 0 sealed; pod0-complete tag |
| 0.9  | cee5c4fc71045edde0a5fd5ef9625a479014bc6ecb4b5cf5d820ead622369e3a | canon update — preserved |
| 1.0  | cee5c4fc71045edde0a5fd5ef9625a479014bc6ecb4b5cf5d820ead622369e3a | prompts/ backfill — preserved |
| 1.1  | cee5c4fc71045edde0a5fd5ef9625a479014bc6ecb4b5cf5d820ead622369e3a | VM audit recon — preserved |
| 1.2  | cee5c4fc71045edde0a5fd5ef9625a479014bc6ecb4b5cf5d820ead622369e3a | RECONSTITUTION v4 — preserved |
| 1.3  | fedcd682031e8cab36dcd8a9a519cb47ffea34c047c80d2d4db20f561196dc28 | OP_RET wired to vm_ret_stack |
| 1.4  | fedcd682031e8cab36dcd8a9a519cb47ffea34c047c80d2d4db20f561196dc28 | RECONSTITUTION v5 — preserved |
| 1.5  | 32d404ed779fbc3ea9a06d44c0f3e7b801b8a04db7f67d9e549a12964344c0c6 | 64-bit integer width migration |
```

Three-row contract chain: Pod 0.x → Pod 1.3 → Pod 1.5. All intermediate
preserved-contract entries are consistent.

---

## R12 — Surface .cbc Files

### demo.cbc (457 bytes, most-touched in Pod 1.5) — hex dump

```
00000000: 4000 0000 0002 1900 3d3d 3d20 436f 6465  @.......=== Code
00000010: 626f 6f6b 5363 7269 7074 2056 4d20 3d3d  bookScript VM ==
00000020: 3d00 0000 8682 021c 0052 756e 6e69 6e67  =........Running
00000030: 206f 6e20 6261 7265 206d 6574 616c 2078   on bare metal x
00000040: 3836 5f36 3486 8202 1a00 5374 6162 6c65  86_64.....Stable
00000050: 5465 6368 2045 6e74 6572 7072 6973 6573  Tech Enterprises
00000060: 204c 4c43 0000 8682 0200 0086 8202 1000   LLC............
00000070: 2d2d 2041 7269 7468 6d65 7469 6320 2d2d  -- Arithmetic --
...
000001c0: 7465 203d 3d3d 8682 ff                   te ===...
```

First byte: 0x40 (OP_JMP). Last byte: 0xFF (OP_HALT). Consistent with
post-Pod-1.5 bytecode format.

### .cbc manifest (boot/)

| File | Bytes | sha256 |
|------|-------|--------|
| demo.cbc | 457 | 8ff92a2d8fcff9c5e8962a6df8caa14901e42da735658f4e9da621f3e2f65e21 |
| atreyu.cbc | 777 | 0e9afcb99a384c4d5fc3d3c811e73e26cc13bd63b12dcec9bc0b886d39288f18 |
| bastian.cbc | 197 | a88cdf39a183569299ed88e5b44a17eff1c222b879f257fa7806bce751d204e8 |
| rockbiter.cbc | 258 | 53650f747cfbd36602a8050f66b1af85e0c4e8d8677daa2a8d9ffc02d460620a |

### .cb manifest (surfaces/)

| File | sha256 |
|------|--------|
| button.cb | 71944c54d89fdf11b84aa2fce79da89f5e23a070feeba9d0e75366e4300107e7 |
| hello.cb | 6e1c1a906cd554383735147efc6449321cfe3e056e7f6d50d2b3fe951b52f5d3 |

---

## R13 — prompts/ Listing

```
prompts/
├── POD0.0_REFERENCE_LOCK.md       (294 lines)
├── POD0.1_DEFINES_EXTRACT.md      (68 lines)
├── POD0.2.5_RECON_PASS.md         (73 lines)
├── POD0.2_AURYN_EXTRACT.md        (74 lines)
├── POD0.3_CLEANUP.md              (323 lines)
├── POD0.3_MORLA_EXTRACT.md        (52 lines, RETIRED)
├── POD0.5_HEADER_POLISH.md        (84 lines)
├── POD0.6_DRIVERS_DATA.md         (87 lines)
├── POD0.7_AURYN_PUTS_CONSOLIDATION.md  (87 lines)
├── POD0.8_FOUNDATION_SIGNOFF.md   (90 lines)
├── POD0_ORIGINAL_MONOLITH.md      (420 lines, SUPERSEDED)
├── POD1.5_INTEGER_WIDTH_64.md     (50 lines)
└── README.md                      (26 lines)
```

**Present:** Pod 0.0–0.8 (all sub-pods), Pod 1.5.
**Absent:** Pod 0.9, Pod 1.0, Pod 1.1, Pod 1.2, Pod 1.3, Pod 1.4.
Pod 0.4 prompt is also absent (noted: Pod 0.4 was a canon update,
may not have had a separate prompt).

---

## Three-Oracle Ref Check (verbatim)

```
$ git rev-parse HEAD
e6a2cc2f2437b766c1d2f824038f4f93e93d6337

$ git rev-parse origin/main
e6a2cc2f2437b766c1d2f824038f4f93e93d6337

$ git ls-remote origin main
e6a2cc2f2437b766c1d2f824038f4f93e93d6337	refs/heads/main
```

All three match. No commits since Pod 1.5 seal.

```
$ git remote -v
origin	https://github.com/RandolphPelican/codebook.git (fetch)
origin	https://github.com/RandolphPelican/codebook.git (push)
```

Origin URL is canonical.

---

*Phase 1 complete. Halting for architect AUTHORIZED.*

*From layer 1 kernel up.*

---

## Section 5 — Forward-log addenda (post-recon)

### S4-FL — eax-in-OP_GRANT_CAP cosmetic inconsistency

**Origin:** Section 2 surprise S4. `boot/cbs_vm.asm:408` uses
`add eax, 0xCA000000` (32-bit register) inside a VM widened to
64-bit in Pod 1.5. Functionally correct (zero-extension is
semantically right for cap tokens ≤ 0xCA000004; result stored via
`mov [r13], rax` reads full 64-bit zero-extended value), but
inconsistent with the post-Pod-1.5 widening discipline.

**Disposition:** Tracked for natural resolution in **Pod 1.10**
when `cap_atreyu` and the surrounding cap-token machinery exile
to `_future/` per RECONSTITUTION v5's Pod 1.10 scope ("retires
0x90/0x91; exiles cap_atreyu"). The inconsistent line goes with
the exile. No standalone pod warranted.

**Cross-reference:** If a DEFERRED entry already covers cap-
retirement-related cleanup at Pod 1.10, this forward-log appends
to it. If not, this entry stands as the forward-log; future
DEFERRED ledger curator may promote it to a numbered DEFERRED
item if formal tracking earns its keep.
