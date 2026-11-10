extends Control
## 물빛울포 마을 지도. 화면보다 큰 가로 지도를 손가락(마우스)으로 끌어 둘러보고, 장소 핀을 골라 이동한다.
## 지도 그림: assets/art/map_village.png (가로 3:2 확장 지도). 핀 위치는 scripts/data/locations.gd
##
## 구성: 맨 위 공통 헤더(고정) / 끌어서 움직이는 지도와 핀 / 아래 종이 시트(장소 정보와 이동)
## 지도는 화면 높이의 MAP_SCREENS배 크기로 보여 준다. 처음에는 지금 있는 곳을 가운데에 둔다.

const PIN_DOT := 14.0 # 잠긴 장소 점 크기
const SERVICE_SCENE := "res://scenes/restaurant/service.tscn"
## 지도 높이를 화면 높이의 몇 배로 보여 줄지
const MAP_SCREENS := 1.2
## 이만큼 움직여야 끌기로 본다 (그보다 적으면 탭)
const DRAG_START := 12.0
## 손을 뗀 뒤 미끄러짐이 줄어드는 정도 (1초에 남는 비율)
const FLING_KEEP := 0.02

var _view: Control # 지도를 잘라 보여 주는 창
var _world: Control # 지도 그림과 핀을 담고 통째로 움직인다
var _map: TextureRect
var _pins := {} # id → Control
var _garden_layer: Control
var _header: GameHeader
var _sheet: PanelContainer
var _sheet_title: Label
var _sheet_desc: Label
var _sheet_time: PanelContainer
var _go_btn: Button
var _toast: PanelContainer
var _toast_label: Label
var _selected := ""
var _action := "" # 시트의 큰 버튼이 할 일: go(이동), open(가게 열기), sleep(자기), "" (못 함)

var _press := false
var _press_at := Vector2.ZERO
var _dragging := false
var _moved := false # 이번 누름이 끌기였으면 핀 탭을 무시한다
var _velocity := Vector2.ZERO
var _focus_tween: Tween
var _drawer: DayDrawer


func _ready() -> void:
	var sea := ColorRect.new()
	sea.color = Color("2f86b8")
	sea.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(sea)

	_view = Control.new()
	_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_view.clip_contents = true
	_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_view)
	_world = Control.new()
	_world.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_view.add_child(_world)
	_map = TextureRect.new()
	_map.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_map.stretch_mode = TextureRect.STRETCH_SCALE
	_map.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ArtSlot.has_art("map_village"):
		_map.texture = load(ArtSlot.art_path("map_village"))
	_world.add_child(_map)
	# 텃밭 이랑 조각 (심은 작물이 지도에 보인다). 핀보다 아래
	_garden_layer = Control.new()
	_garden_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_world.add_child(_garden_layer)
	_rebuild_pins()

	# 헤더 아래 글자가 잘 읽히게 위쪽만 살짝 어둡게
	add_child(UiKit.shade([[0.0, 0.45], [0.14, 0.0], [1.0, 0.0]]))
	_build_top_bar()
	_build_sheet()
	_build_toast()
	# 하루 서랍 (오른쪽 끝 탭). 줄을 누르면 그 장소를 고른다
	_drawer = DayDrawer.new()
	add_child(_drawer)
	_drawer.picked.connect(func(id: String):
		if Locations.is_unlocked(id, GameState.flags):
			_select(id))
	resized.connect(_layout_world)
	_layout_world.call_deferred()
	Sound.play_bgm("town")
	UiKit.fade_in(self)
	_autosave.call_deferred()
	if not GameState.flags.get("map_drag_hint", false):
		GameState.flags["map_drag_hint"] = true
		_show_toast.call_deferred("지도를 끌어서 마을을 둘러봐요")
	else:
		_show_toast.call_deferred(DayFlow.next_hint(GameState.time_minutes, GameState.opened_today))
	_show_notices.call_deferred(2.6)


## 지도에 올 때마다 진행을 저장한다. 화면 찍기용 장면(_shot) 안에 끼워 넣은 지도는 저장하지 않는다
func _autosave() -> void:
	if get_tree().current_scene == self:
		GameState.save_game()


# ─── 지도 크기와 위치 ───────────────────────────────

func _map_size() -> Vector2:
	var ts := _map.texture.get_size() if _map.texture else Vector2(1536, 1024)
	var k := size.y * MAP_SCREENS / ts.y
	return ts * k


func _layout_world() -> void:
	var ms := _map_size()
	_world.size = ms
	_map.size = ms
	var ts := _map.texture.get_size() if _map.texture else Vector2(1536, 1024)
	_garden_layer.position = CropDB.PLOT_RECT.position / ts * ms
	_garden_layer.size = CropDB.PLOT_RECT.size / ts * ms
	_layout_pins()
	_center_on(GameState.current_location, false)


## 지도를 끌 수 있는 범위로 묶는다 (지도 밖 빈 곳이 보이지 않게)
func _clamp_pos(p: Vector2) -> Vector2:
	var ms := _world.size
	return Vector2(clampf(p.x, minf(size.x - ms.x, 0.0), 0.0), clampf(p.y, minf(size.y - ms.y, 0.0), 0.0))


## 장소를 보이는 영역(헤더 아래, 시트 위) 가운데로 옮긴다
func _center_on(id: String, animate := true) -> void:
	var loc := Locations.get_loc(id)
	if loc.is_empty():
		return
	var top := GameHeader.BOTTOM
	var bottom := size.y - (_sheet.size.y + 32.0 if _sheet and _sheet.visible else 0.0)
	var target_screen := Vector2(size.x / 2.0, (top + bottom) / 2.0 + 30.0)
	var target := _clamp_pos(target_screen - loc.pos * _world.size)
	_velocity = Vector2.ZERO
	if _focus_tween:
		_focus_tween.kill()
	if not animate:
		_world.position = target
		return
	_focus_tween = create_tween()
	_focus_tween.tween_property(_world, "position", target, UiKit.MOTION_SLOW).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


# ─── 끌기 ───────────────────────────────────────────
# 핀(버튼)이 누름을 먼저 받아도 끌 수 있게 _input에서 직접 본다. 헤더와 시트, 메뉴 위에서 시작한 누름은 무시한다

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				if _can_drag_from(mb.position):
					_press = true
					_press_at = mb.position
					_dragging = false
					_moved = false
					_velocity = Vector2.ZERO
					if _focus_tween:
						_focus_tween.kill()
			else:
				_press = false
				if _dragging:
					_dragging = false
					get_viewport().set_input_as_handled() # 끌기가 끝난 곳의 핀이 눌리지 않게
		elif mb.pressed and _can_drag_from(mb.position):
			# 휠: 위아래, Shift+휠이나 가로 휠: 좌우
			var step := 60.0
			var d := Vector2.ZERO
			match mb.button_index:
				MOUSE_BUTTON_WHEEL_UP: d = Vector2(step, 0) if mb.shift_pressed else Vector2(0, step)
				MOUSE_BUTTON_WHEEL_DOWN: d = Vector2(-step, 0) if mb.shift_pressed else Vector2(0, -step)
				MOUSE_BUTTON_WHEEL_LEFT: d = Vector2(step, 0)
				MOUSE_BUTTON_WHEEL_RIGHT: d = Vector2(-step, 0)
			if d != Vector2.ZERO:
				_world.position = _clamp_pos(_world.position + d)
	elif event is InputEventMouseMotion and _press:
		var mm := event as InputEventMouseMotion
		if not _dragging and mm.position.distance_to(_press_at) > DRAG_START:
			_dragging = true
			_moved = true
		if _dragging:
			_world.position = _clamp_pos(_world.position + mm.relative)
			_velocity = _velocity.lerp(mm.relative / maxf(get_process_delta_time(), 0.001), 0.5)
			get_viewport().set_input_as_handled()


func _can_drag_from(p: Vector2) -> bool:
	if _header.is_menu_open() or (_drawer and _drawer.is_open()):
		return false
	if p.y < GameHeader.BOTTOM:
		return false
	if _sheet.visible and _sheet.get_global_rect().has_point(p):
		return false
	return true


func _process(delta: float) -> void:
	# 손을 떼면 조금 미끄러지다 멈춘다
	if _press or _velocity.length() < 5.0:
		if not _press:
			_velocity = Vector2.ZERO
		return
	_world.position = _clamp_pos(_world.position + _velocity * delta)
	_velocity *= pow(FLING_KEEP, delta)


# ─── 핀 ─────────────────────────────────────────────

func _rebuild_pins() -> void:
	_rebuild_garden()
	for id in _pins:
		_pins[id].queue_free()
	_pins.clear()
	for id in Locations.LIST:
		if not Locations.is_visible(id, GameState.flags):
			continue # 숨은 장소
		var p := _make_pin(id)
		_pins[id] = p
		_world.add_child(p)
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
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return dot
	var here := id == GameState.current_location
	var b := Button.new()
	b.text = ("● " if here else "") + GameState.line(loc.name)
	b.focus_mode = Control.FOCUS_ALL
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.add_theme_font_override("font", UiKit.font("cute"))
	b.add_theme_font_size_override("font_size", 19)
	var bg := UiKit.CORAL if here else UiKit.GLASS_STRONG
	var normal := UiKit.chunky(bg, UiKit.RADIUS_PILL, 0, 3)
	normal.content_margin_left = 16
	normal.content_margin_right = 16
	normal.content_margin_top = 6
	normal.content_margin_bottom = 9
	UiKit.elevate(normal, 1)
	var hover := normal.duplicate()
	hover.bg_color = bg.lightened(0.1)
	var sel := normal.duplicate()
	sel.bg_color = UiKit.SUN
	var focus := UiKit.box(Color.TRANSPARENT, UiKit.RADIUS_PILL, UiKit.SUN, 3, 0)
	focus.set_expand_margin_all(4)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", sel)
	b.add_theme_stylebox_override("focus", focus)
	for st in ["font_color", "font_hover_color", "font_focus_color"]:
		b.add_theme_color_override(st, Color.WHITE)
	b.add_theme_color_override("font_pressed_color", UiKit.INK)
	b.add_theme_color_override("font_hover_pressed_color", UiKit.INK)
	b.tooltip_text = GameState.line(loc.desc)
	b.pressed.connect(_on_pin_pressed.bind(id))
	UiKit._add_press_motion(b)
	return b


## 텃밭 이랑마다 심은 작물과 자란 정도에 맞는 조각을 뒤 이랑부터 차례로 덮는다
func _rebuild_garden() -> void:
	for c in _garden_layer.get_children():
		c.queue_free()
	for i in GameState.garden.size():
		var path := CropDB.row_art(GameState.garden[i], GameState.day, i)
		if path.is_empty() or not ResourceLoader.exists(path):
			continue
		var r := TextureRect.new()
		r.texture = load(path)
		r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		r.stretch_mode = TextureRect.STRETCH_SCALE
		r.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_garden_layer.add_child(r)


## 장소 핀을 지도 그림 위 비율 위치에 놓는다. 핀의 가운데 아래가 그 위치를 가리킨다
func _layout_pins() -> void:
	for id in _pins:
		var c: Control = _pins[id]
		c.reset_size()
		var at: Vector2 = Locations.get_loc(id).pos * _world.size
		if c is Button and Locations.get_loc(id).get("pin", "") == "below":
			c.position = at - Vector2(c.size.x / 2.0, 0.0)
		elif c is Button:
			c.position = at - Vector2(c.size.x / 2.0, c.size.y)
		else:
			c.position = at - c.size / 2.0


func _on_pin_pressed(id: String) -> void:
	if _moved:
		return # 끌다가 손을 뗀 것
	_select(id)


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
	var here := id == GameState.current_location
	var travel := 0 if here else Locations.travel_minutes(GameState.current_location, id)
	UiKit.set_chip(_sheet_time, "지금 여기" if here else "%d분" % travel)
	_action = "go"
	_go_btn.text = "들어가기" if here else "가기"
	var arrive := GameState.time_minutes + travel
	match id:
		"breakwater":
			if not DayFlow.can_fish(arrive):
				_action = ""
				_go_btn.text = "지금은 낚시 시간이 아니에요"
				_sheet_desc.text = GameState.line(loc.desc) + "
새벽 5시~11시, 밤 9시~11시 반에 낚시할 수 있어요."
		"market":
			if not Market.is_open(arrive):
				_action = ""
				_go_btn.text = "지금은 문을 닫았어요"
				_sheet_desc.text = GameState.line(loc.desc) + "\n새벽 5시부터 오후 5시까지 열어요."
		"shop":
			if GameState.has_flag("first_guest_done"):
				if GameState.opened_today:
					_action = "go" if not here else ""
					_go_btn.text = "오늘 장사는 끝났어요" if here else "가기"
				elif DayFlow.can_open_shop(arrive, false):
					_action = "open"
					_go_btn.text = "가게 열기" if arrive >= DayFlow.SHOP_OPEN else "가게 열기 (저녁 6시로)"
		"home":
			if GameState.opened_today or GameState.time_minutes >= DayFlow.SHOP_CLOSE:
				_action = "sleep"
				_go_btn.text = "집에 가서 자기"
	_go_btn.disabled = _action.is_empty()
	var was_open := _sheet.visible
	_sheet.show()
	if not was_open:
		UiKit.rise_in(_sheet, 0.0, 40.0)
	_go_btn.grab_focus()
	# 시트 크기가 정해진 뒤 고른 곳을 보이는 영역 가운데로
	_center_on.call_deferred(id)


func _close_sheet() -> void:
	_sheet.hide()
	_selected = ""


func _travel() -> void:
	var id := _selected
	var loc := Locations.get_loc(id)
	if _action.is_empty():
		return
	GameState.time_minutes += Locations.travel_minutes(GameState.current_location, id)
	GameState.current_location = id
	_close_sheet()
	if _action == "open":
		UiKit.go_to(self, SERVICE_SCENE)
		return
	if _action == "sleep":
		GameState.end_day()
		Sound.play_sfx("step")
		_refresh_hud()
		_rebuild_pins()
		_show_toast("푹 잤다. %s 아침이 밝았어요" % Calendar.text(GameState.day))
		_drawer.refresh_dot()
		_show_notices.call_deferred(2.6)
		return
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
	_toast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_toast_label.custom_minimum_size.x = 560 # 긴 알림(상환, 상한 생선)은 두 줄로
	_toast.add_child(_toast_label)
	_toast.modulate.a = 0.0


## 쌓인 알림(상환, 상한 생선)을 앞 안내가 사라진 뒤 하나씩 띄운다
func _show_notices(delay: float) -> void:
	for t in GameState.pop_notices():
		await get_tree().create_timer(delay).timeout
		if not is_inside_tree():
			return
		_show_toast(t)
		delay = 3.2


func _show_toast(t: String) -> void:
	_toast_label.text = t
	var tw := create_tween()
	tw.tween_property(_toast, "modulate:a", 1.0, UiKit.MOTION_BASE)
	tw.tween_interval(2.2)
	tw.tween_property(_toast, "modulate:a", 0.0, UiKit.MOTION_SLOW)
