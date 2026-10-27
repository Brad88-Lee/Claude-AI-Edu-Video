#!/bin/bash
# 壓力測試：A) 4K 版 S1/S2/S3  B) 12 張大圖場景（1080p 與 4K）  C) 10 分鐘長算繪（1080p）
# 用法：bash test-render/run_stress.sh        （全部）
#       SKIP_LONG=1 bash test-render/run_stress.sh   （跳過 10 分鐘長算繪）
# 輸出：test-render/results/stress/（results.jsonl、heartbeat.log、disk.txt、summary_stress.md、frames/）
# 預期總時間：視 4K 速度而定，可能 20~40 分鐘。請在背景執行。

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV=/opt/manim-venv
PY="$VENV/bin/python"
MANIM="$VENV/bin/manim"
OUT="$ROOT/results/stress"
LOGS="$OUT/logs"
JSONL="$OUT/results.jsonl"
HB="$OUT/heartbeat.log"
DISK="$OUT/disk.txt"
BASE_JSONL="$ROOT/results/results.jsonl"

mkdir -p "$LOGS" "$OUT/frames"
: > "$JSONL"; : > "$HB"; : > "$DISK"

if [ ! -x "$PY" ] || [ ! -x "$MANIM" ]; then
  echo "ERROR: $VENV 不存在，setup script 可能沒有執行或失敗"
  exit 2
fi

# 心跳：每 20 秒寫一次時間戳。若 VM 在執行期間被暫停或程序被殺，心跳會出現空檔或中斷
( while true; do date +%s >> "$HB"; sleep 20; done ) &
HB_PID=$!
trap 'kill $HB_PID 2>/dev/null' EXIT

{
  echo "=== start ==="; date
  echo "=== versions ==="; "$PY" --version; "$VENV/bin/pip" show manim pillow numpy | grep -E '^(Name|Version)'
  echo "=== nproc / memory ==="; nproc; free -m
  echo "=== disk ==="; df -h /
} > "$OUT/env_stress.txt" 2>&1

"$PY" "$ROOT/make_stress_assets.py" || { echo "ERROR: make_stress_assets.py failed"; exit 3; }

if "$MANIM" render --help 2>&1 | grep -q -- '--frame_rate'; then FPS_FLAG="--frame_rate"; else FPS_FLAG="--fps"; fi

# render_one LABEL WIDTH HEIGHT FPS PYFILE SCENE MEDIA_SUBDIR
render_one() {
  local label="$1" w="$2" h="$3" fps="$4" pyfile="$5" scene="$6" sub="$7"
  echo ">>> $label"
  "$PY" "$ROOT/measure.py" "$label" "$JSONL" -- \
    "$MANIM" render -v WARNING -r "$w,$h" "$FPS_FLAG" "$fps" \
    --media_dir "$ROOT/media/$sub" "$ROOT/$pyfile" "$scene" \
    > "$LOGS/${label}.log" 2>&1
  if [ $? -ne 0 ]; then
    echo "!!! $label failed, last lines:"
    tail -15 "$LOGS/${label}.log"
  fi
  {
    echo "--- after $label ($(date +%H:%M:%S)) ---"
    du -sh "$ROOT/media/$sub" 2>/dev/null
    df -h / | tail -1
  } >> "$DISK"
}

# ---------- A) 4K 版 S1/S2/S3（與主測試的 1080p 結果比較放大倍率）----------
for sc in S1_Formula S2_ImageAndCJKTex S3_Graph; do
  render_one "render_4k_${sc}" 3840 2160 30 scenes.py "$sc" stress/4k_basic
done

# ---------- B) 12 張大圖場景 ----------
render_one "render_1080p_ST1_Images12" 1920 1080 30 scenes_stress.py ST1_Images12 stress/img1080
render_one "render_4k_ST1_Images12"    3840 2160 30 scenes_stress.py ST1_Images12 stress/img4k

# 抽一張 4K 影格縮成 1920 寬，確認圖片與透明背景顯示正常
f4k=$(find "$ROOT/media/stress/img4k" -name "ST1_Images12.mp4" -not -path "*/partial_movie_files/*" | head -1)
if [ -n "$f4k" ]; then
  ffmpeg -y -hide_banner -loglevel error -ss 7 -i "$f4k" -frames:v 1 \
    -vf scale=1920:-1 -q:v 4 "$OUT/frames/ST1_Images12_4k_t7s.jpg"
fi

# ---------- C) 10 分鐘長算繪（1080p）----------
if [ "${SKIP_LONG:-0}" != "1" ]; then
  render_one "render_1080p_ST3_Long10min" 1920 1080 30 scenes_stress.py ST3_Long10min stress/long1080
else
  echo "SKIP_LONG=1, skip long render"
fi

date +%s >> "$HB"
"$PY" "$ROOT/summarize_stress.py" "$OUT" "$BASE_JSONL" "$ROOT/media/stress"
echo "DONE. summary -> $OUT/summary_stress.md"
