extends Control
## 준호네 낚시방 (세로). 낚싯대와 릴을 사고 바로 장착할 수 있다.
## 그림: 가게 내부 bg_tackle_shop (지금은 바다 한 접시의 임시 그림), 준호 초상화 npc_junho (사용자에게 받음)
##       장비 아이콘 gear_icon/* (바다 한 접시에서 가져옴, GearDB의 icon)
##
## 구성: 위 유리 상단바 / 준호와 말풍선 / 아래 종이 시트(낚싯대·릴 탭과 상품 목록)

const MAP_SCENE := "res://scenes/map/map.tscn"

const GREETINGS := [
	"형, 어서 오세요! 오늘은 뭐 보러 오셨어요?",
	"형, 이 릴 기어비 보세요. 아니 진짜로, 보시라니까요.",
	"요즘 새벽 볼락 잘 붙는대요. 장비 하나 바꿔 보실래요?",
]

var _money: PanelContainer
var _talk: Label
var _list: VBoxContainer
var _tab := "rod"
var _tab_buttons := {}


func _ready() -> void:
	var base := ColorRect.new()
	base.color = UiKit.WOOD_DARK
	base.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(base)
	var art := UiKit.cover_art("bg_tackle_shop")
	if art:
		add_child(art)
	add_child(UiKit.shade([[0.0, 0.5], [0.2, 0.1], [0.35, 0.35], [1.0, 0.6]]))

	_build_top_bar()
	_build_junho()
	_build_sheet()
	_refresh()
	Sound.play_bgm("market")
	UiKit.fade_in(self)


func _build_top_bar() -> void:
	var bar := UiKit.glass_panel(0, UiKit.RADIUS_LG, true)
	var s: StyleBoxFlat = bar.get_theme_stylebox("panel")
	s.content_margin_left = 22
	s.content_margin_right = 14
	s.content_margin_top = 12
	s.content_margin_bottom = 12
	bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	bar.offset_left = 16
	bar.offset_right = -16
	bar.offset_top = 20
	add_child(bar)
	var h := UiKit.hbox(UiKit.SPACE_MD)
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	bar.add_child(h)
	var col := UiKit.vbox(0)
	var title := UiKit.text("준호네 낚시방", "h2", UiKit.FOAM)
	title.add_theme_font_override("font", UiKit.font("serif_bold"))
	title.add_theme_font_size_override("font_size", 26)
	col.add_child(title)
	col.add_child(UiKit.text("장비 · 미끼 · 수리", "caption", UiKit.FOAM_SOFT))
	h.add_child(col)
	h.add_child(UiKit.spacer())
	_money = UiKit.chip("", "", "icon_coin")
	h.add_child(_money)
	var out := UiKit.action("나가기", "glass", true)
	out.custom_minimum_size.x = 92
	out.pressed.connect(func(): UiKit.go_to(self, MAP_SCENE))
	h.add_child(out)


## 준호 초상화와 말풍선
func _build_junho() -> void:
	var row := UiKit.hbox(UiKit.SPACE_MD)
	row.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	row.offset_left = 20
	row.offset_right = -20
	row.offset_top = 124
	row.offset_bottom = 404
	add_child(row)
	var junho := ArtSlot.make("npc_junho", "이준호", Vector2(210, 280))
	row.add_child(junho)
	var bubble_holder := UiKit.vbox()
	bubble_holder.alignment = BoxContainer.ALIGNMENT_END
	bubble_holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(bubble_holder)
	var bubble := UiKit.glass_panel(22, UiKit.RADIUS_LG, true)
	bubble_holder.add_child(bubble)
	var bv := UiKit.vbox(UiKit.SPACE_SM)
	bubble.add_child(bv)
	var tag := UiKit.badge("이준호", UiKit.CORAL, Color.WHITE)
	tag.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	bv.add_child(tag)
	_talk = UiKit.paragraph(GameState.line(GREETINGS.pick_random()), "body", UiKit.FOAM)
	_talk.add_theme_font_size_override("font_size", 20)
	bv.add_child(_talk)
	bubble_holder.add_child(UiKit.gap(18))


## 아래 종이 시트: 탭과 상품 목록
func _build_sheet() -> void:
	var sheet := PanelContainer.new()
	sheet.add_theme_stylebox_override("panel", UiKit.paper_box(22, UiKit.RADIUS_LG, 3))
	sheet.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sheet.offset_left = 12
	sheet.offset_right = -12
	sheet.offset_top = 420
	sheet.offset_bottom = -16
	add_child(sheet)
	var v := UiKit.vbox(UiKit.SPACE_MD)
	sheet.add_child(v)
	v.add_child(_make_tabs())
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	_list = UiKit.vbox(UiKit.SPACE_MD)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list)
	UiKit.rise_in(sheet, 0.1, 30.0)


## 낚싯대 / 릴 탭 (알약 모양 분할 버튼)
func _make_tabs() -> PanelContainer:
	var track := PanelContainer.new()
	var ts := UiKit.box(UiKit.PAPER_DEEP, UiKit.RADIUS_PILL, Color.TRANSPARENT, 0, 5)
	track.add_theme_stylebox_override("panel", ts)
	var h := UiKit.hbox(UiKit.SPACE_XS)
	track.add_child(h)
	for kind in [["rod", "낚싯대"], ["reel", "릴"]]:
		var b := Button.new()
		b.text = kind[1]
		b.toggle_mode = true
		b.focus_mode = Control.FOCUS_ALL
		b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size.y = 44
		b.add_theme_font_override("font", UiKit.font("bold"))
		b.add_theme_font_size_override("font_size", 18)
		var off := UiKit.box(Color(0, 0, 0, 0), UiKit.RADIUS_PILL, Color.TRANSPARENT, 0, 0)
		var on := UiKit.elevate(UiKit.box(Color.WHITE, UiKit.RADIUS_PILL, Color.TRANSPARENT, 0, 0), 1)
		b.add_theme_stylebox_override("normal", off)
		b.add_theme_stylebox_override("hover", off)
		b.add_theme_stylebox_override("pressed", on)
		b.add_theme_stylebox_override("hover_pressed", on)
		b.add_theme_stylebox_override("focus", UiKit.box(Color.TRANSPARENT, UiKit.RADIUS_PILL, UiKit.SUN, 2, 0))
		b.add_theme_color_override("font_color", UiKit.INK_MUTED)
		b.add_theme_color_override("font_hover_color", UiKit.INK_SOFT)
		b.add_theme_color_override("font_pressed_color", UiKit.INK)
		b.add_theme_color_override("font_hover_pressed_color", UiKit.INK)
		b.pressed.connect(func():
			_tab = kind[0]
			Sound.play_sfx("tap", 0.05, -8.0)
			_refresh())
		_tab_buttons[kind[0]] = b
		h.add_child(b)
	return track


func _refresh() -> void:
	UiKit.set_chip(_money, GameState.format_won(GameState.money))
	for k in _tab_buttons:
		_tab_buttons[k].set_pressed_no_signal(k == _tab)
	for c in _list.get_children():
		c.queue_free()
	if _tab == "rod":
		for id in GearDB.RODS:
			var r: Dictionary = GearDB.RODS[id]
			_list.add_child(_item_card("rod", id, r, ["던지기 %d%%" % int(r.cast * 100), "버티기 +%d%%" % int(r.strength * 100)]))
	else:
		for id in GearDB.REELS:
			var l: Dictionary = GearDB.REELS[id]
			_list.add_child(_item_card("reel", id, l, ["감기 %d%%" % int(l.speed * 100), "드랙 +%d%%" % int(l.drag * 100)]))


func _item_card(kind: String, id: String, item: Dictionary, stats: Array) -> PanelContainer:
	var owned: Array = GameState.owned_rods if kind == "rod" else GameState.owned_reels
	var equipped: String = GameState.equipped_rod if kind == "rod" else GameState.equipped_reel
	var card := PanelContainer.new()
	var s := UiKit.inset_box(UiKit.SPACE_LG, UiKit.RADIUS_LG)
	if id == equipped:
		s.border_color = UiKit.CORAL
		s.set_border_width_all(2)
	card.add_theme_stylebox_override("panel", s)
	var h := UiKit.hbox(UiKit.SPACE_LG)
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(h)

	var thumb := PanelContainer.new()
	thumb.add_theme_stylebox_override("panel", UiKit.box(Color.WHITE, UiKit.RADIUS_MD, Color.TRANSPARENT, 0, 6))
	thumb.custom_minimum_size = Vector2(92, 92)
	var ic := UiKit.icon_rect(GearDB.icon_art(item), 80)
	if ic:
		thumb.add_child(ic)
	h.add_child(thumb)

	var info := UiKit.vbox(UiKit.SPACE_XS)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_child(UiKit.text(item.name, "title", UiKit.INK))
	info.add_child(UiKit.paragraph(item.desc, "caption", UiKit.INK_SOFT))
	var stat_row := UiKit.hbox(UiKit.SPACE_XS)
	for st in stats:
		stat_row.add_child(UiKit.badge(st, Color(UiKit.SEA, 0.14), UiKit.SEA))
	info.add_child(stat_row)
	h.add_child(info)

	if id == equipped:
		h.add_child(UiKit.badge("사용 중", UiKit.CORAL, Color.WHITE))
	elif id in owned:
		var eq := UiKit.action("장착", "secondary", true)
		eq.custom_minimum_size.x = 104
		eq.pressed.connect(func():
			_equip(kind, id)
			_say("좋죠! %s, 손에 착 붙을 거예요." % item.name))
		h.add_child(eq)
	else:
		var buy := UiKit.action(GameState.format_won(item.price), "primary", true)
		buy.custom_minimum_size.x = 128
		buy.disabled = GameState.money < item.price
		buy.pressed.connect(_buy.bind(kind, id))
		h.add_child(buy)
	return card


func _buy(kind: String, id: String) -> void:
	var err := GameState.buy_gear(kind, id)
	if not err.is_empty():
		Sound.play_sfx("bad", 0.0, -6.0)
		_say("아이고 형, " + err)
		return
	Sound.play_sfx("sold")
	_equip(kind, id)
	var item := GearDB.rod(id) if kind == "rod" else GearDB.reel(id)
	_say("감사합니다! %s 바로 달아 드렸어요. 방파제 가면 차이 느끼실걸요." % item.name)


func _equip(kind: String, id: String) -> void:
	if kind == "rod":
		GameState.equipped_rod = id
	else:
		GameState.equipped_reel = id
	_refresh()


func _say(t: String) -> void:
	_talk.text = GameState.line(t)
	_talk.visible_ratio = 0.0
	create_tween().tween_property(_talk, "visible_ratio", 1.0, 0.4)
