"""격자로 그려진 동작 시트(애니메이션 프레임)를 칸마다 잘라 같은 크기의 투명 PNG로 저장한다.

- 그림 덩어리(이어진 불투명 영역)마다 무게중심이 들어 있는 칸에 넣는다.
  그래서 옆 칸 그림이 칸 경계를 살짝 넘어와도(모자 챙 끝 등) 섞이지 않고, 내 칸 그림이 경계를 넘어가도 잘리지 않는다.
- 모든 칸을 같은 크기로 자르고, 발끝(가장 아래 불투명 픽셀)을 같은 높이에 맞춰서 프레임을 바꿔 끼워도 몸이 튀지 않는다.
- 시트 배경이 투명하지 않으면 먼저 tools/remove_white_bg.py로 배경을 지운다.

사용법: python tools/slice_grid.py 시트.png 열 행 출력폴더 접두어 [최대높이px]
예: python tools/slice_grid.py docs/ref/SD_동작시트_뒤.png 6 2 assets/art/sd back 480
  → assets/art/sd/back_01.png ~ back_12.png (왼쪽 위부터 오른쪽으로)
마지막 줄에 칸 기준 자른 창(left, top)과 크기를 찍는다. 손 위치 같은 걸 옮길 때 쓴다.
"""
import os
import sys

import numpy as np
from PIL import Image
from scipy import ndimage

src, cols, rows, out_dir, prefix = sys.argv[1], int(sys.argv[2]), int(sys.argv[3]), sys.argv[4], sys.argv[5]
max_h = int(sys.argv[6]) if len(sys.argv) > 6 else 0
os.makedirs(out_dir, exist_ok=True)

a = np.asarray(Image.open(src).convert("RGBA"))
h, w = a.shape[:2]
cw, ch = w / cols, h / rows

# 덩어리 나누기: 반투명 가장자리까지 한 덩어리로 묶으려고 조금 부풀린다
solid = a[..., 3] > 8
grouped = ndimage.binary_dilation(solid, iterations=2)
labels, n = ndimage.label(grouped, structure=np.ones((3, 3)))
centers = ndimage.center_of_mass(solid, labels, range(1, n + 1))

owner = np.zeros(n + 1, int) - 1  # 덩어리 → 칸 번호
for i, (cy, cx) in enumerate(centers, start=1):
    if np.isnan(cx):
        continue
    c = min(cols - 1, int(cx // cw))
    r = min(rows - 1, int(cy // ch))
    owner[i] = r * cols + c

cells = []
for idx in range(cols * rows):
    mask = owner[labels] == idx
    layer = np.where(mask[..., None], a, 0).astype(np.uint8)
    ys, xs = np.nonzero(layer[..., 3] > 40)
    r, c = divmod(idx, cols)
    ox, oy = round(c * cw), round(r * ch)
    cells.append({"layer": layer, "ox": ox, "oy": oy,
                  "box": (xs.min() - ox, ys.min() - oy, xs.max() - ox, ys.max() - oy)})

# 칸 기준 좌표로 발끝을 맞춘 공통 창
base = max(cell["box"][3] for cell in cells)
pad = 4
left = min(cell["box"][0] for cell in cells) - pad
right = max(cell["box"][2] for cell in cells) + pad
top = min(cell["box"][1] + (base - cell["box"][3]) for cell in cells) - pad
out_w, out_h = right - left + 1, base + pad - top + 1

for i, cell in enumerate(cells, start=1):
    shift = base - cell["box"][3]  # 발끝을 base에 맞추려고 아래로 내리는 양
    canvas = np.zeros((out_h, out_w, 4), np.uint8)
    # 창 안의 각 픽셀은 시트의 (ox + left + x, oy + top - shift + y)
    sx0, sy0 = cell["ox"] + left, cell["oy"] + top - shift
    x0, y0 = max(0, -sx0), max(0, -sy0)
    x1, y1 = min(out_w, w - sx0), min(out_h, h - sy0)
    canvas[y0:y1, x0:x1] = cell["layer"][sy0 + y0:sy0 + y1, sx0 + x0:sx0 + x1]
    img = Image.fromarray(canvas, "RGBA")
    if max_h and img.height > max_h:
        img = img.resize((round(img.width * max_h / img.height), max_h), Image.LANCZOS)
    img.save(os.path.join(out_dir, f"{prefix}_{i:02d}.png"))
print(prefix, len(cells), "frames", out_w, "x", out_h, "window left", left, "top", top)
