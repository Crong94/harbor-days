class_name PlaceScene
extends Control
## 빈 장소 넷(전망대, 분교, 민박, 연구소)의 공통 바탕 (11-25). 규칙은 Places.
## 구성: 맨 위 공통 헤더 / 장소 이름과 나가기 / 말풍선과 오른쪽 일러스트 / 아래 종이 시트(_body를 장소마다 채운다)
## 그림: 배경 bg_<장소 id>. 없으면 나무색 바탕

const MAP_SCENE := "res://scenes/map/map.tscn"
const SHEET_TOP := 372.0

var place := ""
var host := "" # 말하는 사람 (Portraits 이름). 비면 지문
var _header: GameHeader
var _talk: Label
var _face: TextureRect
var _name: Label
var _bubble: PanelContainer
var _body: VBoxContainer


func setup(id: String, speaker: String) -> void:
	place = id
	GameState.current_location = id
	var base := ColorRect.new()
	base.color = UiKit.WOOD_DARK
	base.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(base)
	var art := UiKit.cover_art("bg_" + id)
	if art:
		add_child(art)
	add_child(UiKit.shade([[0.0, 0.45], [0.2, 0.05], [0.4, 0.15], [1.0, 0.45]]))
	_header = GameHeader.new()
	add_child(_header)
	var row := UiKit.hbox(UiKit.SPACE_MD)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	row.offset_left = 22
	row.offset_right = -20
	row.offset_top = GameHeader.BOTTOM + 12.0
	add_child(row)
	var title := UiKit.text(GameState.line(Locations.get_loc(id).name), "h2", UiKit.FOAM)
	UiKit.outlined(title, 10)
	row.add_child(title)
	row.add_child(UiKit.spacer())
	var out := UiKit.game_button("나가기", UiKit.GRAY_DARK)
	out.pressed.connect(leave)
	row.add_child(out)
	_build_talk()
	var sheet := UiKit.note_paper()
	sheet.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sheet.offset_left = 22
	sheet.offset_right = -22
	sheet.offset_top = GameHeader.BOTTOM + SHEET_TOP
	sheet.offset_bottom = -24
	add_child(sheet)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.scroll_deadzone = 8
	sheet.add_child(scroll)
	_body = UiKit.vbox(UiKit.SPACE_MD)
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_body)
	set_host(speaker)
	UiKit.rise_in(sheet, 0.1, 30.0)
	Sound.play_bgm("town")
	UiKit.fade_in(self)


func _build_talk() -> void:
	_face = TextureRect.new()
	_face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_face.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_face.offset_left = -290
	_face.offset_right = -14
	_face.offset_top = GameHeader.BOTTOM + SHEET_TOP - 272.0
	_face.offset_bottom = GameHeader.BOTTOM + SHEET_TOP + 4.0
	_face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_face)
	_bubble = UiKit.glass_panel(22, UiKit.RADIUS_LG, true)
	_bubble.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_bubble.offset_left = 22
	_bubble.offset_top = GameHeader.BOTTOM + SHEET_TOP - 200.0
	_bubble.offset_bottom = GameHeader.BOTTOM + SHEET_TOP - 16.0
	_bubble.grow_vertical = Control.GROW_DIRECTION_BEGIN
	add_child(_bubble)
	var v := UiKit.vbox(UiKit.SPACE_XS)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	_bubble.add_child(v)
	_name = UiKit.text("", "title", UiKit.SUN)
	v.add_child(_name)
	_talk = UiKit.paragraph("", "body", UiKit.FOAM)
	_talk.add_theme_font_size_override("font_size", 24)
	v.add_child(_talk)


func set_host(who: String) -> void:
	host = who
	var p := Portraits.path(who) if not who.is_empty() else ""
	_face.visible = not p.is_empty()
	if not p.is_empty():
		_face.texture = load(p)
	_bubble.offset_right = -290.0 if _face.visible else -22.0
	_name.text = GameState.line(who)
	_name.visible = not who.is_empty()


func say(t: String, face := "normal") -> void:
	var p := Portraits.path(host, face) if not host.is_empty() else ""
	if not p.is_empty():
		_face.texture = load(p)
	_talk.text = GameState.line(t)
	_talk.visible_ratio = 0.0
	create_tween().tween_property(_talk, "visible_ratio", 1.0, 0.4)


func clear_body() -> void:
	for c in _body.get_children():
		_body.remove_child(c)
		c.queue_free()
	_header.refresh()


func heading(t: String) -> void:
	_body.add_child(UiKit.text(t, "h2", UiKit.NOTE_INK))


func para(t: String, color := UiKit.NOTE_INK_SOFT, px := 22) -> Label:
	var l := UiKit.paragraph(t, "body", color)
	l.add_theme_font_size_override("font_size", px)
	_body.add_child(l)
	return l


func big_button(t: String, kind: String, on_press: Callable, enabled := true) -> Button:
	var b := UiKit.action(t, kind)
	b.disabled = not enabled
	b.pressed.connect(on_press)
	_body.add_child(b)
	return b


func leave() -> void:
	UiKit.go_to(self, MAP_SCENE)
