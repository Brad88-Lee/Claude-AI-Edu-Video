#!/bin/bash
# 單次背景指令上限測試：用單核心滿載的計算迴圈撐滿 MIN 分鐘（比單純 sleep 更接近算繪時的負載），每 20 秒寫心跳，每 10 分鐘把進度推到 GitHub。
# 用法：bash test-render/run_duration.sh MIN BRANCH
MIN="${1:?need minutes}"; BR="${2:?need branch}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; OUT="$ROOT/results/dur_$MIN"; mkdir -p "$OUT"
HB="$OUT/hb_$MIN.log"; : > "$HB"; date -u +%FT%TZ > "$OUT/start_$MIN.txt"
START=$(date +%s); END=$((START + MIN*60))
python3 - "$END" <<'PY' &
import sys, time
end = float(sys.argv[1]); x = 0
while time.time() < end:
    for _ in range(200000): x = (x * 1103515245 + 12345) % 2147483648
PY
JOB=$!; LAST_PUSH=$START
while kill -0 $JOB 2>/dev/null; do
  NOW=$(date +%s); echo "$NOW $((NOW-START)) $(free -m | awk '/Mem/{print $3}')" >> "$HB"
  if [ $((NOW-LAST_PUSH)) -ge 600 ]; then bash "$ROOT/push_progress.sh" "$BR" "$HB" "$OUT/start_$MIN.txt"; LAST_PUSH=$NOW; fi
  sleep 20
done
wait $JOB; echo "job_rc=$? elapsed=$(( $(date +%s) - START ))s end=$(date -u +%FT%TZ)" > "$OUT/end_$MIN.txt"
bash "$ROOT/push_progress.sh" "$BR" "$HB" "$OUT/start_$MIN.txt" "$OUT/end_$MIN.txt"
cat "$OUT/start_$MIN.txt" "$OUT/end_$MIN.txt"; awk 'NR>1 && $1-p>60 {print "gap", $1-p, "s at", p} {p=$1}' "$HB"
