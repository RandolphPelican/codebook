def run(bytecode):
    pc = 0
    variables = {}
    while pc < len(bytecode):
        op = bytecode[pc]
        if op == 0x71:  # LOAD_CONST
            pc += 1
            const = bytearray()
            while pc < len(bytecode) and bytecode[pc] != 0x00:
                const.append(bytecode[pc])
                pc += 1
            if pc < len(bytecode) and bytecode[pc] == 0x00:
                pc += 1  # Skip null terminator
            value = const.decode('utf-8')
            variables['*'] = value  # Store in a temp variable
        elif op == 0x72:  # STORE
            pc += 1
            var_name = chr(bytecode[pc])
            pc += 1
            variables[var_name] = variables['*']  # Store the last loaded const
        elif op == 0x73:  # PRINT
            pc += 1
            var_name = chr(bytecode[pc])
            pc += 1
            if var_name in variables:
                print(variables[var_name])
            else:
                print(f"Error: Variable '{var_name}' not found")
        elif op == 0x74:  # RETURN
            pc += 1
            break
        else:
            raise RuntimeError(f"Unknown opcode: {op}")

if __name__ == '__main__':
    import sys
    if len(sys.argv) < 2:
        print('Usage: python runtime.py <bytecode.cb>')
        sys.exit(1)
    with open(sys.argv[1], 'rb') as f:
        bytecode = list(f.read())
    run(bytecode)