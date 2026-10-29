#!/bin/bash
# 旁白長度驅動畫面長度（1080p/30fps）。MOCK_MANIM=1 時用 ffmpeg 假影片取代 Manim（僅供本機驗證腳本）。
# 目的：量化 A/V 對齊。方法 a：音訊以計畫長度 T 產生；方法 b：音訊補齊到「實際量到的畫面長度」；方法 c：同 b，但每段各自編成 AAC 再串接。
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV=${VENV:-/opt/manim-venv}; OUT="$ROOT/results/narr"; W="$ROOT/media/narr"; mkdir -p "$OUT" "$W/seg" "$W/wa" "$W/wb" "$W/ac"
J="$OUT/narr_results.jsonl"; : > "$J"; LOG="$OUT/narr_notes.txt"; : > "$LOG"
note() { echo "[$(date -u +%T)] $*" | tee -a "$LOG"; }
PYX=${PYX:-$VENV/bin/python}; M() { "$PYX" "$ROOT/measure.py" "$@"; }
python3 "$ROOT/narr_plan.py" "$OUT/plan.json" | tee -a "$LOG"
if [ "$MOCK_MANIM" != 1 ]; then
  if "$VENV/bin/manim" render --help 2>&1 | grep -q -- '--frame_rate'; then FPS_FLAG="--frame_rate"; else FPS_FLAG="--fps"; fi
  "$VENV/bin/python" "$ROOT/make_stress_assets.py" >/dev/null || { note "assets failed"; exit 3; }
fi
JPG="$ROOT/assets/stress/jpg"; [ -d "$JPG" ] || { mkdir -p "$JPG"; for k in 00 01 02; do ffmpeg -y -loglevel error -f lavfi -i testsrc=s=1920x1280:d=1 -frames:v 1 "$JPG/img_$k.jpg"; done; }
IMGS=("$JPG"/img_*.jpg)
mapfile -t ROWS < <(python3 -c "
import json
for p in json.load(open('$OUT/plan.json')): print(p['idx'], p['type'], p['T'], p['narr'])")

make_video_segments() {
  for row in "${ROWS[@]}"; do
    set -- $row; idx=$1; typ=$2; T=$3; f=$(printf "%s/seg/s_%03d.mp4" "$W" "$idx")
    N=$(python3 -c "print(round($T*30))")
    if [ "$typ" = image ]; then
      img="${IMGS[$((idx/2 % ${#IMGS[@]}))]}"
      ffmpeg -y -hide_banner -loglevel error -loop 1 -i "$img" -vf "scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2,fps=30,fade=t=in:st=0:d=0.5,fade=t=out:st=$(python3 -c "print($T-0.5)"):d=0.5,format=yuv420p" -frames:v $N -r 30 -c:v libx264 -preset veryfast -crf 23 "$f" || echo "FAIL image $idx" >> "$LOG"
    elif [ "$MOCK_MANIM" = 1 ]; then
      ffmpeg -y -hide_banner -loglevel error -f lavfi -i "testsrc2=s=1920x1080:r=30" -frames:v $N -c:v libx264 -preset veryfast -crf 23 -pix_fmt yuv420p "$f" || echo "FAIL mock $idx" >> "$LOG"
    else
      SEG_IDX=$idx SEG_DUR=$T "$VENV/bin/manim" render -v ERROR -r 1920,1080 "$FPS_FLAG" 30 -o "s_$(printf %03d $idx).mp4" --media_dir "$W/m/$idx" "$ROOT/scenes_narr.py" ST9_NarrFormula > "$OUT/manim_$idx.log" 2>&1
      src=$(find "$W/m/$idx" -name "s_$(printf %03d $idx).mp4" -not -path '*/partial_movie_files/*' | head -1)
      [ -n "$src" ] && cp "$src" "$f" || echo "FAIL manim $idx" >> "$LOG"
      rm -rf "$W/m/$idx"
    fi
  done
}
if [ "$SKIP_VIDEO" != 1 ]; then
M narr_video_segments "$J" -- bash -c "$(declare -f make_video_segments); $(declare -p ROWS IMGS | tr '\n' ';') ROOT='$ROOT' W='$W' OUT='$OUT' LOG='$LOG' VENV='$VENV' FPS_FLAG='$FPS_FLAG' MOCK_MANIM='$MOCK_MANIM' JPG='$JPG'; make_video_segments" > "$OUT/segments.log" 2>&1
fi

# 量測每段實際影格數與長度
: > "$OUT/measured.csv"
for row in "${ROWS[@]}"; do set -- $row; f=$(printf "%s/seg/s_%03d.mp4" "$W" "$1")
  echo "$1,$2,$3,$(ffprobe -v error -select_streams v:0 -show_entries stream=nb_frames,duration -of csv=p=0 "$f" 2>/dev/null | tr '\n' ',')" >> "$OUT/measured.csv"; done

# 串接畫面（不重新編碼）
ls "$W"/seg/s_*.mp4 | sed "s#^#file '#; s#\$#'#" > "$W/vlist.txt"
[ "$SKIP_VIDEO" != 1 ] && M narr_concat_video "$J" -- ffmpeg -y -hide_banner -loglevel error -f concat -safe 0 -i "$W/vlist.txt" -c copy "$W/video_all.mp4" > "$OUT/vcat.log" 2>&1

# 產生三種音訊：旁白用 440Hz 純音代替，前後各 0.5 秒靜音；音訊長度（方法 a=計畫長度 T，方法 b、c=實際畫面長度）
python3 - "$OUT/plan.json" "$OUT/measured.csv" "$W" <<'PY'
import json, sys, subprocess
plan = json.load(open(sys.argv[1])); W = sys.argv[3]
meas = {}
for line in open(sys.argv[2]):
    p = line.strip().split(",")
    try: meas[int(p[0])] = float(p[3])   # stream duration（ffprobe 先輸出 duration 再輸出 nb_frames）
    except Exception: pass
def tone(path, narr, whole, codec):
    flt = f"sine=frequency=440:sample_rate=48000:duration={narr},adelay=500|500,apad=whole_dur={whole}"
    cmd = ["ffmpeg","-y","-hide_banner","-loglevel","error","-f","lavfi","-i",flt,"-ac","1"] + codec + [path]
    subprocess.run(cmd, check=True)
for p in plan:
    i = p["idx"]; vd = meas.get(i, p["T"])
    tone(f"{W}/wa/a_{i:03d}.wav", p["narr"], p["T"], ["-c:a","pcm_s16le"])
    tone(f"{W}/wb/b_{i:03d}.wav", p["narr"], vd, ["-c:a","pcm_s16le"])
    tone(f"{W}/ac/c_{i:03d}.m4a", p["narr"], vd, ["-c:a","aac","-b:a","128k"])
PY
for k in wa:a wb:b ac:c; do d=${k%%:*}; p=${k##*:}; ext=wav; [ $d = ac ] && ext=m4a
  ls "$W/$d"/${p}_*.$ext | sed "s#^#file '#; s#\$#'#" > "$W/alist_$p.txt"; done
ffmpeg -y -hide_banner -loglevel error -f concat -safe 0 -i "$W/alist_a.txt" -c copy "$W/all_a.wav"
ffmpeg -y -hide_banner -loglevel error -f concat -safe 0 -i "$W/alist_b.txt" -c copy "$W/all_b.wav"
ffmpeg -y -hide_banner -loglevel error -f concat -safe 0 -i "$W/alist_c.txt" -c copy "$W/all_c.m4a"
M narr_mux "$J" -- bash -c "
ffmpeg -y -hide_banner -loglevel error -i '$W/video_all.mp4' -i '$W/all_a.wav' -c:v copy -c:a aac -b:a 128k '$W/final_a.mp4' &&
ffmpeg -y -hide_banner -loglevel error -i '$W/video_all.mp4' -i '$W/all_b.wav' -c:v copy -c:a aac -b:a 128k '$W/final_b.mp4' &&
ffmpeg -y -hide_banner -loglevel error -i '$W/video_all.mp4' -i '$W/all_c.m4a' -c:v copy -c:a copy '$W/final_c.mp4'" > "$OUT/mux.log" 2>&1
python3 "$ROOT/analyze_narration.py" "$OUT" "$W"
