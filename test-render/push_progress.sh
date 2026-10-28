#!/bin/bash
# 用法：push_progress.sh BRANCH 檔案...   把指定檔案以獨立淺層 clone 強制推到 BRANCH，不動目前工作目錄。
# 目的：即使 session 或 VM 中途被回收，GitHub 上仍保留最後一次進度。失敗不影響主流程。
BR="$1"; shift
T=$(mktemp -d) || exit 0
URL=$(git -C "$(dirname "${BASH_SOURCE[0]}")" remote get-url origin 2>/dev/null) || exit 0
git clone -q --depth 1 "$URL" "$T/r" 2>/dev/null || exit 0
cd "$T/r" || exit 0
for f in "$@"; do [ -f "$f" ] && mkdir -p "progress/$(dirname "$(basename "$f")")" && cp "$f" "progress/$(basename "$f")"; done
git add -A progress 2>/dev/null
git -c user.name=claude-test -c user.email=noreply@anthropic.com commit -q -m "progress $(date -u +%H:%M:%S)" 2>/dev/null
git push -q -f origin "HEAD:refs/heads/$BR" 2>/dev/null
rm -rf "$T"; exit 0
