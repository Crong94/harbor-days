extends Control
## 세라와 요리 연구 (2026-11-24 다시 짬). 낮에 식당에서 생선 한 마리와 재료를 주면 세라가 새 요리를 알아낸다. 규칙은 Menu.
## 하루 한 번, 언제나 성공한다. 마을 사람이 알려 준 요리는 연구 없이 바로 메뉴판에 오른다.
## 그림: 식당 낮 배경 bg_shop_inside_day, 요리 dish/<id>

const MAP_SCENE := "res://scenes/map/map.tscn"

var _header: GameHeader
var _list: VBoxContainer
var _say: Label


func _ready() -> void:
	var base := ColorRect.new()
	base.color = UiKit.WOOD_DARK
	base.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(base)
	var art := UiKit.cover_art("bg_shop_inside_day")
	if art:
		add_child(art)
	add_child(UiKit.shade([[0.0, 0.5], [0.2, 0.15], [1.0, 0.55]]))
	_header = GameHeader.new()
	add_child(_header)
	var row := UiKit.hbox(UiKit.SPACE_MD)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	row.offset_left = 22
	row.offset_right = -20
	row.offset_top = GameHeader.BOTTOM + 12.0
	add_child(row)
	var t := UiKit.text("세라와 요리 연구", "h2", UiKit.FOAM)
	UiKit.outlined(t, 10)
	row.add_child(t)
	row.add_child(UiKit.spacer())
	var out := UiKit.game_button("나가기", UiKit.GRAY_DARK)
	out.pressed.connect(func(): UiKit.go_to(self, MAP_SCENE))
	row.add_child(out)

	var sheet := UiKit.note_paper()
	sheet.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sheet.offset_left = 22
	sheet.offset_right = -22
	sheet.offset_top = GameHeader.BOTTOM + 80.0
	sheet.offset_bottom = -24
	add_child(sheet)
	var v := UiKit.vbox(UiKit.SPACE_MD)
	sheet.add_child(v)
	v.add_child(UiKit.text("요리 공책", "h2", UiKit.NOTE_INK))
	_say = UiKit.paragraph("생선 한 마리와 재료를 주면 세라가 %d분 만에 새 요리를 알아내요. 하루에 하나씩이에요" % Menu.LAB_MINUTES, "body", UiKit.NOTE_INK_SOFT)
	_say.add_theme_font_size_override("font_size", 18)
	v.add_child(_say)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.scroll_deadzone = 8
	v.add_child(scroll)
	_list = UiKit.vbox(UiKit.SPACE_MD)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list)
	_refresh()
	Sound.play_bgm("town")
	UiKit.fade_in(self)


func _refresh() -> void:
	_header.refresh()
	for c in _list.get_children():
		c.queue_free()
	# 지금 되는 것 먼저, 그다음 모르는 것, 아는 것
	var ids: Array = Menu.unknown(GameState.flags)
	var ready_ids := ids.filter(func(id): return Menu.can_research(GameState, id))
	for id in ready_ids + ids.filter(func(id): return not id in ready_ids) + Menu.menu_list(GameState.flags):
		_list.add_child(_recipe_card(id))


func _recipe_card(id: String) -> PanelContainer:
	var r := Menu.recipe(id)
	var known := Menu.on_menu(GameState.flags, id)
	var card := PanelContainer.new()
	card.mouse_filter = Control.MOUSE_FILTER_PASS
	card.add_theme_stylebox_override("panel", UiKit.box(Color(UiKit.NOTE_DARK, 0.28), 18, Color(UiKit.NOTE_DARK, 0.6), 1, 14))
	var h := UiKit.hbox(UiKit.SPACE_LG)
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(h)
	var ic := UiKit.icon_rect("dish/" + Menu.art(id, ""), 84)
	if ic:
		if not known:
			ic.modulate = Color(0.12, 0.1, 0.18, 0.55) # 아직 모르는 요리는 그림자로
		h.add_child(ic)
	var info := UiKit.vbox(UiKit.SPACE_XS)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_child(UiKit.text(r.name if known else "??? (%s)" % SpecialGuest.STYLES[SpecialGuest.style_of(id)].name, "title", UiKit.INK))
	var fish_names := "아무 생선" if (r.fish as Array).is_empty() else ", ".join(PackedStringArray((r.fish as Array).map(func(f): return FishDB.get_fish(f).name)))
	if r.get("fresh", false):
		fish_names += " (오늘 잡은 것)"
	var d := UiKit.paragraph("%s + %s" % [fish_names, Menu.needs_text(id)] if not r.needs.is_empty() else fish_names, "caption", UiKit.INK_SOFT)
	d.add_theme_font_size_override("font_size", 17)
	info.add_child(d)
	var more := "구이 값의 %d%%" % int(float(r.mult) * 100) if id != "hoe" else "비싼 생선은 제값, 그 밖엔 구이 값의 140%"
	if not known:
		more += " · %s 친해지면 알려 줘요" % Josa.attach(str(Friends.person(r.who).get("call", r.who)), "과/와")
	info.add_child(UiKit.paragraph(more, "caption", UiKit.NOTE_INK_SOFT))
	h.add_child(info)
	if known:
		h.add_child(UiKit.status_tag("메뉴판", UiKit.GOLD_SOFT, UiKit.GOLD_DARK, Vector2(124, 52)))
	else:
		var b := UiKit.game_button("연구", UiKit.CORAL_DEEP, Vector2(124, 52), 19)
		b.disabled = not Menu.can_research(GameState, id) or GameState.time_minutes + Menu.LAB_MINUTES > DayFlow.SHOP_OPEN
		b.pressed.connect(_start.bind(id))
		h.add_child(b)
	return card


func _start(id: String) -> void:
	var fish := Menu.research_fish(id, GameState.inventory, GameState.day)
	if not Menu.research(GameState, id):
		return
	GameState.time_minutes += Menu.LAB_MINUTES
	var nm: String = Menu.recipe(id).name
	GameState.note("세라와 %s 만들어 냈다." % Josa.attach(nm, "을/를"), 3)
	Sound.play_sfx("newfish")
	Haptics.play("catch")
	_say.text = "세라: \"%s로 %s, 이거 되겠는데요?\" 오늘 저녁부터 메뉴판에서 고를 수 있어요" % [FishDB.get_fish(fish.id).name, nm]
	_refresh()
