常用的指令: 

git init
:初始化GIT。

git pull     
:把REPO上的東西拉下來。

git checkout .
把所有被刪掉的檔案從最後一次 commit 還原回來。

git add .     
:掃描整個資料夾。

git status
確認add的掃瞄解果。

git commit -m "你想要的訊息"
:把掃描到的東西包裝好，可以附上訊息。

git push
:推到Github上。

================================================

cd (你專案的路徑)
D: 
vivado -mode gui -source Nand2Tetris_FPGA.tcl

================================================

如何產生TCL 檔案:
1. File -> Project -> Write TCL
2. 確保Output file的路徑是到「你第一時間下載Git專案的那個資料夾」
，不要在「Nand2Tetris_FPGA」這個資料夾內(會被Git忽略掉)。

3.取消勾選【Copy sources to new project】。

4.如果他問你要不要覆蓋舊的TCL，覆蓋過去。

現在你準備好上傳了，參考Git指令。

然後注意，因為Nand2Tetris_FPGA這個資料夾會被忽略。

在Project中要新增檔案時，記得指定路徑到"Nand2Tetris_FPGA.srcs/sources_1/imports/rtl"這個資料夾才對。

新增到預設路徑"不會"被包入TCL中，離不開你的電腦。

===============================================
