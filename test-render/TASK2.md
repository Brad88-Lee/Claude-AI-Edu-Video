# 第二輪實測任務（驗證 setup + 壓力測試）

目的：
1. 驗證修改後的 setup script（固定 Pillow 12.3.0）在全新環境能通過，且仍在約 5 分鐘快取預算內。
2. 在乾淨環境完整重跑主測試，確認 S1、S2、S3 全部成功。
3. 壓力測試：4K 放大倍率、12 張大圖場景、10 分鐘長算繪（含 VM 是否被暫停的心跳偵測）。

這是測試，**請節省額度**：等待期間不要頻繁輪詢，不要主動重構、不要加功能。

## 階段 1：驗證 setup 與主測試

1. 讀取 `/opt/edu-video-setup.log` 與 `/opt/edu-video-setup.done`，完整貼進回報。
   - 若不存在，表示環境沒有套用 setup script，直接回報並**停止**，不要自己安裝任何東西。
   - 確認 log 裡 pillow 版本是 12.3.0，且沒有 `WARN pillow version`。
2. 執行 `grep -E "Building|Successfully installed|Collecting (manim|pycairo|manimpango|pillow)" /opt/setup-manim_pip.out`，貼出結果，這是用來看 pip 的耗時分布（每行前面有 `[+N s]` 時間戳）。
3. 在背景執行主測試（先 `mkdir -p test-render/results`）：
   `bash test-render/run_test.sh > test-render/results/run.log 2>&1`
   等完成通知，不要輪詢。
4. 讀取 `test-render/results/summary.md`。
   - 若 S1、S2、S3 任何一個失敗：只讀對應 `test-render/results/logs/*.log` 最後 30 行，回報後**停止**，不要進入階段 2。
   - 全部成功才進入階段 2。

## 階段 2：壓力測試（只有階段 1 全部成功才執行）

1. 在背景執行，並且**之後不要主動做任何事**，等待完成通知，這樣才能測到 VM 閒置時背景程序會不會被中斷：
   `mkdir -p test-render/results/stress && bash test-render/run_stress.sh > test-render/results/stress/run.log 2>&1`
   預期 20~40 分鐘。
2. 完成後讀取 `test-render/results/stress/summary_stress.md`。
3. 若通知沒有出現、或 session 顯示 VM 已被回收：不要重跑，回報「被中斷」並檢查 `test-render/results/stress/heartbeat.log` 的最後幾行與 `results.jsonl`，這是重要結果。

## 失敗處理

- 不要為了通過測試而修改腳本。只有明確的筆誤或單一缺漏套件才可以修，**最多修一次**並說明。
- 修不好就停止並回報錯誤，不要連續嘗試。

## 提交

建立並推送新分支 `test/render-benchmark-2`，只提交以下檔案：
- `test-render/results/summary.md`、`env.txt`、`results.jsonl`
- `test-render/results/stress/summary_stress.md`、`results.jsonl`、`heartbeat.log`、`disk.txt`、`env_stress.txt`
- `test-render/results/stress/frames/*.jpg`（若有）
- 階段 1 的 setup log：存成 `test-render/results/setup_log.txt`

**不要提交** `media/`、任何 `.mp4`、`logs/`、`assets/`。

## 回報格式（繁體中文，精簡）

1. setup：總耗時、與上一輪 251s 的差異、pillow 版本、pip 耗時分布重點（哪個套件最久）
2. 主測試：S1、S2、S3 的 480p／1080p 是否全過、耗時
3. 4K 放大倍率（S1、S2、S3、ST1）與記憶體峰值
4. 12 張大圖場景：1080p 與 4K 的耗時、即時倍率
5. 10 分鐘長算繪：是否完成、耗時、心跳有沒有空檔（VM 是否被暫停）
6. 磁碟使用量變化
7. 失敗項目與錯誤摘要
8. 外推 30 分鐘 1080p 與 4K 的算繪時間（引用 summary_stress.md，註明是粗估）
