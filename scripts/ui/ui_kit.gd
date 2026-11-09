class_name UiKit
extends RefCounted
## 화면 전체에서 같은 색, 글자 크기, 버튼 모양을 쓰기 위한 도우미.

const CREAM := Color("f6efe0")
const PAPER := Color("fbf7ee")
const INK := Color("2b2a28")
const INK_SOFT := Color("6b665e")
const NAVY := Color("1f3a5f")
const NAVY_DEEP := Color("13243b")
const MUSTARD := Color("e0ac4a")
const CORAL := Color("f08a6c")
const TEAL := Color("2f8f8a")
const WOOD := Color("7a5134")
const WOOD_DARK := Color("4e321f")
const ERROR := Color("c8553d")

const SIZE_TITLE := 88
const SIZE_HEADING := 40
const SIZE_BODY := 24
const SIZE_SMALL := 18


static func box(bg: Color, radius := 12, border := Color.TRANSPARENT, border_w := 0, pad := 20) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(radius)
	if border_w > 0:
		s.border_color = border
		s.set_border_width_all(border_w)
	s.content_margin_left = pad
	s.content_margin_right = pad
	s.content_margin_top = pad
	s.content_margin_bottom = pad
	return s


static func label(text: String, size := SIZE_BODY, color := INK, align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = align
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


static func shadowed(l: Label, shadow := Color(0, 0, 0, 0.35), offset := 3) -> Label:
	l.add_theme_color_override("font_shadow_color", shadow)
	l.add_theme_constant_override("shadow_offset_x", offset)
	l.add_theme_constant_override("shadow_offset_y", offset)
	return l


static func button(text: String, primary := true) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(170, 54)
	b.focus_mode = Control.FOCUS_ALL
	b.add_theme_font_size_override("font_size", 22)
	var base := NAVY if primary else CREAM
	var fg := CREAM if primary else NAVY
	b.add_theme_stylebox_override("normal", box(base, 27, NAVY, 2, 10))
	b.add_theme_stylebox_override("hover", box(base.lightened(0.12), 27, NAVY, 2, 10))
	b.add_theme_stylebox_override("pressed", box(base.darkened(0.15), 27, NAVY, 2, 10))
	b.add_theme_stylebox_override("focus", box(Color.TRANSPARENT, 27, MUSTARD, 3, 10))
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(state, fg)
	return b


static func line_edit(placeholder: String, size := 32, color := INK, max_len := 0) -> LineEdit:
	var e := LineEdit.new()
	e.placeholder_text = placeholder
	e.max_length = max_len
	e.alignment = HORIZONTAL_ALIGNMENT_CENTER
	e.add_theme_font_size_override("font_size", size)
	e.add_theme_color_override("font_color", color)
	e.add_theme_color_override("font_placeholder_color", Color(color, 0.4))
	e.add_theme_color_override("caret_color", color)
	var underline := StyleBoxFlat.new()
	underline.bg_color = Color.TRANSPARENT
	underline.border_color = Color(color, 0.6)
	underline.border_width_bottom = 2
	underline.content_margin_top = 6
	underline.content_margin_bottom = 6
	e.add_theme_stylebox_override("normal", underline)
	var focused := underline.duplicate()
	focused.border_color = MUSTARD
	focused.border_width_bottom = 3
	e.add_theme_stylebox_override("focus", focused)
	return e


## 장면이 열릴 때 부드럽게 나타나게 한다.
static func fade_in(node: CanvasItem, duration := 0.6) -> void:
	node.modulate.a = 0.0
	node.create_tween().tween_property(node, "modulate:a", 1.0, duration)


## 화면을 어둡게 한 뒤 다음 장면으로 넘어간다.
static func go_to(from: Node, scene_path: String, duration := 0.5) -> void:
	var tw := from.create_tween()
	tw.tween_property(from, "modulate:a", 0.0, duration)
	tw.tween_callback(func(): from.get_tree().change_scene_to_file(scene_path))
