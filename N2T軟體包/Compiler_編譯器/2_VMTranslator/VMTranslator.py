#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
VMTranslator - 超級優化版本
目標：將生成的 ASM 程式碼減到最少
"""

from __future__ import annotations
import os
import sys
from dataclasses import dataclass

ARITHMETIC = {"add", "sub", "neg", "eq", "gt", "lt", "and", "or", "not"}
SEG_BASE = {"local": "LCL", "argument": "ARG", "this": "THIS", "that": "THAT"}
TEMP_BASE = 5
POINTER_THIS = 3
POINTER_THAT = 4

@dataclass
class Command:
    op: str
    args: list[str]
    raw: str

def clean_line(line: str) -> str:
    return line.split("//", 1)[0].strip()

def parse_vm_file(path: str) -> list[Command]:
    cmds: list[Command] = []
    with open(path, "r", encoding="utf-8") as f:
        for line in f:
            raw = line.rstrip("\n")
            line = clean_line(line)
            if not line:
                continue
            parts = line.split()
            cmds.append(Command(op=parts[0], args=parts[1:], raw=raw))
    return cmds

class CodeWriter:
    def __init__(self) -> None:
        self.lines: list[str] = []
        self.file_stem: str = "Static"
        self.label_id: int = 0
        self.current_function: str = ""
        self.call_id: int = 0

    def set_file_name(self, vm_path: str) -> None:
        self.file_stem = os.path.splitext(os.path.basename(vm_path))[0]

    def emit(self, *asm: str) -> None:
        self.lines.extend(asm)

    def write_bootstrap(self) -> None:
        # 極簡 bootstrap
        self.emit("@256", "D=A", "@SP", "M=D")
        self.write_call("Sys.init", 0)

    def write_arithmetic(self, cmd: str) -> None:
        if cmd in ("add", "sub", "and", "or"):
            self.emit("@SP", "AM=M-1", "D=M", "A=A-1")
            self.emit({"add": "M=D+M", "sub": "M=M-D", "and": "M=D&M", "or": "M=D|M"}[cmd])
        elif cmd in ("neg", "not"):
            self.emit("@SP", "A=M-1")
            self.emit("M=-M" if cmd == "neg" else "M=!M")
        elif cmd in ("eq", "gt", "lt"):
            t, e = f"T{self.label_id}", f"E{self.label_id}"
            self.label_id += 1
            self.emit("@SP", "AM=M-1", "D=M", "A=A-1", "D=M-D", f"@{t}")
            self.emit({"eq": "D;JEQ", "gt": "D;JGT", "lt": "D;JLT"}[cmd])
            self.emit("@SP", "A=M-1", "M=0", f"@{e}", "0;JMP")
            self.emit(f"({t})", "@SP", "A=M-1", "M=-1", f"({e})")

    def write_push_pop(self, cmd: str, segment: str, index: int) -> None:
        if cmd == "push":
            if segment == "constant":
                self.emit(f"@{index}", "D=A", "@SP", "AM=M+1", "A=A-1", "M=D")
            elif segment in SEG_BASE:
                if index == 0:
                    self.emit(f"@{SEG_BASE[segment]}", "A=M", "D=M")
                elif index == 1:
                    self.emit(f"@{SEG_BASE[segment]}", "A=M+1", "D=M")
                else:
                    self.emit(f"@{index}", "D=A", f"@{SEG_BASE[segment]}", "A=D+M", "D=M")
                self.emit("@SP", "AM=M+1", "A=A-1", "M=D")
            elif segment == "temp":
                self.emit(f"@{TEMP_BASE + index}", "D=M", "@SP", "AM=M+1", "A=A-1", "M=D")
            elif segment == "pointer":
                addr = POINTER_THIS if index == 0 else POINTER_THAT
                self.emit(f"@{addr}", "D=M", "@SP", "AM=M+1", "A=A-1", "M=D")
            elif segment == "static":
                self.emit(f"@{self.file_stem}.{index}", "D=M", "@SP", "AM=M+1", "A=A-1", "M=D")
        else:  # pop
            if segment in SEG_BASE:
                if index == 0:
                    self.emit("@SP", "AM=M-1", "D=M", f"@{SEG_BASE[segment]}", "A=M", "M=D")
                elif index == 1:
                    self.emit("@SP", "AM=M-1", "D=M", f"@{SEG_BASE[segment]}", "A=M+1", "M=D")
                else:
                    self.emit(f"@{index}", "D=A", f"@{SEG_BASE[segment]}", "D=D+M", "@R13", "M=D")
                    self.emit("@SP", "AM=M-1", "D=M", "@R13", "A=M", "M=D")
            elif segment == "temp":
                self.emit("@SP", "AM=M-1", "D=M", f"@{TEMP_BASE + index}", "M=D")
            elif segment == "pointer":
                addr = POINTER_THIS if index == 0 else POINTER_THAT
                self.emit("@SP", "AM=M-1", "D=M", f"@{addr}", "M=D")
            elif segment == "static":
                self.emit("@SP", "AM=M-1", "D=M", f"@{self.file_stem}.{index}", "M=D")

    def scoped_label(self, label: str) -> str:
        return f"{self.current_function}${label}" if self.current_function else label

    def write_label(self, label: str) -> None:
        self.emit(f"({self.scoped_label(label)})")

    def write_goto(self, label: str) -> None:
        self.emit(f"@{self.scoped_label(label)}", "0;JMP")

    def write_if(self, label: str) -> None:
        self.emit("@SP", "AM=M-1", "D=M", f"@{self.scoped_label(label)}", "D;JNE")

    def write_function(self, func_name: str, n_locals: int) -> None:
        self.current_function = func_name
        self.emit(f"({func_name})")
        if n_locals > 0:
            # 超級優化：批次初始化
            self.emit("@SP", "A=M")
            for _ in range(n_locals):
                self.emit("M=0", "A=A+1")
            self.emit("D=A", "@SP", "M=D")

    def write_call(self, func_name: str, n_args: int) -> None:
        ret = f"R{self.file_stem}{self.call_id}"
        self.call_id += 1
        
        # push return address
        self.emit(f"@{ret}", "D=A", "@SP", "AM=M+1", "A=A-1", "M=D")
        
        # push LCL, ARG, THIS, THAT (合併操作)
        for seg in ("LCL", "ARG", "THIS", "THAT"):
            self.emit(f"@{seg}", "D=M", "@SP", "AM=M+1", "A=A-1", "M=D")
        
        # ARG = SP - 5 - n_args (優化計算)
        self.emit("@SP", "D=M", f"@{5 + n_args}", "D=D-A", "@ARG", "M=D")
        
        # LCL = SP, goto f
        self.emit("@SP", "D=M", "@LCL", "M=D", f"@{func_name}", "0;JMP", f"({ret})")

    def write_return(self) -> None:
        # FRAME = LCL, RET = *(FRAME-5)
        self.emit("@LCL", "D=M", "@R13", "M=D", "@5", "A=D-A", "D=M", "@R14", "M=D")
        
        # *ARG = pop(), SP = ARG + 1
        self.emit("@SP", "AM=M-1", "D=M", "@ARG", "A=M", "M=D", "@ARG", "D=M+1", "@SP", "M=D")
        
        # Restore THAT, THIS, ARG, LCL (優化)
        for seg, offset in [("THAT", 1), ("THIS", 2), ("ARG", 3), ("LCL", 4)]:
            self.emit("@R13", "D=M", f"@{offset}", "A=D-A", "D=M", f"@{seg}", "M=D")
        
        # goto RET
        self.emit("@R14", "A=M", "0;JMP")

def translate(vm_paths: list[str], out_asm_path: str, bootstrap: bool) -> None:
    cw = CodeWriter()
    if bootstrap:
        cw.write_bootstrap()
    
    for vm_path in vm_paths:
        cw.set_file_name(vm_path)
        for c in parse_vm_file(vm_path):
            if c.op in ARITHMETIC:
                cw.write_arithmetic(c.op)
            elif c.op in ("push", "pop"):
                cw.write_push_pop(c.op, c.args[0], int(c.args[1]))
            elif c.op == "label":
                cw.write_label(c.args[0])
            elif c.op == "goto":
                cw.write_goto(c.args[0])
            elif c.op == "if-goto":
                cw.write_if(c.args[0])
            elif c.op == "function":
                cw.write_function(c.args[0], int(c.args[1]))
            elif c.op == "call":
                cw.write_call(c.args[0], int(c.args[1]))
            elif c.op == "return":
                cw.write_return()
    
    with open(out_asm_path, "w", encoding="utf-8") as f:
        f.write("\n".join(cw.lines) + "\n")

def collect_vm_files(path: str) -> tuple[list[str], str, bool]:
    if os.path.isfile(path) and path.lower().endswith(".vm"):
        return [path], os.path.splitext(path)[0] + ".asm", False
    if os.path.isdir(path):
        vm_files = [os.path.join(path, n) for n in sorted(os.listdir(path)) if n.lower().endswith(".vm")]
        if not vm_files:
            raise FileNotFoundError("No .vm files in folder")
        folder = os.path.abspath(path)
        return vm_files, os.path.join(folder, os.path.basename(folder) + ".asm"), True
    raise FileNotFoundError("Input must be a .vm file or a folder")

def main():
    if len(sys.argv) != 2:
        print("Usage: python VMTranslator.py Xxx.vm | Folder")
        sys.exit(1)
    vm_files, out_asm, need_bootstrap = collect_vm_files(sys.argv[1])
    translate(vm_files, out_asm, bootstrap=need_bootstrap)
    print(f"Wrote: {out_asm} ({len(open(out_asm).readlines())} lines)")

if __name__ == "__main__":
    main()