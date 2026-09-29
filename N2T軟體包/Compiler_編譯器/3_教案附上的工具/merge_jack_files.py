import os
import sys

def merge_jack_files(target_folder):
    """
    將目標資料夾中所有 .jack 檔案的內容合併到一個文字檔中
    輸出檔案會放在目標資料夾內,名稱為 jacktemp.txt
    
    參數:
        target_folder: 目標資料夾路徑
    """
    # 檢查目標資料夾是否存在
    if not os.path.exists(target_folder):
        print(f"錯誤: 資料夾 '{target_folder}' 不存在")
        return
    
    if not os.path.isdir(target_folder):
        print(f"錯誤: '{target_folder}' 不是一個資料夾")
        return
    
    # 將輸出檔案放在目標資料夾內
    output_file = os.path.join(target_folder, 'jacktemp.txt')
    
    # 尋找所有 .jack 檔案
    jack_files = []
    for file in os.listdir(target_folder):
        if file.endswith('.jack'):
            jack_files.append(os.path.join(target_folder, file))
    
    # 如果沒有找到 .jack 檔案
    if not jack_files:
        print(f"在 '{target_folder}' 中沒有找到任何 .jack 檔案")
        return
    
    # 排序檔案名稱以確保一致的順序
    jack_files.sort()
    
    # 合併所有檔案內容
    try:
        with open(output_file, 'w', encoding='utf-8') as outfile:
            for i, jack_file in enumerate(jack_files):
                print(f"正在處理: {os.path.basename(jack_file)}")
                
                # 寫入檔案分隔標記
                if i > 0:
                    outfile.write('\n\n')
                outfile.write(f"// ========== {os.path.basename(jack_file)} ==========\n")
                
                # 讀取並寫入檔案內容
                try:
                    with open(jack_file, 'r', encoding='utf-8') as infile:
                        content = infile.read()
                        outfile.write(content)
                except Exception as e:
                    print(f"警告: 無法讀取 {jack_file}: {e}")
                    continue
        
        print(f"\n成功! 已將 {len(jack_files)} 個 .jack 檔案合併到 '{output_file}'")
        
    except Exception as e:
        print(f"錯誤: 無法寫入輸出檔案: {e}")


if __name__ == "__main__":
    # 如果從命令列執行,可以接受資料夾路徑作為參數
    if len(sys.argv) > 1:
        target_folder = sys.argv[1]
    else:
        # 否則提示使用者輸入
        target_folder = input("請輸入目標資料夾路徑: ").strip()
    
    merge_jack_files(target_folder)
