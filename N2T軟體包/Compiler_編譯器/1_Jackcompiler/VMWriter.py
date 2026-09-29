# VMWriter.py
# 把 CompilationEngine 給的 Jack AST，輸出成 VM 指令

class VMWriter:
    def __init__(self, output_stream):
        self.output = output_stream
        self.current_function = None

    # ========== 基本輸出工具 ==========

    def write(self, line: str):
        self.output.write(line + '\n')

    # ========== push / pop ==========

    def writePush(self, segment, index):
        """push segment index"""
        self.write(f"push {segment} {index}")

    def writePop(self, segment, index):
        """pop segment index"""
        self.write(f"pop {segment} {index}")

    def writePushConstant(self, value):
        """push constant value"""
        self.write(f"push constant {value}")

    # 讓 CompilationEngine 可以叫 write_int(...)
    def write_int(self, value):
        """wrapper: push constant {value}"""
        self.writePushConstant(value)

    # 舊名稱 wrapper：如果 CompilationEngine 用 write_push / write_pop / write_push_constant
    def write_push(self, segment, index):
        self.writePush(segment, index)

    def write_pop(self, segment, index):
        self.writePop(segment, index)

    def write_push_constant(self, value):
        self.writePushConstant(value)

    # ========== string 處理（for stringConstant） ==========

    def write_string(self, value: str):
        """
        Jack 的 stringConstant 轉成 VM：
          let s = "abc";
        =>
          push constant 3
          call String.new 1
          push constant 97
          call String.appendChar 2
          push constant 98
          call String.appendChar 2
          push constant 99
          call String.appendChar 2
        最後棧頂就是字串物件指標
        """
        length = len(value)
        # 建立 String 物件
        self.writePushConstant(length)
        self.writeCall("String.new", 1)
        # 依序 append 每個字元
        for ch in value:
            self.writePushConstant(ord(ch))
            self.writeCall("String.appendChar", 2)

    # ---- 針對 symbol 的 push/pop（CompilationEngine 會傳 jack_symbol 進來）----

    def _kind_to_segment(self, kind):
        """
        Jack Symbol.kind -> VM segment 名稱
        kind: 'static', 'field', 'arg', 'var'
        """
        table = {
            'static': 'static',
            'field':  'this',
            'arg':    'argument',
            'var':    'local'
        }
        return table.get(kind, None)

    def write_push_symbol(self, jack_symbol):
        """
        push 一個 symbol 到 stack
        jack_symbol: 具有 kind, type, id 的 JackSymbol
        """
        if jack_symbol is None:
            # 找不到 symbol：先輸出註解方便 debug，不中斷編譯
            self.write("// WARNING: write_push_symbol called with None (undefined variable?)")
            # 避免 VM 堆疊錯亂，先 push 0
            self.writePushConstant(0)
            return

        segment = self._kind_to_segment(jack_symbol.kind)
        if segment is None:
            self.write(f"// WARNING: unknown kind {jack_symbol.kind} in write_push_symbol")
            self.writePushConstant(0)
            return

        index = jack_symbol.id          # CompilationTypes 用的是 id
        self.writePush(segment, index)

    def write_pop_symbol(self, jack_symbol):
        """
        pop stack top 到一個 symbol 變數裡
        """
        if jack_symbol is None:
            # 找不到 symbol：輸出註解，不中斷
            self.write("// WARNING: write_pop_symbol called with None (undefined variable?)")
            # 把 stack top 丟到 temp 0，避免堆疊失衡
            self.writePop("temp", 0)
            return

        segment = self._kind_to_segment(jack_symbol.kind)
        if segment is None:
            self.write(f"// WARNING: unknown kind {jack_symbol.kind} in write_pop_symbol")
            self.writePop("temp", 0)
            return

        index = jack_symbol.id
        self.writePop(segment, index)

    # ========== 算術 / 邏輯運算 ==========

    def writeArithmetic(self, command):
        """
        command: add, sub, neg, eq, gt, lt, and, or, not
        """
        self.write(command)

    # 舊名稱 wrapper：write_arithmetic
    def write_arithmetic(self, command):
        self.writeArithmetic(command)

    # ========== label / goto / if-goto ==========

    def writeLabel(self, label):
        self.write(f"label {label}")

    def writeGoto(self, label):
        self.write(f"goto {label}")

    def writeIf(self, label):
        self.write(f"if-goto {label}")

    # 舊名稱 wrapper：帶底線版本
    def write_label(self, label):
        self.writeLabel(label)

    def write_goto(self, label):
        self.writeGoto(label)

    def write_if(self, label):
        self.writeIf(label)

    # ========== function / call / return ==========

    def writeFunction(self, jack_subroutine):
        """
        接受一個 JackSubroutine 物件。
        CompilationTypes.JackSubroutine 已經有：
          - full_name 屬性: 'ClassName.subroutineName'
          - n_locals() 方法: 回傳 local 變數數
        """
        name = jack_subroutine.full_name
        n_locals = jack_subroutine.n_locals()
        self.current_function = name
        self.write(f"function {name} {n_locals}")

    def writeCall(self, name, n_args):
        """call name n_args"""
        self.write(f"call {name} {n_args}")

    def writeReturn(self):
        """return"""
        self.write("return")

    # ---- 舊名稱 / 相容 wrapper：function / call / return ----

    def write_function(self, jack_subroutine):
        """wrapper for writeFunction(jack_subroutine)"""
        self.writeFunction(jack_subroutine)

    def write_call(self, a, b, c=None):
        """
        兼容兩種呼叫方式：
          1) write_call("Class.func", n_args)
          2) write_call("Class", "func", n_args)   <-- 你現在用的是這種
          3) write_call(jack_subroutine, n_args, ...)  (如果未來有)
        """
        # case 2: write_call("Class", "func", n_args)
        if c is not None and isinstance(a, str) and isinstance(b, str):
            full_name = f"{a}.{b}"
            n_args = c
            self.writeCall(full_name, n_args)
            return

        # 其他情況：a 可能是 "Class.func" 或 JackSubroutine
        name_or_subroutine = a
        n_args = b

        if hasattr(name_or_subroutine, "full_name"):
            target_name = name_or_subroutine.full_name
        else:
            target_name = name_or_subroutine
        self.writeCall(target_name, n_args)

    def write_return(self):
        """wrapper for writeReturn()"""
        self.writeReturn()

    # ========== 關閉輸出 ==========

    def close(self):
        self.output.close()