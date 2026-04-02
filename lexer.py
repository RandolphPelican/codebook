import re

TOKEN_SPEC = [
    ('COMMENT', r'//.*'),
    ('WHITESPACE', r'[ \t\n]'),
    ('LET', r'let\b'),
    ('IF', r'if\b'),
    ('ELSE', r'else\b'),
    ('WHILE', r'while\b'),
    ('RETURN', r'return\b'),
    ('FN', r'fn\b'),
    ('COSTS', r'costs\b'),
    ('PRINT', r'print\b'),
    ('ID', r'[a-zA-Z_][a-zA-Z0-9_]*'),
    ('INT', r'\d+'),
    ('OP', r'[+\-*/%=<>!]=?'),
    ('LBRACE', r'\{'),
    ('RBRACE', r'\}'),
    ('LPAREN', r'\('),
    ('RPAREN', r'\)'),
    ('SEMICOLON', r';'),
    ('STRING', r'"[^"]*"'),
]

token_regex = '|'.join(f'(?P<{name}>{pattern})' for name, pattern in TOKEN_SPEC)

def tokenize(source):
    for match in re.finditer(token_regex, source):
        kind = match.lastgroup
        value = match.group()
        if kind not in ('COMMENT', 'WHITESPACE'):
            yield (kind, value)