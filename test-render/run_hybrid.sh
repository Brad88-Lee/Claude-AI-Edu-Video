#!/bin/bash
# 混合管線測試：Manim 公式段（4K）+ FFmpeg 圖片段（4K，靜止與緩慢推近兩種）+ 串接 + 加音軌 + 透明公式疊在圖片上（1080p）。
# 目的：確認「圖片用 FFmpeg、公式用 Manim」能不能無縫串接，並量各步驟耗時。
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV=/opt/manim-venv; OUT="$ROOT/results/hybrid"; W="$ROOT/media/hybrid"; mkdir -p "$OUT" "$W" "$OUT/frames"
J="$OUT/hybrid_results.jsonl"; : > "$J"; LOG="$OUT/hybrid_notes.txt"; : > "$LOG"
note() { echo "[$(date -u +%T)] $*" | tee -a "$LOG"; }
M() { "$VENV/bin/python" "$ROOT/measure.py" "$@"; }   # M LABEL JSONL -- cmd
"$VENV/bin/python" "$ROOT/make_stress_assets.py" >/dev/null || { note "assets failed"; exit 3; }
if "$VENV/bin/manim" render --help 2>&1 | grep -q -- '--frame_rate'; then FPS_FLAG="--frame_rate"; else FPS_FLAG="--fps"; fi
JPG="$ROOT/assets/stress/jpg"

# 1) Manim 公式段：3 段推導（約 60 秒），4K
SEG_START=0 SEG_COUNT=3 M hy_manim_4k_formula3 "$J" -- "$VENV/bin/manim" render -v WARNING -r 3840,2160 "$FPS_FLAG" 30 -o formula3.mp4 --media_dir "$W/m" "$ROOT/scenes_stress.py" ST7_Chunk > "$OUT/manim_formula.log" 2>&1
FORM=$(find "$W/m" -name formula3.mp4 -not -path '*/partial_movie_files/*' | head -1)
note "formula video: $FORM"; ffprobe -v error -select_streams v:0 -show_entries stream=codec_name,profile,pix_fmt,width,height,r_frame_rate,time_base,duration -of default=nw=1 "$FORM" >> "$LOG" 2>&1

# 2) FFmpeg 圖片段 4K：12 張，每張 4 秒；A=靜止淡入淡出，B=緩慢推近（zoompan）
mkdir -p "$W/ffA" "$W/ffB"
mk_pieces() { # MODE DIR
  local mode="$1" dir="$2" i=0
  for f in "$JPG"/img_*.jpg; do
    if [ "$mode" = A ]; then vf="scale=3840:2160:force_original_aspect_ratio=decrease,pad=3840:2160:(ow-iw)/2:(oh-ih)/2,fps=30,fade=t=in:st=0:d=1,fade=t=out:st=3:d=1,format=yuv420p"
    else vf="scale=3840:2160:force_original_aspect_ratio=decrease,pad=3840:2160:(ow-iw)/2:(oh-ih)/2,zoompan=z='min(zoom+0.0006,1.15)':x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':d=120:s=3840x2160:fps=30,fade=t=in:st=0:d=1,fade=t=out:st=3:d=1,format=yuv420p"; fi
    ffmpeg -y -hide_banner -loglevel error -loop 1 -i "$f" -vf "$vf" -t 4 -r 30 -c:v libx264 -preset veryfast -crf 23 "$dir/p_$(printf %02d $i).mp4" || return 1
    i=$((i+1))
  done
  ( cd "$dir" && ls p_*.mp4 | sed "s#^#file '$dir/#; s#\$#'#" > list.txt )
  ffmpeg -y -hide_banner -loglevel error -f concat -safe 0 -i "$dir/list.txt" -c copy "$dir/images.mp4"
}
M hy_ffmpeg_4k_images_static "$J" -- bash -c "$(declare -f mk_pieces); JPG='$JPG'; mk_pieces A '$W/ffA'" > "$OUT/ffA.log" 2>&1
M hy_ffmpeg_4k_images_zoom   "$J" -- bash -c "$(declare -f mk_pieces); JPG='$JPG'; mk_pieces B '$W/ffB'" > "$OUT/ffB.log" 2>&1

# 3) 串接：公式段 + 圖片段（先試不重新編碼 -c copy）
for V in A B; do
  printf "file '%s'\nfile '%s'\n" "$FORM" "$W/ff$V/images.mp4" > "$W/cat_$V.txt"
  M hy_concat_copy_$V "$J" -- ffmpeg -y -hide_banner -loglevel error -f concat -safe 0 -i "$W/cat_$V.txt" -c copy "$W/final_$V.mp4" > "$OUT/cat_$V.log" 2>&1
  note "concat copy $V: $(tail -3 "$OUT/cat_$V.log" | tr '\n' ' ')"
  note "streams $V: $(ffprobe -v error -show_entries format=duration,size:stream=codec_name,width,height,r_frame_rate -of csv=p=0 "$W/final_$V.mp4" 2>&1 | tr '\n' ' ')"
  # 在接點（公式段結束處）前後各抽一張影格，供目視檢查
  D=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$FORM")
  for off in -0.5 0.5; do
    t=$(python3 -c "print(max(0,$D+($off)))")
    ffmpeg -y -hide_banner -loglevel error -ss "$t" -i "$W/final_$V.mp4" -frames:v 1 -vf scale=960:-1 -q:v 5 "$OUT/frames/junction_${V}_${off}.jpg"
  done
done

# 4) 加音軌（用靜音 AAC 模擬之後的旁白），影像不重新編碼
M hy_mux_audio "$J" -- ffmpeg -y -hide_banner -loglevel error -i "$W/final_A.mp4" -f lavfi -i "anullsrc=r=48000:cl=stereo" -shortest -c:v copy -c:a aac -b:a 128k "$W/final_A_audio.mp4" > "$OUT/mux.log" 2>&1
note "mux: $(ffprobe -v error -show_entries format=duration,size -of csv=p=0 "$W/final_A_audio.mp4" 2>&1 | tr '\n' ' ')"

# 5) 透明公式疊在圖片上（1080p）
M hy_manim_1080_transparent "$J" -- "$VENV/bin/manim" render -v WARNING -t -r 1920,1080 "$FPS_FLAG" 30 -o overlay.mov --media_dir "$W/o" "$ROOT/scenes_stress.py" ST8_OverlayFormula > "$OUT/overlay_manim.log" 2>&1
OV=$(find "$W/o" -name overlay.mov -not -path '*/partial_movie_files/*' | head -1)
if [ -n "$OV" ]; then
  note "overlay file: $(ls -l "$OV" | awk '{print $5}') bytes; $(ffprobe -v error -select_streams v:0 -show_entries stream=codec_name,pix_fmt -of csv=p=0 "$OV")"
  M hy_overlay_ffmpeg "$J" -- ffmpeg -y -hide_banner -loglevel error -i "$W/ffA/images.mp4" -i "$OV" -filter_complex "[0:v]scale=1920:1080[bg];[bg][1:v]overlay=0:0:eof_action=pass[o]" -map "[o]" -t 10 -c:v libx264 -preset veryfast -crf 23 -pix_fmt yuv420p "$W/overlay_result.mp4" > "$OUT/overlay_ff.log" 2>&1
  ffmpeg -y -hide_banner -loglevel error -ss 5 -i "$W/overlay_result.mp4" -frames:v 1 -q:v 5 "$OUT/frames/overlay_t5s.jpg"
else
  note "overlay.mov not produced"
fi
for f in "$W"/final_A.mp4 "$W"/final_B.mp4 "$W"/ffA/images.mp4 "$W"/ffB/images.mp4 "$FORM"; do echo "$f $(ffprobe -v error -show_entries format=duration,size -of csv=p=0 "$f" 2>/dev/null)" >> "$OUT/videos.txt"; done
cat "$J" "$LOG" "$OUT/videos.txt"
