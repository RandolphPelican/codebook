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
| 1.5.5 | 32d404ed779fbc3ea9a06d44c0f3e7b801b8a04db7f67d9e549a12964344c0c6 | pre-Pod-1.6 recon — preserved |
| 1.6  | 32d404ed779fbc3ea9a06d44c0f3e7b801b8a04db7f67d9e549a12964344c0c6 | Sign as native type (canon) — preserved |
| 1.7  | 975a7f809c350d09b2031b9f5490261986d878d5a04e66709f97fae7083b05dc | Sign source implementation |
| 1.8  | ee50771f6802c7b5b69ba5c4af9d0393b13ced5b13b3e616a70bdf94727d4e65 | Energy as native type (per-opcode cost table + DEFERRED #15 resolved) |
| 1.8.5b | a6b8c0f16a148058a41c33601123a7eb7941473b9a828982378473fe46d84a75 | Move 4 — canonical IDs retrofit (Sign + Energy via registry indirection); observed (TB WSL Ubuntu sha256sum verbatim, two-build determinism on BOOTX64.EFI, bare-metal Sign+Energy round-trip passed) |
| 1.8.5b.5 | a6b8c0f16a148058a41c33601123a7eb7941473b9a828982378473fe46d84a75 | preserved (canon-only pod 1.8.5b.5 — prompts backfill, no source changes) |
| 1.8.5c | 03d2642998f41c4ce2080267b41033a78bdafafb96aded360396338f30fe8199 | Conduits — Moves 1, 2, 3, 6, 7 (per-demod cost-table indirection; auto-provenance default-OFF + ProvEvent ring; arena_id + owner_demod_id on Sign A1(d)-reclaim and Energy reserved-tail; OP_ENERGY_RECOVER 0xD4 no-op-with-log; vm_phase enum + OP_PHASE_QUERY 0xD5); observed (TB WSL Ubuntu sha256sum verbatim, two-build determinism, Sign+Energy regression invisible, OP_PHASE_QUERY/OP_ENERGY_RECOVER smoke tests passed, B6 liveness clean) |
| 1.9.1 | 03d2642998f41c4ce2080267b41033a78bdafafb96aded360396338f30fe8199 | preserved (canon-only pod 1.9.1 — Outcome design decisions + RECONSTITUTION v9 patch, no source changes) |
| 1.9.2a | 23e0ed8cfa9a0ba658034fbdaef154d43d81c442167ae77838108a89a9a7d432 | Outcome substrate plumbing (slot pool + outcome_registry per Pod 1.8.5b pattern; vm_fetch_count substrate gap closure per D1.9.1.7; TYPE_CODE_* enum + OUTCOME_ID_NULL constants; new boot/outcome.asm); observed (TB WSL Ubuntu sha256sum verbatim, two-build determinism, Sign+Energy regression invisible — 174j/53j canaries held — confirming structural-not-metabolic doctrine extends to vm_fetch_count, B4 liveness clean) |
| 1.9.2b | 857622e97747df37a19fa5dfed733c211a98257670ae77f20260c06bdfca797b | Outcome opcode handlers + dispatch + cost table + sentinel log strings + prov_append wire-up + tools support + 6 test surfaces (D1.9.1.4 five accessor opcodes at 0xE0-0xE4; D1.9.1.6 prov_append hook in NEW_ERR with A1 fetch_counter bifurcation; D1.9.1.8 sentinel-and-log on UNWRAP wrong-discriminant; A1/A2/A3 ratifications); observed (TB WSL Ubuntu sha256sum verbatim, two-build determinism, Sign+Energy regression invisible — 174j/53j canaries held — six Outcome test surfaces (B4-B9) round-trip verified per fresh-boot harness, UNWRAP wrong-discriminant log lines confirmed verbatim, prov_append first-consumer wire-up clean with cap-gate default-OFF, B10 liveness clean; mid-Phase-2B within-scope fix added missing OP_OUTCOME_* opcode constants to defines.asm per D1.9.2b.10) |
| 1.9.3 | 3bfb0c0a2410e90c9aa9d5def1c598ec26d6c058d68c73cf67cb2da5e737fff6 | Sign + Energy accessor refit + stack-violation refit (closes DEFERRED #13; partial closure of #16 — multi-value accessors HASH/LABEL deferred per A1 i-revised); observed (TB WSL Ubuntu sha256sum verbatim, two-build determinism, 174j/53j canaries held verbatim under Path A success-wrapping per per-opcode-flat-cost model, 4 new error-path tests verify Err shapes, stack-violation refit produces typed Err on operand stack at halt, 6 Pod 1.9.2b Outcome tests byte-identical, B9 liveness clean; mid-Phase-2B Path A course-correction from PAUSED-MID-EXECUTION executed on inferred re-ratification — D1.9.3.8 audit-trail entry records honesty) |
| 1.9.4 | 3bfb0c0a2410e90c9aa9d5def1c598ec26d6c058d68c73cf67cb2da5e737fff6 | preserved (canon-only pod 1.9.4 — throwaway test script removal, no source changes; entry contract carried forward from 1.9.3) |
