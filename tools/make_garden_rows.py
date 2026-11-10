"""텃밭 그림(지도 조각을 ChatGPT로 고친 것)을 이랑 네 줄로 잘라 지도 위에 덮을 조각을 만든다.

입력: docs/ref/텃밭그림/garden_<작물>_<growing|ready>.png
      지도 map_village.png의 (885,335)부터 320x320을 1024로 키워 보낸 그림을 고친 결과다 (크기는 달라도 된다)
출력: assets/art/garden/<작물>_<growing|ready>_<0~3>.png (투명 PNG, 모두 같은 크기)
      0번이 뒤쪽(위) 이랑, 3번이 앞쪽(아래) 이랑. 게임은 0번부터 차례로 그린다.
      조각이 놓일 지도 위 자리는 맨 끝에 출력하는 PLOT_RECT (scripts/data/crop_db.gd에 적는다)

사용법: python tools/make_garden_rows.py
"""
import glob
import os

from PIL import Image, ImageChops, ImageDraw, ImageFilter

SRC = "docs/ref/텃밭그림"
OUT = "assets/art/garden"
PATCH_ORIGIN = (885, 335)  # 지도 픽셀
PATCH = 320
REF = 1024  # 보낸 그림 크기 (아래 좌표의 기준)

# 텃밭 네 모서리 (보낸 1024 그림 기준). 위쪽 변을 따라 이랑이 놓이고, 왼쪽 변을 따라 네 줄이 쌓인다
TOP_LEFT = (495, 392)
TOP_RIGHT = (722, 455)
BOTTOM_LEFT = (300, 548)
BOTTOM_RIGHT = (610, 628)
ROWS = 4
LIFT_BACK = 70  # 맨 뒤 이랑은 키 큰 작물이 텃밭 위로 솟아도 보이게 위로 넉넉히
LIFT = 20  # 나머지 이랑은 앞 이랑을 조금만 덮게


def lerp(a, b, t):
    return (a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t)


def row_mask(k):
    t0, t1 = k / ROWS, (k + 1) / ROWS
    quad = [lerp(TOP_LEFT, BOTTOM_LEFT, t0), lerp(TOP_RIGHT, BOTTOM_RIGHT, t0),
            lerp(TOP_RIGHT, BOTTOM_RIGHT, t1), lerp(TOP_LEFT, BOTTOM_LEFT, t1)]
    lift = LIFT_BACK if k == 0 else LIFT
    m = Image.new("L", (REF, REF), 0)
    d = ImageDraw.Draw(m)
    for dy in range(0, lift + 1, 2):
        d.polygon([(x, y - dy) for x, y in quad], fill=255)
    return m


def main():
    os.makedirs(OUT, exist_ok=True)
    masks = [row_mask(k) for k in range(ROWS)]
    union = masks[0]
    for m in masks[1:]:
        union = ImageChops.lighter(union, m)
    s = PATCH / REF
    small = [m.resize((PATCH, PATCH), Image.LANCZOS).filter(ImageFilter.GaussianBlur(0.6)) for m in masks]
    bx0, by0, bx1, by1 = union.resize((PATCH, PATCH)).getbbox()
    bx0, by0 = max(0, bx0 - 2), max(0, by0 - 2)
    bx1, by1 = min(PATCH, bx1 + 2), min(PATCH, by1 + 2)
    files = sorted(glob.glob(os.path.join(SRC, "garden_*_*.png")))
    for f in files:
        name = os.path.splitext(os.path.basename(f))[0][len("garden_"):]
        img = Image.open(f).convert("RGB").resize((PATCH, PATCH), Image.LANCZOS)
        for k, m in enumerate(small):
            piece = img.copy()
            piece.putalpha(m)
            piece.crop((bx0, by0, bx1, by1)).save(os.path.join(OUT, f"{name}_{k}.png"), optimize=True)
        print(name)
    print("PLOT_RECT := Rect2(%d, %d, %d, %d)" % (PATCH_ORIGIN[0] + bx0, PATCH_ORIGIN[1] + by0, bx1 - bx0, by1 - by0))
    _ = s


if __name__ == "__main__":
    main()
