# 雲端環境實測任務

目的：驗證 setup script 的安裝時間與結果、Manim 在雲端 VM 的算繪速度、磁碟與記憶體用量，以及中文與公式排版是否正常。
這是測試，**請節省額度**：不要反覆輪詢，不要主動重構，不要加功能。

## 步驟

1. 檢查 setup script 是否有執行：
   - 讀取 `/opt/edu-video-setup.log` 與 `/opt/edu-video-setup.done`，把內容完整貼進回報。
   - 若這兩個檔案不存在，表示這個環境沒有套用 setup script，直接回報並停止，不要自己安裝任何東西。
2. 執行實測腳本，**在背景執行**，不要在前景等待，完成後會有通知：
   `bash test-render/run_test.sh > test-render/results/run.log 2>&1`
   （執行前先 `mkdir -p test-render/results`）
   等待期間不要頻繁檢查，需要時最多每幾分鐘讀一次 `test-render/results/run.log` 的最後 20 行。
3. 完成後讀取 `test-render/results/summary.md` 與 `test-render/results/env.txt`。
4. 若有失敗：
   - 只讀對應的 `test-render/results/logs/*.log` 最後 30 行，回報錯誤原因與你的判斷。
   - 最多嘗試修正一次，且只限於明確的筆誤或單一缺漏套件，說明改了什麼。
   - 修不好就停止並回報，不要連續嘗試。
5. 只把 `test-render/results/summary.md`、`env.txt`、`results.jsonl` 提交到新分支 `test/render-benchmark`。
   **不要提交** `media/`、任何 `.mp4`、`results/logs/`。

## 回報格式（繁體中文，精簡）

- setup script：總耗時、各階段耗時、是否有 WARN、缺少哪些工具
- 各場景 480p 與 1080p 的算繪耗時、峰值記憶體
- 成品長度、檔案大小
- 磁碟使用量（media 目錄與 df）
- 中文字型與公式是否正常（有無錯誤訊息）
- 外推 30 分鐘 1080p 的算繪時間與成品大小（引用 summary.md，並註明是粗估）
- 失敗項目與錯誤摘要
