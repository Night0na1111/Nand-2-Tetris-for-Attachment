# JackCompiler.py
# Project 11: Jack Compiler (Jack -> VM)
# 主程式：輸入可以是單一 .jack 或資料夾，輸出對應 .vm

import sys
import os
import JackTokenizer
import CompilationEngine


def compile_file(file_path: str):
    """
    編譯單一 .jack 檔案，輸出同名 .vm
    """
    with open(file_path, 'r', encoding='utf-8') as ifile:
        file_path_no_ext, _ = os.path.splitext(file_path)
        ofile_path = file_path_no_ext + '.vm'

        # Tokenizer 在此版本是「吃整個檔案字串」
        tokenizer = JackTokenizer.JackTokenizer(ifile.read())

        with open(ofile_path, 'w', encoding='utf-8') as ofile:
            engine = CompilationEngine.CompilationEngine(tokenizer, ofile)
            engine.compile_class()


def compile_dir(dir_path: str):
    """
    編譯資料夾底下所有 .jack（不遞迴）
    """
    for file in os.listdir(dir_path):
        file_path = os.path.join(dir_path, file)
        _, ext = os.path.splitext(file_path)
        if os.path.isfile(file_path) and ext.lower() == '.jack':
            compile_file(file_path)


def main():
    if len(sys.argv) != 2:
        print('usage: python JackCompiler.py (file|dir)')
        sys.exit(1)

    input_path = sys.argv[1]

    if os.path.isdir(input_path):
        compile_dir(input_path)
    elif os.path.isfile(input_path):
        compile_file(input_path)
    else:
        print("Invalid file/directory, compilation failed")
        sys.exit(1)


if __name__ == "__main__":
    main()