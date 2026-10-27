#!/bin/bash
# 實測腳本：先 480p 再 1080p，各算繪 3 個場景，再用 FFmpeg 合成並量測。
# 用法：bash test-render/run_test.sh
# 輸出：test-render/results/{env.txt,results.jsonl,summary.md,logs/}、test-render/media/（不要 commit）

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV=/opt/manim-venv
PY="$VENV/bin/python"
MANIM="$VENV/bin/manim"
RESULTS="$ROOT/results"
LOGS="$RESULTS/logs"
RES_JSONL="$RESULTS/results.jsonl"
SCENES=(S1_Formula S2_ImageAndCJKTex S3_Graph)

mkdir -p "$LOGS"
: > "$RES_JSONL"

if [ ! -x "$PY" ] || [ ! -x "$MANIM" ]; then
  echo "ERROR: $VENV 不存在，setup script 可能沒有執行或失敗。請先看 /opt/edu-video-setup.log"
  exit 2
fi

# ---------- 0. 環境紀錄 ----------
{
  echo "=== date ==="; date
  echo "=== uname ==="; uname -a
  echo "=== nproc / memory ==="; nproc; free -m
  echo "=== disk ==="; df -h /
  echo "=== setup log ==="; cat /opt/edu-video-setup.log 2>/dev/null || echo "(no setup log)"
  echo "=== setup done marker (seconds) ==="; cat /opt/edu-video-setup.done 2>/dev/null || echo "(none)"
  echo "=== versions ==="
  "$PY" --version; "$VENV/bin/pip" show manim | grep -E '^(Name|Version)'
  ffmpeg -version | head -1
  xelatex --version | head -1
  dvisvgm --version 2>&1 | head -1
  echo "=== manim checkhealth ==="
  "$MANIM" checkhealth 2>&1 | tail -40
} > "$RESULTS/env.txt" 2>&1
echo "env info -> $RESULTS/env.txt"

# ---------- 1. 測試素材 ----------
"$PY" "$ROOT/make_asset.py" || { echo "ERROR: make_asset.py failed"; exit 3; }

# ---------- 2. 偵測影格率參數名稱 ----------
if "$MANIM" render --help 2>&1 | grep -q -- '--frame_rate'; then
  FPS_FLAG="--frame_rate"
else
  FPS_FLAG="--fps"
fi
echo "using fps flag: $FPS_FLAG"

render_all() {
  local res="$1" w="$2" h="$3" fps="$4" sc
  local mdir="$ROOT/media/$res"
  for sc in "${SCENES[@]}"; do
    echo ">>> render ${res}p ${sc}"
    "$PY" "$ROOT/measure.py" "render_${res}p_${sc}" "$RES_JSONL" -- \
      "$MANIM" render -v WARNING -r "$w,$h" "$FPS_FLAG" "$fps" \
      --media_dir "$mdir" "$ROOT/scenes.py" "$sc" \
      > "$LOGS/render_${res}_${sc}.log" 2>&1
    if [ $? -ne 0 ]; then
      echo "!!! ${sc} @ ${res}p failed, last lines:"
      tail -15 "$LOGS/render_${res}_${sc}.log"
    fi
  done
}

concat_res() {
  local res="$1" list="$ROOT/media/$1/list.txt" sc f
  : > "$list"
  for sc in "${SCENES[@]}"; do
    f=$(find "$ROOT/media/$res" -name "${sc}.mp4" -not -path "*/partial_movie_files/*" | head -1)
    if [ -n "$f" ]; then echo "file '$f'" >> "$list"; fi
  done
  if [ ! -s "$list" ]; then
    echo "no scene videos for ${res}p, skip concat"
    return 1
  fi
  "$PY" "$ROOT/measure.py" "ffmpeg_concat_${res}p" "$RES_JSONL" -- \
    ffmpeg -y -hide_banner -loglevel error \
    -f concat -safe 0 -i "$list" \
    -f lavfi -i anullsrc=r=48000:cl=stereo -shortest \
    -c:v libx264 -preset veryfast -crf 23 -pix_fmt yuv420p \
    -c:a aac -b:a 128k "$ROOT/media/$res/final_${res}p.mp4" \
    > "$LOGS/concat_${res}.log" 2>&1
}

# ---------- 3. 480p（驗證流程）----------
render_all 480 854 480 15
concat_res 480

# ---------- 4. 1080p（只跑一次）----------
render_all 1080 1920 1080 30
concat_res 1080

# ---------- 5. 磁碟與摘要 ----------
{
  echo "=== disk usage after run ==="
  du -sh "$ROOT/media"/* 2>/dev/null
  df -h /
} >> "$RESULTS/env.txt" 2>&1

"$PY" "$ROOT/summarize.py" "$RES_JSONL" "$ROOT/media" "$RESULTS/summary.md"
echo "DONE. summary -> $RESULTS/summary.md"
