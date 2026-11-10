class_name GameMenu
extends CanvasLayer
## 헤더의 메뉴 버튼으로 여는 아래 시트. 탭 네 개: 가방, 도감, 장비, 설정.
## CanvasLayer라서 어느 장면에서 열어도 맨 위에 뜬다. GameHeader가 만든다.
##
## 가방: 아이스박스(GameState.inventory)를 어종별로 묶어 마리 수, 최대 크기, 값
## 도감: FishDB 어종. 잡은 건 그림과 최대 기록, 못 잡은 건 어두운 그림자와 "???"
## 장비: 가진 낚싯대, 릴, 미끼 중 고르기 (바꾸면 gear_changed)
## 설정: 배경음악, 효과음, 진동, 화면 흔들림 켜고 끄기, 타이틀로

signal closed
signal gear_changed

const TITLE_SCENE := "res://scenes/title/title.tscn"
const TABS := [["bag", "가방"], ["dex", "도감"], ["gear", "장비"], ["settings", "설정"]]
const SHEET_H := 940.0 # 가장 클 때 높이. 내용이 적으면 줄어든다
const SHEET_MIN := 520.0
const CHROME := 200.0 # 시트 안 목록 말고 나머지(여백, 제목 줄, 탭) 높이

var _root: Control
var _sheet: PanelContainer
var _list: VBoxContainer
var _tab_buttons := {}
var _tab := "bag"
var _title_armed := false
var _scroll: ScrollContainer
var _height := SHEET_H


func _ready() -> void:
	layer = 20
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	var dim := UiKit.scrim(0.45)
	dim.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed:
			close())
	_root.add_child(dim)

	_sheet = UiKit.note_paper(22, 22)
	_sheet.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_sheet.offset_left = 10
	_sheet.offset_right = -10
	_sheet.offset_top = -SHEET_H
	_sheet.offset_bottom = -12
	_root.add_child(_sheet)
	var v := UiKit.vbox(UiKit.SPACE_MD)
	_sheet.add_child(v)
	var head := UiKit.hbox(UiKit.SPACE_SM)
	head.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(head)
	head.add_child(UiKit.text(GameState.line("{player}의 수첩"), "h2", UiKit.NOTE_INK))
	head.add_child(UiKit.spacer())
	var close_btn := UiKit.game_button("닫기", UiKit.GRAY_DARK)
	close_btn.pressed.connect(close)
	head.add_child(close_btn)
	v.add_child(_make_tabs())
	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(_scroll)
	_list = UiKit.vbox(UiKit.SPACE_SM)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(_list)
	_root.hide()


func open(tab := "") -> void:
	if not tab.is_empty():
		_tab = tab
	_title_armed = false
	_refresh()
	_root.show()
	# 아래에서 쓱 올라온다
	_sheet.offset_top = -_height + 60.0
	_sheet.offset_bottom = 48.0
	_sheet.modulate.a = 0.0
	var tw := _sheet.create_tween().set_parallel()
	tw.tween_property(_sheet, "offset_top", -_height, UiKit.MOTION_BASE).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(_sheet, "offset_bottom", -12.0, UiKit.MOTION_BASE).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(_sheet, "modulate:a", 1.0, UiKit.MOTION_FAST)


func close() -> void:
	if not _root.visible:
		return
	_root.hide()
	closed.emit()


func is_open() -> bool:
	return _root.visible


## 탭 (알약 모양 분할 버튼)
func _make_tabs() -> PanelContainer:
	var track := UiKit.tab_track()
	var h := UiKit.hbox(UiKit.SPACE_XS)
	track.add_child(h)
	for t in TABS:
		var b := UiKit.tab_button(t[1])
		var id: String = t[0]
		b.pressed.connect(func():
			_tab = id
			_title_armed = false
			Sound.play_sfx("tap", 0.05, -8.0)
			_refresh())
		_tab_buttons[id] = b
		h.add_child(b)
	return track


func _refresh() -> void:
	for k in _tab_buttons:
		_tab_buttons[k].set_pressed_no_signal(k == _tab)
	for c in _list.get_children():
		c.queue_free()
	match _tab:
		"bag":
			_build_bag()
		"dex":
			_build_dex()
		"gear":
			_build_gear()
		_:
			_build_settings()
	_fit_height()


## 시트 높이를 목록 길이에 맞춘다 (빈 칸이 크게 남지 않게). 지운 줄은 아직 남아 있을 수 있어 새로 넣은 줄만 센다
func _fit_height() -> void:
	var h := 0.0
	var n := 0
	for c in _list.get_children():
		if c.is_queued_for_deletion():
			continue
		h += (c as Control).get_combined_minimum_size().y
		n += 1
	h += maxf(n - 1, 0) * UiKit.SPACE_SM
	_height = clampf(h + CHROME, SHEET_MIN, SHEET_H)
	if _root.visible:
		_sheet.create_tween().tween_property(_sheet, "offset_top", -_height, UiKit.MOTION_FAST).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


# ─── 가방 ───────────────────────────────────────────

func _build_bag() -> void:
	var total := 0
	for e in GameState.inventory:
		total += FishDB.value_of(e.id, e.size)
	# 위: 아이스박스 칸 (여울 쿨러 6/15 판)
	var box := UiKit.status_tag("아이스박스 %d/%d" % [GameState.inventory.size(), GameState.icebox_size], UiKit.TEAL_BTN, Color.WHITE, Vector2(0, 50))
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_child(box)
	var tip := UiKit.text("잡은 다음 날 저녁까지 팔아요. 그 밤을 넘기면 상해요", "body", UiKit.NOTE_INK_SOFT, HORIZONTAL_ALIGNMENT_RIGHT)
	tip.add_theme_font_size_override("font_size", 16)
	_list.add_child(tip)
	if GameState.inventory.is_empty():
		_list.add_child(_empty_note("아이스박스가 비어 있어요. 방파제에서 낚아 와요"))
		return
	# 오늘 밤 상하는 것 먼저, 그다음 비싼 순서
	var spoiling := GameState.spoiling_tonight()
	var items := GameState.inventory.duplicate()
	items.sort_custom(func(a, b):
		if spoiling.has(a) != spoiling.has(b):
			return spoiling.has(a)
		return FishDB.value_of(a.id, a.size) > FishDB.value_of(b.id, b.size))
	for e in items:
		_list.add_child(FishLine.make(e, GameState.day, GameState.format_won(FishDB.value_of(e.id, e.size))))
	var sum := UiKit.text("모두 %s어치" % GameState.format_won(total), "title", UiKit.NOTE_INK_SOFT, HORIZONTAL_ALIGNMENT_RIGHT)
	_list.add_child(sum)


# ─── 도감 ───────────────────────────────────────────

func _build_dex() -> void:
	var found := 0
	for id in FishDB.FISH:
		if GameState.dex.get(id, 0.0) > 0.0:
			found += 1
	_list.add_child(UiKit.text("북쪽 방파제  ·  발견 %d / %d" % [found, FishDB.FISH.size()], "label", UiKit.INK_SOFT))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", UiKit.SPACE_SM)
	grid.add_theme_constant_override("v_separation", UiKit.SPACE_SM)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_child(grid)
	for id in FishDB.FISH:
		var f := FishDB.get_fish(id)
		var best: float = GameState.dex.get(id, 0.0)
		var caught := best > 0.0
		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", UiKit.inset_box(UiKit.SPACE_MD, UiKit.RADIUS_MD))
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var v := UiKit.vbox(4)
		card.add_child(v)
		var art := UiKit.icon_rect("fish_" + id, 70)
		if art:
			art.custom_minimum_size = Vector2(0, 70)
			if not caught:
				art.modulate = UiKit.SILHOUETTE # 못 잡은 물고기는 그림자만
			v.add_child(art)
		var name_row := UiKit.hbox(6, BoxContainer.ALIGNMENT_CENTER)
		name_row.add_child(UiKit.text(f.name if caught else "???", "title", UiKit.INK if caught else UiKit.INK_SOFT))
		var rar := FishDB.rarity(id)
		if caught and rar != FishDB.RARITY.common:
			name_row.add_child(UiKit.badge(rar.name, rar.color, UiKit.INK))
		v.add_child(name_row)
		v.add_child(UiKit.text("최대 %.1fcm" % best if caught else "아직 못 잡았어요", "caption", UiKit.INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER))
		grid.add_child(card)


# ─── 장비 ───────────────────────────────────────────

func _build_gear() -> void:
	_list.add_child(UiKit.text("낚싯대", "label", UiKit.INK_SOFT))
	for id in GameState.owned_rods:
		var r := GearDB.rod(id)
		_list.add_child(_gear_row(GearDB.icon_art(r), r.name, "던지기 %d%%  ·  버티기 +%d%%" % [int(r.cast * 100), int(r.strength * 100)], id == GameState.equipped_rod, func():
			GameState.equipped_rod = id
			_gear_picked()))
	_list.add_child(UiKit.text("릴", "label", UiKit.INK_SOFT))
	for id in GameState.owned_reels:
		var l := GearDB.reel(id)
		_list.add_child(_gear_row(GearDB.icon_art(l), l.name, "감기 %d%%  ·  드랙 +%d%%" % [int(l.speed * 100), int(l.drag * 100)], id == GameState.equipped_reel, func():
			GameState.equipped_reel = id
			_gear_picked()))
	_list.add_child(UiKit.text("미끼", "label", UiKit.INK_SOFT))
	for id in BaitDB.ORDER:
		var n := GameState.bait_count(id)
		if n == 0:
			continue
		var b := BaitDB.bait(id)
		var stats := ("무제한" if n < 0 else "%d개" % n) + "  ·  잘 무는 고기: " + BaitDB.liked_names(id)
		_list.add_child(_gear_row(BaitDB.icon_art(id), b.name, stats, id == GameState.equipped_bait, func():
			GameState.equipped_bait = id
			_gear_picked()))
	_list.add_child(UiKit.text("새 장비와 미끼는 준호네 낚시방에서 살 수 있어요", "caption", UiKit.INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER))


func _gear_picked() -> void:
	Sound.play_sfx("tap")
	gear_changed.emit()
	_refresh()


## 장비 한 줄 (여울 미끼 줄): 쓰는 것은 금테 칸에 금빛 글자, 오른쪽 "쓰는 중"은 단추와 같은 크기
func _gear_row(icon: String, title: String, stats: String, equipped: bool, on_pick: Callable) -> PanelContainer:
	var row := PanelContainer.new()
	var s := UiKit.box(Color(UiKit.GOLD_SOFT, 0.7) if equipped else Color(UiKit.NOTE_DARK, 0.28), 16, UiKit.GOLD_DARK if equipped else Color(UiKit.NOTE_DARK, 0.6), 2 if equipped else 1, 10)
	s.content_margin_left = 12
	row.add_theme_stylebox_override("panel", s)
	var h := UiKit.hbox(UiKit.SPACE_MD)
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(h)
	var ic := UiKit.icon_rect(icon, 52)
	if ic:
		h.add_child(ic)
	var info := UiKit.vbox(-2)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var t := UiKit.text(title, "title", UiKit.GOLD_DARK if equipped else UiKit.NOTE_INK)
	t.add_theme_font_size_override("font_size", 22)
	info.add_child(t)
	var st := UiKit.paragraph(stats, "body", UiKit.NOTE_INK_SOFT)
	st.add_theme_font_size_override("font_size", 16)
	info.add_child(st)
	h.add_child(info)
	if equipped:
		h.add_child(UiKit.status_tag("쓰는 중"))
	else:
		var b := UiKit.game_button("고르기")
		b.pressed.connect(on_pick)
		h.add_child(b)
	return row


# ─── 설정 ───────────────────────────────────────────

func _build_settings() -> void:
	_list.add_child(_toggle_row("배경음악", Sound.bgm_on, func(on: bool): Sound.set_bgm_on(on)))
	_list.add_child(_toggle_row("효과음", Sound.sfx_on, func(on: bool): Sound.set_sfx_on(on)))
	_list.add_child(_toggle_row("진동", GameState.vibration_on, func(on: bool):
		GameState.set_vibration(on)
		Haptics.play("hook"))) # 켰을 때 어떤 느낌인지 바로 알 수 있게 (끄면 울리지 않는다)
	_list.add_child(_toggle_row("화면 흔들림", GameState.screen_shake_on, func(on: bool): GameState.set_screen_shake(on)))
	_list.add_child(UiKit.gap(8))
	var title_btn := UiKit.game_button("한 번 더 누르면 타이틀로 가요" if _title_armed else "타이틀로", UiKit.RED_BTN if _title_armed else UiKit.GRAY_DARK, Vector2(0, 58))
	title_btn.pressed.connect(func():
		if not _title_armed:
			_title_armed = true
			Sound.play_sfx("tap")
			_refresh()
			return
		close()
		var scene := get_tree().current_scene
		if scene:
			UiKit.go_to(scene, TITLE_SCENE)
		else:
			get_tree().change_scene_to_file(TITLE_SCENE))
	_list.add_child(title_btn)
	_list.add_child(UiKit.text("마을 지도에 올 때마다 저절로 저장돼요. 낚시나 장사 도중은 저장되지 않아요", "caption", UiKit.INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER))


func _toggle_row(label: String, on: bool, setter: Callable) -> PanelContainer:
	var row := _row()
	var h: HBoxContainer = row.get_child(0)
	var l := UiKit.text(label, "title", UiKit.NOTE_INK)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(l)
	var b := UiKit.game_button("켜짐" if on else "꺼짐", UiKit.TEAL_BTN if on else UiKit.GRAY_DARK)
	b.pressed.connect(func():
		setter.call(not on)
		Sound.play_sfx("tap")
		_refresh())
	h.add_child(b)
	return row


# ─── 공통 ───────────────────────────────────────────

## 목록 한 줄: 공책 줄 (get_child(0)이 HBoxContainer)
func _row() -> PanelContainer:
	return UiKit.note_row()


func _add_fish_thumb(h: HBoxContainer, id: String, dark: bool) -> void:
	var t := UiKit.icon_rect("fish_" + id, 44)
	if t:
		t.custom_minimum_size = Vector2(80, 44)
		if dark:
			t.modulate = UiKit.SILHOUETTE
		h.add_child(t)


func _empty_note(t: String) -> Control:
	var l := UiKit.paragraph(t, "body", UiKit.INK_SOFT, 0.0, HORIZONTAL_ALIGNMENT_CENTER)
	l.custom_minimum_size.y = 120
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return l
