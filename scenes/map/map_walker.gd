class_name MapWalker
extends Control
## 지도 위를 걷는 주민 한 명 (규칙과 길은 Walkers). 걷기 시트 8칸에서 칸을 골라 그린다. 누르면 tapped.
## 발이 이 노드 아래 가운데에 온다. 칸 경계는 k/8 근처에서 가장 빈 열 (GuestSD.find_cuts_n).

signal tapped(id: String)

const SHEET := "res://assets/art/sd_guest/%s_walk.png"
static var _cache := {}

var walker_id := ""
var cell := 0
var flip := false


static func has_sheet(id: String) -> bool:
	return ResourceLoader.exists(SHEET % id)


static func _sheet(id: String) -> Dictionary:
	if _cache.has(id):
		return _cache[id]
	var tex: Texture2D = load(SHEET % id)
	var img := tex.get_image()
	if img.is_compressed():
		img.decompress()
	var cols := PackedFloat32Array()
	cols.resize(img.get_width())
	for x in img.get_width():
		var s := 0.0
		for y in range(0, img.get_height(), 6):
			s += img.get_pixel(x, y).a
		cols[x] = s
	var e := {"tex": tex, "cuts": GuestSD.find_cuts_n(cols, 8)}
	_cache[id] = e
	return e


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		tapped.emit(walker_id)


func _draw() -> void:
	if not has_sheet(walker_id):
		return
	var e := _sheet(walker_id)
	var tex: Texture2D = e.tex
	var x0: int = e.cuts[cell]
	var x1: int = e.cuts[cell + 1]
	var src := Rect2(x0, 0, x1 - x0, tex.get_height())
	var k := size.y / src.size.y
	var dw := src.size.x * k
	# 발밑 그림자
	draw_set_transform(Vector2(size.x / 2.0, size.y - 2.0), 0.0, Vector2(1.0, 0.35))
	draw_circle(Vector2.ZERO, dw * 0.28, Color(0, 0, 0, 0.18))
	draw_set_transform_matrix(Transform2D.IDENTITY)
	if flip:
		draw_set_transform(Vector2(size.x, 0), 0.0, Vector2(-1, 1))
	draw_texture_rect_region(tex, Rect2(size.x / 2.0 - dw / 2.0, 0, dw, size.y), src)
	draw_set_transform_matrix(Transform2D.IDENTITY)
