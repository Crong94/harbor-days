extends Control
## 준호네 낚시방. 낚싯대와 릴을 사고 바로 장착할 수 있다.
## 그림: 가게 내부 bg_tackle_shop, 준호 초상화 npc_junho (사용자에게 받음. 없으면 그림 자리만 보인다)
##       장비 아이콘 gear_icon/* (바다 한 접시에서 가져옴, GearDB의 icon)

const MAP_SCENE := "res://scenes/map/map.tscn"

const GREETINGS := [
	"형, 어서 오세요! 오늘은 뭐 보러 오셨어요?",
	"형, 이 릴 기어비 보세요. 아니 진짜로, 보시라니까요.",
	"요즘 새벽 볼락 잘 붙는대요. 장비 하나 바꿔 보실래요?",
]

var _money: Label
var _talk: Label
var _list: VBoxContainer


func _ready() -> void:
	var base := ColorRect.new()
	base.color = UiKit.WOOD_DARK
	base.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(base)
	var bg := ArtSlot.make("bg_tackle_shop", "준호네 낚시방 내부", Vector2.ZERO)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var junho := ArtSlot.make("npc_junho", "이준호 초상화", Vector2(300, 420))
	junho.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	junho.offset_left = 40
	junho.offset_right = 340
	junho.offset_top = -600
	junho.offset_bottom = -180
	add_child(junho)

	var bubble := PanelContainer.new()
	bubble.add_theme_stylebox_override("panel", UiKit.box(Color(UiKit.NAVY_DEEP, 0.92), 16, UiKit.MUSTARD, 2, 20))
	bubble.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	bubble.offset_left = 30
	bubble.offset_right = 520
	bubble.offset_top = -170
	bubble.offset_bottom = -24
	bubble.grow_vertical = Control.GROW_DIRECTION_BEGIN
	add_child(bubble)
	var bv := VBoxContainer.new()
	bubble.add_child(bv)
	bv.add_child(UiKit.label("이준호", UiKit.SIZE_BODY, UiKit.MUSTARD))
	_talk = UiKit.label(GameState.line(GREETINGS.pick_random()), 22, UiKit.CREAM)
	_talk.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bv.add_child(_talk)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiKit.box(UiKit.PAPER, 16, UiKit.NAVY, 2, 22))
	panel.set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE)
	panel.offset_left = -700
	panel.offset_right = -30
	panel.offset_top = 30
	panel.offset_bottom = -30
	add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	panel.add_child(v)
	var head := HBoxContainer.new()
	var title := UiKit.label("준호네 낚시방", 32, UiKit.INK)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	_money = UiKit.label("", 22, UiKit.TEAL)
	head.add_child(_money)
	v.add_child(head)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 8)
	scroll.add_child(_list)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	var out := UiKit.button("나가기", false)
	out.pressed.connect(func(): UiKit.go_to(self, MAP_SCENE))
	row.add_child(out)
	v.add_child(row)

	_refresh()
	Sound.play_bgm("market")
	UiKit.fade_in(self)
	out.grab_focus()


func _refresh() -> void:
	_money.text = "잔고 " + GameState.format_won(GameState.money)
	for c in _list.get_children():
		c.queue_free()
	_list.add_child(UiKit.label("낚싯대", 22, UiKit.TEAL))
	for id in GearDB.RODS:
		var r: Dictionary = GearDB.RODS[id]
		_list.add_child(_item_row("rod", id, r, "던지기 %d%%  버티기 +%d%%" % [int(r.cast * 100), int(r.strength * 100)]))
	_list.add_child(UiKit.label("릴", 22, UiKit.TEAL))
	for id in GearDB.REELS:
		var l: Dictionary = GearDB.REELS[id]
		_list.add_child(_item_row("reel", id, l, "감기 %d%%  드랙 +%d%%" % [int(l.speed * 100), int(l.drag * 100)]))


func _item_row(kind: String, id: String, item: Dictionary, stats: String) -> PanelContainer:
	var owned: Array = GameState.owned_rods if kind == "rod" else GameState.owned_reels
	var equipped: String = GameState.equipped_rod if kind == "rod" else GameState.equipped_reel
	var box := PanelContainer.new()
	box.add_theme_stylebox_override("panel", UiKit.box(UiKit.CREAM, 12, Color.TRANSPARENT, 0, 10))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	box.add_child(h)
	h.add_child(ArtSlot.make(GearDB.icon_art(item), item.name, Vector2(72, 72)))
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_child(UiKit.label(item.name, 22, UiKit.INK))
	var desc := UiKit.label(item.desc, 16, UiKit.INK_SOFT)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_child(desc)
	info.add_child(UiKit.label(stats, 16, UiKit.TEAL))
	h.add_child(info)
	var b: Button
	if id == equipped:
		h.add_child(UiKit.label("사용 중", 18, UiKit.CORAL))
		return box
	if id in owned:
		b = UiKit.button("장착", false)
		b.pressed.connect(func():
			_equip(kind, id)
			_say("좋죠! %s, 손에 착 붙을 거예요." % item.name))
	else:
		b = UiKit.button(GameState.format_won(item.price))
		b.disabled = GameState.money < item.price
		b.pressed.connect(_buy.bind(kind, id))
	b.custom_minimum_size = Vector2(140, 44)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(b)
	return box


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


func _say(text: String) -> void:
	_talk.text = GameState.line(text)
