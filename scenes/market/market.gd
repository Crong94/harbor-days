extends Control
## 물빛 수산시장 (세로). 아이스박스 생선을 한 마리씩 오용팔 경매사에게 판다. 규칙은 Market.
## 그림: 시장 내부 bg_market (아직 없음, 없으면 나무색 바탕), 오용팔 초상화 npc_yongpal (아직 없음, 그림 자리)
##
## 구성: 맨 위 공통 헤더 / 시장 이름과 나가기 / 용팔과 말풍선 / 아래 종이 시트(생선 목록)

const MAP_SCENE := "res://scenes/map/map.tscn"

const GREETINGS := [
	"자, 오늘 물건 좀 보자. 좋은 건 제값 쳐 줄게.",
	"요새 배가 안 들어와서 {player} 사장 고기가 귀하다니까.",
	"비싼 고기는 식당보다 여기가 낫지. 내가 도시로 넘겨 줄게.",
]

var _header: GameHeader
var _talk: Label
var _list: VBoxContainer
var _box: Label


func _ready() -> void:
	var base := ColorRect.new()
	base.color = UiKit.WOOD_DARK
	base.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(base)
	var art := UiKit.cover_art("bg_market")
	if art:
		add_child(art)
	add_child(UiKit.shade([[0.0, 0.5], [0.2, 0.1], [0.35, 0.35], [1.0, 0.6]]))

	_header = GameHeader.new()
	add_child(_header)
	var row := UiKit.hbox(UiKit.SPACE_MD)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	row.offset_left = 22
	row.offset_right = -20
	row.offset_top = GameHeader.BOTTOM + 12.0
	add_child(row)
	var title := UiKit.text("물빛 수산시장", "h2", UiKit.FOAM)
	UiKit.outlined(title, 10)
	row.add_child(title)
	row.add_child(UiKit.spacer())
	var out := UiKit.action("나가기", "secondary", true)
	out.custom_minimum_size.x = 104
	out.pressed.connect(func(): UiKit.go_to(self, MAP_SCENE))
	row.add_child(out)

	_build_yongpal()
	_build_sheet()
	_refresh()
	Sound.play_bgm("market")
	UiKit.fade_in(self)


func _build_yongpal() -> void:
	var row := UiKit.hbox(UiKit.SPACE_MD)
	row.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	row.offset_left = 20
	row.offset_right = -20
	row.offset_top = GameHeader.BOTTOM + 76.0
	row.offset_bottom = GameHeader.BOTTOM + 300.0
	add_child(row)
	row.add_child(ArtSlot.make("npc_yongpal", "오용팔", Vector2(170, 220)))
	var holder := UiKit.vbox()
	holder.alignment = BoxContainer.ALIGNMENT_END
	holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(holder)
	var bubble := UiKit.glass_panel(22, UiKit.RADIUS_LG, true)
	holder.add_child(bubble)
	var bv := UiKit.vbox(UiKit.SPACE_SM)
	bubble.add_child(bv)
	var tag := UiKit.badge("오용팔", UiKit.CORAL, Color.WHITE)
	tag.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	bv.add_child(tag)
	_talk = UiKit.paragraph(GameState.line(GREETINGS.pick_random()), "body", UiKit.FOAM)
	_talk.add_theme_font_size_override("font_size", 20)
	bv.add_child(_talk)
	holder.add_child(UiKit.gap(18))


func _build_sheet() -> void:
	var sheet := PanelContainer.new()
	sheet.add_theme_stylebox_override("panel", UiKit.paper_box(22, UiKit.RADIUS_LG, 3))
	sheet.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sheet.offset_left = 12
	sheet.offset_right = -12
	sheet.offset_top = GameHeader.BOTTOM + 314.0
	sheet.offset_bottom = -16
	add_child(sheet)
	var v := UiKit.vbox(UiKit.SPACE_MD)
	sheet.add_child(v)
	var head := UiKit.hbox(UiKit.SPACE_MD)
	head.alignment = BoxContainer.ALIGNMENT_CENTER
	head.add_child(UiKit.text("생선 팔기", "h2", UiKit.INK))
	head.add_child(UiKit.spacer())
	_box = UiKit.text("", "label", UiKit.INK_SOFT)
	head.add_child(_box)
	v.add_child(head)
	v.add_child(UiKit.paragraph("흔한 고기는 저녁에 구워 파는 게 더 남아요. 비싼 고기는 보통 손님이 못 사니 여기서 팔아요", "caption", UiKit.INK_SOFT))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	_list = UiKit.vbox(UiKit.SPACE_SM)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list)
	UiKit.rise_in(sheet, 0.1, 30.0)


func _refresh() -> void:
	_header.refresh()
	_box.text = "아이스박스 %d / %d" % [GameState.inventory.size(), GameState.icebox_size]
	for c in _list.get_children():
		c.queue_free()
	if GameState.inventory.is_empty():
		var l := UiKit.paragraph("팔 생선이 없어요. 방파제에서 낚아 와요", "body", UiKit.INK_SOFT, 0.0, HORIZONTAL_ALIGNMENT_CENTER)
		l.custom_minimum_size.y = 120
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_list.add_child(l)
		return
	var spoiling := GameState.spoiling_tonight()
	var order := range(GameState.inventory.size())
	order.sort_custom(func(a, b):
		var ea: Dictionary = GameState.inventory[a]
		var eb: Dictionary = GameState.inventory[b]
		return Market.price(ea.id, ea.size) > Market.price(eb.id, eb.size))
	for i in order:
		_list.add_child(_fish_row(GameState.inventory[i], spoiling.has(GameState.inventory[i])))


func _fish_row(e: Dictionary, spoiling: bool) -> PanelContainer:
	var row := PanelContainer.new()
	row.add_theme_stylebox_override("panel", UiKit.inset_box(UiKit.SPACE_MD, UiKit.RADIUS_MD))
	var h := UiKit.hbox(UiKit.SPACE_MD)
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(h)
	var t := UiKit.icon_rect("fish_" + e.id, 44)
	if t:
		t.custom_minimum_size = Vector2(80, 44)
		h.add_child(t)
	var info := UiKit.vbox(0)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var name_row := UiKit.hbox(6)
	name_row.add_child(UiKit.text(FishDB.get_fish(e.id).name, "title", UiKit.INK))
	name_row.add_child(UiKit.text("★".repeat(FishDB.stars(e.id, e.size)), "label", UiKit.SUN))
	info.add_child(name_row)
	var tags := UiKit.hbox(4)
	tags.add_child(UiKit.text("%.1fcm" % e.size, "caption", UiKit.INK_SOFT))
	if spoiling:
		tags.add_child(UiKit.badge("오늘 밤 상해요", UiKit.CORAL, Color.WHITE))
	if Market.better_here(e.id, e.size):
		tags.add_child(UiKit.badge("시장이 나아요", UiKit.SEA, Color.WHITE))
	info.add_child(tags)
	h.add_child(info)
	var sell := UiKit.action(GameState.format_won(Market.price(e.id, e.size)), "primary", true)
	sell.custom_minimum_size.x = 128
	sell.pressed.connect(_sell.bind(e))
	h.add_child(sell)
	return row


func _sell(e: Dictionary) -> void:
	var got := GameState.sell_fish(e)
	if got <= 0:
		return
	Sound.play_sfx("coin")
	Haptics.play("tap")
	var fname: String = FishDB.get_fish(e.id).name
	_say("%s %.0fcm! %s 쳐 줄게." % [fname, e.size, GameState.format_won(got)] if FishDB.stars(e.id, e.size) >= 3 else "%s 하나, %s." % [fname, GameState.format_won(got)])
	_refresh()


func _say(t: String) -> void:
	_talk.text = GameState.line(t)
	_talk.visible_ratio = 0.0
	create_tween().tween_property(_talk, "visible_ratio", 1.0, 0.4)
