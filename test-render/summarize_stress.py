#!/usr/bin/env python3
"""
用法：summarize_stress.py STRESS_OUT_DIR BASELINE_JSONL STRESS_MEDIA_DIR
產生 STRESS_OUT_DIR/summary_stress.md：各步驟量測、4K 對 1080p 的放大倍率、
圖片場景外推、長算繪是否完成、心跳空檔（偵測 VM 暫停或程序中斷）。
外推只是粗估。
"""
import glob
import json
import os
import subprocess
import sys


def load(path):
    if not os.path.exists(path):
        return []
    with open(path, encoding="utf-8") as f:
        return [json.loads(x) for x in f if x.strip()]


def probe(path):
    try:
        out = subprocess.check_output(
            ["ffprobe", "-v", "error", "-show_entries", "format=duration,size",
             "-of", "json", path], text=True)
        fmt = json.loads(out)["format"]
        return float(fmt["duration"]), int(fmt["size"])
    except Exception:
        return None, None


def find_video(media, scene):
    hits = [p for p in glob.glob(os.path.join(media, "**", f"{scene}.mp4"), recursive=True)
            if "partial_movie_files" not in p]
    return hits[0] if hits else None


def main():
    out_dir, base_jsonl, media = sys.argv[1:4]
    rows = load(os.path.join(out_dir, "results.jsonl"))
    base = {r["label"]: r for r in load(base_jsonl)}
    cur = {r["label"]: r for r in rows}

    L = ["# 壓力測試摘要", "", "## 各步驟量測", "",
         "| 步驟 | rc | 耗時(s) | 峰值記憶體(MB) |", "|---|---|---|---|"]
    for r in rows:
        L.append(f"| {r['label']} | {r['rc']} | {r['elapsed_s']} | {r['peak_rss_mb']:.0f} |")

    failed = [r["label"] for r in rows if r["rc"] != 0]
    L += ["", "## 失敗項目", ""]
    L += [f"- {x}" for x in failed] if failed else ["- 無"]

    L += ["", "## 4K 對 1080p 的放大倍率（耗時比，越大越慢）", ""]
    for sc in ("S1_Formula", "S2_ImageAndCJKTex", "S3_Graph"):
        a, b = cur.get(f"render_4k_{sc}"), base.get(f"render_1080p_{sc}")
        if a and b and a["rc"] == 0 and b["rc"] == 0:
            L.append(f"- {sc}：1080p {b['elapsed_s']}s → 4K {a['elapsed_s']}s，約 {a['elapsed_s']/b['elapsed_s']:.1f} 倍；"
                     f"記憶體 {b['peak_rss_mb']:.0f} → {a['peak_rss_mb']:.0f} MB")
        else:
            L.append(f"- {sc}：缺少有效的 1080p 基準或 4K 結果，無法比較")
    a, b = cur.get("render_4k_ST1_Images12"), cur.get("render_1080p_ST1_Images12")
    if a and b and a["rc"] == 0 and b["rc"] == 0:
        L.append(f"- ST1_Images12：1080p {b['elapsed_s']}s → 4K {a['elapsed_s']}s，約 {a['elapsed_s']/b['elapsed_s']:.1f} 倍；"
                 f"記憶體 {b['peak_rss_mb']:.0f} → {a['peak_rss_mb']:.0f} MB")

    L += ["", "## 影片長度與即時倍率（算繪耗時 ÷ 影片長度）", ""]
    scenes = {"render_1080p_ST1_Images12": "ST1_Images12", "render_4k_ST1_Images12": "ST1_Images12",
              "render_1080p_ST3_Long10min": "ST3_Long10min"}
    for label, sc in scenes.items():
        r = cur.get(label)
        if not r:
            continue
        sub = {"render_1080p_ST1_Images12": "img1080", "render_4k_ST1_Images12": "img4k",
               "render_1080p_ST3_Long10min": "long1080"}[label]
        v = find_video(os.path.join(media, sub), sc)
        dur, size = probe(v) if v else (None, None)
        if r["rc"] != 0 or not dur:
            L.append(f"- {label}：沒有可用成品（rc={r['rc']}）")
            continue
        factor = r["elapsed_s"] / dur
        L.append(f"- {label}：影片 {dur:.0f}s，檔案 {size/1e6:.1f} MB，算繪 {r['elapsed_s']}s，"
                 f"約 {factor:.2f} 倍即時；外推 30 分鐘約 {factor*1800/3600:.1f} 小時（粗估）")

    L += ["", "## 長算繪與心跳（是否被中斷）", ""]
    hb_path = os.path.join(out_dir, "heartbeat.log")
    beats = []
    if os.path.exists(hb_path):
        with open(hb_path) as f:
            beats = [int(x) for x in f if x.strip().isdigit()]
    if len(beats) >= 2:
        gaps = [(beats[i], beats[i + 1] - beats[i]) for i in range(len(beats) - 1)
                if beats[i + 1] - beats[i] > 60]
        L.append(f"- 心跳共 {len(beats)} 筆，涵蓋 {(beats[-1]-beats[0])/60:.1f} 分鐘")
        if gaps:
            L.append(f"- 偵測到 {len(gaps)} 個超過 60 秒的空檔（可能是 VM 暫停）："
                     + "，".join(f"{g}s" for _, g in gaps))
        else:
            L.append("- 沒有超過 60 秒的空檔，執行期間 VM 沒有被暫停")
    else:
        L.append("- 沒有足夠的心跳紀錄")
    lr = cur.get("render_1080p_ST3_Long10min")
    if lr is None:
        L.append("- 10 分鐘長算繪沒有執行（可能設定了 SKIP_LONG=1，或腳本中途被中斷）")
    else:
        L.append(f"- 10 分鐘長算繪：rc={lr['rc']}，耗時 {lr['elapsed_s']}s")

    disk = os.path.join(out_dir, "disk.txt")
    if os.path.exists(disk):
        L += ["", "## 磁碟紀錄", "", "```", open(disk, encoding="utf-8").read().strip(), "```"]

    L += ["", "> 注意：外推只是粗估；ST3 是重複的公式推導，ST1 是圖片淡入與縮放，"
          "實際影片的物件數量與特效不同，速度會有差異。"]

    path = os.path.join(out_dir, "summary_stress.md")
    with open(path, "w", encoding="utf-8") as f:
        f.write("\n".join(L) + "\n")
    print("\n".join(L))


if __name__ == "__main__":
    main()
