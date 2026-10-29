# 旁白長度驅動畫面長度測試（無人值守）

目的：100 段（偶數段 Manim 公式、奇數段 FFmpeg 圖片，1080p/30fps），每段畫面長度 = 旁白長度 + 前後各 0.5 秒。量化 A/V 對齊誤差與耗時。請節省額度：不要呼叫連接器、不要輪詢、不要改腳本；全程繁體中文簡短回報。

1. 若目前資料夾不是這個 repo：`git clone https://github.com/Brad88-Lee/Claude-AI-Edu-Video` 並進入；確認 `/opt/manim-venv` 存在，否則回報後停止。
2. 用 Bash 工具**背景模式**執行（逾時 `3600000` 毫秒）：`bash test-render/run_narration.sh`。預估 20～40 分鐘。啟動後不要做任何事，等完成通知。
3. 完成後讀取 `test-render/results/narr/narr_summary.md`、`narr_results.jsonl`、`narr_notes.txt`、`measured.csv`。
4. 寫 `report.md`（繁體中文）：各階段耗時與記憶體；Manim 公式段實際影格數與計畫的差（有幾段不一致、最大差幾格）；三種音訊方法的 A/V 總長差與旁白起點偏移；失敗段與錯誤摘要。
5. 只用 `bash test-render/push_progress.sh progress/narr-result <narr_summary.md narr_results.jsonl narr_notes.txt measured.csv report.md>` 推送。**不要執行其他 git push**，不要提交 media、mp4、assets。
