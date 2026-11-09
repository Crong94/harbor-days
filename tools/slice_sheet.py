"""여러 개가 그려진 시트 그림을 한 개씩 잘라 투명 PNG로 저장한다.
배경색은 가장자리 픽셀로 추정하고, 가장자리에서 이어진 배경만 지운다 (그림 안쪽의 밝은 색은 남긴다).
글자 줄(라벨)처럼 낮고 납작한 조각은 버린다.

사용법: python3 tools/slice_sheet.py 시트.png 출력폴더 [접두어]
"""
import os
import sys

import numpy as np
from PIL import Image
from scipy import ndimage

HARD = 10  # 배경색과 이 정도 이내면 완전 투명
SOFT = 34  # 이 사이는 반투명 가장자리
PAD = 6
MIN_AREA_RATIO = 0.004  # 시트 넓이 대비 이보다 작은 조각은 버린다

src, out_dir = sys.argv[1], sys.argv[2]
prefix = sys.argv[3] if len(sys.argv) > 3 else os.path.splitext(os.path.basename(src))[0]
os.makedirs(out_dir, exist_ok=True)

rgb = np.asarray(Image.open(src).convert("RGB")).astype(np.float32)
h, w, _ = rgb.shape
border = np.concatenate([rgb[0], rgb[-1], rgb[:, 0], rgb[:, -1]])
bg_color = np.median(border, axis=0)
diff = np.abs(rgb - bg_color).max(axis=2)

cand = diff <= SOFT
labels, _ = ndimage.label(cand)
edge = np.unique(np.concatenate([labels[0], labels[-1], labels[:, 0], labels[:, -1]]))
edge = edge[edge != 0]
bg = np.isin(labels, edge)

alpha = np.ones((h, w), np.float32)
alpha[bg] = np.clip((diff[bg] - HARD) / (SOFT - HARD), 0.0, 1.0)

# 반투명 가장자리의 배경색 번짐 제거
a = np.maximum(alpha, 1e-3)[..., None]
clean = np.where(alpha[..., None] < 1.0, (rgb - bg_color * (1.0 - a)) / a, rgb)
rgba = np.dstack([np.clip(clean, 0, 255), alpha * 255.0]).astype(np.uint8)

# 조각 나누기: 살짝 부풀려서 떨어진 지느러미, 수염 등을 한 덩어리로
solid = alpha > 0.5
grouped = ndimage.binary_dilation(solid, iterations=4)
parts, n = ndimage.label(grouped)
objs = ndimage.find_objects(parts)

items = []
for i, sl in enumerate(objs, start=1):
    ys, xs = sl
    bw, bh = xs.stop - xs.start, ys.stop - ys.start
    area = int((parts[sl] == i).sum())
    if area < MIN_AREA_RATIO * w * h:
        continue
    if bh < 0.06 * h and bw > 2.5 * bh:  # 글자 줄
        continue
    items.append((ys.start, xs.start, sl, i))

# 위에서 아래, 왼쪽에서 오른쪽 순서 (같은 줄은 y가 비슷한 것끼리)
items.sort(key=lambda t: (round(t[0] / (h * 0.12)), t[1]))
for k, (_, _, sl, i) in enumerate(items, start=1):
    ys, xs = sl
    y0, y1 = max(0, ys.start - PAD), min(h, ys.stop + PAD)
    x0, x1 = max(0, xs.start - PAD), min(w, xs.stop + PAD)
    crop = rgba[y0:y1, x0:x1].copy()
    mask = parts[y0:y1, x0:x1] == i
    crop[..., 3] = np.where(mask, crop[..., 3], 0)
    name = f"{prefix}_{k:02d}.png"
    Image.fromarray(crop, "RGBA").save(os.path.join(out_dir, name))
print(prefix, len(items), "pieces")
