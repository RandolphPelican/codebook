from parser import LetNode, IfNode, WhileNode, BinOpNode, ReturnNode

class Compiler:
    def __init__(self):
        self.var_ids = {}
        self.next_var_id = 0
        self.bytecode = []

    def get_var_id(self, var_name):
        if var_name not in self.var_ids:
            self.var_ids[var_name] = self.next_var_id
            self.next_var_id += 1
        return self.var_ids[var_name]

    def emit(self, opcode, operands=None):
        self.bytecode.append(opcode)
        if operands is not None:
            for byte in operands:
                self.bytecode.append(byte)

    def compile(self, node):
        if isinstance(node, LetNode):
            self.compile_let(node)
        elif isinstance(node, IfNode):
            self.compile_if(node)
        elif isinstance(node, WhileNode):
            self.compile_while(node)
        elif isinstance(node, BinOpNode):
            self.compile_binop(node)
        elif isinstance(node, ReturnNode):
            self.compile_return(node)
        elif isinstance(node, str):
            self.compile_identifier(node)
        elif isinstance(node, int):
            self.compile_int(node)
        else:
            raise ValueError(f"Unknown node type: {type(node)}")

    def compile_identifier(self, var_name):
        var_id = self.get_var_id(var_name)
        self.emit(0x70, [var_id & 0xFF, (var_id >> 8) & 0xFF, (var_id >> 16) & 0xFF, (var_id >> 24) & 0xFF])

    def compile_int(self, value):
        self.emit(0x01, [value & 0xFF, (value >> 8) & 0xFF, (value >> 16) & 0xFF, (value >> 24) & 0xFF])

    def compile_let(self, node):
        self.compile(node.value)
        var_id = self.get_var_id(node.var_name)
        self.emit(0x71, [var_id & 0xFF, (var_id >> 8) & 0xFF, (var_id >> 16) & 0xFF, (var_id >> 24) & 0xFF])

    def compile_if(self, node):
        self.emit(0x20, [0x64, 0x00, 0x00, 0x00])
        self.compile(node.condition)
        jump_if_false_pos = len(self.bytecode)
        self.emit(0x55, [0x00, 0x00, 0x00, 0x00])
        self.compile(node.then_block)
        jump_pos = len(self.bytecode)
        self.emit(0x55, [0x00, 0x00, 0x00, 0x00])
        if node.else_block:
            self.compile(node.else_block)
        else_jump_offset = len(self.bytecode) - jump_pos - 4
        self.bytecode[jump_pos + 1] = else_jump_offset & 0xFF
        self.bytecode[jump_pos + 2] = (else_jump_offset >> 8) & 0xFF
        self.bytecode[jump_pos + 3] = (else_jump_offset >> 16) & 0xFF
        self.bytecode[jump_pos + 4] = (else_jump_offset >> 24) & 0xFF
        if_jump_offset = len(self.bytecode) - jump_if_false_pos - 4
        self.bytecode[jump_if_false_pos + 1] = if_jump_offset & 0xFF
        self.bytecode[jump_if_false_pos + 2] = (if_jump_offset >> 8) & 0xFF
        self.bytecode[jump_if_false_pos + 3] = (if_jump_offset >> 16) & 0xFF
        self.bytecode[jump_if_false_pos + 4] = (if_jump_offset >> 24) & 0xFF

    def compile_while(self, node):
        self.emit(0x20, [0xC8, 0x00, 0x00, 0x00])
        condition_start = len(self.bytecode)
        self.compile(node.condition)
        jump_if_false_pos = len(self.bytecode)
        self.emit(0x55, [0x00, 0x00, 0x00, 0x00])
        self.compile(node.body)
        self.emit(0x56, [0x00, 0x00, 0x00, 0x00])
        jump_back_offset = condition_start - len(self.bytecode) + 4
        self.bytecode[-4] = jump_back_offset & 0xFF
        self.bytecode[-3] = (jump_back_offset >> 8) & 0xFF
        self.bytecode[-2] = (jump_back_offset >> 16) & 0xFF
        self.bytecode[-1] = (jump_back_offset >> 24) & 0xFF
        jump_if_false_offset = len(self.bytecode) - jump_if_false_pos - 4
        self.bytecode[jump_if_false_pos + 1] = jump_if_false_offset & 0xFF
        self.bytecode[jump_if_false_pos + 2] = (jump_if_false_offset >> 8) & 0xFF
        self.bytecode[jump_if_false_pos + 3] = (jump_if_false_offset >> 16) & 0xFF
        self.bytecode[jump_if_false_pos + 4] = (jump_if_false_offset >> 24) & 0xFF

    def compile_binop(self, node):
        self.compile(node.left)
        self.compile(node.right)
        if node.op == ">":
            self.emit(0x17)
        elif node.op == "<":
            self.emit(0x16)
        elif node.op == "+":
            self.emit(0x10)
        else:
            raise ValueError(f"Unsupported operator: {node.op}")

    def compile_return(self, node):
        self.compile(node.value)
        self.emit(0x53)

def compile_ast(ast):
    compiler = Compiler()
    compiler.compile(ast)
    return compiler.bytecode
