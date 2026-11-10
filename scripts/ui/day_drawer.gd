class_name DayDrawer
extends Control
## 하루 서랍 (여울 "N일차 오늘" 서랍 모양). 지도 오른쪽 끝 작은 탭을 누르면 오른쪽에서 종이가 밀려 나온다.
## 내용은 DayBrief.build(GameState). 장소가 있는 줄을 누르면 서랍이 닫히고 picked(장소 id)를 보낸다.
##
## 쓰는 법: var d := DayDrawer.new(); add_child(d); d.picked.connect(...)
##   탭은 이 노드가 만든다. 오늘 아직 안 열었으면 탭에 빨간 점 (GameState.drawer_seen_day)

signal picked(target: String)

const WIDTH := 600.0
const TAB_Y := 300.0
const TONE := {
	"gold": Color("e0a31f"),
	"good": Color("5aa65a"),
	"bad": Color("d9534f"),
	"info": Color("b8ab92"),
}

var _tab: PanelContainer
var _dot: Panel
var _root: Control
var _dim: ColorRect
var _panel: PanelContainer
var _body: VBoxContainer
var _open := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_tab()
	_build_drawer()
	refresh_dot()


func is_open() -> bool:
	return _open


func refresh_dot() -> void:
	_dot.visible = GameState.drawer_seen_day != GameState.day


## 오른쪽 끝에 붙은 작은 탭 (‹)
func _build_tab() -> void:
	_tab = PanelContainer.new()
	var s := UiKit.box(Color(UiKit.NOTE, 0.97), 0, Color.TRANSPARENT, 0, 0)
	s.corner_radius_top_left = 22
	s.corner_radius_bottom_left = 22
	s.shadow_color = Color(0, 0, 0, 0.28)
	s.shadow_size = 8
	s.shadow_offset = Vector2(0, 3)
	_tab.add_theme_stylebox_override("panel", s)
	_tab.anchor_left = 1.0
	_tab.anchor_right = 1.0
	_tab.offset_left = -46
	_tab.offset_right = 0
	_tab.offset_top = TAB_Y
	_tab.offset_bottom = TAB_Y + 86
	_tab.mouse_filter = Control.MOUSE_FILTER_STOP
	_tab.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var arrow := UiKit.text("‹", "h1", UiKit.PURPLE, HORIZONTAL_ALIGNMENT_CENTER)
	arrow.add_theme_font_override("font", UiKit.font("bold"))
	arrow.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_tab.add_child(arrow)
	_tab.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and not e.pressed:
			open())
	add_child(_tab)
	_dot = Panel.new()
	_dot.add_theme_stylebox_override("panel", UiKit.box(UiKit.RED_BTN, 9, UiKit.NOTE, 3, 0))
	_dot.anchor_left = 1.0
	_dot.anchor_right = 1.0
	_dot.offset_left = -54
	_dot.offset_right = -36
	_dot.offset_top = TAB_Y - 8
	_dot.offset_bottom = TAB_Y + 10
	_dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_dot)


func _build_drawer() -> void:
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.hide()
	add_child(_root)
	_dim = ColorRect.new()
	_dim.color = Color(UiKit.NIGHT_DEEP, 0.5)
	_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dim.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and not e.pressed:
			close())
	_root.add_child(_dim)
	_panel = PanelContainer.new()
	var s := UiKit.box(UiKit.NOTE, 0, Color.TRANSPARENT, 0, 30)
	s.corner_radius_top_left = 30
	s.corner_radius_bottom_left = 30
	s.content_margin_top = GameHeader.TOP_PAD + 18
	s.content_margin_bottom = 30
	s.shadow_color = Color(0, 0, 0, 0.4)
	s.shadow_size = 20
	_panel.add_theme_stylebox_override("panel", s)
	_panel.anchor_left = 1.0
	_panel.anchor_right = 1.0
	_panel.anchor_bottom = 1.0
	_panel.offset_left = 0
	_panel.offset_right = WIDTH
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(_panel)
	var col := UiKit.vbox(0)
	_panel.add_child(col)
	var head := UiKit.hbox(0)
	head.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_child(head)
	var title := UiKit.text("", "h2", UiKit.NOTE_INK)
	title.add_theme_font_size_override("font_size", 34)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.name = "Title"
	head.add_child(title)
	var close_btn := Button.new()
	close_btn.text = "›"
	close_btn.flat = true
	close_btn.focus_mode = Control.FOCUS_NONE
	close_btn.custom_minimum_size = Vector2(60, 60)
	close_btn.add_theme_font_override("font", UiKit.font("bold"))
	close_btn.add_theme_font_size_override("font_size", 44)
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
		close_btn.add_theme_color_override(c, UiKit.PURPLE)
	close_btn.pressed.connect(close)
	head.add_child(close_btn)
	col.add_child(UiKit.gap(10))
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(scroll)
	_body = UiKit.vbox(0)
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_body)


func open() -> void:
	if _open:
		return
	_open = true
	GameState.drawer_seen_day = GameState.day
	refresh_dot()
	Sound.play_sfx("page", 0.05, -6.0)
	Haptics.play("tap")
	_fill(DayBrief.build(GameState))
	_root.show()
	_dim.modulate.a = 0.0
	_panel.offset_left = 0
	_panel.offset_right = WIDTH
	var tw := create_tween().set_parallel()
	tw.tween_property(_dim, "modulate:a", 1.0, 0.2)
	tw.tween_property(_panel, "offset_left", -WIDTH, 0.32).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(_panel, "offset_right", 0.0, 0.32).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func close(then := "") -> void:
	if not _open:
		return
	_open = false
	var tw := create_tween().set_parallel()
	tw.tween_property(_dim, "modulate:a", 0.0, 0.2)
	tw.tween_property(_panel, "offset_left", 0.0, 0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.tween_property(_panel, "offset_right", WIDTH, 0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(func():
		_root.hide()
		if not then.is_empty():
			picked.emit(then))


func _fill(brief: Dictionary) -> void:
	(_panel.find_child("Title", true, false) as Label).text = brief.title
	for c in _body.get_children():
		c.queue_free()
	# 맨 위 숫자 칸
	var stats := UiKit.hbox(UiKit.SPACE_SM)
	for st in brief.stats:
		stats.add_child(_stat_cell(st))
	_body.add_child(stats)
	_body.add_child(UiKit.gap(22))
	for sec in brief.sections:
		_body.add_child(_section(sec.name))
		for r in sec.rows:
			_body.add_child(_row(r))
		_body.add_child(UiKit.gap(22))


## 숫자 한 칸: 작은 이름 위, 큰 값 아래
func _stat_cell(st: Dictionary) -> PanelContainer:
	var p := PanelContainer.new()
	var s := UiKit.box(Color(UiKit.NOTE_DARK, 0.4), 16, Color.TRANSPARENT, 0, 10)
	s.content_margin_left = 12
	s.content_margin_right = 12
	p.add_theme_stylebox_override("panel", s)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v := UiKit.vbox(-2)
	p.add_child(v)
	var n := UiKit.text(st.name, "body", UiKit.NOTE_INK_SOFT)
	n.add_theme_font_size_override("font_size", 15)
	v.add_child(n)
	var col: Color = UiKit.NOTE_INK
	if st.tone == "good":
		col = TONE.good
	elif st.tone == "bad":
		col = TONE.bad
	var val := UiKit.text(st.value, "number", col)
	val.add_theme_font_size_override("font_size", 21)
	v.add_child(val)
	return p


## 분류 제목: 작은 글자 뒤로 가는 줄 (여울 NewsCards.Section)
func _section(t: String) -> Control:
	var h := UiKit.hbox(10)
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	var l := UiKit.text(t, "body", UiKit.NOTE_INK_SOFT)
	l.add_theme_font_override("font", UiKit.font("bold"))
	l.add_theme_font_size_override("font_size", 17)
	h.add_child(l)
	var line := ColorRect.new()
	line.color = Color(UiKit.GOLD, 0.45)
	line.custom_minimum_size = Vector2(0, 2)
	line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(line)
	var wrap := MarginContainer.new()
	wrap.add_theme_constant_override("margin_bottom", 4)
	wrap.add_child(h)
	return wrap


## 한 줄: 색 점 · 내용 · 오른쪽 상태 · (갈 곳이 있으면) ›
func _row(r: Dictionary) -> Control:
	var row := PanelContainer.new()
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0, 0, 0, 0)
	s.border_color = Color(UiKit.NOTE_DARK, 0.75)
	s.border_width_bottom = 2
	s.content_margin_top = 12
	s.content_margin_bottom = 12
	row.add_theme_stylebox_override("panel", s)
	var h := UiKit.hbox(12)
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(h)
	var dot := Panel.new()
	dot.custom_minimum_size = Vector2(11, 11)
	dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dot.add_theme_stylebox_override("panel", UiKit.box(TONE.get(r.tone, TONE.info), 6, Color.TRANSPARENT, 0, 0))
	h.add_child(dot)
	var t := UiKit.paragraph(r.text, "body", UiKit.NOTE_INK)
	t.add_theme_font_size_override("font_size", 19)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(t)
	if not r.state.is_empty():
		var st := UiKit.text(r.state, "number", TONE.gold if r.tone == "gold" else (TONE.bad if r.tone == "bad" else UiKit.NOTE_INK_SOFT))
		st.add_theme_font_size_override("font_size", 19)
		st.mouse_filter = Control.MOUSE_FILTER_IGNORE
		h.add_child(st)
	if not r.target.is_empty():
		var a := UiKit.text("›", "h2", UiKit.PURPLE)
		a.add_theme_font_override("font", UiKit.font("bold"))
		a.mouse_filter = Control.MOUSE_FILTER_IGNORE
		h.add_child(a)
		row.mouse_filter = Control.MOUSE_FILTER_STOP
		row.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var target: String = r.target
		row.gui_input.connect(func(e):
			if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and not e.pressed:
				Sound.play_sfx("tap", 0.05, -6.0)
				close(target))
	else:
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return row
