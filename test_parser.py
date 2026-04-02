from lexer import tokenize
from parser import parse, LetNode, IfNode, WhileNode, BinOpNode, ReturnNode

def test_variables():
    ast = parse(tokenize("let x = 10"))
    assert isinstance(ast, LetNode)
    assert ast.var_name == "x"
    assert ast.value == 10
    print("Test variables passed")

def test_conditionals():
    ast = parse(tokenize("if x > 10 { return 100 } else { return 0 }"))
    assert isinstance(ast, IfNode)
    assert isinstance(ast.condition, BinOpNode)
    assert ast.condition.op == ">"
    assert isinstance(ast.then_block, ReturnNode)
    assert ast.then_block.value == 100
    assert isinstance(ast.else_block, ReturnNode)
    assert ast.else_block.value == 0
    print("Test conditionals passed")

def test_loops():
    ast = parse(tokenize("while i < 5 { i = i + 1 }"))
    assert isinstance(ast, WhileNode)
    assert isinstance(ast.condition, BinOpNode)
    assert ast.condition.op == "<"
    assert isinstance(ast.body, LetNode)
    print("Test loops passed")

if __name__ == "__main__":
    test_variables()
    test_conditionals()
    test_loops()
    print("\nAll tests passed!")
