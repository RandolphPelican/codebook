import sys
try:
    with open(sys.argv[1], 'r') as f:
        sys.stdout.write(f.read())
except Exception:
    print("Error: Could not read file", file=sys.stderr)
    sys.exit(1)
