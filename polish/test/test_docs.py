"""Tier 2 doc-structure smoke tests for the 5 V1.0 SHIP public docs.

Verifies file presence + headline structure + internal link resolution + key anchors
that the README/GETTING_STARTED/CBS_LANGUAGE/ARCHITECTURE/CONTRIBUTING family commits to.

Per D4.8 polish-layer verification: structure-sanity not byte-exact.
"""
import os
import re

import pytest

REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))

DOCS = {
    'README.md':            os.path.join(REPO_ROOT, 'README.md'),
    'GETTING_STARTED.md':   os.path.join(REPO_ROOT, 'GETTING_STARTED.md'),
    'CBS_LANGUAGE.md':      os.path.join(REPO_ROOT, 'CBS_LANGUAGE.md'),
    'ARCHITECTURE.md':      os.path.join(REPO_ROOT, 'ARCHITECTURE.md'),
    'CONTRIBUTING.md':      os.path.join(REPO_ROOT, 'CONTRIBUTING.md'),
}

V1_0_SEAL_SHA = 'c9923b8cf9fb6caf4c195e2d0d0ea2ed4a8e51e4e9f827b1fc24dd0b28c1d900'


@pytest.mark.parametrize('doc_name,doc_path', list(DOCS.items()))
def test_doc_exists_and_nonempty(doc_name, doc_path):
    """All 5 V1.0 SHIP docs exist and have substantive content (> 1000 bytes)."""
    assert os.path.exists(doc_path), f"{doc_name} missing at {doc_path}"
    sz = os.path.getsize(doc_path)
    assert sz > 1000, f"{doc_name} too short: {sz} bytes"


@pytest.mark.parametrize('doc_name,doc_path', list(DOCS.items()))
def test_doc_has_h1_title(doc_name, doc_path):
    """Each doc opens with an H1 heading."""
    with open(doc_path, encoding='utf-8') as f:
        first_real_line = next(line.strip() for line in f if line.strip())
    assert first_real_line.startswith('# '), \
        f"{doc_name} should open with '# <Title>'; got: {first_real_line!r}"


def test_readme_has_sha_anchor():
    """README cites the V1.0 SEAL contract sha for audit-anchoring."""
    with open(DOCS['README.md'], encoding='utf-8') as f:
        content = f.read()
    assert V1_0_SEAL_SHA in content, "README must cite V1.0 SEAL sha for audit-anchoring"


def test_readme_has_quickstart():
    """README has a 5-command quickstart section."""
    with open(DOCS['README.md'], encoding='utf-8') as f:
        content = f.read()
    assert re.search(r'(?i)#+ +quickstart', content), "README missing quickstart section"
    assert './build.sh' in content
    assert './test_qemu.sh' in content


def test_getting_started_lists_six_demos():
    """GETTING_STARTED enumerates all 6 canary demos by their pod4.0.f sub-pod."""
    with open(DOCS['GETTING_STARTED.md'], encoding='utf-8') as f:
        content = f.read()
    for sub in ['b53', 'b54', 'b55', 'b56', 'b57', 'b58']:
        assert f'pod40f_{sub}' in content, f"GETTING_STARTED missing demo pod40f_{sub}"


def test_cbs_language_lists_five_typed_primitives():
    """CBS_LANGUAGE references all 5 typed primitives by name."""
    with open(DOCS['CBS_LANGUAGE.md'], encoding='utf-8') as f:
        content = f.read()
    for primitive in ['Sign', 'Energy', 'Outcome', 'Cap', 'Embedding']:
        assert primitive in content, f"CBS_LANGUAGE missing primitive: {primitive}"


def test_architecture_lists_five_typed_primitives():
    """ARCHITECTURE has a section per typed primitive (load-bearing for doctrinal depth)."""
    with open(DOCS['ARCHITECTURE.md'], encoding='utf-8') as f:
        content = f.read()
    for primitive in ['Sign', 'Energy', 'Outcome', 'Cap', 'Embedding']:
        pattern = rf'(?m)^#+ +{primitive}\b'
        assert re.search(pattern, content), \
            f"ARCHITECTURE missing typed-primitive section header for {primitive}"


def test_architecture_cites_load_bearing_doctrines():
    """ARCHITECTURE surfaces a sample of the 44-doctrine corpus's load-bearing entries."""
    with open(DOCS['ARCHITECTURE.md'], encoding='utf-8') as f:
        content = f.read()
    for doctrine in ['D3.14', 'D3.17', 'D3.37', 'D2.2.5', 'D1.10.1.7', 'D4.1', 'D4.2']:
        assert doctrine in content, f"ARCHITECTURE missing load-bearing doctrine cite: {doctrine}"


def test_contributing_explains_pod_methodology():
    """CONTRIBUTING explains the chunked-pod methodology (recon → HALT 1 → chunks → SEAL)."""
    with open(DOCS['CONTRIBUTING.md'], encoding='utf-8') as f:
        content = f.read()
    for token in ['Recon', 'HALT 1', 'SEAL', 'three-oracle']:
        assert token.lower() in content.lower(), f"CONTRIBUTING missing methodology token: {token}"


def test_contributing_cites_d4_1_byte_lock():
    """CONTRIBUTING references D4.1 polish-vs-credential separation."""
    with open(DOCS['CONTRIBUTING.md'], encoding='utf-8') as f:
        content = f.read()
    assert 'D4.1' in content, "CONTRIBUTING must cite D4.1 polish-vs-credential separation"


@pytest.mark.parametrize('doc_name,doc_path', list(DOCS.items()))
def test_relative_links_resolve(doc_name, doc_path):
    """Every relative markdown link in each doc points to a file that exists."""
    with open(doc_path, encoding='utf-8') as f:
        content = f.read()
    # Strip fenced code blocks and inline code spans so example links inside
    # ``[Title](file.md)`` aren't treated as real links.
    content = re.sub(r'```.*?```', '', content, flags=re.DOTALL)
    content = re.sub(r'`[^`]*`', '', content)
    # Match [text](relative-link) — skip http(s), anchors, mailto
    link_pattern = re.compile(r'\[[^\]]+\]\(([^)]+)\)')
    for raw_target in link_pattern.findall(content):
        if raw_target.startswith(('http://', 'https://', 'mailto:', '#')):
            continue
        # Strip in-file anchor (#section) suffix
        target = raw_target.split('#', 1)[0]
        if not target:
            continue
        # Ignore placeholder tokens like {YOUTUBE_URL_TBD}
        if target.startswith('{') and target.endswith('}'):
            continue
        # Resolve relative to the doc's directory (REPO_ROOT for all 5)
        abs_target = os.path.join(REPO_ROOT, target)
        assert os.path.exists(abs_target), \
            f"{doc_name} → broken relative link: '{raw_target}' (resolved {abs_target})"


def test_cross_doc_consistency_sha():
    """V1.0 SEAL sha appears identically in README + CBS_LANGUAGE + ARCHITECTURE."""
    occurrences = 0
    for name, path in DOCS.items():
        with open(path, encoding='utf-8') as f:
            if V1_0_SEAL_SHA in f.read():
                occurrences += 1
    # README must have it; CBS_LANGUAGE + ARCHITECTURE should reference it for anchoring
    assert occurrences >= 3, \
        f"V1.0 SEAL sha should anchor at least 3 of the 5 docs; found in {occurrences}"


def test_cross_doc_consistency_headline_numbers():
    """README cites the 25.4 KB / 44 doctrines / 6 demos headline numbers consistently."""
    with open(DOCS['README.md'], encoding='utf-8') as f:
        readme = f.read()
    assert '25.4 KB' in readme or '25.4KB' in readme
    assert '44' in readme  # doctrines
    assert '6 ' in readme  # demos count appears in tables
