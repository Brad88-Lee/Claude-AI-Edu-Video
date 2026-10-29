#!/usr/bin/env python3
"""產生旁白計畫：100 段，偶數段為公式（Manim）、奇數段為圖片（FFmpeg）。
T = 每段畫面長度（秒）= 旁白長度 + 前後各 0.5 秒留白；旁白長度 3～25 秒（毫秒精度，模擬 TTS 不整齊的長度）。固定亂數種子，結果可重現。"""
import json, random, sys
rng = random.Random(20261029)
plan = []
for i in range(100):
    narr = round(rng.uniform(3.0, 25.0), 3)
    plan.append({"idx": i, "type": "formula" if i % 2 == 0 else "image", "narr": narr, "T": round(narr + 1.0, 3)})
json.dump(plan, open(sys.argv[1], "w"), ensure_ascii=False, indent=0)
print("segments", len(plan), "total_T", round(sum(p["T"] for p in plan), 1), "s")
