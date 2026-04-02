from dataclasses import dataclass
from typing import List, Optional

@dataclass
class LetNode:
    var_name: str
    value: object

@dataclass
class IfNode:
    condition: object
    then_block: object
    else_block: Optional[object] = None

@dataclass
class WhileNode:
    condition: object
    body: object

@dataclass
class BinOpNode:
    left: object
    op: str
    right: object

@dataclass
class ReturnNode:
    value: object

class Parser:
    def __init__(self, tokens):
        self.tokens = list(tokens)
        self.pos = 0

    def current_token(self):
        if self.pos < len(self.tokens):
            return self.tokens[self.pos]
        return None

    def consume(self, expected_type=None, expected_value=None):
        token = self.current_token()
        if token is None:
            raise SyntaxError("Unexpected end of input")
        if expected_type and token[0] != expected_type:
            raise SyntaxError(f"Expected {expected_type}, got {token[0]}")
        if expected_value and token[1] != expected_value:
            raise SyntaxError(f"Expected {expected_value}, got {token[1]}")
        self.pos += 1
        return token

    def parse(self):
        return self.parse_statement()

    def parse_statement(self):
        token = self.current_token()
        if token is None:
            raise SyntaxError("Unexpected end of input")

        if token[0] == 'LET':
            return self.parse_let()
        elif token[0] == 'IF':
            return self.parse_if()
        elif token[0] == 'WHILE':
            return self.parse_while()
        elif token[0] == 'RETURN':
            return self.parse_return()
        elif token[0] == 'ID':
            return self.parse_assignment()
        else:
            raise SyntaxError(f"Unexpected token: {token}")

    def parse_assignment(self):
        var_name = self.consume('ID')[1]
        self.consume('OP', '=')
        value = self.parse_expression()
        return LetNode(var_name, value)

    def parse_let(self):
        self.consume('LET')
        var_name = self.consume('ID')[1]
        self.consume('OP', '=')
        value = self.parse_expression()
        return LetNode(var_name, value)

    def parse_if(self):
        self.consume('IF')
        condition = self.parse_expression()
        self.consume('LBRACE')
        then_block = self.parse_statement()
        self.consume('RBRACE')
        else_block = None
        if self.current_token() and self.current_token()[0] == 'ELSE':
            self.consume('ELSE')
            self.consume('LBRACE')
            else_block = self.parse_statement()
            self.consume('RBRACE')
        return IfNode(condition, then_block, else_block)

    def parse_while(self):
        self.consume('WHILE')
        condition = self.parse_expression()
        self.consume('LBRACE')
        body = self.parse_statement()
        self.consume('RBRACE')
        return WhileNode(condition, body)

    def parse_return(self):
        self.consume('RETURN')
        value = self.parse_expression()
        return ReturnNode(value)

    def parse_expression(self):
        left = self.parse_term()
        while self.current_token() and self.current_token()[0] == 'OP':
            op = self.consume('OP')[1]
            right = self.parse_term()
            left = BinOpNode(left, op, right)
        return left

    def parse_term(self):
        token = self.current_token()
        if token[0] == 'ID':
            return self.consume('ID')[1]
        elif token[0] == 'INT':
            return int(self.consume('INT')[1])
        else:
            raise SyntaxError(f"Unexpected token in term: {token}")

def parse(tokens):
    parser = Parser(tokens)
    return parser.parse()
