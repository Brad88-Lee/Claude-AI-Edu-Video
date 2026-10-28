# 第 4 輪：4K 公式影片分段算繪再串接（無人值守）

目的：同樣 100 段推導（約 33 分鐘影片）、4K，分 5 個獨立 manim 指令（每個 20 段）逐段算繪，最後用 ffmpeg 串接。看每段耗時是否穩定、總耗時、串接是否正常。
請節省額度，不要呼叫任何連接器，不要輪詢，全程繁體中文簡短回報。

1. 若目前資料夾不是這個 repo：`git clone https://github.com/Brad88-Lee/Claude-AI-Edu-Video` 並進入；確認 `/opt/manim-venv` 存在，否則回報後停止。`date -u` 記下開始時間。
2. 用 Bash 工具**背景模式**執行（逾時 `7200000` 毫秒）：`TAG=chunked bash test-render/run_chunked4k.sh`
   腳本每個分段結束後會自動把進度推到 `progress/chunked`。
3. 啟動後什麼都不要做、不要輪詢，只等完成通知。
4. 若被中止或 session 被中斷，記錄停止時的經過時間，**不要重跑、不要改腳本**。
5. 完成後讀取 `test-render/results/chunked/` 內的 `chunk_results.jsonl`、`start.txt`、`chunk_heartbeat.log`，彙整成 `report.md`（每段耗時與記憶體、串接耗時、最終影片長度與檔案大小、心跳空檔、磁碟增加量）。
6. 只用 `bash test-render/push_progress.sh test/round-4 <上述檔案與 report.md>` 推送，**不要推送到 main**，不要提交 `media/`、`.mp4`。
