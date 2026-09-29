# JackTokenizer.py
# Project 11: Jack Compiler
# 功能：把 Jack 程式切成 token stream（Token(type, value)）
# 注意：這個 tokenizer 提供 current_token() / advance() 介面，
# CompilationEngine 會一直 pop token。

import re
import sys
from collections import namedtuple

Token = namedtuple('Token', ('type', 'value'))


class JackTokenizer:
    """
    Jack Tokenizer（簡化版）
    - 輸入是一整個 Jack 檔案內容字串
    - remove_comments() 先去註解
    - tokenize() 再依序切 token
    """

    # lexical elements regex
    RE_INTEGER = r'\d+'
    RE_STRING = r'"[^"\n]*"'  # 不跨行字串
    RE_IDENTIFIER = r'[A-Za-z_][A-Za-z_\d]*'
    RE_SYMBOL = r'\{|\}|\(|\)|\[|\]|\.|,|;|\+|-|\*|/|&|\||\<|\>|=|~'

    # keyword 要加 word boundary，避免 className 被拆成 class + Name
    KEYWORDS = [
        'class', 'method', 'constructor', 'function', 'field', 'static', 'var',
        'int', 'char', 'boolean', 'void', 'true', 'false', 'null', 'this', 'let',
        'do', 'if', 'else', 'while', 'return'
    ]
    RE_KEYWORD = r'(?:' + '|'.join(KEYWORDS) + r')\b'

    # token 類型檢查順序很重要：keyword 要先於 identifier
    LEXICAL_TYPES = [
        (RE_KEYWORD, 'keyword'),
        (RE_SYMBOL, 'symbol'),
        (RE_INTEGER, 'integerConstant'),
        (RE_STRING, 'stringConstant'),
        (RE_IDENTIFIER, 'identifier')
    ]

    # split 用：symbol 或 string 常數要被保留成獨立 token；其他以空白切
    RE_SPLIT = '(' + '|'.join(expr for expr in [RE_SYMBOL, RE_STRING]) + r')|\s+'

    @staticmethod
    def remove_comments(code: str) -> str:
        """
        移除 // 單行註解 與 /* ... */ 多行註解
        使用 non-greedy 避免吃掉過多內容
        """
        code = re.sub(r'//.*?\n', '\n', code)
        code = re.sub(r'/\*.*?\*/', '', code, flags=re.DOTALL)
        return code

    def __init__(self, file_content: str):
        self.code = JackTokenizer.remove_comments(file_content)
        self.tokens = self.tokenize()

    def tokenize(self):
        """
        將 code 切成 Token list
        """
        split_code = re.split(self.RE_SPLIT, self.code)
        tokens = []

        for lex in split_code:
            if lex is None or re.match(r'^\s*$', lex):
                continue

            matched = False
            for expr, lex_type in self.LEXICAL_TYPES:
                if re.fullmatch(expr, lex):
                    tokens.append(Token(lex_type, lex))
                    matched = True
                    break

            if not matched:
                print('Error: unknown token', lex)
                sys.exit(1)

        return tokens

    def current_token(self):
        """回傳目前 token（不 pop），若沒了回傳 None"""
        return self.tokens[0] if self.tokens else None

    def advance(self):
        """pop 並回傳目前 token；若沒了回傳 None"""
        return self.tokens.pop(0) if self.tokens else None