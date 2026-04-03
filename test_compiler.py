from compiler import compile_ast, LetNode, PrintNode, ReturnNode

ast = [
    LetNode(var_name='message', value='Hello, Codebook!'),
    PrintNode(value='message'),
    ReturnNode(value='love')
]

bytecode = compile_ast(ast)
print("Bytecode:", list(bytecode))