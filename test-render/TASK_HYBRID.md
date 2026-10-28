# 混合管線測試（無人值守）

目的：驗證「Manim 公式段 + FFmpeg 圖片段」能否無縫串接、加音軌、疊透明公式，並量各步驟耗時（4K）。
請節省額度：不要呼叫連接器、不要輪詢、不要改腳本；全程繁體中文簡短回報。

1. 若目前資料夾不是這個 repo：`git clone https://github.com/Brad88-Lee/Claude-AI-Edu-Video` 並進入；確認 `/opt/manim-venv` 存在，否則回報後停止。
2. 用 Bash 工具**背景模式**執行（逾時 `3600000` 毫秒）：`bash test-render/run_hybrid.sh`。預估 15～30 分鐘。啟動後不要做任何事，等完成通知。
3. 完成後讀取 `test-render/results/hybrid/` 的 `hybrid_results.jsonl`、`hybrid_notes.txt`、`videos.txt`，並檢視 `frames/*.jpg`（接點前後與疊圖影格）確認畫面正常、沒有黑畫面或格式錯誤。
4. 寫 `report.md`（繁體中文）：各步驟耗時與記憶體；串接是否成功（`-c copy` 是否 rc=0、成品長度是否等於各段相加）；接點前後影格是否正常；疊圖是否有透明背景；加音軌是否成功；任何失敗與錯誤摘要。
5. 只用 `bash test-render/push_progress.sh progress/hybrid-result <hybrid_results.jsonl hybrid_notes.txt videos.txt report.md 以及 frames 內所有 jpg>` 推送。**不要執行其他 git push**，不要提交 media、mp4、assets。
