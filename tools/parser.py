#!/usr/bin/env python3
"""
CodebookScript Parser — Phase 1 Complete
Handles: let, if/else, while, functions, calls, strings, booleans, all operators
"""
import re
from typing import List, Optional, Any, Dict

class Token:
    def __init__(self, type, value, line, col):
        self.type = type; self.value = value
        self.line = line; self.col = col
    def __repr__(self): return f"Token({self.type}, {self.value!r})"

class Lexer:
    KEYWORDS = {
        'fn','costs','return','if','else','while','let','true','false',
        'print','and','or','not','demod','budget','degrade'
    }
    PATTERNS = [
        ('ENERGY',    r'\d+j'),
        ('NUMBER',    r'\d+'),
        ('STRING',    r'"[^"]*"'),
        ('COMMENT',   r'//[^\n]*'),
        ('ARROW',     r'->'),
        ('EQ',        r'=='),
        ('NE',        r'!='),
        ('LE',        r'<='),
        ('GE',        r'>='),
        ('LT',        r'<'),
        ('GT',        r'>'),
        ('ASSIGN',    r'='),
        ('PLUS',      r'\+'),
        ('MINUS',     r'-'),
        ('STAR',      r'\*'),
        ('SLASH',     r'/'),
        ('PERCENT',   r'%'),
        ('LPAREN',    r'\('),
        ('RPAREN',    r'\)'),
        ('LBRACE',    r'\{'),
        ('RBRACE',    r'\}'),
        ('COMMA',     r','),
        ('SEMICOLON', r';'),
        ('COLON',     r':'),
        ('IDENT',     r'[a-zA-Z_][a-zA-Z0-9_]*'),
        ('NEWLINE',   r'\n'),
        ('SKIP',      r'[ \t]+'),
        ('COMMENT',   r'//[^\n]*'),
    ]

    def __init__(self, source):
        self.source = source; self.pos = 0
        self.line = 1; self.col = 1

    def tokenize(self):
        tokens = []
        compiled = [(t, re.compile(p)) for t, p in self.PATTERNS]
        while self.pos < len(self.source):
            matched = False
            for ttype, rx in compiled:
                m = rx.match(self.source, self.pos)
                if m:
                    val = m.group(0)
                    if ttype not in ('SKIP','COMMENT','NEWLINE'):
                        if ttype == 'IDENT' and val in self.KEYWORDS:
                            tokens.append(Token(val.upper(), val, self.line, self.col))
                        elif ttype == 'ENERGY':
                            tokens.append(Token('ENERGY', int(val[:-1]), self.line, self.col))
                        elif ttype == 'NUMBER':
                            tokens.append(Token('NUMBER', int(val), self.line, self.col))
                        elif ttype == 'STRING':
                            tokens.append(Token('STRING', val[1:-1], self.line, self.col))
                        else:
                            tokens.append(Token(ttype, val, self.line, self.col))
                    if ttype == 'NEWLINE': self.line += 1; self.col = 1
                    else: self.col += len(val)
                    self.pos = m.end(); matched = True; break
            if not matched:
                raise SyntaxError(f"Unexpected '{self.source[self.pos]}' at line {self.line}")
        return tokens

class Parser:
    def __init__(self, tokens):
        self.tokens = tokens; self.pos = 0

    def peek(self, offset=0):
        i = self.pos + offset
        return self.tokens[i] if i < len(self.tokens) else None

    def consume(self, expected=None):
        t = self.peek()
        if t is None: raise SyntaxError("Unexpected end of input")
        if expected and t.type != expected:
            raise SyntaxError(f"Expected {expected}, got {t.type} '{t.value}' at line {t.line}")
        self.pos += 1; return t

    def match(self, *types):
        if self.peek() and self.peek().type in types:
            return self.consume()
        return None

    def parse(self):
        stmts = []
        while self.peek():
            stmts.append(self.parse_top_level())
        return {'type':'program','body':stmts}

    def parse_top_level(self):
        if self.peek().type == 'FN':
            return self.parse_function()
        return self.parse_statement()

    def parse_function(self):
        self.consume('FN')
        name = self.consume('IDENT').value
        self.consume('LPAREN')
        params = []
        if self.peek() and self.peek().type == 'IDENT':
            params.append(self.consume('IDENT').value)
            while self.match('COMMA'):
                params.append(self.consume('IDENT').value)
        self.consume('RPAREN')
        cost = 0
        if self.peek() and self.peek().type == 'COSTS':
            self.consume('COSTS')
            cost = self.consume('ENERGY').value
        ret_type = 'Int'
        if self.peek() and self.peek().type == 'ARROW':
            self.consume('ARROW')
            ret_type = self.consume('IDENT').value
        body = self.parse_block()
        return {'type':'function','name':name,'params':params,'cost':cost,'ret_type':ret_type,'body':body}

    def parse_block(self):
        self.consume('LBRACE')
        stmts = []
        while self.peek() and self.peek().type != 'RBRACE':
            stmts.append(self.parse_statement())
        self.consume('RBRACE')
        return {'type':'block','stmts':stmts}

    def parse_statement(self):
        t = self.peek()
        if t.type == 'LET':
            return self.parse_let()
        elif t.type == 'RETURN':
            self.consume('RETURN')
            expr = self.parse_expr()
            self.match('SEMICOLON')
            return {'type':'return','value':expr}
        elif t.type == 'IF':
            return self.parse_if()
        elif t.type == 'WHILE':
            return self.parse_while()
        elif t.type == 'PRINT':
            self.consume('PRINT')
            self.consume('LPAREN')
            expr = self.parse_expr()
            self.consume('RPAREN')
            self.match('SEMICOLON')
            return {'type':'print','value':expr}
        elif t.type == 'LBRACE':
            return self.parse_block()
        else:
            expr = self.parse_expr()
            self.match('SEMICOLON')
            return {'type':'expr_stmt','value':expr}

    def parse_let(self):
        self.consume('LET')
        name = self.consume('IDENT').value
        self.consume('ASSIGN')
        value = self.parse_expr()
        self.match('SEMICOLON')
        return {'type':'let','name':name,'value':value}

    def parse_if(self):
        self.consume('IF')
        self.consume('LPAREN')
        cond = self.parse_expr()
        self.consume('RPAREN')
        then = self.parse_block()
        else_ = None
        if self.peek() and self.peek().type == 'ELSE':
            self.consume('ELSE')
            if self.peek() and self.peek().type == 'IF':
                else_ = self.parse_if()
            else:
                else_ = self.parse_block()
        return {'type':'if','cond':cond,'then':then,'else':else_}

    def parse_while(self):
        self.consume('WHILE')
        self.consume('LPAREN')
        cond = self.parse_expr()
        self.consume('RPAREN')
        body = self.parse_block()
        return {'type':'while','cond':cond,'body':body}

    def parse_expr(self):
        return self.parse_or()

    def parse_or(self):
        left = self.parse_and()
        while self.peek() and self.peek().type == 'OR':
            self.consume(); right = self.parse_and()
            left = {'type':'or','left':left,'right':right}
        return left

    def parse_and(self):
        left = self.parse_not()
        while self.peek() and self.peek().type == 'AND':
            self.consume(); right = self.parse_not()
            left = {'type':'and','left':left,'right':right}
        return left

    def parse_not(self):
        if self.peek() and self.peek().type == 'NOT':
            self.consume()
            return {'type':'not','value':self.parse_not()}
        return self.parse_comparison()

    def parse_comparison(self):
        left = self.parse_additive()
        ops = {'EQ':'eq','NE':'ne','LT':'lt','GT':'gt','LE':'le','GE':'ge'}
        while self.peek() and self.peek().type in ops:
            op = ops[self.consume().type]
            right = self.parse_additive()
            left = {'type':op,'left':left,'right':right}
        return left

    def parse_additive(self):
        left = self.parse_multiplicative()
        while self.peek() and self.peek().type in ('PLUS','MINUS'):
            op = 'add' if self.consume().type == 'PLUS' else 'sub'
            right = self.parse_multiplicative()
            left = {'type':op,'left':left,'right':right}
        return left

    def parse_multiplicative(self):
        left = self.parse_unary()
        while self.peek() and self.peek().type in ('STAR','SLASH','PERCENT'):
            t = self.consume().type
            op = 'mul' if t=='STAR' else ('div' if t=='SLASH' else 'mod')
            right = self.parse_unary()
            left = {'type':op,'left':left,'right':right}
        return left

    def parse_unary(self):
        if self.peek() and self.peek().type == 'MINUS':
            self.consume()
            return {'type':'neg','value':self.parse_primary()}
        return self.parse_primary()

    def parse_primary(self):
        t = self.peek()
        if t.type == 'NUMBER':
            self.consume(); return {'type':'int','value':t.value}
        elif t.type == 'STRING':
            self.consume(); return {'type':'str','value':t.value}
        elif t.type == 'TRUE':
            self.consume(); return {'type':'bool','value':True}
        elif t.type == 'FALSE':
            self.consume(); return {'type':'bool','value':False}
        elif t.type == 'IDENT':
            self.consume()
            # function call
            if self.peek() and self.peek().type == 'LPAREN':
                self.consume('LPAREN')
                args = []
                if self.peek() and self.peek().type != 'RPAREN':
                    args.append(self.parse_expr())
                    while self.match('COMMA'):
                        args.append(self.parse_expr())
                self.consume('RPAREN')
                return {'type':'call','name':t.value,'args':args}
            return {'type':'var','name':t.value}
        elif t.type == 'LPAREN':
            self.consume('LPAREN')
            expr = self.parse_expr()
            self.consume('RPAREN')
            return expr
        else:
            raise SyntaxError(f"Unexpected token {t.type} '{t.value}' at line {t.line}")
