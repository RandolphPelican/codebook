#!/usr/bin/env python3
"""
Pod 3.8 codebook image builder — external embedding source -> CBKBOK01 image.

Input formats:
  .npy           NumPy 2D array (count x dim); requires numpy on build host
  .txt / .csv    plaintext; one vector per line, comma-separated f32

Outputs:
  <out>.bin      CBKBOK01 codebook binary image
  <out>.asm      NASM `db ...` block embedding the same image (for
                 inclusion via boot/codebook_data.asm; matches Pod 3.8
                 single-artifact embed strategy beta.1)

Image format (V1.0; CBKBOK01):
  +0x00  magic "CBKBOK01"        (8 bytes ASCII)
  +0x08  count                   (u64; number of embeddings)
  +0x10  dim                     (u64; embedding dimensionality;
                                   must equal 384 for V1.0 substrate)
  +0x18  scalar_type             (u32; 0 = f32)
  +0x1C  reserved                (u32; 0)
  +0x20  vector_block_offset     (u64; absolute offset to vectors; 0x40)
  +0x28  vector_block_bytes      (u64; count * dim * 4)
  +0x30  payload_hash            (16 bytes; SHA-256(vector_block) truncated)
  +0x40  vectors[count][dim]     f32 little-endian, contiguous

Hash choice: SHA-256 truncated to 16 bytes. Build-time integrity check
only; not enforced at substrate runtime (substrate MACs each embedding
individually via per-boot SipHash key during ingestion). SHA-256 chosen
over SipHash-128 for build-tool simplicity (hashlib stdlib; no
substrate-side crypto needed at build time).

Two-build determinism: identical input + format produce byte-identical
output. No timestamps, no random padding, no file-system dependencies.
"""
import argparse
import hashlib
import os
import struct
import sys


MAGIC = b"CBKBOK01"
HEADER_SIZE = 64
SCALAR_TYPE_F32 = 0


def parse_plaintext(path):
    """Parse comma-separated vectors, one per line. Skips blanks and # comments."""
    vectors = []
    with open(path, "r") as f:
        for line_no, line in enumerate(f, 1):
            stripped = line.strip()
            if not stripped or stripped.startswith("#"):
                continue
            try:
                values = [float(x.strip()) for x in stripped.split(",")]
            except ValueError as e:
                sys.exit("plaintext parse error at line %d: %s" % (line_no, e))
            vectors.append(values)
    if not vectors:
        sys.exit("plaintext input contains no vectors")
    dim = len(vectors[0])
    for i, v in enumerate(vectors):
        if len(v) != dim:
            sys.exit("dim mismatch at line %d: expected %d, got %d" % (i + 1, dim, len(v)))
    return vectors


def parse_npy(path):
    """Parse NumPy 2D array (count x dim); requires numpy."""
    try:
        import numpy as np
    except ImportError:
        sys.exit("numpy not available; cannot parse .npy input. Use plaintext .txt/.csv format instead.")
    arr = np.load(path)
    if arr.ndim != 2:
        sys.exit("npy must be 2D (count x dim); got shape %s" % (arr.shape,))
    return arr.astype(np.float32).tolist()


def build_image(vectors, expected_dim=None, dim_for_empty=384):
    """Construct CBKBOK01 image bytes from list-of-lists of floats.

    Empty codebook (vectors == []) emits a valid CBKBOK01 image with count=0,
    dim=expected_dim or dim_for_empty (default 384 matching substrate
    EMBEDDING_DIM). Used by substrate boot path when no inputs/codebook.txt
    is configured — substrate boots, ingests 0 embeddings, vm_embedding_next
    stays at 0, prior-pod canary IDs start from 1 unchanged.
    """
    if vectors:
        count = len(vectors)
        dim = len(vectors[0])
    else:
        count = 0
        dim = expected_dim if expected_dim is not None else dim_for_empty
    if expected_dim is not None and dim != expected_dim:
        sys.exit("dim mismatch: codebook has %d, expected %d" % (dim, expected_dim))

    # Vector block: contiguous f32 little-endian
    vector_block = bytearray()
    for v in vectors:
        for x in v:
            vector_block += struct.pack("<f", x)
    vector_block = bytes(vector_block)
    vector_block_bytes = len(vector_block)

    # Payload hash: SHA-256 of vector block, truncated to 16 bytes
    payload_hash = hashlib.sha256(vector_block).digest()[:16]

    # Build header (exactly 64 bytes)
    header = bytearray()
    header += MAGIC                                       # +0x00 (8 bytes)
    header += struct.pack("<Q", count)                    # +0x08 (8)
    header += struct.pack("<Q", dim)                      # +0x10 (8)
    header += struct.pack("<I", SCALAR_TYPE_F32)          # +0x18 (4)
    header += struct.pack("<I", 0)                        # +0x1C reserved (4)
    header += struct.pack("<Q", HEADER_SIZE)              # +0x20 vector_block_offset (8)
    header += struct.pack("<Q", vector_block_bytes)       # +0x28 vector_block_bytes (8)
    header += payload_hash                                # +0x30 (16)
    assert len(header) == HEADER_SIZE, "header size %d != %d" % (len(header), HEADER_SIZE)

    return bytes(header) + vector_block


def emit_asm(image_size, incbin_ref, label="codebook_image"):
    """Emit NASM incbin directive wrapping the binary image at incbin_ref.

    Pod 3.8.F: omits `section .rodata` and `global` directives. Substrate uses
    NASM `-f bin` flat-binary mode where section semantics interfere with the
    contiguous-stream layout (`times TEXT_RAWSZ - ($ - text_start)` calculation
    in boot.asm:.reloc-padding). Single emit form suitable for both standalone
    `nasm -f bin <only-codebook.asm>` validation and substrate-embedded include.
    """
    lines = []
    lines.append("; Pod 3.8 codebook image - auto-generated by tools/codebook_builder.py")
    lines.append("; Format: CBKBOK01 (incbin-form embed; binary at %s)" % incbin_ref)
    lines.append("; DO NOT EDIT - regenerate by re-running codebook_builder.py")
    lines.append("")
    lines.append("    align 16")
    lines.append("%s_start:" % label)
    lines.append('    incbin "%s"' % incbin_ref)
    lines.append("%s_end:" % label)
    lines.append("")
    lines.append("; Image total: %d bytes (%d-byte header + %d-byte vector block)" % (
        image_size, HEADER_SIZE, image_size - HEADER_SIZE))
    return "\n".join(lines) + "\n"


def main():
    parser = argparse.ArgumentParser(
        description="Pod 3.8 codebook image builder (CBKBOK01 format)",
    )
    parser.add_argument("input", nargs='?', default=None,
                        help="Input file: .npy / .txt / .csv (omit if --empty)")
    parser.add_argument("output", help="Output base path (produces .bin + .asm)")
    parser.add_argument("--expected-dim", type=int, default=None,
                        help="Validate dim matches (e.g., 384 for V1.0 substrate)")
    parser.add_argument("--label", default="codebook_image",
                        help="NASM label prefix (default: codebook_image)")
    parser.add_argument("--incbin-path", default=None,
                        help="Override incbin string written into .asm (default: same as <output>.bin path)")
    parser.add_argument("--empty", action="store_true",
                        help="Emit empty CBKBOK01 image (count=0, dim=384). Used by substrate build pipeline when no inputs/codebook.txt is configured.")
    parser.add_argument("--dim-for-empty", type=int, default=384,
                        help="Dim value for --empty image header (default: 384 matching V1.0 EMBEDDING_DIM)")
    args = parser.parse_args()

    if args.empty:
        if args.input:
            sys.exit("cannot specify both --empty and an input file")
        vectors = []
    else:
        if not args.input:
            sys.exit("must provide input file (or use --empty)")
        ext = os.path.splitext(args.input)[1].lower()
        if ext == ".npy":
            vectors = parse_npy(args.input)
        elif ext in (".txt", ".csv"):
            vectors = parse_plaintext(args.input)
        else:
            sys.exit("unrecognized input extension '%s' (expected .npy / .txt / .csv)" % ext)

    image = build_image(vectors, expected_dim=args.expected_dim,
                        dim_for_empty=args.dim_for_empty)

    bin_path = args.output + ".bin"
    asm_path = args.output + ".asm"

    with open(bin_path, "wb") as f:
        f.write(image)
    print("  wrote %s (%d bytes)" % (bin_path, len(image)))

    incbin_ref = args.incbin_path if args.incbin_path else bin_path
    with open(asm_path, "w") as f:
        f.write(emit_asm(len(image), incbin_ref, label=args.label))
    asm_size = os.path.getsize(asm_path)
    print("  wrote %s (%d bytes; incbin -> %s)" % (asm_path, asm_size, incbin_ref))

    if vectors:
        dim_reported = len(vectors[0])
    else:
        dim_reported = args.dim_for_empty if args.expected_dim is None else args.expected_dim
    print("  count=%d dim=%d scalar_type=f32 payload_hash=%s" % (
        len(vectors), dim_reported, image[0x30:0x40].hex()))


if __name__ == "__main__":
    main()
