# 第三輪實測任務（無人值守，第 1 輪）

這是無人值守的排程任務，沒有人會回答問題，也不會核准任何動作。請依下列順序完成，**節省額度**：
等待長時間指令期間不要輪詢，不要主動重構、不要加功能、不要呼叫任何連接器（Supabase、Lovable、Claude_Docs 等一律不要用）。
全程用繁體中文簡短回報。

目的：
- 第 4 點：確認能否連到 Internxt 與其他儲存服務（只探測，不登入、不上傳）。
- 第 3+2 點：4K 約 33 分鐘公式影片單次背景算繪，測單次背景指令上限與 VM 閒置暫停。
- 第 1 點：12 張圖在 1080p 下四種做法的耗時比較。

## 階段 0：檢查環境

1. 若目前資料夾不是這個 repo，執行 `git clone https://github.com/Brad88-Lee/Claude-AI-Edu-Video` 並進入。
2. 讀取 `/opt/edu-video-setup.done`；若 `/opt/manim-venv` 不存在，回報後停止。
3. 記錄開始時間：`date -u`。

## 階段 A：第 4 點探測（約 5 分鐘）

執行 `bash test-render/probe_internxt.sh`（前景，最多 5 分鐘）。結果會寫入 `test-render/results/round/probe_internxt.txt`，不需要額外處理。

## 階段 B：第 3+2 點長算繪（預估 40～60 分鐘）

1. 用 Bash 工具的背景模式啟動，**逾時請設 `3600000` 毫秒（60 分鐘）**：
   `bash test-render/run_long4k.sh`
2. 啟動後**不要做任何事、不要輪詢**，只等完成通知。
3. 回報時務必寫下：
   - 指令是否正常完成、總耗時；
   - 若被系統中止（例如約 30 分鐘時被停止），寫下中止時的經過時間與訊息，**不要重跑，不要改腳本**；
   - 若 VM 被回收或 session 被中斷，這就是結果本身，照實記錄。
4. 心跳檔 `test-render/results/round/long_heartbeat.log`（每行：時間戳 磁碟使用 記憶體MB）會顯示是否有空檔；階段 B 結束後，用以下指令計算大於 60 秒的空檔並記錄：
   `awk 'NR>1 && $1-p>60 {print "gap", $1-p, "s at", p} {p=$1}' test-render/results/round/long_heartbeat.log`

## 階段 C：第 1 點圖片做法比較（約 10～15 分鐘）

階段 B 無論成功失敗，都接著執行（除非 VM 已被回收）：
`bash test-render/run_img_compare.sh`（背景模式，逾時 `1800000`）。
結果在 `test-render/results/round/img_results.jsonl` 與 `img_videos.txt`。

## 失敗處理

- 不要為了通過測試修改任何腳本。只有明確筆誤才可修，最多一次並說明。
- 修不好就記錄錯誤並繼續下一階段。

## 提交

建立並推送新分支 `test/round-1`，**只提交** `test-render/results/round/` 內的以下檔案：
`probe_internxt.txt`、`long_results.jsonl`、`long_heartbeat.log`、`long_start.txt`、`long_render.log` 的最後 50 行（存成 `long_render_tail.txt`）、
`img_results.jsonl`、`img_videos.txt`，以及你寫的 `report.md`（回報內容，格式見下）。
**不要提交** `media/`、`.mp4`、`assets/`，不要推送到 main。
若 push 失敗，把完整錯誤放在對話中並停止。

## report.md 格式（繁體中文，精簡）

1. 階段 A：Node 版本、`@internxt/cli` 是否能安裝、每個網址的回應（特別是是否為 `host_not_allowed`）
2. 階段 B：是否完成、總耗時、有無被中止及時間、心跳空檔、影片長度與檔案大小、記憶體與磁碟峰值
3. 階段 C：四種做法的耗時與檔案大小對照
4. 失敗或異常
