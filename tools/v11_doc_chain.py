#!/usr/bin/env python3
"""
V1.1 doc seal-chain flip.

Convention (Pod 5): chain, never overwrite. Every existing V1.0 statement is
true *about V1.0* and stays exactly as written; V1.1 statements are added
alongside. This has a useful side effect: polish/test/test_docs.py asserts the
V1.0 sha is present in README/ARCHITECTURE/CBS_LANGUAGE/CONTRIBUTING, and
chaining keeps all of those assertions passing unmodified.

One exception: CONTRIBUTING.md line 103 makes a claim about *present policy*
("substrate-tier changes are V2.0 work", "the substrate is byte-locked at
<V1.0 sha>"). V1.1 is the counterexample, so a chain-append would leave a
false sentence standing. That one is reworded — and still contains the V1.0
sha, so the test keeps passing.

Frozen, deliberately untouched: release/RELEASE_NOTES.md,
release/v1.0-ship_TAG_MESSAGE.txt, drafts/*, recon/*, and the dated
"Updated: May 11, 2026" header at RECONSTITUTION.md:11. Those describe what
shipped in May; editing them to match today's code is the exact rot the
ledger separation was designed to prevent.

Run from repo root:  python3 tools/v11_doc_chain.py
"""

import os
import sys

V10 = 'c9923b8cf9fb6caf4c195e2d0d0ea2ed4a8e51e4e9f827b1fc24dd0b28c1d900'
V11 = '58823aa9e9ad17c3fd0975cad557c934599c22588c38506d4454b6dbe1b5db6a'

# (path, mode, anchor, payload)
#   mode 'after' -> insert payload as a new line following the anchor line
#   mode 'tail'  -> append payload to the end of the anchor's line
#   mode 'swap'  -> replace anchor outright
EDITS = [
    ('README.md', 'after',
     'V1.0 SEAL contract sha: `%s`' % V10,
     'V1.1 SEAL contract sha: `%s` (Pod 5 metabolic enforcement; see `recon/POD5_DECISION_RECORD.md`)' % V11),

    ('ARCHITECTURE.md', 'after',
     'V1.0 SEAL substrate contract: `%s`.' % V10,
     'V1.1 SEAL substrate contract: `%s`. Seal shas are chained, never overwritten.' % V11),

    ('CBS_LANGUAGE.md', 'tail',
     'Any code change that affects substrate behavior shifts this sha; pure documentation changes do not.',
     ' The V1.1 SEAL contract sha is `%s` (Pod 5 metabolic enforcement); seal shas are chained, never overwritten.' % V11),

    ('RECONSTITUTION.md', 'after',
     'V1.0 SEAL contract: **`%s`** (load-bearing reference for regression discipline across Pod 4.0 polish work).' % V10,
     'V1.1 SEAL contract: **`%s`** (Pod 5 metabolic enforcement; the live contract from V1.1 onward, chained per Pod 5 convention).' % V11),

    ('RECONSTITUTION.md', 'tail',
     '— V1.0 SEAL contract sha.',
     ' V1.1 reseals at **`%s`** after Pod 5 metabolic enforcement.' % V11),

    ('polish/README.md', 'tail',
     'substrate stays unchanged through V1.0 SHIP except for OP_READ_KEY addition at Pod 4.0.F (per D4.2).',
     ' V1.1 reseals the substrate at `%s` (Pod 5 metabolic enforcement — a credential-tier change, outside the polish layer).' % V11),

    ('CONTRIBUTING.md', 'swap',
     'Substrate-tier changes are V2.0 work. The bar is high: every substrate change rewrites the V1.0 SEAL contract sha. **At V1.0 SHIP, the substrate is byte-locked at `%s`** (per D4.1 polish-vs-credential separation). Polish-tier work must not touch any file under `boot/`.' % V10,
     'Substrate-tier changes require a decision record in `recon/` and reseal the contract sha. The bar is high: every substrate change rewrites the SEAL contract sha, and the new sha is **chained** into the docs rather than overwriting the old one. **The substrate is byte-locked per release — V1.0 at `%s`, V1.1 at `%s`** (per D4.1 polish-vs-credential separation; V1.1 reseal per Pod 5). Polish-tier work must not touch any file under `boot/`.' % (V10, V11)),
]


def die(msg):
    print('ABORTED: %s' % msg)
    sys.exit(1)


def main():
    if not os.path.isfile('README.md'):
        die('run me from the repo root (no README.md in %s)' % os.getcwd())

    # Preflight: every anchor must exist exactly once, nothing already chained.
    loaded = {}
    for path, mode, anchor, payload in EDITS:
        if not os.path.isfile(path):
            die('missing file: %s' % path)
        if path not in loaded:
            with open(path, 'r', encoding='utf-8', newline='') as f:
                loaded[path] = f.read()
        text = loaded[path]
        if text.count(anchor) != 1:
            die('anchor matched %d times (expected 1) in %s:\n  %s'
                % (text.count(anchor), path, anchor[:90]))

    for path in loaded:
        if V11 in loaded[path]:
            die('%s already contains the V1.1 sha - chain appears to have run' % path)

    print('preflight OK - %d edits across %d files' % (len(EDITS), len(loaded)))

    # Apply.
    for path, mode, anchor, payload in EDITS:
        text = loaded[path]
        nl = '\r\n' if '\r\n' in text else '\n'
        if mode == 'after':
            new = anchor + nl + payload
        elif mode == 'tail':
            new = anchor + payload
        elif mode == 'swap':
            new = payload
        else:
            die('bad mode %r' % mode)
        loaded[path] = text.replace(anchor, new)
        print('  %-22s %-6s ok' % (path, mode))

    for path, text in loaded.items():
        with open(path, 'w', encoding='utf-8', newline='') as f:
            f.write(text)

    # Postflight: the V1.0 sha must survive everywhere test_docs.py looks.
    print('')
    for path in ['README.md', 'ARCHITECTURE.md', 'CBS_LANGUAGE.md', 'CONTRIBUTING.md']:
        with open(path, encoding='utf-8') as f:
            c = f.read()
        print('  %-22s V1.0 present: %-5s  V1.1 present: %s'
              % (path, V10 in c, V11 in c))

    print('')
    print('DOC CHAIN COMPLETE')


if __name__ == '__main__':
    main()
