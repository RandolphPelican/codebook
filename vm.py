import struct

class VM:
    def __init__(self, bytecode, energy_budget=1000, debug=False):
        self.stack = []
        self.vars = {}
        self.pc = 0
        self.energy = energy_budget
        self.bytecode = bytecode
        self.debug = debug

    def run(self):
        while self.pc < len(self.bytecode):
            opcode = self.bytecode[self.pc]
            if self.debug:
                print(f"PC: {self.pc}, Opcode: 0x{opcode:02X}, Stack: {self.stack}, Energy: {self.energy}, Vars: {self.vars}")

            if opcode == 0x01:
                if self.pc + 5 > len(self.bytecode):
                    raise RuntimeError("PUSH requires 4 bytes of value")
                value = struct.unpack("<I", bytes(self.bytecode[self.pc+1:self.pc+5]))[0]
                self.stack.append(value)
                self.pc += 5
            elif opcode == 0x10:
                if len(self.stack) < 2:
                    raise RuntimeError("Stack underflow on ADD")
                b = self.stack.pop()
                a = self.stack.pop()
                self.stack.append(a + b)
                self.pc += 1
            elif opcode == 0x16:
                if len(self.stack) < 2:
                    raise RuntimeError("Stack underflow on LT")
                b = self.stack.pop()
                a = self.stack.pop()
                self.stack.append(1 if a < b else 0)
                self.pc += 1
            elif opcode == 0x17:
                if len(self.stack) < 2:
                    raise RuntimeError("Stack underflow on GT")
                b = self.stack.pop()
                a = self.stack.pop()
                self.stack.append(1 if a > b else 0)
                self.pc += 1
            elif opcode == 0x20:
                if self.pc + 5 > len(self.bytecode):
                    raise RuntimeError("RESERVE requires 4 bytes of energy")
                energy = struct.unpack("<I", bytes(self.bytecode[self.pc+1:self.pc+5]))[0]
                self.pc += 5
                if self.energy < energy:
                    while self.pc < len(self.bytecode):
                        next_op = self.bytecode[self.pc]
                        if next_op == 0x20 or next_op == 0xFF:
                            break
                        self.pc += 1
                else:
                    self.energy -= energy
            elif opcode == 0x53:
                if not self.stack:
                    raise RuntimeError("Stack underflow on RET")
                result = self.stack.pop()
                if self.debug:
                    print(f"Execution finished. Result: {result}")
                return result
            elif opcode == 0x55:
                if self.pc + 5 > len(self.bytecode):
                    raise RuntimeError("JUMP_IF_FALSE requires 4 bytes of offset")
                offset = struct.unpack("<i", bytes(self.bytecode[self.pc+1:self.pc+5]))[0]
                self.pc += 5
                if not self.stack.pop():
                    self.pc += offset
            elif opcode == 0x56:
                if self.pc + 5 > len(self.bytecode):
                    raise RuntimeError("JUMP_BACK requires 4 bytes of offset")
                offset = struct.unpack("<i", bytes(self.bytecode[self.pc+1:self.pc+5]))[0]
                self.pc += 5
                self.pc -= offset
            elif opcode == 0x70:
                if self.pc + 5 > len(self.bytecode):
                    raise RuntimeError("LOAD requires 4 bytes of var_id")
                var_id = struct.unpack("<I", bytes(self.bytecode[self.pc+1:self.pc+5]))[0]
                self.pc += 5
                self.stack.append(self.vars.get(var_id, 0))
            elif opcode == 0x71:
                if self.pc + 5 > len(self.bytecode):
                    raise RuntimeError("STORE requires 4 bytes of var_id")
                var_id = struct.unpack("<I", bytes(self.bytecode[self.pc+1:self.pc+5]))[0]
                self.pc += 5
                if not self.stack:
                    raise RuntimeError("Stack underflow on STORE")
                self.vars[var_id] = self.stack.pop()
            elif opcode == 0xFF:
                return None
            else:
                raise RuntimeError(f"Unsupported opcode: 0x{opcode:02X}")

        if self.debug:
            print("Execution finished. Stack empty.")
        return None

if __name__ == "__main__":
    bytecode = [
        0x20, 0x64, 0x00, 0x00, 0x00,
        0x01, 0x0A, 0x00, 0x00, 0x00,
        0x71, 0x00, 0x00, 0x00, 0x00,
        0x70, 0x00, 0x00, 0x00, 0x00,
        0x01, 0x05, 0x00, 0x00, 0x00,
        0x17,
        0x55, 0x08, 0x00, 0x00, 0x00,
        0x01, 0x64, 0x00, 0x00, 0x00,
        0x53,
        0x01, 0x00, 0x00, 0x00, 0x00,
        0x53
    ]
    vm = VM(bytecode, debug=True)
    result = vm.run()
    print("Result:", result)
