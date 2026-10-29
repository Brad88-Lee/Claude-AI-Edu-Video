#!/usr/bin/env python3
"""分析 A/V 對齊：用 silencedetect 找最終成品音軌中每段「旁白起點」，與影片時間軸上預期的起點（累積實際畫面長度 + 0.5 秒）比較。"""
import json, re, subprocess, sys, os
out, W = sys.argv[1], sys.argv[2]
plan = json.load(open(f"{out}/plan.json"))
meas = {}
for line in open(f"{out}/measured.csv"):
    p = line.strip().split(",")
    try: meas[int(p[0])] = (int(p[4]), float(p[3]))   # frames, duration（ffprobe 先輸出 duration 再輸出 nb_frames）
    except Exception: pass
def dur(path, stream=None):
    sel = ["-select_streams", stream] if stream else []
    try:
        return float(subprocess.check_output(["ffprobe","-v","error"]+sel+["-show_entries","stream=duration" if stream else "format=duration","-of","csv=p=0",path], text=True).split()[0])
    except Exception: return None
# 預期起點：依實際畫面長度累積
starts, t = [], 0.0
for p in plan:
    i = p["idx"]; vd = meas.get(i, (None, p["T"]))[1]
    starts.append(t + 0.5); t += vd
vid_total = dur(f"{W}/video_all.mp4")
lines = ["# 旁白驅動測試摘要（1080p，100 段）", ""]
frames_dev = [meas[i][0] - round(p["T"] * 30) for p in plan for i in [p["idx"]] if i in meas]
lines += [f"- 計畫總長 {sum(p['T'] for p in plan):.3f} 秒；串接後畫面實際總長 {vid_total} 秒",
          f"- 各段影格數與計畫（四捨五入）的差：最小 {min(frames_dev) if frames_dev else 'n/a'}、最大 {max(frames_dev) if frames_dev else 'n/a'}、不為 0 的段數 {sum(1 for d in frames_dev if d)}",
          ""]
for key, name in (("a", "方法 a：音訊用計畫長度 T，PCM 串接後一次編成 AAC"),
                  ("b", "方法 b：音訊補齊到實際畫面長度，PCM 串接後一次編成 AAC"),
                  ("c", "方法 c：同 b，但每段各自編成 AAC 再串接")):
    f = f"{W}/final_{key}.mp4"
    if not os.path.exists(f):
        lines += [f"## {name}", "- 成品不存在", ""]; continue
    v, a = dur(f, "v:0"), dur(f, "a:0")
    r = subprocess.run(["ffmpeg","-hide_banner","-nostats","-i",f,"-vn","-af","silencedetect=n=-45dB:d=0.3","-f","null","-"], capture_output=True, text=True)
    ends = [float(x) for x in re.findall(r"silence_end: ([0-9.]+)", r.stderr)]
    n = min(len(ends), len(starts))
    drift = [ends[i] - starts[i] for i in range(n)]
    lines += [f"## {name}",
              f"- 成品畫面 {v} 秒、音軌 {a} 秒，差 {None if v is None or a is None else round(a - v, 3)} 秒",
              f"- 偵測到旁白起點 {len(ends)} 個（預期 100；若為 101，多出的是檔尾靜音）",
              (f"- 起點偏移（偵測 − 預期，秒）：第 1 段 {drift[0]:+.3f}、第 50 段 {drift[min(49,n-1)]:+.3f}、最後一段 {drift[-1]:+.3f}；最大絕對值 {max(abs(d) for d in drift):.3f}" if n else "- 無法計算偏移"), ""]
lines += ["> 說明：起點偵測靠 silencedetect，精度約 ±0.02 秒；方法 a 的偏移反映『若直接用音訊長度當畫面長度、畫面因影格取整而不一致』造成的累積漂移。"]
open(f"{out}/narr_summary.md", "w", encoding="utf-8").write("\n".join(lines) + "\n")
print("\n".join(lines))
