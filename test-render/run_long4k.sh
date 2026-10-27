#!/bin/bash
# 第 3、2 點：4K 約 33 分鐘公式影片單次算繪。每 20 秒寫心跳。預期耗時 40～60 分鐘，用來測單次背景指令上限與 VM 閒置暫停。
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV=/opt/manim-venv; OUT="$ROOT/results/round"; mkdir -p "$OUT"
JSONL="$OUT/long_results.jsonl"; HB="$OUT/long_heartbeat.log"; : > "$JSONL"; : > "$HB"
( while true; do echo "$(date +%s) $(df --output=used / | tail -1 | tr -d ' ') $(free -m | awk '/Mem/{print $3}')" >> "$HB"; sleep 20; done ) &
HB_PID=$!; trap 'kill $HB_PID 2>/dev/null' EXIT
if "$VENV/bin/manim" render --help 2>&1 | grep -q -- '--frame_rate'; then FPS_FLAG="--frame_rate"; else FPS_FLAG="--fps"; fi
date -u > "$OUT/long_start.txt"
"$VENV/bin/python" "$ROOT/measure.py" render_4k_ST4_Long33min "$JSONL" -- \
  "$VENV/bin/manim" render -v WARNING -r 3840,2160 "$FPS_FLAG" 30 --media_dir "$ROOT/media/long4k" "$ROOT/scenes_stress.py" ST4_Long33min \
  > "$OUT/long_render.log" 2>&1
echo "rc=$?" >> "$OUT/long_start.txt"; date -u >> "$OUT/long_start.txt"
V=$(find "$ROOT/media/long4k" -name ST4_Long33min.mp4 -not -path '*/partial_movie_files/*' | head -1)
[ -n "$V" ] && ffprobe -v error -show_entries format=duration,size -of default=nw=1 "$V" >> "$OUT/long_start.txt"
cat "$JSONL" "$OUT/long_start.txt"
