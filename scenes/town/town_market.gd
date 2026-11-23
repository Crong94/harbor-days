extends Control
## 읍내 장터 (버스로 온다). 규칙은 Bus.
## - 도매상에게 생선을 수산시장보다 조금 비싸게 넘긴다
## - 미끼를 낚시방보다 싸게 산다
## - 돌아가는 버스 시각을 골라 타면 그만큼 시간이 흐르고 마을 정류장에 내린다
## 그림: 장터 배경 bg_town_market (아직 없음, 없으면 나무색 바탕)

const MAP_SCENE := "res://scenes/map/map.tscn"

var _header: GameHeader
var _talk: Label
var _list: VBoxContainer
var _box: Label
var _bus_row: HBoxContainer


func _ready() -> void:
	var base := ColorRect.new()
	base.color = UiKit.WOOD_DARK
	base.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(base)
	var art := UiKit.cover_art("bg_town_market")
	if art:
		add_child(art)
	add_child(UiKit.shade([[0.0, 0.5], [0.2, 0.1], [0.35, 0.35], [1.0, 0.6]]))

	_header = GameHeader.new()
	add_child(_header)
	var title := UiKit.text("읍내 장터", "h2", UiKit.FOAM)
	UiKit.outlined(title, 10)
	title.position = Vector2(26, GameHeader.BOTTOM + 14.0)
	add_child(title)

	var bubble := UiKit.glass_panel(22, UiKit.RADIUS_LG, true)
	bubble.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	bubble.offset_left = 22
	bubble.offset_right = -22
	bubble.offset_top = GameHeader.BOTTOM + 80.0
	add_child(bubble)
	_talk = UiKit.paragraph(GameState.line("오일장이 섰다. 도매상은 생선을 마을 시장보다 조금 더 쳐 주고, 미끼 가게는 묶음을 싸게 판다."), "body", UiKit.FOAM)
	_talk.add_theme_font_size_override("font_size", 20)
	bubble.add_child(_talk)

	_build_sheet()
	_refresh()
	Sound.play_bgm("market")
	UiKit.fade_in(self)


func _build_sheet() -> void:
	var sheet := UiKit.note_paper()
	sheet.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sheet.offset_left = 22
	sheet.offset_right = -22
	sheet.offset_top = GameHeader.BOTTOM + 230.0
	sheet.offset_bottom = -24
	add_child(sheet)
	var v := UiKit.vbox(UiKit.SPACE_SM)
	sheet.add_child(v)
	var head := UiKit.hbox(UiKit.SPACE_MD)
	head.alignment = BoxContainer.ALIGNMENT_CENTER
	head.add_child(UiKit.text("장 보기", "h2", UiKit.NOTE_INK))
	head.add_child(UiKit.spacer())
	_box = UiKit.text("", "body", UiKit.NOTE_INK_SOFT)
	_box.add_theme_font_size_override("font_size", 18)
	head.add_child(_box)
	v.add_child(head)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	_list = UiKit.vbox(UiKit.SPACE_SM)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list)
	v.add_child(UiKit.gap(4))
	v.add_child(UiKit.text("돌아가는 버스", "title", UiKit.NOTE_INK))
	_bus_row = UiKit.hbox(UiKit.SPACE_SM)
	v.add_child(_bus_row)
	UiKit.rise_in(sheet, 0.1, 30.0)


func _section(t: String) -> void:
	var l := UiKit.text(t, "title", UiKit.NOTE_INK_SOFT)
	l.add_theme_font_size_override("font_size", 19)
	_list.add_child(l)


func _refresh() -> void:
	_header.refresh()
	_box.text = "아이스박스 %d/%d" % [GameState.inventory.size(), GameState.icebox_size]
	for c in _list.get_children():
		c.queue_free()
	_section("생선 넘기기 (도매상)")
	if GameState.inventory.is_empty():
		_list.add_child(UiKit.paragraph("넘길 생선이 없어요", "body", UiKit.NOTE_INK_SOFT))
	var order := range(GameState.inventory.size())
	order.sort_custom(func(a, b):
		var ea: Dictionary = GameState.inventory[a]
		var eb: Dictionary = GameState.inventory[b]
		return Bus.fish_price(ea.id, ea.size) > Bus.fish_price(eb.id, eb.size))
	for i in order:
		var e: Dictionary = GameState.inventory[i]
		var sell := UiKit.game_button("팔기")
		sell.pressed.connect(_sell.bind(e))
		var p := Bus.fish_price(e.id, e.size)
		_list.add_child(FishLine.make(e, GameState.day, GameState.format_won(p), "시장 %s" % GameState.format_won(Market.price(e.id, e.size)), sell))
	_list.add_child(UiKit.gap(6))
	_section("미끼 묶음 (도매값)")
	for id in BaitDB.BAITS:
		if int(BaitDB.bait(id).amount) > 0:
			_list.add_child(_bait_line(id))
	_refresh_bus()


func _bait_line(id: String) -> PanelContainer:
	var b := BaitDB.bait(id)
	var row := UiKit.note_row()
	var h: HBoxContainer = row.get_child(0)
	var icon := UiKit.icon_rect(BaitDB.icon_art(id), 50)
	if icon:
		icon.custom_minimum_size = Vector2(84, 50)
		h.add_child(icon)
	var text := UiKit.vbox(-2)
	text.alignment = BoxContainer.ALIGNMENT_CENTER
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var title := UiKit.text("%s %d개" % [b.name, b.amount], "title", UiKit.NOTE_INK)
	title.add_theme_font_size_override("font_size", 23)
	text.add_child(title)
	var sub := UiKit.text("낚시방 %s · 가진 것 %d개" % [GameState.format_won(b.price), maxi(GameState.bait_count(id), 0)], "body", UiKit.NOTE_INK_SOFT)
	sub.add_theme_font_size_override("font_size", 17)
	text.add_child(sub)
	h.add_child(text)
	var price := Bus.bait_price(id)
	var buy := UiKit.game_button(GameState.format_won(price), UiKit.CORAL_DEEP)
	buy.disabled = GameState.money < price + Bus.FARE # 돌아갈 차비는 남긴다
	buy.pressed.connect(func():
		if not GameState.buy_bait(id, price).is_empty():
			Sound.play_sfx("bad", 0.0, -6.0)
			return
		Sound.play_sfx("sold")
		_say("%s 한 묶음 샀다. 낚시방보다 %s 싸다." % [b.name, GameState.format_won(int(b.price) - price)])
		_refresh())
	h.add_child(buy)
	return row


func _refresh_bus() -> void:
	for c in _bus_row.get_children():
		c.queue_free()
	for t in Bus.returns_after(GameState.time_minutes):
		var b := UiKit.game_button(Bus.clock(t), UiKit.TEAL_BTN)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(_go_home.bind(t))
		_bus_row.add_child(b)


func _sell(e: Dictionary) -> void:
	var got := GameState.sell_fish(e, Bus.fish_price(e.id, e.size))
	if got <= 0:
		return
	Sound.play_sfx("coin")
	Haptics.play("tap")
	_say("%s 하나 넘기고 %s 받았다." % [FishDB.get_fish(e.id).name, GameState.format_won(got)])
	_refresh()


## 고른 시각의 버스를 타고 마을 정류장에 내린다
## 차비가 모자라면 기사님이 있는 만큼만 받는다 (읍내에 갇히지 않게)
func _go_home(depart: int) -> void:
	GameState.spend(clampi(GameState.money, 0, Bus.FARE))
	GameState.time_minutes = depart + Bus.RIDE
	GameState.current_location = "bus"
	Sound.play_sfx("step")
	UiKit.go_to(self, MAP_SCENE)


func _say(t: String) -> void:
	_talk.text = GameState.line(t)
	_talk.visible_ratio = 0.0
	create_tween().tween_property(_talk, "visible_ratio", 1.0, 0.4)
