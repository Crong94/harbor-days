class_name ArtSlot
extends Control
## 그림이 들어갈 자리. res://assets/art/<art_id>.png 파일이 있으면 그 그림을 보여 주고,
## 없으면 회색 빈칸에 이름을 적어 둔다. 그림은 사용자에게 받아서 넣는다 (docs/그림_요청_목록.md).

const ART_DIR := "res://assets/art/"

var art_id := ""
var label_text := ""
var flip_h := false
## true면 칸을 꽉 채우도록 그림을 키우고 넘치는 부분은 잘라 낸다 (배경, 지도)
var cover := false
var _tex: Texture2D


static func make(id: String, label: String, min_size: Vector2) -> ArtSlot:
	var s := ArtSlot.new()
	s.art_id = id
	s.label_text = label
	s.custom_minimum_size = min_size
	return s


static func has_art(id: String) -> bool:
	return ResourceLoader.exists(ART_DIR + id + ".png") or ResourceLoader.exists(ART_DIR + id + ".jpg")


## 그림 파일 경로 (png 우선, 없으면 jpg)
static func art_path(id: String) -> String:
	var png := ART_DIR + id + ".png"
	return png if ResourceLoader.exists(png) else ART_DIR + id + ".jpg"


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if has_art(art_id):
		_tex = load(art_path(art_id))
	queue_redraw()


func set_art(id: String, label: String) -> void:
	art_id = id
	label_text = label
	_tex = load(art_path(id)) if has_art(id) else null
	queue_redraw()


## 그림이 실제로 그려지는 영역 (비율 유지로 생기는 여백 제외). 그림이 없으면 칸 전체.
func content_rect() -> Rect2:
	if not _tex:
		return Rect2(Vector2.ZERO, size)
	var ts := _tex.get_size()
	var k := maxf(size.x / ts.x, size.y / ts.y) if cover else minf(size.x / ts.x, size.y / ts.y)
	var ds := ts * k
	return Rect2((size - ds) / 2.0, ds)


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	if _tex:
		# 비율을 유지하며 칸 안에 맞춘다
		if flip_h:
			draw_set_transform(Vector2(size.x, 0), 0.0, Vector2(-1, 1))
		draw_texture_rect(_tex, content_rect(), false)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		return
	# 그림이 오기 전 빈 자리: 옅은 점선 느낌의 둥근 칸과 작은 안내
	draw_style_box(UiKit.box(Color(1, 1, 1, 0.07), UiKit.RADIUS_MD, Color(1, 1, 1, 0.28), 2, 0), r)
	var font := UiKit.font("semibold")
	var small := UiKit.font("regular")
	var lines := [[label_text, font, 17, Color(1, 1, 1, 0.85)], ["그림 준비 중 · " + art_id, small, 13, Color(1, 1, 1, 0.55)]]
	var y := size.y / 2.0 - 18.0
	for line in lines:
		var w: float = line[1].get_string_size(line[0], HORIZONTAL_ALIGNMENT_LEFT, -1, line[2]).x
		draw_string(line[1], Vector2((size.x - w) / 2.0, y + line[2]), line[0], HORIZONTAL_ALIGNMENT_LEFT, -1, line[2], line[3])
		y += line[2] + 10.0
