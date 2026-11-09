class_name ArtSlot
extends Control
## 그림이 들어갈 자리. res://assets/art/<art_id>.png 파일이 있으면 그 그림을 보여 주고,
## 없으면 회색 빈칸에 이름을 적어 둔다. 그림은 사용자에게 받아서 넣는다 (docs/그림_요청_목록.md).

const ART_DIR := "res://assets/art/"

var art_id := ""
var label_text := ""
var flip_h := false
var _tex: Texture2D


static func make(id: String, label: String, min_size: Vector2) -> ArtSlot:
	var s := ArtSlot.new()
	s.art_id = id
	s.label_text = label
	s.custom_minimum_size = min_size
	return s


static func has_art(id: String) -> bool:
	return ResourceLoader.exists(ART_DIR + id + ".png")


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if has_art(art_id):
		_tex = load(ART_DIR + art_id + ".png")
	queue_redraw()


func set_art(id: String, label: String) -> void:
	art_id = id
	label_text = label
	_tex = load(ART_DIR + id + ".png") if has_art(id) else null
	queue_redraw()


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	if _tex:
		# 비율을 유지하며 칸 안에 맞춘다
		var ts := _tex.get_size()
		var k := minf(size.x / ts.x, size.y / ts.y)
		var ds := ts * k
		var pos := (size - ds) / 2.0
		if flip_h:
			draw_set_transform(Vector2(size.x, 0), 0.0, Vector2(-1, 1))
		draw_texture_rect(_tex, Rect2(pos, ds), false)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		return
	draw_rect(r, Color(0.6, 0.6, 0.6, 0.35))
	draw_rect(r, Color(1, 1, 1, 0.6), false, 2.0)
	var font := get_theme_default_font()
	var fs := 16
	var lines := ["그림 필요", label_text, art_id + ".png"]
	var y := size.y / 2.0 - fs * 1.6
	for line in lines:
		var w := font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		draw_string(font, Vector2((size.x - w) / 2.0, y + fs), line, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1, 1, 1, 0.9))
		y += fs * 1.4
