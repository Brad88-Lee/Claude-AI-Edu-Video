# 壓力測試摘要

## 各步驟量測

| 步驟 | rc | 耗時(s) | 峰值記憶體(MB) |
|---|---|---|---|
| render_4k_S1_Formula | 0 | 47.6 | 2207 |
| render_4k_S2_ImageAndCJKTex | 0 | 64.3 | 2093 |
| render_4k_S3_Graph | 0 | 26.8 | 2145 |
| render_1080p_ST1_Images12 | 0 | 209.0 | 1206 |
| render_4k_ST1_Images12 | 0 | 654.7 | 2466 |
| render_1080p_ST3_Long10min | 0 | 239.1 | 804 |

## 失敗項目

- 無

## 4K 對 1080p 的放大倍率（耗時比，越大越慢）

- S1_Formula：1080p 14.3s → 4K 47.6s，約 3.3 倍；記憶體 733 → 2207 MB
- S2_ImageAndCJKTex：1080p 17.8s → 4K 64.3s，約 3.6 倍；記憶體 848 → 2093 MB
- S3_Graph：1080p 9.9s → 4K 26.8s，約 2.7 倍；記憶體 685 → 2145 MB
- ST1_Images12：1080p 209.0s → 4K 654.7s，約 3.1 倍；記憶體 1206 → 2466 MB

## 影片長度與即時倍率（算繪耗時 ÷ 影片長度）

- render_1080p_ST1_Images12：影片 60s，檔案 8.5 MB，算繪 209.0s，約 3.48 倍即時；外推 30 分鐘約 1.7 小時（粗估）
- render_4k_ST1_Images12：影片 60s，檔案 19.1 MB，算繪 654.7s，約 10.91 倍即時；外推 30 分鐘約 5.5 小時（粗估）
- render_1080p_ST3_Long10min：影片 600s，檔案 9.9 MB，算繪 239.1s，約 0.40 倍即時；外推 30 分鐘約 0.2 小時（粗估）

## 長算繪與心跳（是否被中斷）

- 心跳共 64 筆，涵蓋 20.9 分鐘
- 沒有超過 60 秒的空檔，執行期間 VM 沒有被暫停
- 10 分鐘長算繪：rc=0，耗時 239.1s

## 磁碟紀錄

```
--- after render_4k_S1_Formula (16:47:57) ---
3.6M	/home/user/Claude-AI-Edu-Video/test-render/media/stress/4k_basic
/dev/vda        252G   11G   29G  27% /
--- after render_4k_S2_ImageAndCJKTex (16:49:01) ---
6.9M	/home/user/Claude-AI-Edu-Video/test-render/media/stress/4k_basic
/dev/vda        252G   11G   29G  27% /
--- after render_4k_S3_Graph (16:49:28) ---
8.0M	/home/user/Claude-AI-Edu-Video/test-render/media/stress/4k_basic
/dev/vda        252G   11G   29G  27% /
--- after render_1080p_ST1_Images12 (16:52:57) ---
17M	/home/user/Claude-AI-Edu-Video/test-render/media/stress/img1080
/dev/vda        252G   11G   29G  27% /
--- after render_4k_ST1_Images12 (17:03:52) ---
37M	/home/user/Claude-AI-Edu-Video/test-render/media/stress/img4k
/dev/vda        252G   11G   29G  27% /
--- after render_1080p_ST3_Long10min (17:07:52) ---
16M	/home/user/Claude-AI-Edu-Video/test-render/media/stress/long1080
/dev/vda        252G   11G   29G  27% /
```

> 注意：外推只是粗估；ST3 是重複的公式推導，ST1 是圖片淡入與縮放，實際影片的物件數量與特效不同，速度會有差異。
