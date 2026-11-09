"""격자로 그려진 동작 시트(애니메이션 프레임)를 칸마다 잘라 같은 크기의 투명 PNG로 저장한다.
모든 칸을 같은 크기로 자르고, 발끝(가장 아래 불투명 픽셀)을 같은 높이에 맞춰서 프레임을 바꿔 끼워도 몸이 튀지 않는다.
시트 배경이 투명하지 않으면 먼저 tools/remove_white_bg.py로 배경을 지운다.

사용법: python tools/slice_grid.py 시트.png 열 행 출력폴더 접두어 [최대높이px]
예: python tools/slice_grid.py docs/ref/SD_동작시트_뒤.png 6 2 assets/art/sd back 420
  → assets/art/sd/back_01.png ~ back_12.png (왼쪽 위부터 오른쪽으로)
"""
import os
import sys

import numpy as np
from PIL import Image

src, cols, rows, out_dir, prefix = sys.argv[1], int(sys.argv[2]), int(sys.argv[3]), sys.argv[4], sys.argv[5]
max_h = int(sys.argv[6]) if len(sys.argv) > 6 else 0
os.makedirs(out_dir, exist_ok=True)

im = Image.open(src).convert("RGBA")
a = np.asarray(im)
h, w = a.shape[:2]
cw, ch = w / cols, h / rows

cells = []
for r in range(rows):
    for c in range(cols):
        x0, x1 = round(c * cw), round((c + 1) * cw)
        y0, y1 = round(r * ch), round((r + 1) * ch)
        cells.append(a[y0:y1, x0:x1])

# 칸마다 불투명한 영역과 발끝 높이
cw_i = min(cell.shape[1] for cell in cells)
ch_i = min(cell.shape[0] for cell in cells)
cells = [cell[:ch_i, :cw_i] for cell in cells]
bottoms, boxes = [], []
for cell in cells:
    solid = cell[..., 3] > 40
    ys, xs = np.nonzero(solid)
    bottoms.append(ys.max())
    boxes.append((xs.min(), ys.min(), xs.max(), ys.max()))
base = max(bottoms)

# 발끝을 맞춘 뒤 모든 칸을 덮는 공통 사각형
left = min(b[0] for b in boxes)
right = max(b[2] for b in boxes)
top = min(b[1] + (base - bt) for b, bt in zip(boxes, bottoms))
pad = 4
left, top, right = max(0, left - pad), max(0, top - pad), min(cw_i - 1, right + pad)
out_w, out_h = right - left + 1, base - top + 1 + pad

for i, (cell, bt) in enumerate(zip(cells, bottoms), start=1):
    canvas = np.zeros((out_h, out_w, 4), np.uint8)
    shift = base - bt
    src_y0 = max(0, top - shift)
    dst_y0 = src_y0 + shift - top
    part = cell[src_y0:, left:right + 1]
    hh = min(part.shape[0], out_h - dst_y0)
    canvas[dst_y0:dst_y0 + hh] = part[:hh]
    img = Image.fromarray(canvas, "RGBA")
    if max_h and img.height > max_h:
        img = img.resize((round(img.width * max_h / img.height), max_h), Image.LANCZOS)
    img.save(os.path.join(out_dir, f"{prefix}_{i:02d}.png"))
print(prefix, len(cells), "frames", out_w, "x", out_h)
