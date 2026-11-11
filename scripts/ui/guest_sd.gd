class_name GuestSD
extends Control
## 손님 SD 한 명. 반응 시트(assets/art/sd_guest/<id>_react.png, 3:2 한 줄 세 칸)에서 한 칸을 골라 그린다.
##   0 서 있기(주문 기다림)  1 만족  2 아쉬움
## 걷기 시트(<id>_walk.png, 8칸)는 지도 걷기에 쓸 자리 (아직 안 씀).
## 시트마다 그림이 칸 경계에서 맞닿기도 해서, 1/3과 2/3 근처에서 가장 빈 열을 찾아 자른다.
## 그림이 없는 사람은 아무것도 그리지 않는다. 발이 이 노드 아래 가운데에 오게 맞춘다.

const DIR := "res://assets/art/sd_guest/"
const POSES := {"stand": 0, "happy": 1, "sad": 2}
const CUT_SEARCH := 0.08 # 경계 찾는 범위 (그림 너비 대비)

static var _cache := {} # id → {"tex": Texture2D, "cuts": [x0, x1, x2, x3]}

var guest_id := ""
var pose := "stand"
var _t := 0.0
var _pop := 1.0 # 자세가 바뀔 때 살짝 튀는 연출 (0에서 1로)


## 손님 이름(대사 speaker, 주문 손님 이름) → 그림 id. Portraits와 같은 표를 쓴다
static func id_for(name: String) -> String:
	return Portraits.SPEAKERS.get(name, "")


static func sheet_path(id: String) -> String:
	return DIR + "%s_react.png" % id


static func has_sheet(id: String) -> bool:
	return not id.is_empty() and ResourceLoader.exists(sheet_path(id))


## 열마다 그림이 있는 정도(알파 합)에서 세 칸 경계를 찾는다. [0, a, b, 너비]
static func find_cuts(cols: PackedFloat32Array) -> Array:
	var w := cols.size()
	var cuts := [0]
	for k in [1, 2]:
		var mid := int(w * k / 3.0)
		var r := int(w * CUT_SEARCH)
		var best := mid
		for x in range(maxi(1, mid - r), mini(w - 1, mid + r) + 1):
			# 같은 값이면 가운데에 가까운 쪽
			if cols[x] < cols[best] or (cols[x] == cols[best] and absi(x - mid) < absi(best - mid)):
				best = x
		cuts.append(best)
	cuts.append(w)
	return cuts


static func _sheet(id: String) -> Dictionary:
	if _cache.has(id):
		return _cache[id]
	var tex: Texture2D = load(sheet_path(id))
	var img := tex.get_image()
	if img.is_compressed():
		img.decompress()
	var w := img.get_width()
	var h := img.get_height()
	var cols := PackedFloat32Array()
	cols.resize(w)
	for x in w:
		var s := 0.0
		for y in range(0, h, 6):
			s += img.get_pixel(x, y).a
		cols[x] = s
	var e := {"tex": tex, "cuts": find_cuts(cols)}
	_cache[id] = e
	return e


## 요리 별 수 → 손님 몸짓. 3개 만족, 2개는 그냥 서 있음, 1개 이하 아쉬움
static func pose_for_stars(stars: int) -> String:
	if stars >= 3:
		return "happy"
	return "stand" if stars == 2 else "sad"


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_pose(p: String) -> void:
	if p != pose:
		pose = p
		_pop = 0.0
	queue_redraw()


func _process(delta: float) -> void:
	_t += delta
	_pop = minf(1.0, _pop + delta / 0.35)
	queue_redraw()


func _draw() -> void:
	if not has_sheet(guest_id):
		return
	var e := _sheet(guest_id)
	var tex: Texture2D = e.tex
	var i: int = POSES.get(pose, 0)
	var x0: int = e.cuts[i]
	var x1: int = e.cuts[i + 1]
	var src := Rect2(x0, 0, x1 - x0, tex.get_height())
	# 칸 높이를 노드 높이에 맞추고 발을 아래 가운데에. 숨쉬기와 자세가 바뀔 때 통 튀기
	var k := size.y / src.size.y
	var bounce := 1.0 + 0.08 * sin(_pop * PI) * (1.0 - _pop * 0.5)
	var breathe := 1.0 + 0.012 * sin(_t * 2.4)
	var dw := src.size.x * k
	var dh := src.size.y * k * breathe * bounce
	draw_texture_rect_region(tex, Rect2(size.x / 2.0 - dw / 2.0, size.y - dh, dw, dh), src)
