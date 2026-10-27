#!/usr/bin/env python3
"""
用法：summarize.py RESULTS_JSONL MEDIA_DIR OUT_MD
讀取 measure.py 的紀錄與成品影片，輸出 Markdown 摘要與粗略外推。
外推只是粗估：場景複雜度、素材量都會讓實際值不同。
"""
import glob
import json
import os
import subprocess
import sys


def probe(path):
    try:
        out = subprocess.check_output(
            ["ffprobe", "-v", "error", "-show_entries", "format=duration,size",
             "-of", "json", path],
            text=True,
        )
        fmt = json.loads(out)["format"]
        return float(fmt["duration"]), int(fmt["size"])
    except Exception:
        return None, None


def main():
    jsonl, media, out_md = sys.argv[1:4]
    rows = []
    if os.path.exists(jsonl):
        with open(jsonl, encoding="utf-8") as f:
            rows = [json.loads(line) for line in f if line.strip()]

    lines = ["# 實測摘要", "", "## 各步驟量測", "",
             "| 步驟 | rc | 耗時(s) | 峰值記憶體(MB) | CPU user(s) |",
             "|---|---|---|---|---|"]
    for r in rows:
        lines.append(f"| {r['label']} | {r['rc']} | {r['elapsed_s']} | "
                     f"{r['peak_rss_mb']:.0f} | {r['cpu_user_s']} |")

    failed = [r["label"] for r in rows if r["rc"] != 0]
    lines += ["", "## 失敗項目", ""]
    lines += [f"- {x}" for x in failed] if failed else ["- 無（全部步驟 rc=0）"]

    lines += ["", "## 成品與外推（粗估）", ""]
    lines += ["> 測試場景很簡單，外推只當下限參考；若有失敗場景，影片長度與耗時不完整。", ""]
    for res in ("480", "1080"):
        finals = glob.glob(os.path.join(media, res, f"final_{res}p.mp4"))
        render_s = sum(r["elapsed_s"] for r in rows
                       if r["label"].startswith(f"render_{res}p_") and r["rc"] == 0)
        n_ok = sum(1 for r in rows
                   if r["label"].startswith(f"render_{res}p_") and r["rc"] == 0)
        if not finals:
            lines.append(f"- {res}p：沒有成品（成功算繪 {n_ok} 個場景，耗時 {render_s:.0f}s）")
            continue
        dur, size = probe(finals[0])
        if not dur:
            lines.append(f"- {res}p：成品無法以 ffprobe 讀取")
            continue
        factor = render_s / dur
        lines.append(
            f"- {res}p：影片長度 {dur:.1f}s，檔案 {size/1e6:.1f} MB，"
            f"算繪合計 {render_s:.0f}s（約為影片長度的 {factor:.1f} 倍）"
        )
        lines.append(
            f"  - 外推 30 分鐘：算繪約 {factor*1800/3600:.1f} 小時，"
            f"成品約 {size/dur*1800/1e9:.2f} GB（單一最終檔，不含中間檔）"
        )

    with open(out_md, "w", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")
    print("\n".join(lines))


if __name__ == "__main__":
    main()
