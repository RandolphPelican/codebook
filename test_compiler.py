from lexer import tokenize
from parser import parse
from compiler import compile_ast

def test_if_statement():
    ast = parse(tokenize("if x > 10 { return 100 } else { return 0 }"))
    bytecode = compile_ast(ast)
    expected_start = [0x20, 0x64, 0x00, 0x00, 0x00]
    assert bytecode[:5] == expected_start
    print("Test if-statement passed")

def test_while_loop():
    ast = parse(tokenize("while i < 5 { i = i + 1 }"))
    bytecode = compile_ast(ast)
    expected_start = [0x20, 0xC8, 0x00, 0x00, 0x00]
    assert bytecode[:5] == expected_start
    print("Test while-loop passed")

def test_let_statement():
    ast = parse(tokenize("let x = 10"))
    bytecode = compile_ast(ast)
    assert bytecode[0] == 0x01
    assert bytecode[5] == 0x71
    print("Test let-statement passed")

if __name__ == "__main__":
    test_if_statement()
    test_while_loop()
    test_let_statement()
    print("\nAll compiler tests passed!")
