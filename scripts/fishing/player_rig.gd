class_name PlayerRig
extends Control
## 낚시하는 SD 주인공(뒷모습)을 동작 프레임 + 낚싯대 그림으로 조립해서 그린다.
##
## 그림
##   몸: assets/art/sd/back_01~12.png (사용자가 준 SD 동작 시트 뒷모습을 tools/slice_grid.py로 자름)
##     01 차렷  02 기본  03 힘 모으기  04 머리 뒤로 넘김  05 던지기  06 던진 뒤
##     07 콧노래(♪)  08 입질 놀람(!!!)  09 감기  10 버티기(땀)  11 크게 버티기  12 만세
##   낚싯대: 바다 한 접시 장비 그림. 대 몸통 blank-n(낚싯대 단계) 위에 밑동+릴 butt-n(릴 단계)
##     GearDB.BLANK_LOOK, BUTT_LOOK 숫자로 이어 붙인다. 대 몸통은 물고기가 당기면 휜다(bend)
## 손은 프레임마다 위치가 달라서 HANDS 표에 프레임 크기 대비 비율로 적었다.
## 낚싯대를 먼저 그리고 몸을 나중에 그려서 주먹이 손잡이를 쥔 것처럼 보이게 한다.

const FRAME_ART := "sd/back_%02d"
const FRAME_COUNT := 12
## 프레임별 오른손(낚싯대 쥔 손) 위치. 프레임 크기 대비 비율
const HANDS := {
	1: Vector2(0.826, 0.682), 2: Vector2(0.810, 0.635), 3: Vector2(0.826, 0.481),
	4: Vector2(0.858, 0.363), 5: Vector2(0.826, 0.505), 6: Vector2(0.864, 0.505),
	7: Vector2(0.794, 0.612), 8: Vector2(0.794, 0.612), 9: Vector2(0.794, 0.528),
	10: Vector2(0.729, 0.481), 11: Vector2(0.664, 0.469), 12: Vector2(0.761, 0.209),
}
## 자세 이름 → 프레임
const POSES := {
	"stand": 1, "idle": 2, "charge": 3, "charge_full": 4, "cast": 5, "cast_end": 6,
	"wait": 2, "hum": 7, "bite": 8, "reel": 9, "strain": 10, "strain_hard": 11, "cheer": 12, "fail": 1,
}
const ROD_LENGTH := 470.0 # 화면에서 낚싯대 전체 길이 (px, 밑동 끝에서 대 끝까지)
const BEND_MAX := 0.30 # 최대로 휠 때 대 끝이 옆으로 가는 정도 (대 몸통 길이 대비)
const BEND_DROP := 0.16 # 크게 휠 때 대 끝이 수면 쪽(화면 아래)으로 꺾이는 정도
const BLANK_SEGMENTS := 16

var rod_id := GearDB.DEFAULT_ROD
var reel_id := GearDB.DEFAULT_REEL
var pose := "idle"
## 낚싯대를 든 높이 (도). 뒤에서 보는 시점이라 화면 회전이 아니라 원근으로 표현한다.
##   0: 바다 쪽으로 수평 (화면에서는 짧게 보임)  45: 찌를 보는 기본 자세
##   90: 하늘로 수직 (가장 길게 보임)  120 이상: 머리 뒤로 넘김 (캐스팅 준비)
var pitch := 45.0
## 낚싯대가 오른쪽으로 벌어진 정도 (도)
var roll := 22.0
## 몸 기울기 (도)
var lean := 0.0
## 대가 휜 정도 0~1과 휘는 쪽 (화면 좌표, 보통 찌나 물고기 위치)
var bend := 0.0
var bend_toward := Vector2.ZERO
## 대 끝 빛 (줄다리기 장력 표시). 알파 0이면 그리지 않는다
var tip_glow := Color(0, 0, 0, 0)

var _frames: Array = []
var _blank_tex: Texture2D
var _butt_tex: Texture2D
var _t := 0.0
var _hum_timer := 4.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# 낚싯대 그림은 2000px 넘는 큰 그림을 4~5배 줄여 그린다. 밉맵 없이 줄이면 무늬가 점박이로 깨진다 (blank, butt 그림은 밉맵을 켜서 가져온다)
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_frames.resize(FRAME_COUNT + 1)
	for i in range(1, FRAME_COUNT + 1):
		var id := FRAME_ART % i
		_frames[i] = load(ArtSlot.art_path(id)) if ArtSlot.has_art(id) else null
	set_gear(rod_id, reel_id)


func set_gear(new_rod: String, new_reel: String) -> void:
	rod_id = new_rod
	reel_id = new_reel
	var b := GearDB.blank_art(rod_id)
	var u := GearDB.butt_art(reel_id)
	_blank_tex = load(ArtSlot.art_path(b)) if ArtSlot.has_art(b) else null
	_butt_tex = load(ArtSlot.art_path(u)) if ArtSlot.has_art(u) else null
	queue_redraw()


## 몸 그림 비율 (가로/세로). 크기를 정할 때 쓴다
func body_aspect() -> float:
	var tex: Texture2D = _frames[2] if _frames.size() > 2 else null
	return tex.get_width() / float(tex.get_height()) if tex else 0.7


func _process(delta: float) -> void:
	_t += delta
	# 찌를 보며 기다릴 때 가끔 콧노래
	if pose == "wait":
		_hum_timer -= delta
		if _hum_timer < -1.4:
			_hum_timer = randf_range(5.0, 9.0)
	queue_redraw()


func frame() -> int:
	var p := pose
	if p == "wait" and _hum_timer < 0.0:
		p = "hum"
	return POSES.get(p, 2)


## 몸 기울기와 숨쉬기를 적용한 변환 (발 가운데를 중심으로)
func _body_xform() -> Transform2D:
	var pivot := Vector2(size.x / 2.0, size.y)
	var breathe := 1.0
	if pose in ["idle", "wait", "stand"]:
		breathe = 1.0 + 0.012 * sin(_t * 2.4)
	return Transform2D(deg_to_rad(lean), Vector2(1.0, breathe), 0.0, pivot) * Transform2D(0.0, -pivot)


func _hand() -> Vector2:
	return _body_xform() * (HANDS.get(frame(), HANDS[2]) * size)


## 화면에서 낚싯대가 향하는 각도 (라디안). 머리 뒤로 넘기면 끝이 살짝 몸쪽으로 돌아온다
func _screen_angle() -> float:
	var back := maxf(pitch - 90.0, 0.0)
	return deg_to_rad(-90.0 + roll + lean + back * 1.3)


## 원근: 바다 쪽으로 누울수록, 머리 뒤로 넘길수록 화면에서 짧아 보인다
func _foreshorten() -> float:
	return 0.32 + 0.68 * sin(deg_to_rad(clampf(pitch, 0.0, 180.0)))


## 낚싯대 그림 배치 계산. 그림이 없으면 빈 Dictionary
func _geom() -> Dictionary:
	if _blank_tex == null or _butt_tex == null:
		return {}
	var bl: Array = GearDB.BLANK_LOOK[GearDB.rod(rod_id).tier - 1]
	var bu: Array = GearDB.BUTT_LOOK[GearDB.reel(reel_id).tier - 1]
	var bw := float(_butt_tex.get_width())
	var bh := float(_butt_tex.get_height())
	var kw := float(_blank_tex.get_width())
	var kh := float(_blank_tex.get_height())
	var sb: float = bu[1] / bl[1] # 대 몸통 그림 px → 밑동 그림 px
	var s := ROD_LENGTH / (bh + kh * sb) # 그림 px → 화면 px
	var axis := Vector2.from_angle(_screen_angle())
	var right := Vector2(-axis.y, axis.x)
	var fore := _foreshorten()
	var hand := _hand()
	var grip_y := GearDB.BUTT_GRIP_Y * bh
	var tube_x: float = bu[0] * bw
	# 휘는 방향: 대 끝에서 본 목표가 대의 오른쪽인지 왼쪽인지
	var blank_len := kh * sb * s * fore
	var side := 1.0
	if bend_toward != Vector2.ZERO:
		var local_target := get_global_transform().affine_inverse() * bend_toward
		side = signf((local_target - hand).dot(right))
		if side == 0.0:
			side = 1.0
	return {
		"bw": bw, "bh": bh, "kw": kw, "kh": kh, "sb": sb, "s": s, "axis": axis, "right": right,
		"fore": fore, "hand": hand, "grip_y": grip_y, "tube_x": tube_x, "blank_cx": bl[0] * kw,
		"bend_vec": (right * side * BEND_MAX + Vector2(0, BEND_DROP) * clampf(bend, 0.0, 1.0)) * clampf(bend, 0.0, 1.0) * blank_len,
	}


## 밑동 그림 좌표 → 이 노드 좌표
func _butt_point(g: Dictionary, ix: float, iy: float) -> Vector2:
	return g.hand + g.right * (ix - g.tube_x) * g.s + g.axis * (g.grip_y - iy) * g.s * g.fore


## 대 몸통 그림 좌표 → 이 노드 좌표 (휨 포함)
func _blank_point(g: Dictionary, jx: float, jy: float) -> Vector2:
	var u: float = (g.kh - jy) / g.kh
	var ix: float = g.tube_x + (jx - g.blank_cx) * g.sb
	var iy: float = -(g.kh - jy) * g.sb
	return _butt_point(g, ix, iy) + g.bend_vec * u * u


## 낚싯대 끝 (이 노드 좌표)
func tip_local() -> Vector2:
	var g := _geom()
	if g.is_empty():
		var axis := Vector2.from_angle(_screen_angle())
		return _hand() + axis * ROD_LENGTH * 0.8 * _foreshorten()
	return _blank_point(g, g.blank_cx, 0.0)


## 낚싯대 끝의 화면 좌표. 낚싯줄이 여기서 나간다.
func tip_global() -> Vector2:
	return get_global_transform() * tip_local()


func _draw() -> void:
	var g := _geom()
	if g.is_empty():
		draw_line(_hand(), tip_local(), Color("3a3a42"), 4.0, true)
	else:
		_draw_blank(g)
		_draw_tip_glow(g)
		# 밑동+릴: 그림을 대 방향으로 돌리고 길이만 원근으로 줄인다
		var origin := _butt_point(g, 0.0, 0.0)
		draw_set_transform_matrix(Transform2D(g.right * g.s, -g.axis * g.s * g.fore, origin))
		draw_texture(_butt_tex, Vector2.ZERO)
		draw_set_transform_matrix(Transform2D.IDENTITY)

	# 몸은 맨 나중에 그려서 손이 낚싯대 손잡이를 쥔 것처럼 보이게 한다
	var tex: Texture2D = _frames[frame()] if _frames.size() > frame() else null
	draw_set_transform_matrix(_body_xform())
	if tex:
		draw_texture_rect(tex, Rect2(Vector2.ZERO, size), false)
	else:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.6, 0.6, 0.6, 0.35))
	draw_set_transform_matrix(Transform2D.IDENTITY)


## 대 몸통을 여러 토막으로 나눠 휜 모양대로 그린다
func _draw_blank(g: Dictionary) -> void:
	var white := PackedColorArray([Color.WHITE, Color.WHITE, Color.WHITE, Color.WHITE])
	for k in BLANK_SEGMENTS:
		var y0: float = g.kh * (1.0 - float(k) / BLANK_SEGMENTS)
		var y1: float = g.kh * (1.0 - float(k + 1) / BLANK_SEGMENTS)
		var pts := PackedVector2Array([
			_blank_point(g, 0.0, y0), _blank_point(g, g.kw, y0),
			_blank_point(g, g.kw, y1), _blank_point(g, 0.0, y1),
		])
		var uvs := PackedVector2Array([
			Vector2(0, y0 / g.kh), Vector2(1, y0 / g.kh), Vector2(1, y1 / g.kh), Vector2(0, y1 / g.kh),
		])
		draw_polygon(pts, white, uvs, _blank_tex)


## 대 끝 빛: 끝에서 3분의 1을 따라 빛나는 선과 끝의 동그란 빛 (장력: 청록 알맞음, 빨강 위험)
func _draw_tip_glow(g: Dictionary) -> void:
	if tip_glow.a <= 0.01:
		return
	var pts := PackedVector2Array()
	for k in 9:
		pts.append(_blank_point(g, g.blank_cx, g.kh * 0.34 * (1.0 - k / 8.0)))
	draw_polyline(pts, Color(tip_glow, tip_glow.a * 0.3), 11.0, true)
	draw_polyline(pts, Color(tip_glow, tip_glow.a * 0.85), 4.5, true)
	var tip := pts[pts.size() - 1]
	for i in 4:
		draw_circle(tip, 26.0 - i * 6.0, Color(tip_glow, tip_glow.a * (0.1 + i * 0.1)))
	draw_circle(tip, 5.0, Color(tip_glow.lightened(0.5), tip_glow.a))
