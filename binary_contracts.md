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
