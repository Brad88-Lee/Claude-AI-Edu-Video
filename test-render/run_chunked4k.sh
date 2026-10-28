#!/bin/bash
# 第 4 輪：同樣 100 段 4K 公式影片，分 5 個獨立 manim 指令（每次 20 段），逐段計時，最後用 ffmpeg 串接（不重新編碼）。
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV=/opt/manim-venv; OUT="$ROOT/results/chunked"; mkdir -p "$OUT"
JSONL="$OUT/chunk_results.jsonl"; HB="$OUT/chunk_heartbeat.log"; : > "$JSONL"; : > "$HB"
( n=0; while true; do echo "$(date +%s) $(df --output=used / | tail -1 | tr -d ' ') $(free -m | awk '/Mem/{print $3}')" >> "$HB"; n=$((n+1)); \
  if [ -n "$TAG" ] && [ $((n % 30)) -eq 0 ]; then bash "$ROOT/push_progress.sh" "progress/$TAG" "$HB" "$JSONL"; fi; sleep 20; done ) &
HB_PID=$!; trap 'kill $HB_PID 2>/dev/null' EXIT
if "$VENV/bin/manim" render --help 2>&1 | grep -q -- '--frame_rate'; then FPS_FLAG="--frame_rate"; else FPS_FLAG="--fps"; fi
date -u +%FT%TZ > "$OUT/start.txt"; : > "$OUT/list.txt"
for k in 0 1 2 3 4; do
  SEG_START=$((k*20)) SEG_COUNT=20 "$VENV/bin/python" "$ROOT/measure.py" "chunk_4k_$k" "$JSONL" -- \
    "$VENV/bin/manim" render -v WARNING -r 3840,2160 "$FPS_FLAG" 30 -o "chunk_$k.mp4" --media_dir "$ROOT/media/chunk$k" "$ROOT/scenes_stress.py" ST7_Chunk \
    > "$OUT/chunk_$k.log" 2>&1
  V=$(find "$ROOT/media/chunk$k" -name "chunk_$k.mp4" -not -path '*/partial_movie_files/*' | head -1)
  [ -n "$V" ] && echo "file '$V'" >> "$OUT/list.txt"
  bash "$ROOT/push_progress.sh" "progress/${TAG:-chunked}" "$HB" "$JSONL"
done
S=$(date +%s)
ffmpeg -y -hide_banner -loglevel error -f concat -safe 0 -i "$OUT/list.txt" -c copy "$ROOT/media/final_4k.mp4" 2> "$OUT/concat.log"
echo "concat_rc=$? concat_s=$(( $(date +%s) - S ))" >> "$OUT/start.txt"; date -u +%FT%TZ >> "$OUT/start.txt"
ffprobe -v error -show_entries format=duration,size -of default=nw=1 "$ROOT/media/final_4k.mp4" >> "$OUT/start.txt" 2>&1
cat "$JSONL" "$OUT/start.txt"
awk 'NR>1 && $1-p>60 {print "gap", $1-p, "s at", p} {p=$1}' "$HB"
