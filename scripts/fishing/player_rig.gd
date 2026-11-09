class_name PlayerRig
extends Control
## 낚시하는 SD 주인공을 몸, 낚싯대, 릴 세 장으로 조립해서 그린다.
## 장비를 바꾸면 set_gear()로 낚싯대와 릴 그림만 바뀐다.
##
## 그림 (사용자에게 받음)
##   player_sd_body.png : 낚싯대 없이 오른손으로 무언가를 쥔 자세의 SD 뒷모습
##   rod_<id>.png, reel_<id>.png : GearDB 참고
## 그림이 없으면 몸은 회색 칸, 낚싯대는 선, 릴은 원으로 대신 보여 준다.

const BODY_ART := "player_sd_body"
## 몸 그림 크기 대비 오른손 위치 (그림이 오면 맞춘다)
const HAND := Vector2(0.74, 0.5)
const ROD_LENGTH := 300.0 # 화면에서 낚싯대 길이 (px)
const ROD_THICK := 26.0 # 낚싯대 그림을 그릴 높이 (px)
const REEL_SIZE := 46.0

var rod_id := GearDB.DEFAULT_ROD
var reel_id := GearDB.DEFAULT_REEL
## 낚싯대 각도 (도). 0은 오른쪽 수평, -90은 수직 위
var rod_angle := -70.0
## 몸 기울기 (도)
var lean := 0.0

var _body_tex: Texture2D
var _rod_tex: Texture2D
var _reel_tex: Texture2D


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ArtSlot.has_art(BODY_ART):
		_body_tex = load(ArtSlot.art_path(BODY_ART))
	set_gear(rod_id, reel_id)


func set_gear(new_rod: String, new_reel: String) -> void:
	rod_id = new_rod
	reel_id = new_reel
	_rod_tex = load(ArtSlot.art_path("rod_" + rod_id)) if ArtSlot.has_art("rod_" + rod_id) else null
	_reel_tex = load(ArtSlot.art_path("reel_" + reel_id)) if ArtSlot.has_art("reel_" + reel_id) else null
	queue_redraw()


func _process(_delta: float) -> void:
	queue_redraw()


## 몸 기울기를 적용한 변환 (발 가운데를 중심으로 기운다)
func _body_xform() -> Transform2D:
	var pivot := Vector2(size.x / 2.0, size.y)
	return Transform2D(deg_to_rad(lean), pivot) * Transform2D(0.0, -pivot)


func _hand() -> Vector2:
	return _body_xform() * (HAND * size)


func _rod_dir() -> Vector2:
	return Vector2.from_angle(deg_to_rad(rod_angle + lean))


## 낚싯대 위 비율 위치(0 손잡이 끝 ~ 1 낚싯대 끝)를 이 노드 좌표로
func _rod_point(t: float) -> Vector2:
	var r := GearDB.rod(rod_id)
	return _hand() + _rod_dir() * (t - r.grip) * ROD_LENGTH


## 낚싯대 끝의 화면 좌표. 낚싯줄이 여기서 나간다.
func tip_global() -> Vector2:
	return get_global_transform() * _rod_point(GearDB.rod(rod_id).tip)


func _draw() -> void:
	# 몸
	draw_set_transform_matrix(_body_xform())
	if _body_tex:
		draw_texture_rect(_body_tex, Rect2(Vector2.ZERO, size), false)
	else:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.6, 0.6, 0.6, 0.35))
		draw_rect(Rect2(Vector2.ZERO, size), Color(1, 1, 1, 0.6), false, 2.0)
		var font := get_theme_default_font()
		draw_string(font, Vector2(8, size.y * 0.8), "SD 몸 그림 필요", HORIZONTAL_ALIGNMENT_LEFT, size.x - 16, 15, Color(1, 1, 1, 0.9))
	draw_set_transform_matrix(Transform2D.IDENTITY)

	# 낚싯대
	var r := GearDB.rod(rod_id)
	var start := _rod_point(0.0)
	var ang := deg_to_rad(rod_angle + lean)
	if _rod_tex:
		draw_set_transform(start, ang)
		draw_texture_rect(_rod_tex, Rect2(0, -ROD_THICK / 2.0, ROD_LENGTH, ROD_THICK), false)
		draw_set_transform_matrix(Transform2D.IDENTITY)
	else:
		draw_line(start, _rod_point(r.tip), r.color, 4.0, true)
		draw_line(start, _rod_point(r.seat + 0.06), Color("2b2a28"), 7.0, true) # 손잡이

	# 릴 (낚싯대 아래쪽에 매달림)
	var l := GearDB.reel(reel_id)
	var seat := _rod_point(r.seat)
	var down := _rod_dir().orthogonal() # 낚싯대 아래 방향
	if down.y < 0:
		down = -down
	if _reel_tex:
		draw_set_transform(seat, ang)
		var ts := _reel_tex.get_size()
		var h := REEL_SIZE
		var w := h * ts.x / ts.y
		draw_texture_rect(_reel_tex, Rect2(-w / 2.0, 0, w, h), false)
		draw_set_transform_matrix(Transform2D.IDENTITY)
	else:
		draw_line(seat, seat + down * 12.0, Color("2b2a28"), 3.0)
		draw_circle(seat + down * 20.0, 10.0, l.color)
		draw_circle(seat + down * 20.0, 4.0, Color("2b2a28"))
