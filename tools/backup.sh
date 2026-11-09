#!/usr/bin/env bash
# 커밋된 전체 이력을 bundle로, 현재 작업 폴더를 zip으로 만든다. 결과는 build/backup/에 생긴다.
set -euo pipefail
cd "$(dirname "$0")/.."
STAMP=$(date +%Y%m%d-%H%M)
OUT=build/backup
mkdir -p "$OUT"
git bundle create "$OUT/oneului-bada-$STAMP.bundle" --all
git bundle verify "$OUT/oneului-bada-$STAMP.bundle" >/dev/null
git archive --format=zip -o "$OUT/oneului-bada-$STAMP.zip" HEAD
ls -la "$OUT"/*"$STAMP"*
