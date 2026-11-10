extends Control
## 물빛울포 마을 지도. 장소를 골라 이동하면 거리만큼 시간이 흐른다.
## 지도 그림은 assets/art/map_village.jpg (사용자에게 받음). 없으면 그림 자리만 보인다.

const MAP_FOCUS := Vector2(0.5, 0.15)

var _map: ArtSlot
var _pins_root: Control
var _pins := {} # id → Button
var _clock: Label
var _money: Label
var _panel: PanelContainer
var _panel_title: Label
var _panel_desc: Label
var _panel_time: Label
var _go_btn: Button
var _toast: Label
var _selected := ""


func _ready() -> void:
	var sea := ColorRect.new()
	sea.color = Color("2f7f8a")
	sea.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(sea)

	_map = ArtSlot.make("map_village", "마을 지도 일러스트", Vector2.ZERO)
	# 3:2 지도를 16:9 화면에 꽉 채운다. 위아래가 조금 잘리는데 아래쪽 빈 바다를 더 잘라 뒷산 전망대를 살린다
	_map.cover = true
	_map.cover_focus = MAP_FOCUS
	_map.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_map)

	_pins_root = Control.new()
	_pins_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_pins_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_pins_root)
	_make_pins()

	_build_hud()
	_build_panel()
	resized.connect(_layout_pins)
	_layout_pins.call_deferred()
	UiKit.fade_in(self)


func _make_pin(id: String) -> Button:
	var loc := Locations.get_loc(id)
	var open := Locations.is_unlocked(id, GameState.flags)
	var here := id == GameState.current_location
	var b := Button.new()
	b.text = GameState.line(loc.name) if open else "???"
	b.disabled = not open
	b.focus_mode = Control.FOCUS_ALL
	b.add_theme_font_size_override("font_size", 18)
	var bg := UiKit.MUSTARD if here else UiKit.PAPER
	var border := UiKit.NAVY if open else Color(0.4, 0.4, 0.4)
	b.add_theme_stylebox_override("normal", UiKit.box(bg, 18, border, 2, 8))
	b.add_theme_stylebox_override("hover", UiKit.box(bg.lightened(0.2), 18, UiKit.MUSTARD, 3, 8))
	b.add_theme_stylebox_override("pressed", UiKit.box(bg.darkened(0.1), 18, UiKit.MUSTARD, 3, 8))
	b.add_theme_stylebox_override("focus", UiKit.box(Color.TRANSPARENT, 18, UiKit.CORAL, 3, 8))
	b.add_theme_stylebox_override("disabled", UiKit.box(Color(0.15, 0.15, 0.15, 0.55), 18, border, 2, 8))
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(state, UiKit.INK)
	b.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0.6))
	b.tooltip_text = loc.desc if open else "아직 갈 수 없어요"
	b.pressed.connect(_select.bind(id))
	return b


## 지도에 보일 장소만 핀을 만든다 (숨은 장소는 찾기 전까지 없음)
func _make_pins() -> void:
	for id in Locations.LIST:
		if not Locations.is_visible(id, GameState.flags):
			continue
		var b := _make_pin(id)
		_pins[id] = b
		_pins_root.add_child(b)


## 장소 핀을 지도 그림 위 비율 위치에 놓는다. 핀의 가운데 아래가 그 위치를 가리킨다.
## "pin": "below"인 곳은 핀의 가운데 위가 그 위치에 붙는다.
func _layout_pins() -> void:
	var r := _map.content_rect()
	for id in _pins:
		var b: Button = _pins[id]
		b.reset_size()
		var loc := Locations.get_loc(id)
		var p: Vector2 = loc.pos
		var at := r.position + p * r.size
		var below: bool = loc.get("pin", "") == "below"
		b.position = at - Vector2(b.size.x / 2.0, 0.0 if below else b.size.y)


func _build_hud() -> void:
	var bar := PanelContainer.new()
	bar.add_theme_stylebox_override("panel", UiKit.box(Color(UiKit.NAVY_DEEP, 0.85), 14, Color.TRANSPARENT, 0, 14))
	# 왼쪽 위에는 뒷산 전망대가 있어서 오른쪽 위(하늘과 먼바다)에 둔다
	bar.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	bar.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	bar.offset_left = -24
	bar.offset_right = -24
	bar.offset_top = 20
	add_child(bar)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 28)
	bar.add_child(h)
	h.add_child(UiKit.label("물빛울포", 24, UiKit.MUSTARD))
	_clock = UiKit.label("", 22, UiKit.CREAM)
	h.add_child(_clock)
	_money = UiKit.label("", 22, UiKit.CREAM)
	h.add_child(_money)
	var gear_btn := UiKit.button("장비", false)
	gear_btn.custom_minimum_size = Vector2(90, 40)
	gear_btn.pressed.connect(_open_gear)
	h.add_child(gear_btn)
	_refresh_hud()

	_toast = UiKit.shadowed(UiKit.label("", 22, UiKit.CREAM, HORIZONTAL_ALIGNMENT_CENTER), Color(0, 0, 0, 0.7), 2)
	_toast.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_toast.offset_top = 86
	_toast.offset_bottom = 120
	add_child(_toast)


func _refresh_hud() -> void:
	_clock.text = GameState.clock_text()
	_money.text = "잔고 " + GameState.format_won(GameState.money)


func _build_panel() -> void:
	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel", UiKit.box(UiKit.PAPER, 16, UiKit.NAVY, 2, 24))
	_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_panel.custom_minimum_size = Vector2(460, 0)
	_panel.offset_left = -230
	_panel.offset_right = 230
	_panel.offset_top = -210
	_panel.offset_bottom = -24
	_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	add_child(_panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	_panel.add_child(v)
	_panel_title = UiKit.label("", 30, UiKit.INK, HORIZONTAL_ALIGNMENT_CENTER)
	v.add_child(_panel_title)
	_panel_desc = UiKit.label("", 20, UiKit.INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER)
	v.add_child(_panel_desc)
	_panel_time = UiKit.label("", 20, UiKit.TEAL, HORIZONTAL_ALIGNMENT_CENTER)
	v.add_child(_panel_time)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	var cancel := UiKit.button("취소", false)
	cancel.pressed.connect(func(): _panel.hide())
	row.add_child(cancel)
	_go_btn = UiKit.button("가기")
	_go_btn.pressed.connect(_travel)
	row.add_child(_go_btn)
	v.add_child(row)
	_panel.hide()


func _select(id: String) -> void:
	_selected = id
	var loc := Locations.get_loc(id)
	_panel_title.text = GameState.line(loc.name)
	_panel_desc.text = GameState.line(loc.desc)
	if id == GameState.current_location:
		_panel_time.text = "지금 여기 있어요"
		_go_btn.text = "들어가기"
	else:
		_panel_time.text = "이동 %d분" % Locations.travel_minutes(GameState.current_location, id)
		_go_btn.text = "가기"
	_panel.show()
	_go_btn.grab_focus()


func _travel() -> void:
	var id := _selected
	var loc := Locations.get_loc(id)
	GameState.time_minutes += Locations.travel_minutes(GameState.current_location, id)
	GameState.current_location = id
	_panel.hide()
	var scene: String = loc.get("scene", "")
	if not scene.is_empty():
		UiKit.go_to(self, scene)
		return
	# 장소 화면이 아직 없으면 지도에 머문다
	_refresh_hud()
	for pid in _pins:
		_pins[pid].queue_free()
	_pins.clear()
	_make_pins()
	_layout_pins.call_deferred()
	_show_toast(GameState.line("%s에 왔다. 장소 화면은 준비 중이에요." % loc.name))


func _show_toast(text: String) -> void:
	_toast.text = text
	_toast.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_interval(2.0)
	tw.tween_property(_toast, "modulate:a", 0.0, 0.6)


# ─── 장비 ───────────────────────────────────────────
# 가진 낚싯대와 릴 중에서 고른다. 고른 장비는 낚시 화면의 SD 주인공과 낚시 능력치에 바로 반영된다.

var _gear_panel: PanelContainer


func _open_gear() -> void:
	if _gear_panel:
		_gear_panel.queue_free()
	_gear_panel = PanelContainer.new()
	_gear_panel.add_theme_stylebox_override("panel", UiKit.box(UiKit.PAPER, 16, UiKit.NAVY, 2, 24))
	_gear_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_gear_panel.custom_minimum_size = Vector2(560, 0)
	_gear_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_gear_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(_gear_panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	_gear_panel.add_child(v)
	v.add_child(UiKit.label("낚시 장비", 30, UiKit.INK, HORIZONTAL_ALIGNMENT_CENTER))
	v.add_child(UiKit.label("낚싯대", 22, UiKit.TEAL))
	for id in GameState.owned_rods:
		var r := GearDB.rod(id)
		v.add_child(_gear_row(r.name, "던지기 %d%%  버티기 +%d%%" % [int(r.cast * 100), int(r.strength * 100)], id == GameState.equipped_rod, func():
			GameState.equipped_rod = id
			_open_gear()))
	v.add_child(UiKit.label("릴", 22, UiKit.TEAL))
	for id in GameState.owned_reels:
		var l := GearDB.reel(id)
		v.add_child(_gear_row(l.name, "감기 %d%%  드랙 +%d%%" % [int(l.speed * 100), int(l.drag * 100)], id == GameState.equipped_reel, func():
			GameState.equipped_reel = id
			_open_gear()))
	v.add_child(UiKit.label("새 장비는 준호네 낚시방에서 살 수 있어요.", 18, UiKit.INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	var close := UiKit.button("닫기")
	close.pressed.connect(func():
		_gear_panel.queue_free()
		_gear_panel = null)
	row.add_child(close)
	v.add_child(row)


func _gear_row(title: String, stats: String, equipped: bool, on_pick: Callable) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	var name_label := UiKit.label(title, 20, UiKit.INK)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(name_label)
	h.add_child(UiKit.label(stats, 17, UiKit.INK_SOFT))
	if equipped:
		h.add_child(UiKit.label("사용 중", 18, UiKit.CORAL))
	else:
		var b := UiKit.button("장착", false)
		b.custom_minimum_size = Vector2(80, 36)
		b.pressed.connect(on_pick)
		h.add_child(b)
	return h
