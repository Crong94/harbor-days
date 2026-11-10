extends Control
## 준호네 낚시방 (세로). 낚싯대와 릴(10단계)을 사고 바로 장착하고, 미끼를 산다.
## 이야기로 받는 장비(unlock story)는 조건만 보여 주고, 다음 바다 장비(later)는 진열하지 않는다.
## 그림: 가게 내부 bg_tackle_shop (지금은 바다 한 접시의 임시 그림), 준호 초상화 npc_junho (사용자에게 받음)
##       장비 아이콘 gear_icon/* (바다 한 접시에서 가져옴, GearDB의 icon)
##
## 구성: 위 유리 상단바 / 준호와 말풍선 / 아래 종이 시트(낚싯대·릴 탭과 상품 목록)

const MAP_SCENE := "res://scenes/map/map.tscn"
## 상품 오른쪽 칸 크기 (사기, 장착, 쓰는 중, 잠김 모두 같다)
const SHOP_BTN := Vector2(124, 52)

const GREETINGS := [
	"형, 어서 오세요! 오늘은 뭐 보러 오셨어요?",
	"형, 이 릴 기어비 보세요. 아니 진짜로, 보시라니까요.",
	"요즘 새벽 볼락 잘 붙는대요. 장비 하나 바꿔 보실래요?",
]

var _header: GameHeader
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


## 맨 위 공통 헤더 + 그 아래 가게 이름과 나가기
func _build_top_bar() -> void:
	_header = GameHeader.new()
	add_child(_header)
	_header.gear_changed.connect(_refresh)
	var row := UiKit.hbox(UiKit.SPACE_MD)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	row.offset_left = 22
	row.offset_right = -20
	row.offset_top = GameHeader.BOTTOM + 12.0
	add_child(row)
	var title := UiKit.text("준호네 낚시방", "h2", UiKit.FOAM)
	UiKit.outlined(title, 10)
	row.add_child(title)
	row.add_child(UiKit.spacer())
	var out := UiKit.game_button("나가기", UiKit.GRAY_DARK)
	out.pressed.connect(func(): UiKit.go_to(self, MAP_SCENE))
	row.add_child(out)


## 준호 초상화와 말풍선
func _build_junho() -> void:
	var row := UiKit.hbox(UiKit.SPACE_MD)
	row.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	row.offset_left = 20
	row.offset_right = -20
	row.offset_top = GameHeader.BOTTOM + 76.0
	row.offset_bottom = GameHeader.BOTTOM + 330.0
	add_child(row)
	var junho := ArtSlot.make("npc_junho", "이준호", Vector2(190, 250))
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
	var sheet := UiKit.note_paper(20, 20)
	sheet.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sheet.offset_left = 18
	sheet.offset_right = -18
	sheet.offset_top = GameHeader.BOTTOM + 344.0
	sheet.offset_bottom = -22
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
	var track := UiKit.tab_track()
	var h := UiKit.hbox(UiKit.SPACE_XS)
	track.add_child(h)
	for kind in [["rod", "낚싯대"], ["reel", "릴"], ["bait", "미끼"]]:
		var b := UiKit.tab_button(kind[1])
		b.pressed.connect(func():
			_tab = kind[0]
			Sound.play_sfx("tap", 0.05, -8.0)
			_refresh())
		_tab_buttons[kind[0]] = b
		h.add_child(b)
	return track


func _refresh() -> void:
	_header.refresh()
	for k in _tab_buttons:
		_tab_buttons[k].set_pressed_no_signal(k == _tab)
	for c in _list.get_children():
		c.queue_free()
	if _tab == "rod":
		for id in [GearDB.DEFAULT_ROD] + GearDB.shop_list("rod"):
			var r: Dictionary = GearDB.RODS[id]
			_list.add_child(_item_card("rod", id, r, ["던지기 %d%%" % int(r.cast * 100), "버티기 +%d%%" % int(r.strength * 100)]))
	elif _tab == "reel":
		for id in [GearDB.DEFAULT_REEL] + GearDB.shop_list("reel"):
			var l: Dictionary = GearDB.REELS[id]
			_list.add_child(_item_card("reel", id, l, ["감기 %d%%" % int(l.speed * 100), "드랙 +%d%%" % int(l.drag * 100)]))
	else:
		for id in BaitDB.ORDER:
			if BaitDB.bait(id).amount > 0:
				_list.add_child(_bait_card(id))


func _item_card(kind: String, id: String, item: Dictionary, stats: Array) -> PanelContainer:
	var owned: Array = GameState.owned_rods if kind == "rod" else GameState.owned_reels
	var equipped: String = GameState.equipped_rod if kind == "rod" else GameState.equipped_reel
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _card_box(id == equipped))
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
	var stat_row := UiKit.hbox(UiKit.SPACE_MD)
	for st in stats:
		stat_row.add_child(_stat_text(st))
	info.add_child(stat_row)
	h.add_child(info)

	# 오른쪽 칸은 단추든 상태 표시든 같은 크기 (SHOP_BTN)
	if id == equipped:
		h.add_child(UiKit.status_tag("쓰는 중", UiKit.GOLD_SOFT, UiKit.GOLD_DARK, SHOP_BTN))
	elif id in owned:
		var eq := UiKit.game_button("장착", UiKit.TEAL_BTN, SHOP_BTN)
		eq.pressed.connect(func():
			_equip(kind, id)
			_say("좋죠! %s, 손에 착 붙을 거예요." % item.name))
		h.add_child(eq)
	elif item.get("unlock", "shop") == "story":
		var lock := UiKit.vbox(4)
		lock.alignment = BoxContainer.ALIGNMENT_CENTER
		lock.add_child(UiKit.status_tag("잠김", Color(UiKit.NOTE_DARK, 0.8), UiKit.NOTE_INK_SOFT, SHOP_BTN))
		var why := UiKit.paragraph(item.get("unlock_text", ""), "caption", UiKit.NOTE_INK_SOFT, SHOP_BTN.x, HORIZONTAL_ALIGNMENT_CENTER)
		lock.add_child(why)
		h.add_child(lock)
	else:
		var buy := UiKit.game_button(GameState.format_won(item.price), UiKit.CORAL_DEEP, SHOP_BTN, 19)
		buy.disabled = GameState.money < item.price
		buy.pressed.connect(_buy.bind(kind, id))
		h.add_child(buy)
	return card


## 상품 칸: 공책 위 옅은 칸. 쓰는 것은 금테
func _card_box(on: bool) -> StyleBoxFlat:
	var s := UiKit.box(Color(UiKit.GOLD_SOFT, 0.7) if on else Color(UiKit.NOTE_DARK, 0.28), 18, UiKit.GOLD_DARK if on else Color(UiKit.NOTE_DARK, 0.6), 2 if on else 1, 14)
	return s


## 미끼 한 줄: 아이콘, 이름, 잘 무는 고기, 가진 수, 사기
func _bait_card(id: String) -> PanelContainer:
	var b := BaitDB.bait(id)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _card_box(false))
	var h := UiKit.hbox(UiKit.SPACE_LG)
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(h)
	var thumb := PanelContainer.new()
	thumb.add_theme_stylebox_override("panel", UiKit.box(Color.WHITE, UiKit.RADIUS_MD, Color.TRANSPARENT, 0, 6))
	thumb.custom_minimum_size = Vector2(92, 92)
	var ic := UiKit.icon_rect(BaitDB.icon_art(id), 80)
	if ic:
		thumb.add_child(ic)
	h.add_child(thumb)
	var info := UiKit.vbox(UiKit.SPACE_XS)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_child(UiKit.text("%s  ·  %d개 묶음" % [b.name, b.amount], "title", UiKit.INK))
	info.add_child(UiKit.paragraph(b.desc, "caption", UiKit.INK_SOFT))
	var stat_row := UiKit.hbox(UiKit.SPACE_MD)
	stat_row.add_child(_stat_text("잘 무는 고기: " + BaitDB.liked_names(id)))
	info.add_child(stat_row)
	info.add_child(UiKit.text("가진 것 %d개" % maxi(GameState.bait_count(id), 0), "caption", UiKit.INK_SOFT))
	h.add_child(info)
	var buy := UiKit.game_button(GameState.format_won(b.price), UiKit.CORAL_DEEP, SHOP_BTN, 19)
	buy.disabled = GameState.money < b.price
	buy.pressed.connect(func():
		var err := GameState.buy_bait(id)
		if not err.is_empty():
			Sound.play_sfx("bad", 0.0, -6.0)
			_say("아이고 형, " + err)
			return
		Sound.play_sfx("sold")
		GameState.equipped_bait = id
		_say("%s 넣어 드렸어요! %s 노리시는 거죠?" % [b.name, BaitDB.liked_names(id)])
		_refresh())
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


## 능력치 한 토막 (알약 대신 청록 글자)
func _stat_text(t: String) -> Label:
	var l := UiKit.text(t, "body", UiKit.TEAL_BTN)
	l.add_theme_font_override("font", UiKit.font("bold"))
	l.add_theme_font_size_override("font_size", 15)
	return l
