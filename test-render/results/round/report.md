# 第 2 輪實測報告（round-2）

## 階段 A
- Node v22.22.0、npm 10.9.4；`@internxt/cli` 1.6.10 可安裝並執行（暫存 prefix）。
- internxt.com、drive/gateway/api.internxt.com、drive.internxt.com/api：全部 CONNECT tunnel 403 Forbidden（代理拒絕，未見 `host_not_allowed` 字樣）。
- uploads.github.com、api.github.com、storage.googleapis.com、s3.amazonaws.com：隧道可建立（回 400/400/400/405，屬無參數請求的正常回應）。

## 階段 B
- 未完成：2026-10-28 00:21:44 UTC 啟動，約 60 分鐘後（01:21 UTC）因達背景指令逾時上限（3600000 ms）被系統中止（killed）。未重跑、未改腳本。
- 中止時算繪停在 Animation 720，`long_results.jsonl` 為空、無影片產出。
- 心跳：180 行，大於 60 秒的空檔：無（VM 全程未閒置暫停）。
- 峰值：記憶體 4192 MB；磁碟使用 10,931,968 KB（起始 10,869,568 KB）。

## 階段 C（1080p，12 張圖）
| 做法 | 耗時 | 峰值 RSS | 影片長度 | 檔案大小 |
|---|---|---|---|---|
| ST1_Images12 | 268.4 s | 1058 MB | 60 s | 8.52 MB |
| ST5_ImagesStatic | 117.4 s | 725 MB | 60 s | 3.85 MB |
| ST6_ImagesStaticJpg | 145.5 s | 843 MB | 60 s | 3.73 MB |
| ffmpeg | 22.3 s | 604 MB | 48 s | 2.64 MB |

## 失敗或異常
- 階段 B 被 60 分鐘逾時中止（見上）。其餘皆 rc=0。
