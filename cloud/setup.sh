#!/bin/bash
# ============================================================
# Edu-video cloud environment setup script
# 目標環境：Claude Code cloud environment（Ubuntu 24.04、root、Trusted 網路）
# 規則：
#   1. 一定要 exit 0，否則 session 會啟動失敗
#   2. 總時間要控制在約 5 分鐘內，環境快取才會建立
# 紀錄：/opt/edu-video-setup.log（各階段耗時）
# 完成標記：/opt/edu-video-setup.done（內容為總秒數）
# 各階段完整輸出：/opt/setup-<階段名>.out
# ============================================================
export DEBIAN_FRONTEND=noninteractive
mkdir -p /opt
LOG=/opt/edu-video-setup.log
: > "$LOG"
T0=$(date +%s)

log() { echo "[+$(( $(date +%s) - T0 ))s] $*" | tee -a "$LOG"; }

# 執行一個階段並記錄耗時；失敗只記錄，不中斷整個腳本
run_stage() {
  local name="$1"; shift
  local s; s=$(date +%s)
  log "START $name"
  "$@" > "/opt/setup-${name}.out" 2>&1
  local rc=$?
  log "END   $name rc=$rc took=$(( $(date +%s) - s ))s"
  return 0
}

# ---- 階段 1：編譯 ManimPango / pycairo 所需的系統依賴（Manim 官方文件列出的 Debian 依賴）----
stage_apt_base() {
  apt-get update -y || return 1
  apt-get install -y --no-install-recommends \
    build-essential python3-dev python3-venv python3-pip pkg-config \
    libcairo2-dev libpango1.0-dev
}

# ---- 階段 2a：精簡 TeX Live + 中文字型 + dvisvgm ----
TEX_PKGS="fonts-noto-cjk texlive-xetex texlive-latex-extra texlive-science texlive-fonts-recommended texlive-lang-chinese cm-super dvisvgm"

stage_tex_fonts() {
  if apt-get install -y --no-install-recommends $TEX_PKGS; then
    return 0
  fi
  echo "bulk install failed, retrying package by package"
  local rc=0 p
  for p in $TEX_PKGS; do
    apt-get install -y --no-install-recommends "$p" || { echo "FAILED package: $p"; rc=1; }
  done
  return $rc
}

# ---- 階段 2b：在獨立 venv 安裝 Manim Community（與 2a 平行執行）----
stage_manim_pip() {
  python3 -m venv /opt/manim-venv || return 1
  /opt/manim-venv/bin/pip install --quiet --upgrade pip || return 1
  /opt/manim-venv/bin/pip install --quiet manim
}

run_stage apt_base stage_apt_base

# apt 與 pip 不共用 dpkg 鎖，可以平行；pip 編譯需要階段 1 已完成
run_stage tex_fonts stage_tex_fonts &
PID_TEX=$!
run_stage manim_pip stage_manim_pip &
PID_PIP=$!
wait "$PID_TEX" "$PID_PIP"

# ---- 驗證與版本紀錄 ----
fc-cache -f >/dev/null 2>&1
{
  echo "--- verification ---"
  echo "system python: $(python3 --version 2>&1)"
  if [ -x /opt/manim-venv/bin/python ]; then
    echo "venv python: $(/opt/manim-venv/bin/python --version 2>&1)"
    /opt/manim-venv/bin/pip show manim 2>/dev/null | grep -E '^(Name|Version)'
  else
    echo "MISSING venv: /opt/manim-venv"
  fi
  for c in xelatex latex dvisvgm ffmpeg; do
    if command -v "$c" >/dev/null 2>&1; then
      echo "OK      $c: $($c --version 2>&1 | head -1)"
    else
      echo "MISSING $c"
    fi
  done
  echo "fc-list entries matching 'Noto Sans CJK TC': $(fc-list | grep -ci 'Noto Sans CJK TC')"
  echo "fc-list entries matching 'Noto Sans CJK'   : $(fc-list | grep -ci 'Noto Sans CJK')"
  echo "pango: $(pkg-config --modversion pango 2>&1)"
  echo "cairo: $(pkg-config --modversion cairo 2>&1)"
  df -h / | tail -1
} 2>&1 | tee -a "$LOG"

TOTAL=$(( $(date +%s) - T0 ))
log "TOTAL ${TOTAL}s (cache budget is roughly 300s)"
if [ "$TOTAL" -gt 270 ]; then
  log "WARN: close to or over the 5-minute caching budget"
fi
echo "$TOTAL" > /opt/edu-video-setup.done
exit 0
