# CompilationTypes.py
# Project 11
# 功能：提供 symbol table 相關資料結構（class scope / subroutine scope）
# JackSymbol(kind, type, id)
# kind: static / field / arg / var
# id: 在對應 segment 的 offset

from collections import namedtuple

JackSymbol = namedtuple('Symbol', ['kind', 'type', 'id'])


class JackClass:
    """代表一個 Jack class 的 class scope symbol table"""

    def __init__(self, name):
        self.name = name
        self.symbols = dict()
        self.static_symbols = 0
        self.field_symbols = 0

    def add_field(self, name, var_type):
        self.symbols[name] = JackSymbol('field', var_type, self.field_symbols)
        self.field_symbols += 1

    def add_static(self, name, var_type):
        self.symbols[name] = JackSymbol('static', var_type, self.static_symbols)
        self.static_symbols += 1

    def get_symbol(self, name):
        return self.symbols.get(name)


class JackSubroutine:
    """代表一個 Jack subroutine 的 subroutine scope symbol table"""

    def __init__(self, name, subroutine_type, return_type, jack_class):
        self.name = name
        self.jack_class = jack_class          # JackClass 物件
        self.subroutine_type = subroutine_type  # constructor/function/method
        self.return_type = return_type

        self.symbols = dict()
        self.arg_symbols = 0
        self.var_symbols = 0

        # method 的 argument 0 是隱含的 this
        if subroutine_type == 'method':
            self.add_arg('this', self.jack_class.name)

    # ---- 給 CompilationEngine / VMWriter 用的輔助屬性 ----

    @property
    def full_name(self):
        """回傳 'ClassName.subroutineName'"""
        return f"{self.jack_class.name}.{self.name}"

    def n_locals(self):
        """回傳 local 變數數量（var kind 的數量）"""
        return self.var_symbols

    # ---- 符號表操作 ----

    def add_arg(self, name, var_type):
        self.symbols[name] = JackSymbol('arg', var_type, self.arg_symbols)
        self.arg_symbols += 1

    def add_var(self, name, var_type):
        self.symbols[name] = JackSymbol('var', var_type, self.var_symbols)
        self.var_symbols += 1

    def get_symbol(self, name):
        """
        先找 subroutine scope，找不到再找 class scope
        """
        symbol = self.symbols.get(name)
        if symbol is not None:
            return symbol
        return self.jack_class.get_symbol(name)