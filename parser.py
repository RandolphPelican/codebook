from dataclasses import dataclass
from typing import List, Optional

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
        statements = []
        while self.current_token():
            statements.append(self.parse_statement())
        return statements

    def parse_statement(self):
        token = self.current_token()
        if token is None:
            raise SyntaxError("Unexpected end of input")

        if token[0] == 'LET':
            return self.parse_let()
        elif token[0] == 'PRINT':
            return self.parse_print()
        elif token[0] == 'RETURN':
            return self.parse_return()
        else:
            raise SyntaxError(f"Unexpected token: {token}")

    def parse_let(self):
        self.consume('LET')
        var_name = self.consume('ID')[1]
        self.consume('OP', '=')
        value = self.parse_expression()
        self.consume('SEMICOLON')
        return LetNode(var_name, value)

    def parse_print(self):
        self.consume('PRINT')
        self.consume('LPAREN')
        value = self.parse_expression()
        self.consume('RPAREN')
        self.consume('SEMICOLON')
        return PrintNode(value)

    def parse_return(self):
        self.consume('RETURN')
        value = self.consume('ID')[1]
        self.consume('SEMICOLON')
        return ReturnNode(value)

    def parse_expression(self):
        token = self.current_token()
        if token[0] == 'ID':
            return self.consume('ID')[1]
        elif token[0] == 'INT':
            return int(self.consume('INT')[1])
        elif token[0] == 'STRING':
            return self.consume('STRING')[1][1:-1]  # Strip quotes
        else:
            raise SyntaxError(f"Unexpected token in expression: {token}")

def parse(tokens):
    parser = Parser(tokens)
    return parser.parse()