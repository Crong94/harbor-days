class_name DialogueBox
extends Control
## 화면 아래쪽 대사창. 유리 패널 위에 말하는 사람 이름표가 붙는다.
## 글자가 한 자씩 나오고, 클릭이나 Enter로 넘긴다.
## lines 형식: [{"speaker": "순덕", "text": "{shop|이/가}라..."}]
## speaker와 text 안의 {player}, {shop|이/가} 같은 템플릿은 GameState.line()으로 바뀐다.
## speaker가 비어 있으면 지문(설명)으로 보고 이름표 없이 조금 흐린 글자로 보여 준다.
## 말하는 사람의 얼굴 일러스트(Portraits)가 있으면 대사창 오른쪽 위에 띄운다. "face": "smile" / "sad"로 표정을 고른다.
## 화면에 그 사람이 이미 크게 서 있는 장면은 on_stage에 그 사람 id를 넣는다 (전부 끄려면 show_portraits = false).

signal finished

const CHARS_PER_SEC := 30.0
const SIDE := 20.0
const BOTTOM := 28.0
const HEIGHT := 230.0
const PORTRAIT := 330.0 # 얼굴 그림 크기 (정사각형 안에 맞춘다)

var show_portraits := true
## 화면에 이미 크게 서 있는 사람 (얼굴 그림 id). 이 사람이 말할 때는 얼굴을 띄우지 않는다
var on_stage: Array = []

var _lines: Array = []
var _index := -1
var _panel: PanelContainer
var _name_tag: VBoxContainer
var _text: Label
var _next_mark: Label
var _tween: Tween
var _t := 0.0
var _portrait: TextureRect
var _portrait_path := ""


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	offset_left = SIDE
	offset_right = -SIDE
	offset_top = -HEIGHT - BOTTOM
	offset_bottom = -BOTTOM
	mouse_filter = Control.MOUSE_FILTER_STOP

	# 얼굴 일러스트: 대사창 오른쪽 위에 아래가 살짝 걸치게
	_portrait = TextureRect.new()
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_portrait.offset_left = -PORTRAIT - 6
	_portrait.offset_right = -6
	_portrait.offset_top = -PORTRAIT + 18
	_portrait.offset_bottom = 18
	_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_portrait.hide()
	add_child(_portrait)

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

	# 이름: 패널 왼쪽 위 가장자리에 걸친 외곽선 글자와 인물 색 밑줄 (알약 상자 없이)
	_name_tag = UiKit.name_label("", Color(0, 0, 0, 0), 33)
	_name_tag.position = Vector2(26, -34)
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
	UiKit.set_name_label(_name_tag, speaker)
	_name_tag.reset_size()
	_name_tag.visible = not speaker.is_empty()
	_show_portrait(str(line.get("speaker", "")), str(line.get("face", "normal")))
	_text.text = GameState.line(line.get("text", ""))
	# 지문은 흐리게, 대사는 밝게
	_text.add_theme_color_override("font_color", UiKit.FOAM if not speaker.is_empty() else UiKit.FOAM_SOFT)
	_text.visible_ratio = 0.0
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_text, "visible_ratio", 1.0, maxf(0.2, _text.text.length() / CHARS_PER_SEC))


## 말하는 사람 얼굴을 보여 준다. 같은 사람이 이어 말하면 그림만 바꾸고, 사람이 바뀌면 살짝 떠오르게
func _show_portrait(speaker: String, face: String) -> void:
	var p := Portraits.path(speaker, face) if show_portraits and not Portraits.SPEAKERS.get(speaker, "") in on_stage else ""
	if p.is_empty():
		_portrait.hide()
		_portrait_path = ""
		return
	var same_person := _portrait.visible and _portrait_path.get_file().get_slice("_", 0) == p.get_file().get_slice("_", 0)
	_portrait.texture = load(p)
	_portrait_path = p
	_portrait.show()
	if not same_person:
		_portrait.modulate.a = 0.0
		var tw := create_tween()
		tw.tween_property(_portrait, "modulate:a", 1.0, 0.2)


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
