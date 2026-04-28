# prompts/

Pod-by-pod build prompts for CodebookOS. Each file is the prompt as it was
delivered to Terminal Boy on the day. Reconstructed prompts (where the
original was not preserved) carry an explicit `SOURCE: reconstructed` header.
Retired prompts (planned but superseded) carry an explicit `STATUS: RETIRED`
header.

## Naming convention

`PODX.Y_NAME.md` — sub-pod X.Y of Pod X, descriptive name in SCREAMING_SNAKE.

## Sub-pods without standalone prompt files

Some sub-pods were canon-only or memo-only work directed conversationally
and produced no standalone prompt artifact. They are documented here so the
absence is explicit, not a gap:

- **POD0.4 (Canon updates v2):** Conversational canon work landing in
  RECONSTITUTION.md v2 at commits a521db2 and 8a04b16. No standalone prompt.
- **POD0.9 (cap_graph + paging deep read):** Conversational memo work
  landing as `recon/POD0.9_CAP_GRAPH_DEEP_READ.md` at commit 0ab996c, with
  RECONSTITUTION.md v3 follow-on at a26b173. No standalone prompt.

Future canon-only or memo-only sub-pods should still leave a short stub
prompt file here for posterity, even when the deliverable is elsewhere.
