import sys
try:
    with open(sys.argv[1], 'wb') as f:
        # sys.argv[2] is expected to be a hex string for now
        f.write(bytes.fromhex(sys.argv[2]))
    print(f"Wrote {sys.argv[1]}")
except Exception as e:
    print(f"Error: {e}", file=sys.stderr)
    sys.exit(1)
