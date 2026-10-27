#!/bin/bash
# 第 1 點：同樣 12 張圖、約 60 秒影片，比較 1080p 下的做法：ST1 逐格縮放位移 / ST5 靜止淡入淡出 / ST6 預先縮小的 JPEG / FFmpeg 直接合成。
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV=/opt/manim-venv; OUT="$ROOT/results/round"; mkdir -p "$OUT"
JSONL="$OUT/img_results.jsonl"; : > "$JSONL"
"$VENV/bin/python" "$ROOT/make_stress_assets.py" > /dev/null || { echo "assets failed"; exit 3; }
if "$VENV/bin/manim" render --help 2>&1 | grep -q -- '--frame_rate'; then FPS_FLAG="--frame_rate"; else FPS_FLAG="--fps"; fi
for sc in ST1_Images12 ST5_ImagesStatic ST6_ImagesStaticJpg; do
  "$VENV/bin/python" "$ROOT/measure.py" "img1080_$sc" "$JSONL" -- \
    "$VENV/bin/manim" render -v WARNING -r 1920,1080 "$FPS_FLAG" 30 --media_dir "$ROOT/media/imgcmp/$sc" "$ROOT/scenes_stress.py" "$sc" \
    > "$OUT/img_$sc.log" 2>&1
done
# FFmpeg 直接合成：每張 JPEG 4 秒，淡入 1 秒、淡出 1 秒，縮放置中到 1920x1080，串接
FF_DIR="$ROOT/media/imgcmp/ffmpeg"; mkdir -p "$FF_DIR"
ff_all() {
  inputs=(); filt=""; n=0
  for f in "$ROOT"/assets/stress/jpg/img_*.jpg; do
    inputs+=(-loop 1 -t 4 -i "$f")
    filt+="[$n:v]scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2,fps=30,fade=t=in:st=0:d=1,fade=t=out:st=3:d=1[v$n];"
    n=$((n+1))
  done
  c=""; for i in $(seq 0 $((n-1))); do c+="[v$i]"; done
  ffmpeg -y -hide_banner -loglevel error "${inputs[@]}" -filter_complex "${filt}${c}concat=n=${n}:v=1:a=0[out]" -map "[out]" -c:v libx264 -preset veryfast -crf 23 -pix_fmt yuv420p "$FF_DIR/ff_images.mp4"
}
export -f ff_all 2>/dev/null
"$VENV/bin/python" "$ROOT/measure.py" img1080_ffmpeg "$JSONL" -- bash -c "$(declare -f ff_all); ROOT='$ROOT'; FF_DIR='$FF_DIR'; ff_all" > "$OUT/img_ffmpeg.log" 2>&1
for f in $(find "$ROOT/media/imgcmp" -name '*.mp4' -not -path '*/partial_movie_files/*'); do
  echo "$f $(ffprobe -v error -show_entries format=duration,size -of csv=p=0 "$f")" >> "$OUT/img_videos.txt"
done
cat "$JSONL"; cat "$OUT/img_videos.txt" 2>/dev/null
