class_name ArtSlot
extends Control
## 그림이 들어갈 자리. res://assets/art/<art_id>.png 파일이 있으면 그 그림을 보여 주고,
## 없으면 회색 빈칸에 이름을 적어 둔다. 그림은 사용자에게 받아서 넣는다 (docs/그림_요청_목록.md).

const ART_DIR := "res://assets/art/"

var art_id := ""
var label_text := ""
var flip_h := false
## true면 칸을 빈틈없이 채우고 넘치는 부분은 잘라 낸다 (지도처럼 화면을 꽉 채울 그림)
var cover := false
## cover일 때 어느 쪽을 남길지. (0.5, 0.5)는 가운데, y가 0이면 위쪽을 남긴다
var cover_focus := Vector2(0.5, 0.5)
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
	clip_contents = cover
	if has_art(art_id):
		_tex = load(art_path(art_id))
	queue_redraw()


func set_art(id: String, label: String) -> void:
	art_id = id
	label_text = label
	_tex = load(art_path(id)) if has_art(id) else null
	queue_redraw()


## 그림이 실제로 그려지는 영역 (비율 유지로 생기는 여백 제외). 그림이 없으면 칸 전체.
## cover면 칸보다 클 수 있다 (잘려 나간 부분까지 포함한 그림 전체 영역).
func content_rect() -> Rect2:
	if not _tex:
		return Rect2(Vector2.ZERO, size)
	return fit_rect(_tex.get_size(), size, cover, cover_focus)


## 그림 크기 ts를 칸 크기 box에 맞춘 영역. fill이면 꽉 채우고, 아니면 칸 안에 다 들어가게.
static func fit_rect(ts: Vector2, box: Vector2, fill := false, focus := Vector2(0.5, 0.5)) -> Rect2:
	var k := maxf(box.x / ts.x, box.y / ts.y) if fill else minf(box.x / ts.x, box.y / ts.y)
	var ds := ts * k
	return Rect2((box - ds) * focus, ds)


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	if _tex:
		# 비율을 유지하며 칸 안에 맞춘다
		if flip_h:
			draw_set_transform(Vector2(size.x, 0), 0.0, Vector2(-1, 1))
		draw_texture_rect(_tex, content_rect(), false)
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
