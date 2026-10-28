# 單次背景指令上限測試（無人值守）

目的：測「單次背景指令最長能撐多久」。排程 prompt 會指定 MIN（分鐘）與 BRANCH。請節省額度，不要呼叫任何連接器，不要輪詢，全程繁體中文簡短回報。

1. 若目前資料夾不是這個 repo：`git clone https://github.com/Brad88-Lee/Claude-AI-Edu-Video` 並進入；`date -u` 記下開始時間。
2. 用 Bash 工具**背景模式**執行 `bash test-render/run_duration.sh MIN BRANCH`（把 MIN、BRANCH 換成排程 prompt 的值）。
   逾時設定：MIN 為 60、80、100 時，設為 (MIN+10)*60000 毫秒；MIN 為 118 時設為 7200000（上限）。
3. 啟動後什麼都不要做、不要輪詢，只等完成通知。
4. 若被系統中止或 session 被中斷，這就是結果本身：記錄停止時的經過時間與訊息，**不要重跑、不要改腳本**。
5. 完成後讀取 `test-render/results/dur_MIN/` 內的 `start_MIN.txt`、`end_MIN.txt`、`hb_MIN.log`，並用 `awk 'NR>1 && $1-p>60 {print "gap",$1-p,"s at",p} {p=$1}' test-render/results/dur_MIN/hb_MIN.log` 計算大於 60 秒的心跳空檔。
6. 只用 `bash test-render/push_progress.sh BRANCH <上述三個檔案>` 推送結果（腳本已定期推送進度，這是最後一次）。**不要推送到 main**，不要提交其他檔案。
7. 回報：預定 MIN、實際經過、job_rc、是否被中止、心跳空檔、記憶體。
