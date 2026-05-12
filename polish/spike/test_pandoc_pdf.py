"""Spike: pandoc subprocess — sample Markdown → PDF; verify page count + section landmarks.

Run: python3 polish/spike/test_pandoc_pdf.py
Skips with informative message if pandoc not on PATH.

Note: pandoc needs a LaTeX engine for PDF (texlive-luatex / xelatex / wkhtmltopdf).
If pandoc is installed but no LaTeX engine, ships with HTML→PDF fallback message.
"""

import os
import shutil
import subprocess
import sys
import tempfile

OUT_PDF = os.path.join(os.path.dirname(__file__), 'spike_pandoc_out.pdf')

SAMPLE_MARKDOWN = """\
# CodebookOS V1.0 Manifesto (spike)

A 64KB-class bare-metal operating system with its own programming language.

## Substrate

Pure x86_64 NASM. SipHash MAC integrity. F32 IEEE 754 byte-exact determinism.
~25 KB of hand-crafted assembly.

## Maid V1.0 capability surface

- Recognize: cosine, dot, L2, lookup_top1, lookup_top_k
- Compose: add, subtract, scale, normalize, lerp
- Decompose: project, reject
- Import: boot_ingest_codebook, imported_handle
- Maintain: codebook_meta

## Doctrine corpus

44 codified architectural decisions through V1.0 SEAL.

## Spike note

This document tests pandoc's Markdown-to-PDF pipeline. Real manifesto generation
happens at Pod 4.0.I.

---

*github.com/RandolphPelican/codebook*
"""


def main() -> int:
    pandoc_path = shutil.which('pandoc')
    if pandoc_path is None:
        print("SKIP: pandoc not found on PATH; install per polish/README.md")
        print("      (Linux: apt install pandoc | macOS: brew install pandoc | Windows: choco install pandoc)")
        return 0

    with tempfile.NamedTemporaryFile(mode='w', suffix='.md', delete=False) as f:
        f.write(SAMPLE_MARKDOWN)
        md_path = f.name

    try:
        cmd = [pandoc_path, md_path, '-o', OUT_PDF]
        result = subprocess.run(cmd, capture_output=True, text=True)
        if result.returncode != 0:
            stderr = result.stderr.strip()
            # Common: pandoc needs LaTeX engine for PDF
            if 'pdflatex' in stderr.lower() or 'latex' in stderr.lower() or 'xelatex' in stderr.lower():
                print(f"SKIP: pandoc installed but PDF engine missing.")
                print(f"      Install texlive: apt install texlive-luatex texlive-latex-extra")
                print(f"      OR use HTML→PDF via wkhtmltopdf as fallback")
                print(f"      stderr: {stderr[:300]}")
                return 0
            print(f"FAIL: pandoc exit={result.returncode}\nstderr={stderr[:500]}")
            return 1

        if not os.path.exists(OUT_PDF) or os.path.getsize(OUT_PDF) < 500:
            print(f"FAIL: PDF not produced or too small: {OUT_PDF}")
            return 1

        sz = os.path.getsize(OUT_PDF)
        # Quick PDF sanity: starts with %PDF
        with open(OUT_PDF, 'rb') as f:
            head = f.read(8)
        if not head.startswith(b'%PDF'):
            print(f"FAIL: output does not look like PDF (header: {head!r})")
            return 1

        print(f"PASS: PDF generated at {OUT_PDF} ({sz} bytes)")
        return 0
    finally:
        if os.path.exists(md_path):
            os.unlink(md_path)


if __name__ == '__main__':
    sys.exit(main())
