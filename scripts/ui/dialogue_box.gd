class_name DialogueBox
extends PanelContainer
## 화면 아래쪽 대사창. 글자가 한 자씩 나오고, 클릭이나 Enter로 넘긴다.
## lines 형식: [{"speaker": "순덕", "text": "{shop|이/가}라..."}]
## speaker와 text 안의 {player}, {shop|이/가} 같은 템플릿은 GameState.line()으로 바뀐다.

signal finished

const CHARS_PER_SEC := 28.0

var _lines: Array = []
var _index := -1
var _speaker: Label
var _text: Label
var _next_mark: Label
var _tween: Tween


func _ready() -> void:
	add_theme_stylebox_override("panel", UiKit.box(Color(UiKit.NAVY_DEEP, 0.92), 16, UiKit.MUSTARD, 2, 24))
	set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	offset_left = 60
	offset_right = -60
	offset_top = -210
	offset_bottom = -30
	mouse_filter = Control.MOUSE_FILTER_STOP

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	add_child(v)
	_speaker = UiKit.label("", UiKit.SIZE_BODY, UiKit.MUSTARD)
	v.add_child(_speaker)
	_text = UiKit.label("", 26, UiKit.CREAM)
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(_text)
	_next_mark = UiKit.label("▼", UiKit.SIZE_SMALL, UiKit.MUSTARD, HORIZONTAL_ALIGNMENT_RIGHT)
	v.add_child(_next_mark)
	hide()


func play(lines: Array) -> void:
	_lines = lines
	_index = -1
	show()
	UiKit.fade_in(self, 0.3)
	_advance()


func _advance() -> void:
	_index += 1
	if _index >= _lines.size():
		hide()
		finished.emit()
		return
	var line: Dictionary = _lines[_index]
	_speaker.text = GameState.line(line.get("speaker", ""))
	_speaker.visible = not _speaker.text.is_empty()
	_text.text = GameState.line(line.get("text", ""))
	_text.visible_ratio = 0.0
	_next_mark.modulate.a = 0.0
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_text, "visible_ratio", 1.0, max(0.2, _text.text.length() / CHARS_PER_SEC))
	_tween.tween_property(_next_mark, "modulate:a", 1.0, 0.2)


func _on_proceed() -> void:
	if not visible:
		return
	if _text.visible_ratio < 1.0:
		_tween.kill()
		_text.visible_ratio = 1.0
		_next_mark.modulate.a = 1.0
	else:
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
