extends Control
## 물빛울포 마을 지도 (세로). 장소 핀을 골라 이동하면 거리만큼 시간이 흐른다.
## 지도 그림: assets/art/map_village (지금은 바다 한 접시의 임시 그림). 핀 위치는 scripts/data/locations.gd
##
## 구성: 맨 위 공통 헤더(날짜와 시각, 날씨, 돈, 메뉴: 가방, 도감, 장비, 설정) / 마을 이름 / 지도와 핀 / 아래 종이 시트(장소 정보와 이동)

const PIN_DOT := 14.0 # 잠긴 장소 점 크기

var _map: ArtSlot
var _pins_root: Control
var _pins := {} # id → Control
var _header: GameHeader
var _sheet: PanelContainer
var _sheet_title: Label
var _sheet_desc: Label
var _sheet_time: PanelContainer
var _go_btn: Button
var _toast: PanelContainer
var _toast_label: Label
var _selected := ""


func _ready() -> void:
	var sea := ColorRect.new()
	sea.color = Color("2a6f9e")
	sea.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(sea)

	_map = ArtSlot.make("map_village", "마을 지도", Vector2.ZERO)
	_map.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_map.cover = true
	_map.clip_contents = true
	add_child(_map)
	# 위아래 글자가 잘 읽히게 살짝 어둡게
	add_child(UiKit.shade([[0.0, 0.45], [0.16, 0.0], [0.82, 0.0], [1.0, 0.35]]))

	_pins_root = Control.new()
	_pins_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_pins_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_pins_root)
	_rebuild_pins()

	_build_top_bar()
	_build_sheet()
	_build_toast()
	resized.connect(_layout_pins)
	Sound.play_bgm("town")
	UiKit.fade_in(self)


# ─── 핀 ─────────────────────────────────────────────

func _rebuild_pins() -> void:
	for id in _pins:
		_pins[id].queue_free()
	_pins.clear()
	for id in Locations.LIST:
		var p := _make_pin(id)
		_pins[id] = p
		_pins_root.add_child(p)
	_layout_pins.call_deferred()


func _make_pin(id: String) -> Control:
	var loc := Locations.get_loc(id)
	if not Locations.is_unlocked(id, GameState.flags):
		# 아직 갈 수 없는 곳은 작은 점으로만
		var dot := Panel.new()
		dot.custom_minimum_size = Vector2(PIN_DOT, PIN_DOT)
		dot.size = Vector2(PIN_DOT, PIN_DOT)
		dot.add_theme_stylebox_override("panel", UiKit.box(Color(UiKit.NAVY_DEEP, 0.55), UiKit.RADIUS_PILL, Color(1, 1, 1, 0.5), 2, 0))
		dot.tooltip_text = "아직 갈 수 없어요"
		return dot
	var here := id == GameState.current_location
	var b := Button.new()
	b.text = GameState.line(loc.name)
	b.focus_mode = Control.FOCUS_ALL
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.add_theme_font_override("font", UiKit.font("bold"))
	b.add_theme_font_size_override("font_size", 16)
	var bg := UiKit.CORAL if here else UiKit.GLASS_STRONG
	var normal := UiKit.box(bg, UiKit.RADIUS_PILL, Color(1, 1, 1, 0.35) if not here else Color.WHITE, 2, 0)
	normal.content_margin_left = 14
	normal.content_margin_right = 14
	normal.content_margin_top = 7
	normal.content_margin_bottom = 8
	UiKit.elevate(normal, 1)
	var hover := normal.duplicate()
	hover.bg_color = bg.lightened(0.1)
	var sel := normal.duplicate()
	sel.border_color = UiKit.SUN
	sel.set_border_width_all(3)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", sel)
	b.add_theme_stylebox_override("focus", sel)
	for st in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(st, Color.WHITE)
	b.tooltip_text = GameState.line(loc.desc)
	b.pressed.connect(_select.bind(id))
	UiKit._add_press_motion(b)
	return b


## 장소 핀을 지도 그림 위 비율 위치에 놓는다. 핀의 가운데 아래가 그 위치를 가리킨다
func _layout_pins() -> void:
	var r := _map.content_rect()
	for id in _pins:
		var c: Control = _pins[id]
		c.reset_size()
		var at: Vector2 = r.position + Locations.get_loc(id).pos * r.size
		if c is Button:
			c.position = at - Vector2(c.size.x / 2.0, c.size.y)
		else:
			c.position = at - c.size / 2.0


# ─── 상단 ───────────────────────────────────────────

func _build_top_bar() -> void:
	_header = GameHeader.new()
	add_child(_header)
	# 헤더 아래 마을 이름 (지도 위 스티커 글자)
	var town := UiKit.text("물빛울포", "h2", UiKit.FOAM)
	UiKit.outlined(town, 10)
	town.position = Vector2(26, GameHeader.BOTTOM + 8.0)
	add_child(town)


func _refresh_hud() -> void:
	_header.refresh()


# ─── 아래 시트 ──────────────────────────────────────

func _build_sheet() -> void:
	_sheet = PanelContainer.new()
	var s := UiKit.paper_box(28, UiKit.RADIUS_LG, 3)
	_sheet.add_theme_stylebox_override("panel", s)
	_sheet.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_sheet.offset_left = 12
	_sheet.offset_right = -12
	_sheet.offset_top = -16 # 내용 높이만큼 위로 자란다
	_sheet.offset_bottom = -16
	_sheet.grow_vertical = Control.GROW_DIRECTION_BEGIN
	add_child(_sheet)
	var v := UiKit.vbox(UiKit.SPACE_MD)
	_sheet.add_child(v)
	var head := UiKit.hbox(UiKit.SPACE_MD)
	_sheet_title = UiKit.text("", "h2", UiKit.INK)
	head.add_child(_sheet_title)
	head.add_child(UiKit.spacer())
	_sheet_time = UiKit.chip("이동", "", "", false)
	head.add_child(_sheet_time)
	v.add_child(head)
	_sheet_desc = UiKit.paragraph("", "body", UiKit.INK_SOFT)
	v.add_child(_sheet_desc)
	v.add_child(UiKit.gap(4))
	var row := UiKit.hbox(UiKit.SPACE_MD)
	var cancel := UiKit.action("닫기", "secondary")
	cancel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cancel.pressed.connect(_close_sheet)
	row.add_child(cancel)
	_go_btn = UiKit.action("가기")
	_go_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_go_btn.size_flags_stretch_ratio = 1.6
	_go_btn.pressed.connect(_travel)
	row.add_child(_go_btn)
	v.add_child(row)
	_sheet.hide()


func _select(id: String) -> void:
	Sound.play_sfx("tap", 0.05, -6.0)
	_selected = id
	var loc := Locations.get_loc(id)
	_sheet_title.text = GameState.line(loc.name)
	_sheet_desc.text = GameState.line(loc.desc)
	if id == GameState.current_location:
		UiKit.set_chip(_sheet_time, "지금 여기")
		_go_btn.text = "들어가기"
	else:
		UiKit.set_chip(_sheet_time, "%d분" % Locations.travel_minutes(GameState.current_location, id))
		_go_btn.text = "가기"
	var was_open := _sheet.visible
	_sheet.show()
	if not was_open:
		UiKit.rise_in(_sheet, 0.0, 40.0)
	_go_btn.grab_focus()


func _close_sheet() -> void:
	_sheet.hide()
	_selected = ""


func _travel() -> void:
	var id := _selected
	var loc := Locations.get_loc(id)
	GameState.time_minutes += Locations.travel_minutes(GameState.current_location, id)
	GameState.current_location = id
	_close_sheet()
	var scene: String = loc.get("scene", "")
	if not scene.is_empty():
		UiKit.go_to(self, scene)
		return
	# 장소 화면이 아직 없으면 지도에 머문다
	Sound.play_sfx("step")
	_refresh_hud()
	_rebuild_pins()
	_show_toast(GameState.line("%s에 왔어요. 장소 화면은 준비 중이에요." % loc.name))


# ─── 토스트 ─────────────────────────────────────────

func _build_toast() -> void:
	var holder := CenterContainer.new()
	holder.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	holder.offset_top = GameHeader.BOTTOM + 56.0
	holder.offset_bottom = GameHeader.BOTTOM + 112.0
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(holder)
	_toast = UiKit.glass_panel(0, UiKit.RADIUS_PILL, true)
	var s: StyleBoxFlat = _toast.get_theme_stylebox("panel")
	s.content_margin_left = 22
	s.content_margin_right = 22
	s.content_margin_top = 10
	s.content_margin_bottom = 11
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(_toast)
	_toast_label = UiKit.text("", "label", UiKit.FOAM, HORIZONTAL_ALIGNMENT_CENTER)
	_toast.add_child(_toast_label)
	_toast.modulate.a = 0.0


func _show_toast(t: String) -> void:
	_toast_label.text = t
	var tw := create_tween()
	tw.tween_property(_toast, "modulate:a", 1.0, UiKit.MOTION_BASE)
	tw.tween_interval(2.2)
	tw.tween_property(_toast, "modulate:a", 0.0, UiKit.MOTION_SLOW)
