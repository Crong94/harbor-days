extends Control
## 경자상회 안 (세로, 2026-11-24). 준호네 낚시방처럼 안으로 들어가 탭별로 산다. 규칙은 Store, KitchenDB, Tank, Coop.
## 그림: 가게 안 bg_store (그림 세션에 요청. 없으면 나무색 바탕), 경자 일러스트 portrait/gyeongja_*
##
## 구성: 맨 위 공통 헤더 / 가게 이름과 나가기 / 경자와 말풍선 / 아래 종이 시트(탭과 상품 목록)

const MAP_SCENE := "res://scenes/map/map.tscn"
const SHOP_BTN := Vector2(124, 52)
const TABS := [["food", "식재료"], ["gift", "선물"], ["kitchen", "주방"], ["home", "살림"]]
const GREETINGS := [
	"왔나. 천천히 골라라.",
	"채소는 매일 아침에 조금씩만 들어온다. 텃밭 거 떨어지면 와라.",
	"주방 장비도 주문해 준다. 읍내보다 싸게 해 줄게.",
]
const TALK_FOOD := ["싱싱한 걸로 골라 놨다.", "세라가 좋아하겠네.", "그거 넣고 푹 끓여 봐라."]

var _header: GameHeader
var _talk: Label
var _list: VBoxContainer
var _tab := "food"
var _tab_buttons := {}


func _ready() -> void:
	var base := ColorRect.new()
	base.color = UiKit.WOOD_DARK
	base.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(base)
	var art := UiKit.cover_art("bg_store")
	if art:
		add_child(art)
	add_child(UiKit.shade([[0.0, 0.5], [0.2, 0.1], [0.35, 0.35], [1.0, 0.6]]))
	_header = GameHeader.new()
	add_child(_header)
	_build_title()
	_build_owner()
	_build_sheet()
	_refresh()
	Sound.play_bgm("market")
	UiKit.fade_in(self)


func _build_title() -> void:
	var row := UiKit.hbox(UiKit.SPACE_MD)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	row.offset_left = 22
	row.offset_right = -20
	row.offset_top = GameHeader.BOTTOM + 12.0
	add_child(row)
	var title := UiKit.text("경자상회", "h2", UiKit.FOAM)
	UiKit.outlined(title, 10)
	row.add_child(title)
	row.add_child(UiKit.spacer())
	var out := UiKit.game_button("나가기", UiKit.GRAY_DARK)
	out.pressed.connect(func(): UiKit.go_to(self, MAP_SCENE))
	row.add_child(out)


func _build_owner() -> void:
	var row := UiKit.hbox(UiKit.SPACE_MD)
	row.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	row.offset_left = 20
	row.offset_right = -20
	row.offset_top = GameHeader.BOTTOM + 76.0
	row.offset_bottom = GameHeader.BOTTOM + 330.0
	add_child(row)
	row.add_child(ArtSlot.make("portrait/gyeongja_normal", "문경자", Vector2(190, 250)))
	var holder := UiKit.vbox()
	holder.alignment = BoxContainer.ALIGNMENT_END
	holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(holder)
	var bubble := UiKit.glass_panel(22, UiKit.RADIUS_LG, true)
	holder.add_child(bubble)
	var bv := UiKit.vbox(UiKit.SPACE_SM)
	bubble.add_child(bv)
	var tag := UiKit.name_label("문경자", Color(0, 0, 0, 0), 28)
	tag.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	bv.add_child(tag)
	_talk = UiKit.paragraph(GREETINGS.pick_random(), "body", UiKit.FOAM)
	_talk.add_theme_font_size_override("font_size", 20)
	bv.add_child(_talk)
	holder.add_child(UiKit.gap(18))


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
	var track := UiKit.tab_track()
	var h := UiKit.hbox(UiKit.SPACE_XS)
	track.add_child(h)
	for t in TABS:
		var b := UiKit.tab_button(t[1])
		b.pressed.connect(func():
			_tab = t[0]
			Sound.play_sfx("tap", 0.05, -8.0)
			_refresh())
		_tab_buttons[t[0]] = b
		h.add_child(b)
	v.add_child(track)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.scroll_deadzone = 8
	v.add_child(scroll)
	_list = UiKit.vbox(UiKit.SPACE_MD)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list)
	UiKit.rise_in(sheet, 0.1, 30.0)


func _refresh() -> void:
	_header.refresh()
	for k in _tab_buttons:
		_tab_buttons[k].set_pressed_no_signal(k == _tab)
	for c in _list.get_children():
		c.queue_free()
	match _tab:
		"food":
			for id in Store.INGREDIENT_ORDER:
				_list.add_child(_food_card(id))
		"gift":
			for id in Store.GOODS:
				_list.add_child(_gift_card(id))
		"kitchen":
			for id in KitchenDB.ORDER:
				_list.add_child(_gear_card(id))
		"home":
			_list.add_child(_tank_card())
			if GameState.has_flag("coop_open"):
				_list.add_child(_feed_card())


func _food_card(id: String) -> PanelContainer:
	var left := Store.stock(GameState, id)
	return _card(Pantry.art_of(id), "%s  ·  오늘 %d개 남음" % [Pantry.name_of(id), left], "들어가는 요리: " + Store.used_in(id) if not Store.used_in(id).is_empty() else "게시판 의뢰나 선물에 쓴다",
		"가진 것 %d개" % int(GameState.produce.get(id, 0)), Store.price(GameState, int(Store.INGREDIENTS[id])) if left > 0 else -1, "품절",
		func(): _done(Store.buy_ingredient(GameState, id), TALK_FOOD.pick_random()))


func _gift_card(id: String) -> PanelContainer:
	var g: Dictionary = Store.GOODS[id]
	var fans := PackedStringArray()
	for n in Friends.PEOPLE:
		if GameState.flags.get(Friends.PEOPLE[n].met, false) and Friends.taste(n, "goods:" + id) != "base":
			fans.append(Friends.PEOPLE[n].call)
	return _card("goods/" + id, g.name, g.desc, "좋아하는 사람: %s · 가진 것 %d개" % [", ".join(fans) if not fans.is_empty() else "아직 모름", int(GameState.goods.get(id, 0))],
		Store.price(GameState, int(g.price)), "", func(): _done(Store.buy_goods(GameState, id), "선물하게? 좋아하겠다."))


func _gear_card(id: String) -> PanelContainer:
	var lv := KitchenDB.level(GameState.kitchen, id)
	var np := KitchenDB.next_price(GameState.kitchen, id)
	var show_lv := mini(lv + 1, KitchenDB.MAX)
	return _card(KitchenDB.art(id, show_lv), "%s %d단계" % [KitchenDB.GEAR[id].name, lv] + (" → %s" % KitchenDB.LEVEL_NAMES[lv] if np >= 0 else ""),
		"지금: " + (KitchenDB.effect_text(id, lv) if lv > 1 else "식당에 처음부터 있던 것"), "다음: " + KitchenDB.effect_text(id, lv + 1) if np >= 0 else "",
		Store.price(GameState, np) if np >= 0 else -1, "최고", func(): _done(Store.buy_gear(GameState, id), "내일 아침이 아니라 지금 바로 갖다 놔 줄게."))


func _tank_card() -> PanelContainer:
	var nx := Tank.next_info(GameState.tank_level)
	var cur := Tank.level_info(GameState.tank_level)
	var now: String = "%s · %d마리" % [cur.name, int(cur.slots)] if GameState.tank_level > 0 else "아직 없음"
	return _card("kit/tank_%d" % clampi(GameState.tank_level + 1, 1, Tank.LEVELS.size()), "활어 수조", "고기를 살려 둔다. 꺼내면 오늘 잡은 것처럼 싱싱해서 회로 낼 수 있다. 지금: " + now,
		"다음: %s · %d마리" % [nx.name, int(nx.slots)] if not nx.is_empty() else "", Store.price(GameState, int(nx.price)) if not nx.is_empty() else -1, "최고",
		func(): _done(GameState.buy_tank(), "함지에 물 받아 두면 고기가 며칠은 산다. 식당에 갖다 놨다."))


func _feed_card() -> PanelContainer:
	return _card("hen", "닭 모이 한 포대", "모이를 준 날은 닭이 알을 낳는다", "남은 모이 %d번" % GameState.chicken_feed, Coop.FEED_PRICE, "",
		func(): _done(Coop.buy_feed(GameState), "닭들 배불리 먹여라."))


func _done(err: String, thanks: String) -> void:
	if not err.is_empty():
		Sound.play_sfx("bad", 0.0, -6.0)
		_say(err)
		return
	Sound.play_sfx("sold")
	Haptics.play("tap")
	_say(thanks)
	_refresh()


func _say(t: String) -> void:
	_talk.text = t
	_talk.visible_ratio = 0.0
	create_tween().tween_property(_talk, "visible_ratio", 1.0, 0.4)


## 상품 한 칸. price가 -1이면 사기 대신 sold 글자
func _card(icon: String, title: String, desc: String, stat: String, price: int, sold: String, on_buy: Callable) -> PanelContainer:
	var card := PanelContainer.new()
	card.mouse_filter = Control.MOUSE_FILTER_PASS
	card.add_theme_stylebox_override("panel", UiKit.box(Color(UiKit.NOTE_DARK, 0.28), 18, Color(UiKit.NOTE_DARK, 0.6), 1, 14))
	var h := UiKit.hbox(UiKit.SPACE_LG)
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(h)
	var ic := UiKit.icon_rect(icon, 80)
	if ic:
		var thumb := PanelContainer.new()
		thumb.add_theme_stylebox_override("panel", UiKit.box(Color.WHITE, UiKit.RADIUS_MD, Color.TRANSPARENT, 0, 6))
		thumb.custom_minimum_size = Vector2(92, 92)
		thumb.add_child(ic)
		h.add_child(thumb)
	var info := UiKit.vbox(UiKit.SPACE_XS)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_child(UiKit.paragraph(title, "title", UiKit.INK))
	var d := UiKit.paragraph(desc, "caption", UiKit.INK_SOFT)
	d.add_theme_font_size_override("font_size", 17)
	info.add_child(d)
	if not stat.is_empty():
		var s := UiKit.paragraph(stat, "caption", UiKit.TEAL_BTN)
		s.add_theme_font_override("font", UiKit.font("bold"))
		s.add_theme_font_size_override("font_size", 16)
		info.add_child(s)
	h.add_child(info)
	if price < 0:
		h.add_child(UiKit.status_tag(sold, UiKit.GOLD_SOFT, UiKit.GOLD_DARK, SHOP_BTN))
	else:
		var buy := UiKit.game_button(GameState.format_won(price), UiKit.CORAL_DEEP, SHOP_BTN, 19)
		buy.disabled = GameState.money < price
		buy.pressed.connect(on_buy)
		h.add_child(buy)
	return card
