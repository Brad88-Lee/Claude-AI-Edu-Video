# 第三輪實測報告（第 1 輪）

## 階段 A
- Node v22.22.0、npm 10.9.4；`@internxt/cli` 1.6.10 可安裝（24 秒，398 套件），`--version`／`--help` 正常。
- internxt.com、drive／gateway／api.internxt.com、drive.internxt.com/api：全部 `HTTP/1.1 403 Forbidden`，`CONNECT tunnel failed, response 403`（代理拒絕；輸出無 `host_not_allowed` 字樣，也無 x-deny-reason 標頭）。
- uploads.github.com／api.github.com：隧道成功，回 400；storage.googleapis.com：回 400；s3.amazonaws.com：回 405（皆可連線）。

## 階段 B（4K 長算繪）
- 未完成。18:14:58 UTC 啟動，約 60 分鐘（19:14 UTC）被背景指令逾時上限（3600000 ms）停止，狀態 killed。
- 停止時算繪進行到 Animation 593；`long_results.jsonl` 為空、無最終影片。未重跑、未改腳本。
- 心跳 180 行，大於 60 秒的空檔：無（VM 未見閒置暫停）。
- 記憶體峰值約 4168 MB；磁碟使用量由 10869464 增至約 10920572（心跳單位推測為 KB，約 +50 MB）。
- 因無影片，無長度與檔案大小。

## 階段 C（1080p，12 張圖）
| 做法 | 耗時 | 峰值記憶體 | 影片長度 | 檔案大小 |
|---|---|---|---|---|
| ST1 Images12（逐張 Manim） | 381.6 s | 1062 MB | 60 s | 8.52 MB |
| ST5 ImagesStatic（PNG） | 168.5 s | 715 MB | 60 s | 3.85 MB |
| ST6 ImagesStaticJpg | 189.9 s | 840 MB | 60 s | 3.73 MB |
| ffmpeg 直接合成 | 27.2 s | 604 MB | 48 s | 2.64 MB |
全部 rc=0。ffmpeg 影片長度 48 s，與其餘 60 s 不同，比較時需留意。

## 失敗或異常
- 階段 B 被 60 分鐘上限停止（結果本身）。
- Internxt 網域被代理 403 阻擋。
