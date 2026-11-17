class_name GuestSD
extends Control
## 손님 SD 한 명. 반응 시트(assets/art/sd_guest/<id>_react.png, 3:2 한 줄 세 칸)에서 한 칸을 골라 그린다.
##   0 서 있기(주문 기다림)  1 만족  2 아쉬움
## 걷기 시트(<id>_walk.png, 같은 폭 8칸): 1·2 앞, 3·4 뒤, 5~8 오른쪽 옆 한 걸음. walk에 "front", "back", "side"를 주면 걷는 그림
## (식당 입구에서 자리까지). 왼쪽으로 걸을 때는 flip.
## 시트마다 그림이 칸 경계에서 맞닿기도 해서, 1/3과 2/3 근처에서 가장 빈 열을 찾아 자른다.
## 그림이 없는 사람은 아무것도 그리지 않는다. 발이 이 노드 아래 가운데에 오게 맞춘다.
## 앉은 자세 (seat = "back" 앞 바 뒷모습, "side" 옆모습, 오른쪽을 봄. flip이면 왼쪽을 봄):
##   <id>_seat_back.png, <id>_seat_side.png 한 줄 4칸, 칸 폭은 같음. 0 기다림 1 먹는 중 2 만족 3 화남
##   앉은 키는 서 있는 키의 SEAT_H. 앉은 그림이 없으면 서 있는 반응 그림으로 대신한다

const DIR := "res://assets/art/sd_guest/"
const POSES := {"stand": 0, "happy": 1, "sad": 2}
const SEAT_POSES := {"stand": 0, "eat": 1, "happy": 2, "sad": 3}
const SEAT_H := 0.78
## 앉은 시트는 다섯 명이 같은 기준으로 잘려 있어서 배율 하나로 줄인다 (서 있는 키 442px → 150px, 그림 세션)
const SEAT_SCALE := 0.339
const STAND_H := 150.0
const CUT_SEARCH := 0.08 # 경계 찾는 범위 (그림 너비 대비)

## 이름 없는 손님 그림 (11-12 그림 세션). 손님 이름 → 그림 id. 모르는 이름은 다섯 중 하나
const GUEST_FACES := {
	"퇴근한 회사원": "guest_office", "고깃배 선장": "guest_fisher", "등산객": "guest_tourist",
	"민박 손님": "guest_tourist", "물질 마친 해녀": "guest_haenyeo", "학교 마친 학생": "guest_student", "낚시꾼": "guest_fisher",
}
const NAMELESS := ["guest_office", "guest_fisher", "guest_tourist", "guest_haenyeo", "guest_student"]
## 그림이 없을 때 대신 앉는 주민
const TEMP_FACES := ["bokja", "junho", "gyeongja", "mansu", "sundeok"]

static var _cache := {} # id → {"tex": Texture2D, "cuts": [x0, x1, x2, x3]}

## 홀 식당 (2026-11-17 3안): 앉은 그림을 엉덩이 바닥에 맞춘다. seat_k > 0이면 이 노드의 원점이 엉덩이 자리다.
##   back, front: 그림 가운데를 원점에. side: 엉덩이 뒤쪽 끝을 원점에 (의자 뒤쪽 끝에 맞춤)
##   그림마다 발바닥에서 엉덩이 바닥까지 비율 (칸 0 그림 높이 대비, 그림 세션이 눈금으로 잼). 없는 그림은 HIP_DEFAULT
const HIP_UP := {
	"back": {"mansu": 0.20, "sundeok": 0.16, "bokja": 0.18, "junho": 0.16, "gyeongja": 0.18},
	"side": {"mansu": 0.20, "sundeok": 0.20, "bokja": 0.18, "junho": 0.17, "gyeongja": 0.15},
	"front": {"mansu": 0.18, "sundeok": 0.16, "bokja": 0.14, "junho": 0.14, "gyeongja": 0.14},
}
const HIP_DEFAULT := {"back": 0.18, "side": 0.18, "front": 0.15}
var seat_k := 0.0 # 시트 px → 화면 px (홀 식당). 0이면 예전처럼 노드 아래 가운데가 발

var guest_id := ""
var pose := "stand"
var seat := "" # "", "back", "side"
var flip := false
var walk := "" # "", "front", "back", "side": 걷는 중이면 걷기 시트에서 그린다
const WALK_FPS := 7.0
const WALK_SCALE := 1.2
var _t := 0.0
var _pop := 1.0 # 자세가 바뀔 때 살짝 튀는 연출 (0에서 1로)


## 손님 이름(대사 speaker, 주문 손님 이름) → 그림 id. Portraits와 같은 표를 쓴다
static func id_for(name: String) -> String:
	return Portraits.SPEAKERS.get(name, "")


static func sheet_path(id: String) -> String:
	return DIR + "%s_react.png" % id


static func has_sheet(id: String) -> bool:
	return not id.is_empty() and ResourceLoader.exists(sheet_path(id))


static func seat_path(id: String, kind: String) -> String:
	return DIR + "%s_seat_%s.png" % [id, kind]


static func has_seat(id: String, kind: String) -> bool:
	return not id.is_empty() and not kind.is_empty() and ResourceLoader.exists(seat_path(id, kind))


## 앉은 시트 (칸 폭이 같은 4칸)
static func _seat_sheet(id: String, kind: String) -> Dictionary:
	var key := id + "/" + kind
	if _cache.has(key):
		return _cache[key]
	var tex: Texture2D = load(seat_path(id, kind))
	var w := tex.get_width()
	var e := {"tex": tex, "cuts": [0, w / 4, w / 2, w * 3 / 4, w]}
	_cache[key] = e
	return e


## 지금 앉은 그림으로 그리는가
func seated() -> bool:
	return has_seat(guest_id, seat_kind())


## 실제로 쓰는 앉은 시트 종류. 앞모습 시트가 없으면 옆모습으로 대신한다
func seat_kind() -> String:
	if seat == "front" and not has_seat(guest_id, "front"):
		return "side"
	return seat


## 앉은 시트 칸마다 그림이 있는 사각형과 엉덩이 뒤쪽 끝 (홀 식당용)
## {tex, cells: [Rect2], h0: 칸 0 그림 높이, butt: [칸 안 x (오른쪽을 보는 그림의 등 쪽 끝)]}
static func seat_cells(id: String, kind: String) -> Dictionary:
	var key := id + "/" + kind + "/cells"
	if _cache.has(key):
		return _cache[key]
	var tex: Texture2D = load(seat_path(id, kind))
	var img := tex.get_image()
	if img.is_compressed():
		img.decompress()
	var cw := img.get_width() / 4
	var hip: float = HIP_UP.get(kind, {}).get(id, HIP_DEFAULT.get(kind, 0.18))
	var cells := []
	var butt := []
	for i in 4:
		var r := img.get_region(Rect2i(i * cw, 0, cw, img.get_height())).get_used_rect()
		r.position.x += i * cw
		cells.append(Rect2(r))
	var h0: float = cells[0].size.y
	for i in 4:
		var r: Rect2 = cells[i]
		# 엉덩이 높이 바로 위 몇 줄에서 가장 왼쪽 (등 쪽) 픽셀
		var y := int(r.end.y - hip * h0 - 4.0)
		var bx := r.size.x / 2.0
		for x in range(int(r.position.x), int(r.end.x)):
			var hit := false
			for yy in range(maxi(0, y - 3), y + 1):
				if img.get_pixel(x, yy).a > 0.24:
					hit = true
					break
			if hit:
				bx = x - r.position.x
				break
		butt.append(bx)
	var e := {"tex": tex, "cells": cells, "h0": h0, "hip": hip, "butt": butt}
	_cache[key] = e
	return e


## 홀 식당 앉은 그림의 머리 꼭대기 (원점 기준 위로 몇 px)
func seated_top() -> float:
	if not seated() or seat_k <= 0.0:
		return 0.0
	var e := seat_cells(guest_id, seat_kind())
	var r: Rect2 = e.cells[SEAT_POSES.get(pose, 0)]
	return (r.size.y - float(e.hip) * float(e.h0)) * seat_k


func _draw_hall_seat() -> void:
	var kind := seat_kind()
	var e := seat_cells(guest_id, kind)
	var i: int = SEAT_POSES.get(pose, 0)
	var src: Rect2 = e.cells[i]
	var k := seat_k
	var bounce := 1.0 + 0.06 * sin(_pop * PI) * (1.0 - _pop * 0.5)
	var breathe := 1.0 + 0.012 * sin(_t * 2.4)
	var dw := src.size.x * k
	var dh := src.size.y * k * breathe * bounce
	var hip := float(e.hip) * float(e.h0) * k
	# 그림 왼쪽 끝 (뒤집기 전 좌표). side는 등 쪽 끝을 원점에, 나머지는 가운데를
	var x0 := -dw / 2.0
	if seat == "side":
		x0 = -float(e.butt[i]) * k
	if flip:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(-1, 1))
	draw_texture_rect_region(e.tex, Rect2(x0, hip - dh, dw, dh), src)
	draw_set_transform_matrix(Transform2D.IDENTITY)


## 열마다 그림이 있는 정도(알파 합)에서 세 칸 경계를 찾는다. [0, a, b, 너비]
static func find_cuts(cols: PackedFloat32Array) -> Array:
	return find_cuts_n(cols, 3)


## n칸 시트의 경계: k/n 근처(그림 너비의 CUT_SEARCH 안)에서 가장 빈 열. [0, ..., 너비]
static func find_cuts_n(cols: PackedFloat32Array, n: int) -> Array:
	var w := cols.size()
	var cuts := [0]
	for k in range(1, n):
		var mid := int(w * k / float(n))
		var r := int(w * CUT_SEARCH * 3.0 / n)
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


static func walk_path(id: String) -> String:
	return DIR + id + "_walk.png"


static func has_walk(id: String) -> bool:
	return id != "" and ResourceLoader.exists(walk_path(id))


## 걷기 칸: 앞 0·1, 뒤 2·3, 옆 4~7
static func walk_frame(dir: String, t: float) -> int:
	match dir:
		"front":
			return int(t * WALK_FPS * 0.5) % 2
		"back":
			return 2 + int(t * WALK_FPS * 0.5) % 2
	return 4 + int(t * WALK_FPS) % 4


func _draw_walk() -> void:
	# 지도 걷기(MapWalker)와 같은 시트 캐시를 쓴다 (칸 경계도 가장 빈 열에서 찾음)
	var e := MapWalker._sheet(guest_id)
	var tex: Texture2D = e.tex
	var f := walk_frame(walk, _t)
	var src := Rect2(e.cuts[f], 0, e.cuts[f + 1] - e.cuts[f], tex.get_height())
	# 걷기 시트는 칸 위 여백이 커서 서 있는 그림과 키를 맞추려고 조금 키운다
	var k := size.y / src.size.y * WALK_SCALE
	var dw := src.size.x * k
	var dh := src.size.y * k
	if flip:
		draw_set_transform(Vector2(size.x, 0), 0.0, Vector2(-1, 1))
	draw_texture_rect_region(tex, Rect2(size.x / 2.0 - dw / 2.0, size.y - dh, dw, dh), src)
	draw_set_transform_matrix(Transform2D.IDENTITY)


func _draw() -> void:
	if walk != "" and has_walk(guest_id):
		_draw_walk()
		return
	var sit := seated()
	if sit and seat_k > 0.0:
		_draw_hall_seat()
		return
	if not sit and not has_sheet(guest_id):
		return
	var e := _seat_sheet(guest_id, seat_kind()) if sit else _sheet(guest_id)
	var tex: Texture2D = e.tex
	var i: int = SEAT_POSES.get(pose, 0) if sit else POSES.get(pose, 0)
	var x0: int = e.cuts[i]
	var x1: int = e.cuts[i + 1]
	var src := Rect2(x0, 0, x1 - x0, tex.get_height())
	# 칸 높이를 노드 높이에 맞추고 발을 아래 가운데에. 숨쉬기와 자세가 바뀔 때 통 튀기
	var k := SEAT_SCALE * size.y / STAND_H if sit else size.y / src.size.y
	var bounce := 1.0 + 0.08 * sin(_pop * PI) * (1.0 - _pop * 0.5)
	var breathe := 1.0 + 0.012 * sin(_t * 2.4)
	var dw := src.size.x * k
	var dh := src.size.y * k * breathe * bounce
	if flip:
		draw_set_transform(Vector2(size.x, 0), 0.0, Vector2(-1, 1))
	draw_texture_rect_region(tex, Rect2(size.x / 2.0 - dw / 2.0, size.y - dh, dw, dh), src)
	draw_set_transform_matrix(Transform2D.IDENTITY)


## 손님 이름 → 그림 id. 이름 없는 손님 그림이 있으면 그것, 없으면 주민 그림으로 대신
static func face_for(name: String, i := 0) -> String:
	var id: String = GUEST_FACES.get(name, NAMELESS[absi(hash(name) + i) % NAMELESS.size()])
	if GuestSD.has_sheet(id):
		return id
	return TEMP_FACES[absi(hash(name) + i) % TEMP_FACES.size()]


## 걷는 방향 → 걷기 시트 칸 (앞 0·1, 뒤 2·3, 옆 4~7). 왼쪽으로 걸으면 그리는 쪽에서 뒤집는다
static func walk_cell(dir: Vector2, t: float) -> int:
	if absf(dir.x) >= absf(dir.y):
		return 4 + int(t * WALK_FPS) % 4
	if dir.y < 0.0:
		return 2 + int(t * WALK_FPS * 0.5) % 2
	return int(t * WALK_FPS * 0.5) % 2
