#!/bin/bash
# 第 4 點探測：不登入、不上傳。只檢查 Node 版本、能否安裝 Internxt CLI、對 Internxt 與其他儲存服務的主機連線結果。
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="$ROOT/results/round/probe_internxt.txt"
mkdir -p "$ROOT/results/round"; : > "$OUT"
{
  echo "== node/npm =="; node --version; npm --version
  echo "== npm view =="; npm view @internxt/cli version dist.unpackedSize 2>&1 | head -5
  echo "== install to temp prefix (不使用 -g，避免動到系統) =="
  P=$(mktemp -d); ( cd "$P" && timeout 240 npm install --no-audit --no-fund @internxt/cli 2>&1 | tail -5 )
  echo "== cli version =="; "$P/node_modules/.bin/internxt" --version 2>&1 | head -3
  echo "== cli help (前 15 行) =="; "$P/node_modules/.bin/internxt" --help 2>&1 | head -15
  for u in https://internxt.com https://drive.internxt.com https://gateway.internxt.com https://api.internxt.com https://drive.internxt.com/api \
           https://uploads.github.com https://api.github.com https://storage.googleapis.com https://s3.amazonaws.com; do
    echo "== $u =="; curl -sS -m 10 -o /dev/null -D - -I "$u" 2>&1 | grep -i -E "^(HTTP|x-deny-reason|curl)" | head -3
  done
} >> "$OUT" 2>&1
cat "$OUT"
