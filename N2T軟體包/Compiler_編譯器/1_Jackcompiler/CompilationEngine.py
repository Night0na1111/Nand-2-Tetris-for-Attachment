#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# CompilationEngine.py
# Project 11: Jack Compiler
# 功能：把 Jack token stream 轉成 VM code
# 實作重點：
# - 建 symbol table（class scope + subroutine scope）
# - 生成 VM：function/call/return、memory access、control flow、expression evaluation

import VMWriter
import CompilationTypes

# 二元運算符對應 VM 動作
binary_op_actions = {
    '+': 'add',
    '-': 'sub',
    '*': 'call Math.multiply 2',
    '/': 'call Math.divide 2',
    '&': 'and',
    '|': 'or',
    '<': 'lt',
    '>': 'gt',
    '=': 'eq'
}


class CompilationEngine:
    def __init__(self, tokenizer, ostream):
        self.tokenizer = tokenizer
        self.vm_writer = VMWriter.VMWriter(ostream)
        self.label_count = 0  # 用來產生唯一 label（避免 global）

    def _new_label(self, prefix="L"):
        """產生唯一 label（for if/while）"""
        label = f"{prefix}{self.label_count}"
        self.label_count += 1
        return label

    # -------------------------
    # class level
    # -------------------------

    def compile_class(self):
        """
        class: 'class' className '{' classVarDec* subroutineDec* '}'
        """
        self.tokenizer.advance()  # 'class'

        class_name = self.tokenizer.advance().value
        jack_class = CompilationTypes.JackClass(class_name)

        self.tokenizer.advance()  # '{'

        self.compile_class_vars(jack_class)
        self.compile_class_subroutines(jack_class)

        self.tokenizer.advance()  # '}'

    def compile_class_vars(self, jack_class):
        """
        classVarDec:
            ('static'|'field') type varName (',' varName)* ';'
        """
        token = self.tokenizer.current_token()
        while token is not None and token.type == 'keyword' and token.value in ['static', 'field']:
            kind = self.tokenizer.advance().value  # static/field
            is_static = (kind == 'static')

            var_type = self.tokenizer.advance().value  # type

            # 可能同一行多個 varName
            while True:
                var_name = self.tokenizer.advance().value
                if is_static:
                    jack_class.add_static(var_name, var_type)
                else:
                    jack_class.add_field(var_name, var_type)

                token = self.tokenizer.advance()  # ',' 或 ';'
                if token == ('symbol', ','):
                    continue
                else:
                    break

            token = self.tokenizer.current_token()

    def compile_class_subroutines(self, jack_class):
        """
        subroutineDec:
          ('constructor'|'function'|'method') ('void'|type) subroutineName
          '(' parameterList ')' subroutineBody
        """
        token = self.tokenizer.current_token()
        while token is not None and token.type == 'keyword' and token.value in ['constructor', 'function', 'method']:
            subroutine_type = self.tokenizer.advance().value
            return_type = self.tokenizer.advance().value
            name = self.tokenizer.advance().value

            jack_subroutine = CompilationTypes.JackSubroutine(
                name, subroutine_type, return_type, jack_class
            )

            self.tokenizer.advance()  # '('
            self.compile_parameter_list(jack_subroutine)
            self.tokenizer.advance()  # ')'

            self.compile_subroutine_body(jack_subroutine)

            token = self.tokenizer.current_token()

    def compile_parameter_list(self, jack_subroutine):
        """
        parameterList: ((type varName) (',' type varName)*)?
        結束條件：下一個 token 是 ')'
        """
        token = self.tokenizer.current_token()
        # type 可以是 keyword(int/char/boolean) 或 identifier(className)
        still_vars = token is not None and token.type in ['keyword', 'identifier'] and token.value != ')'

        while still_vars:
            param_type = self.tokenizer.advance().value
            param_name = self.tokenizer.advance().value
            jack_subroutine.add_arg(param_name, param_type)

            token = self.tokenizer.current_token()
            if token == ('symbol', ','):
                self.tokenizer.advance()  # 丟掉 ','
                token = self.tokenizer.current_token()
                still_vars = token is not None and token.type in ['keyword', 'identifier']
            else:
                still_vars = False

    # -------------------------
    # subroutine body / varDec
    # -------------------------

    def compile_subroutine_body(self, jack_subroutine):
        """
        subroutineBody: '{' varDec* statements '}'
        同時負責：
        - 輸出 function header
        - constructor/method 的 this 初始化
        """
        self.tokenizer.advance()  # '{'

        self.compile_subroutine_vars(jack_subroutine)

        # function Class.Sub nLocals
        self.vm_writer.writeFunction(jack_subroutine)

        # constructor: alloc memory for fields, set pointer 0 (this)
        if jack_subroutine.subroutine_type == 'constructor':
            field_count = jack_subroutine.jack_class.field_symbols
            self.vm_writer.write_push('constant', field_count)
            self.vm_writer.write_call('Memory', 'alloc', 1)
            self.vm_writer.write_pop('pointer', 0)

        # method: argument0 是 this，要設 pointer 0
        elif jack_subroutine.subroutine_type == 'method':
            self.vm_writer.write_push('argument', 0)
            self.vm_writer.write_pop('pointer', 0)

        self.compile_statements(jack_subroutine)

        self.tokenizer.advance()  # '}'

    def compile_subroutine_vars(self, jack_subroutine):
        """
        varDec: 'var' type varName (',' varName)* ';'
        """
        token = self.tokenizer.current_token()
        while token is not None and token == ('keyword', 'var'):
            self.tokenizer.advance()  # 'var'
            var_type = self.tokenizer.advance().value
            var_name = self.tokenizer.advance().value
            jack_subroutine.add_var(var_name, var_type)

            # 可能有 , varName 重複
            while self.tokenizer.current_token() == ('symbol', ','):
                self.tokenizer.advance()  # ','
                var_name = self.tokenizer.advance().value
                jack_subroutine.add_var(var_name, var_type)

            self.tokenizer.advance()  # ';'
            token = self.tokenizer.current_token()

    # -------------------------
    # statements
    # -------------------------

    def compile_statements(self, jack_subroutine):
        """
        statements: statement*
        """
        while True:
            token = self.tokenizer.current_token()
            if token == ('keyword', 'if'):
                self.compile_statement_if(jack_subroutine)
            elif token == ('keyword', 'while'):
                self.compile_statement_while(jack_subroutine)
            elif token == ('keyword', 'let'):
                self.compile_statement_let(jack_subroutine)
            elif token == ('keyword', 'do'):
                self.compile_statement_do(jack_subroutine)
            elif token == ('keyword', 'return'):
                self.compile_statement_return(jack_subroutine)
            else:
                break

    def compile_statement_if(self, jack_subroutine):
        """
        ifStatement:
          'if' '(' expression ')' '{' statements '}' ('else' '{' statements '}')?
        VM 策略：
          - 先算 condition，若 false 跳到 false_label
          - true 區塊結束後 goto end_label
          - false_label: else 區塊（若有）
          - end_label:
        """
        self.tokenizer.advance()  # 'if'
        self.tokenizer.advance()  # '('
        self.compile_expression(jack_subroutine)
        self.tokenizer.advance()  # ')'
        self.tokenizer.advance()  # '{'

        false_label = self._new_label("IF_FALSE_")
        end_label = self._new_label("IF_END_")

        # if condition is false -> jump to IF_FALSE
        self.vm_writer.write('not')
        self.vm_writer.write_if(false_label)

        self.compile_statements(jack_subroutine)
        self.tokenizer.advance()  # '}'
        self.vm_writer.write_goto(end_label)

        self.vm_writer.write_label(false_label)

        # optional else
        token = self.tokenizer.current_token()
        if token == ('keyword', 'else'):
            self.tokenizer.advance()  # 'else'
            self.tokenizer.advance()  # '{'
            self.compile_statements(jack_subroutine)
            self.tokenizer.advance()  # '}'

        self.vm_writer.write_label(end_label)

    def compile_statement_while(self, jack_subroutine):
        """
        whileStatement:
          'while' '(' expression ')' '{' statements '}'
        VM 策略：
          LOOP:
            compute expression
            if not condition goto END
            statements
            goto LOOP
          END:
        """
        self.tokenizer.advance()  # 'while'

        loop_label = self._new_label("WHILE_LOOP_")
        end_label = self._new_label("WHILE_END_")

        self.vm_writer.write_label(loop_label)

        self.tokenizer.advance()  # '('
        self.compile_expression(jack_subroutine)
        self.tokenizer.advance()  # ')'

        # if not condition -> exit
        self.vm_writer.write('not')
        self.vm_writer.write_if(end_label)

        self.tokenizer.advance()  # '{'
        self.compile_statements(jack_subroutine)
        self.tokenizer.advance()  # '}'

        self.vm_writer.write_goto(loop_label)
        self.vm_writer.write_label(end_label)

    def compile_statement_let(self, jack_subroutine):
        """
        letStatement:
          'let' varName ('[' expression ']')? '=' expression ';'
        
        若是陣列賦值 arr[exp1] = exp2：
          1) push arr
          2) push exp1
          3) add -> 得到目標地址
          4) push exp2
          5) pop temp 0
          6) pop pointer 1  (THAT = 目標地址)
          7) push temp 0
          8) pop that 0
        """
        self.tokenizer.advance()  # 'let'
        var_name = self.tokenizer.advance().value
        var_symbol = jack_subroutine.get_symbol(var_name)

        # 檢查是否為陣列存取
        is_array = False
        if self.tokenizer.current_token() == ('symbol', '['):
            is_array = True
            self.tokenizer.advance()  # '['
            
            # push 陣列基址
            if var_symbol:
                self.vm_writer.write_push_symbol(var_symbol)
            else:
                self.vm_writer.write("// WARNING: undefined array " + var_name)
                self.vm_writer.write_push_constant(0)
            
            # push 索引
            self.compile_expression(jack_subroutine)
            self.tokenizer.advance()  # ']'
            
            # 計算目標地址
            self.vm_writer.write('add')

        self.tokenizer.advance()  # '='
        self.compile_expression(jack_subroutine)
        self.tokenizer.advance()  # ';'

        if is_array:
            # 陣列賦值：先把右值存到 temp，設定 THAT，再寫入
            self.vm_writer.write_pop('temp', 0)
            self.vm_writer.write_pop('pointer', 1)
            self.vm_writer.write_push('temp', 0)
            self.vm_writer.write_pop('that', 0)
        else:
            # 一般變數賦值
            if var_symbol:
                self.vm_writer.write_pop_symbol(var_symbol)
            else:
                self.vm_writer.write("// WARNING: undefined variable " + var_name)
                self.vm_writer.write_pop('temp', 0)

    def compile_statement_do(self, jack_subroutine):
        """
        doStatement:
          'do' subroutineCall ';'
        """
        self.tokenizer.advance()  # 'do'
        self.compile_subroutine_call(jack_subroutine)
        self.tokenizer.advance()  # ';'
        # do 語句會產生返回值，但我們不需要，丟棄它
        self.vm_writer.write_pop('temp', 0)

    def compile_statement_return(self, jack_subroutine):
        """
        returnStatement:
          'return' expression? ';'
        """
        self.tokenizer.advance()  # 'return'

        token = self.tokenizer.current_token()
        if token != ('symbol', ';'):
            self.compile_expression(jack_subroutine)
        else:
            # void function: push 0
            self.vm_writer.write_push_constant(0)

        self.tokenizer.advance()  # ';'
        self.vm_writer.write_return()

    # -------------------------
    # expressions
    # -------------------------

    def compile_expression(self, jack_subroutine):
        """
        expression: term (op term)*
        Jack 沒有運算子優先級，嚴格從左到右
        """
        self.compile_term(jack_subroutine)

        while True:
            token = self.tokenizer.current_token()
            if token and token.type == 'symbol' and token.value in binary_op_actions:
                op = self.tokenizer.advance().value
                self.compile_term(jack_subroutine)
                
                # 輸出對應的 VM 指令
                vm_cmd = binary_op_actions[op]
                if vm_cmd.startswith('call'):
                    # 乘法和除法需要呼叫 Math 函數
                    parts = vm_cmd.split()
                    self.vm_writer.write_call(parts[1], int(parts[2]))
                else:
                    self.vm_writer.write(vm_cmd)
            else:
                break

    def compile_term(self, jack_subroutine):
        """
        term:
          integerConstant | stringConstant | keywordConstant |
          varName | varName '[' expression ']' |
          subroutineCall |
          '(' expression ')' |
          unaryOp term
        """
        token = self.tokenizer.current_token()

        # integerConstant
        if token.type == 'integerConstant':
            value = int(self.tokenizer.advance().value)
            self.vm_writer.write_int(value)
            return

        # stringConstant
        if token.type == 'stringConstant':
            s = self.tokenizer.advance().value
            if len(s) >= 2 and s[0] == '"' and s[-1] == '"':
                s = s[1:-1]  # 移除前後的引號，變成 'TETRIS'
            self.vm_writer.write_string(s)
            return

        # keywordConstant: true, false, null, this
        if token.type == 'keyword' and token.value in ['true', 'false', 'null', 'this']:
            kw = self.tokenizer.advance().value
            if kw == 'true':
                self.vm_writer.write_push_constant(0)
                self.vm_writer.write('not')
            elif kw in ['false', 'null']:
                self.vm_writer.write_push_constant(0)
            elif kw == 'this':
                self.vm_writer.write_push('pointer', 0)
            return

        # '(' expression ')'
        if token == ('symbol', '('):
            self.tokenizer.advance()  # '('
            self.compile_expression(jack_subroutine)
            self.tokenizer.advance()  # ')'
            return

        # unaryOp term
        if token.type == 'symbol' and token.value in ['-', '~']:
            op = self.tokenizer.advance().value
            self.compile_term(jack_subroutine)
            if op == '-':
                self.vm_writer.write('neg')
            else:
                self.vm_writer.write('not')
            return

        # 剩下是 identifier：可能是 varName, varName[exp], subroutineCall
        if token.type == 'identifier':
            name = self.tokenizer.advance().value
            next_token = self.tokenizer.current_token()

            # varName '[' expression ']'
            if next_token == ('symbol', '['):
                var_symbol = jack_subroutine.get_symbol(name)
                if var_symbol:
                    self.vm_writer.write_push_symbol(var_symbol)
                else:
                    self.vm_writer.write("// WARNING: undefined array " + name)
                    self.vm_writer.write_push_constant(0)
                
                self.tokenizer.advance()  # '['
                self.compile_expression(jack_subroutine)
                self.tokenizer.advance()  # ']'
                
                self.vm_writer.write('add')
                self.vm_writer.write_pop('pointer', 1)
                self.vm_writer.write_push('that', 0)
                return

            # subroutineCall: name '(' expressionList ')' 或 name '.' name '(' expressionList ')'
            if next_token and next_token.type == 'symbol' and next_token.value in ['(', '.']:
                # 回退，讓 compile_subroutine_call 處理
                self.tokenizer.tokens.insert(0, token)
                self.compile_subroutine_call(jack_subroutine)
                return

            # 單純 varName
            var_symbol = jack_subroutine.get_symbol(name)
            if var_symbol:
                self.vm_writer.write_push_symbol(var_symbol)
            else:
                self.vm_writer.write("// WARNING: undefined variable " + name)
                self.vm_writer.write_push_constant(0)
            return

        raise ValueError(f"Unexpected term: {token}")

    def compile_subroutine_call(self, jack_subroutine):
        """
        subroutineCall:
          subroutineName '(' expressionList ')' |
          (className | varName) '.' subroutineName '(' expressionList ')'
        """
        name = self.tokenizer.advance().value
        token = self.tokenizer.current_token()

        if token == ('symbol', '('):
            # method call on current object: name(...)
            # 等同於 this.name(...)
            self.vm_writer.write_push('pointer', 0)
            self.tokenizer.advance()  # '('
            n_args = self.compile_expression_list(jack_subroutine)
            self.tokenizer.advance()  # ')'
            
            # 方法呼叫：className.methodName
            full_name = f"{jack_subroutine.jack_class.name}.{name}"
            self.vm_writer.write_call(full_name, n_args + 1)

        elif token == ('symbol', '.'):
            # obj.method(...) 或 Class.function(...)
            self.tokenizer.advance()  # '.'
            method_name = self.tokenizer.advance().value
            
            # 檢查 name 是否為變數（物件）
            var_symbol = jack_subroutine.get_symbol(name)
            
            if var_symbol:
                # 是物件，呼叫方法
                self.vm_writer.write_push_symbol(var_symbol)
                self.tokenizer.advance()  # '('
                n_args = self.compile_expression_list(jack_subroutine)
                self.tokenizer.advance()  # ')'
                
                # 方法呼叫：varType.methodName
                full_name = f"{var_symbol.type}.{method_name}"
                self.vm_writer.write_call(full_name, n_args + 1)
            else:
                # 是類別名稱，呼叫函數或建構子
                self.tokenizer.advance()  # '('
                n_args = self.compile_expression_list(jack_subroutine)
                self.tokenizer.advance()  # ')'
                
                full_name = f"{name}.{method_name}"
                self.vm_writer.write_call(full_name, n_args)

    def compile_expression_list(self, jack_subroutine):
        """
        expressionList: (expression (',' expression)*)?
        回傳表達式數量
        """
        count = 0
        token = self.tokenizer.current_token()
        
        if token != ('symbol', ')'):
            self.compile_expression(jack_subroutine)
            count = 1
            
            while self.tokenizer.current_token() == ('symbol', ','):
                self.tokenizer.advance()  # ','
                self.compile_expression(jack_subroutine)
                count += 1
        
        return count
