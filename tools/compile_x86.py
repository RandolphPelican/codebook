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


"""
atreyu_x86.py — CBS → Bytecode Compiler
Opcodes match the bare-metal x86 VM in boot.asm exactly.
"""
import sys, struct

# === Opcodes (MUST match boot.asm %define OP_* values) ===
OP_PUSH      = 0x01  # push i32
OP_PUSH_STR  = 0x02  # push string (2-byte len + data + pad)
OP_ADD       = 0x10
OP_SUB       = 0x11
OP_MUL       = 0x12
OP_DIV       = 0x13
OP_EQ        = 0x14
OP_NE        = 0x15
OP_LT        = 0x16
OP_GT        = 0x17
OP_LE        = 0x18
OP_GE        = 0x19
OP_RESERVE   = 0x20
OP_JMP       = 0x40  # unconditional, signed i32 offset
OP_JIF       = 0x55  # jump if false (TOS==0), signed i32 offset
OP_JBACK     = 0x56  # jump back, unsigned offset (subtracted)
OP_RET       = 0x53
OP_LOAD      = 0x70
OP_STORE     = 0x71
OP_PRINT_NUM = 0x80
OP_EMIT      = 0x81
OP_NEWLINE   = 0x82
OP_DUP       = 0x83
OP_DROP      = 0x84
OP_SWAP      = 0x85
OP_PRINT_STR = 0x86  # pop string ref, print
OP_MOD       = 0x1A
OP_CALL      = 0x50
OP_DUP2      = 0x87
OP_GRANT_CAP = 0x90
OP_USE_CAP   = 0x91
OP_HALT      = 0xFF

class Emitter:
    def __init__(self):
        self.code = bytearray()
    def pos(self): return len(self.code)
    def emit(self, b): self.code.append(b & 0xFF)
    def emit_i32(self, v): self.code.extend(struct.pack('<i', v))
    def emit_u16(self, v): self.code.extend(struct.pack('<H', v))
    def patch_i32(self, off, val): self.code[off:off+4] = struct.pack('<i', val)
    def get(self): return bytes(self.code)

class AtreyuX86:
    def __init__(self):
        self.e = Emitter()
        self.vars = {}
        self.next_var = 0
        self.funcs = {}

    def var_id(self, name):
        if name not in self.vars:
            self.vars[name] = self.next_var; self.next_var += 1
        return self.vars[name]

    def compile(self, ast):
        e = self.e
        if ast.get('type') == 'program':
            # JMP over functions
            e.emit(OP_JMP); jp = e.pos(); e.emit_i32(0)
            for s in ast.get('body', []):
                if s.get('type') == 'function':
                    self.funcs[s['name']] = e.pos()
                    self._func(s)
            e.patch_i32(jp, e.pos() - (jp + 4))
            for s in ast.get('body', []):
                if s.get('type') != 'function': self._stmt(s)
        e.emit(OP_HALT)
        return e.get()

    def _func(self, n):
        for p in reversed(n.get('params', [])):
            self.e.emit(OP_STORE); self.e.emit_i32(self.var_id(p))
        cost = n.get('cost', 0)
        if cost > 0:
            self.e.emit(OP_RESERVE); self.e.emit_i32(cost)
        self._block(n['body'])
        self.e.emit(OP_PUSH); self.e.emit_i32(0)
        self.e.emit(OP_RET)

    def _block(self, n):
        for s in n.get('stmts', []): self._stmt(s)

    def _stmt(self, n):
        e = self.e; t = n['type']
        if t == 'let':
            self._expr(n['value']); e.emit(OP_STORE); e.emit_i32(self.var_id(n['name']))
        elif t == 'return':
            self._expr(n['value']); e.emit(OP_RET)
        elif t == 'print':
            v = n['value']
            if v.get('type') == 'str':
                self._push_str(v['value']); e.emit(OP_PRINT_STR)
            else:
                self._expr(v); e.emit(OP_PRINT_NUM)
            e.emit(OP_NEWLINE)
        elif t == 'if': self._if(n)
        elif t == 'while': self._while(n)
        elif t == 'block': self._block(n)
        elif t == 'expr_stmt':
            self._expr(n['value']); e.emit(OP_DROP)

    def _push_str(self, s):
        e = self.e; raw = s.encode('utf-8')
        e.emit(OP_PUSH_STR); e.emit_u16(len(raw))
        e.code.extend(raw)
        pad = (4 - (len(raw) % 4)) % 4
        e.code.extend(b'\x00' * pad)

    def _if(self, n):
        e = self.e
        self._expr(n['cond'])
        e.emit(OP_JIF); ep = e.pos(); e.emit_i32(0)
        self._block(n['then'])
        if n.get('else'):
            e.emit(OP_JMP); endp = e.pos(); e.emit_i32(0)
            e.patch_i32(ep, e.pos() - (ep + 4))
            el = n['else']
            if el['type'] == 'if': self._if(el)
            else: self._block(el)
            e.patch_i32(endp, e.pos() - (endp + 4))
        else:
            e.patch_i32(ep, e.pos() - (ep + 4))

    def _while(self, n):
        e = self.e
        top = e.pos()
        self._expr(n['cond'])
        e.emit(OP_JIF); ep = e.pos(); e.emit_i32(0)
        self._block(n['body'])
        e.emit(OP_JMP); e.emit_i32(top - (e.pos() + 4))
        e.patch_i32(ep, e.pos() - (ep + 4))

    def _expr(self, n):
        e = self.e; t = n['type']
        if t == 'int': e.emit(OP_PUSH); e.emit_i32(n['value'])
        elif t == 'bool': e.emit(OP_PUSH); e.emit_i32(1 if n['value'] else 0)
        elif t == 'str': self._push_str(n['value'])
        elif t == 'var': e.emit(OP_LOAD); e.emit_i32(self.var_id(n['name']))
        elif t == 'neg': self._expr(n['value']); e.emit(OP_PUSH); e.emit_i32(0); e.emit(OP_SWAP); e.emit(OP_SUB)
        elif t == 'not': self._expr(n['value']); e.emit(OP_PUSH); e.emit_i32(0); e.emit(OP_EQ)
        elif t in ('add','sub','mul','div','mod','eq','ne','lt','gt','le','ge'):
            self._expr(n['left']); self._expr(n['right'])
            m = {'add':OP_ADD,'sub':OP_SUB,'mul':OP_MUL,'div':OP_DIV,'mod':OP_MOD,
                 'eq':OP_EQ,'ne':OP_NE,'lt':OP_LT,'gt':OP_GT,'le':OP_LE,'ge':OP_GE}
            e.emit(m[t])
        elif t == 'call':
            for a in n['args']: self._expr(a)
            # Simple: inline call not supported yet, treat as error
            print(f"Warning: function calls not yet supported in bytecode", file=sys.stderr)

# === Demo Programs ===
def demo_full():
    return {'type':'program','body':[
        {'type':'print','value':{'type':'str','value':'=== CodebookScript VM ==='}},
        {'type':'print','value':{'type':'str','value':'Running on bare metal x86_64'}},
        {'type':'print','value':{'type':'str','value':'StableTech Enterprises LLC'}},
        {'type':'print','value':{'type':'str','value':''}},
        # Math
        {'type':'print','value':{'type':'str','value':'-- Arithmetic --'}},
        {'type':'let','name':'x','value':{'type':'int','value':42}},
        {'type':'let','name':'y','value':{'type':'mul','left':{'type':'var','name':'x'},'right':{'type':'int','value':10}}},
        {'type':'print','value':{'type':'var','name':'y'}},
        # Conditional
        {'type':'print','value':{'type':'str','value':'-- Conditional --'}},
        {'type':'if',
         'cond':{'type':'gt','left':{'type':'var','name':'y'},'right':{'type':'int','value':100}},
         'then':{'type':'block','stmts':[{'type':'print','value':{'type':'str','value':'y > 100: true'}}]},
         'else':{'type':'block','stmts':[{'type':'print','value':{'type':'str','value':'y > 100: false'}}]}},
        # Fibonacci
        {'type':'print','value':{'type':'str','value':'-- Fibonacci (20 terms) --'}},
        {'type':'let','name':'a','value':{'type':'int','value':0}},
        {'type':'let','name':'b','value':{'type':'int','value':1}},
        {'type':'let','name':'n','value':{'type':'int','value':0}},
        {'type':'while',
         'cond':{'type':'lt','left':{'type':'var','name':'n'},'right':{'type':'int','value':20}},
         'body':{'type':'block','stmts':[
             {'type':'print','value':{'type':'var','name':'a'}},
             {'type':'let','name':'t','value':{'type':'var','name':'b'}},
             {'type':'let','name':'b','value':{'type':'add','left':{'type':'var','name':'a'},'right':{'type':'var','name':'b'}}},
             {'type':'let','name':'a','value':{'type':'var','name':'t'}},
             {'type':'let','name':'n','value':{'type':'add','left':{'type':'var','name':'n'},'right':{'type':'int','value':1}}},
         ]}},
        {'type':'print','value':{'type':'str','value':''}},
        {'type':'print','value':{'type':'str','value':'=== CBS complete ==='}},
    ]}

    if '--build' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_full())
        out = sys.argv[sys.argv.index('--build')+1] if len(sys.argv) > sys.argv.index('--build')+1 else 'demo.cbc'
        with open(out,'wb') as f: f.write(bc)
        print(f"Compiled {len(bc)} bytes -> {out}")
        print(f"Vars: {c.vars}")
    elif '--test' in sys.argv:
        c = AtreyuX86(); bc = c.compile(demo_full())
        print(f"Demo: {len(bc)} bytes, vars: {c.vars}")
        for i in range(0, min(len(bc),64), 16):
            h = ' '.join(f'{b:02X}' for b in bc[i:i+16])
            print(f"  {i:04X}: {h}")
        print(f"First: 0x{bc[0]:02X} Last: 0x{bc[-1]:02X}")
    else:
        print("Usage: python3 atreyu_x86.py --build [out.cbc] | --test")
#..


if __name__ == '__main__':
    if len(sys.argv) < 2:
        print('Usage: compile_x86.py <source.cbs> [out.cbc]')
        sys.exit(1)
    with open(sys.argv[1]) as f: source = f.read()
    tokens = Lexer(source).tokenize()
    ast = Parser(tokens).parse()
    bc = AtreyuX86().compile(ast)
    out = sys.argv[2] if len(sys.argv) > 2 else sys.argv[1].replace('.cbs', '.cbc')
    with open(out, 'wb') as f: f.write(bc)
    print(f'Compiled {len(bc)} bytes -> {out}')
