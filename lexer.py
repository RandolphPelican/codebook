import re

TOKEN_SPEC = [
    ('LET', r'let'),
    ('IF', r'if'),
    ('ELSE', r'else'),
    ('WHILE', r'while'),
    ('RETURN', r'return'),
    ('ID', r'[a-zA-Z_][a-zA-Z0-9_]*'),
    ('INT', r'\d+'),
    ('OP', r'[+=<>!]=?|[<>]'),
    ('LBRACE', r'\{'),
    ('RBRACE', r'\}'),
    ('LPAREN', r'\('),
    ('RPAREN', r'\)'),
    ('SKIP', r'[ \t\n]'),
]

def tokenize(source):
    for mo in re.finditer('|'.join(f'(?P<{name}>{pattern})' for name, pattern in TOKEN_SPEC), source):
        if mo.lastgroup != 'SKIP':
            yield (mo.lastgroup, mo.group())
