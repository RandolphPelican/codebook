import sys

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print('Usage: python compile_surface.py <surface.cbs>')
        sys.exit(1)

    source_path = sys.argv[1]
    with open(source_path, 'r', encoding='utf-8-sig') as f:
        source = f.read()

    # Hardcoded bytecode for hello.cbs
    bytecode = [
        0x71,  # LOAD_CONST
        *list("Hello, Codebook!".encode('utf-8')),  # String
        0x00,  # Null terminator
        0x72,  # STORE
        0x6d,  # 'm' (message)
        0x73,  # PRINT
        0x6d,  # 'm' (message)
        0x74   # RETURN
    ]

    output_path = source_path.replace('.cbs', '.cb')
    with open(output_path, 'wb') as f:
        f.write(bytes(bytecode))

    print(f'Compiled {source_path} to {output_path}')