from dataclasses import dataclass

@dataclass
class LetNode:
    var_name: str
    value: object

@dataclass
class PrintNode:
    value: object

@dataclass
class ReturnNode:
    value: object

def compile_ast(ast):
    bytecode = []
    for node in ast:
        if isinstance(node, LetNode):
            bytecode.append(0x71)  # LOAD_CONST
            bytecode.extend(node.value.encode('utf-8'))  # String
            bytecode.append(0x00)  # Null terminator
            bytecode.append(0x72)  # STORE
            bytecode.append(ord(node.var_name[0]))  # Var name (simplified)
        elif isinstance(node, PrintNode):
            bytecode.append(0x73)  # PRINT
            bytecode.append(ord(node.value[0]))  # Var name (simplified)
        elif isinstance(node, ReturnNode):
            bytecode.append(0x74)  # RETURN
    return bytecode