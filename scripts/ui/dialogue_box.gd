class_name DialogueBox
extends Control
## 화면 아래쪽 대사창. 유리 패널 위에 말하는 사람 이름표가 붙는다.
## 글자가 한 자씩 나오고, 클릭이나 Enter로 넘긴다.
## lines 형식: [{"speaker": "순덕", "text": "{shop|이/가}라..."}]
## speaker와 text 안의 {player}, {shop|이/가} 같은 템플릿은 GameState.line()으로 바뀐다.
## speaker가 비어 있으면 지문(설명)으로 보고 이름표 없이 조금 흐린 글자로 보여 준다.

signal finished

const CHARS_PER_SEC := 30.0
const SIDE := 20.0
const BOTTOM := 28.0
const HEIGHT := 230.0

var _lines: Array = []
var _index := -1
var _panel: PanelContainer
var _name_tag: PanelContainer
var _name: Label
var _text: Label
var _next_mark: Label
var _tween: Tween
var _t := 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	offset_left = SIDE
	offset_right = -SIDE
	offset_top = -HEIGHT - BOTTOM
	offset_bottom = -BOTTOM
	mouse_filter = Control.MOUSE_FILTER_STOP

	_panel = UiKit.glass_panel(0, UiKit.RADIUS_LG, true)
	var s: StyleBoxFlat = _panel.get_theme_stylebox("panel")
	s.content_margin_left = 28
	s.content_margin_right = 28
	s.content_margin_top = 34
	s.content_margin_bottom = 22
	_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_panel)

	var v := UiKit.vbox(UiKit.SPACE_SM)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(v)
	_text = UiKit.paragraph("", "body", UiKit.FOAM)
	_text.add_theme_font_size_override("font_size", 23)
	_text.add_theme_constant_override("line_spacing", 8)
	_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(_text)
	_next_mark = UiKit.text("▼", "caption", UiKit.SUN, HORIZONTAL_ALIGNMENT_RIGHT)
	v.add_child(_next_mark)

	# 이름표: 패널 왼쪽 위에 걸친 산호색 알약
	_name_tag = PanelContainer.new()
	var ns := UiKit.box(UiKit.CORAL, UiKit.RADIUS_PILL, Color.TRANSPARENT, 0, 0)
	ns.content_margin_left = 18
	ns.content_margin_right = 18
	ns.content_margin_top = 6
	ns.content_margin_bottom = 7
	UiKit.elevate(ns, 1)
	_name_tag.add_theme_stylebox_override("panel", ns)
	_name_tag.position = Vector2(22, -18)
	_name_tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_name = UiKit.text("", "title", Color.WHITE)
	_name.add_theme_font_size_override("font_size", 19)
	_name_tag.add_child(_name)
	add_child(_name_tag)
	hide()


func _process(delta: float) -> void:
	if not visible:
		return
	_t += delta
	# 글자가 다 나오면 다음 표시가 숨 쉬듯 깜박인다
	_next_mark.modulate.a = (0.45 + 0.55 * absf(sin(_t * 3.0))) if _text.visible_ratio >= 1.0 else 0.0


func play(lines: Array) -> void:
	_lines = lines
	_index = -1
	show()
	UiKit.rise_in(self, 0.0, 14.0)
	_advance()


func _advance() -> void:
	_index += 1
	if _index >= _lines.size():
		hide()
		finished.emit()
		return
	var line: Dictionary = _lines[_index]
	var speaker := GameState.line(line.get("speaker", ""))
	_name.text = speaker
	_name_tag.visible = not speaker.is_empty()
	_text.text = GameState.line(line.get("text", ""))
	# 지문은 흐리게, 대사는 밝게
	_text.add_theme_color_override("font_color", UiKit.FOAM if not speaker.is_empty() else UiKit.FOAM_SOFT)
	_text.visible_ratio = 0.0
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_text, "visible_ratio", 1.0, maxf(0.2, _text.text.length() / CHARS_PER_SEC))


func _on_proceed() -> void:
	if not visible:
		return
	if _text.visible_ratio < 1.0:
		_tween.kill()
		_text.visible_ratio = 1.0
	else:
		Sound.play_sfx("tap", 0.05, -12.0)
		_advance()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		_on_proceed()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		get_viewport().set_input_as_handled()
		_on_proceed()
