"""흰 단색 배경을 투명하게 만든다. 가장자리에서 이어진 흰 영역만 지워서 캐릭터 안의 흰색(수건 등)은 남긴다.
사용법: python3 tools/remove_white_bg.py 입력.png 출력.png [x0,y0,x1,y1 ...]
뒤에 사각형을 주면 그 안에 완전히 들어가는 닫힌 흰 영역(예: 낚싯대와 낚싯줄 사이 틈)도 지운다.
"""
import sys
import numpy as np
from PIL import Image
from scipy import ndimage

HARD = 14   # 이보다 하얀 픽셀은 완전 투명
SOFT = 48   # 이 사이는 반투명 (가장자리 부드럽게)

src, dst = sys.argv[1], sys.argv[2]
rgb = np.asarray(Image.open(src).convert("RGB")).astype(np.float32)
d = 255.0 - rgb.min(axis=2)  # 흰색에서 얼마나 먼지

candidate = d <= SOFT
labels, _ = ndimage.label(candidate)
border = np.unique(np.concatenate([labels[0], labels[-1], labels[:, 0], labels[:, -1]]))
border = border[border != 0]
bg = np.isin(labels, border)

for rect in sys.argv[3:]:
    x0, y0, x1, y1 = map(int, rect.split(","))
    for lab, sl in enumerate(ndimage.find_objects(labels), start=1):
        if sl is None or lab in border:
            continue
        ys, xs = sl
        if xs.start >= x0 and xs.stop <= x1 and ys.start >= y0 and ys.stop <= y1:
            bg |= labels == lab

alpha = np.ones(d.shape, np.float32)
alpha[bg] = np.clip((d[bg] - HARD) / (SOFT - HARD), 0.0, 1.0)

# 반투명 가장자리의 흰 번짐 제거
a = np.maximum(alpha, 1e-3)[..., None]
out_rgb = np.where(alpha[..., None] < 1.0, (rgb - 255.0 * (1.0 - a)) / a, rgb)
out = np.dstack([np.clip(out_rgb, 0, 255), alpha * 255.0]).astype(np.uint8)
img = Image.fromarray(out, "RGBA")
bbox = img.getchannel("A").point(lambda v: 255 if v > 8 else 0).getbbox()
img = img.crop(bbox)
img.save(dst)
print("saved", dst, img.size, "bbox", bbox)
