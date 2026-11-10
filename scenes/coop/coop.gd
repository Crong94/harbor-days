extends Control
## 닭장 (세로). 모이를 주고 달걀을 줍는다. 모이가 떨어지면 경자상회에 한 포대 시킨다. 규칙은 Coop
## 그림: 위쪽은 마을 지도(map_village)에서 닭장 자리만 크게 보여 준다. 닭 그림 hen (사용자에게 받음. 없으면 그림 자리만)

const MAP_SCENE := "res://scenes/map/map.tscn"
## 지도 그림에서 닭장이 있는 자리 (1536x1024 기준 픽셀)
const MAP_REGION := Rect2(846, 420, 330, 196)
const ART_H := 330.0

var _header: GameHeader
var _hint: Label
var _hens_row: HBoxContainer
var _hens_text: Label
var _egg_text: Label
var _egg_btn: Button
var _feed_text: Label
var _feed_btn: Button
var _buy_btn: Button
var _basket: Label


func _ready() -> void:
	var base := ColorRect.new()
	base.color = UiKit.INK
	base.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(base)
	_build_art()
	_build_top_bar()
	_build_sheet()
	_refresh()
	Sound.play_bgm("market")
	UiKit.fade_in(self)


## 위쪽: 지도에서 닭장 자리를 잘라 꽉 채운다
func _build_art() -> void:
	if not ArtSlot.has_art("map_village"):
		return
	var r := TextureRect.new()
	var at := AtlasTexture.new()
	at.atlas = load(ArtSlot.art_path("map_village"))
	at.region = MAP_REGION
	r.texture = at
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	r.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	r.offset_bottom = GameHeader.BOTTOM + ART_H
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(r)


func _build_top_bar() -> void:
	_header = GameHeader.new()
	add_child(_header)
	var row := UiKit.hbox(UiKit.SPACE_MD)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	row.offset_left = 22
	row.offset_right = -20
	row.offset_top = GameHeader.BOTTOM + 12.0
	add_child(row)
	var title := UiKit.text("닭장", "h2", UiKit.FOAM)
	UiKit.outlined(title, 10)
	row.add_child(title)
	row.add_child(UiKit.spacer())
	var out := UiKit.action("나가기", "secondary", true)
	out.custom_minimum_size.x = 104
	out.pressed.connect(func(): UiKit.go_to(self, MAP_SCENE))
	row.add_child(out)


func _build_sheet() -> void:
	var sheet := PanelContainer.new()
	sheet.add_theme_stylebox_override("panel", UiKit.paper_box(22, UiKit.RADIUS_LG, 3))
	sheet.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sheet.offset_left = 12
	sheet.offset_right = -12
	sheet.offset_top = GameHeader.BOTTOM + ART_H - 40.0
	sheet.offset_bottom = -16
	add_child(sheet)
	var v := UiKit.vbox(UiKit.SPACE_MD)
	sheet.add_child(v)
	_hint = UiKit.paragraph("", "body", UiKit.INK_SOFT)
	v.add_child(_hint)

	# 닭
	var hens_card := _card()
	v.add_child(hens_card)
	var hv := UiKit.vbox(UiKit.SPACE_SM)
	hens_card.add_child(hv)
	_hens_text = UiKit.text("", "title", UiKit.INK)
	hv.add_child(_hens_text)
	_hens_row = UiKit.hbox(UiKit.SPACE_SM)
	hv.add_child(_hens_row)

	# 달걀 줍기
	var egg_card := _card()
	v.add_child(egg_card)
	var eh := UiKit.hbox(UiKit.SPACE_LG)
	eh.alignment = BoxContainer.ALIGNMENT_CENTER
	egg_card.add_child(eh)
	_egg_text = UiKit.paragraph("", "body", UiKit.INK)
	_egg_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	eh.add_child(_egg_text)
	_egg_btn = UiKit.action("줍기", "primary", true)
	_egg_btn.custom_minimum_size.x = 112
	_egg_btn.pressed.connect(_collect)
	eh.add_child(_egg_btn)

	# 모이 주기
	var feed_card := _card()
	v.add_child(feed_card)
	var fh := UiKit.hbox(UiKit.SPACE_LG)
	fh.alignment = BoxContainer.ALIGNMENT_CENTER
	feed_card.add_child(fh)
	_feed_text = UiKit.paragraph("", "body", UiKit.INK)
	_feed_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fh.add_child(_feed_text)
	_feed_btn = UiKit.action("모이 주기", "mint", true)
	_feed_btn.custom_minimum_size.x = 128
	_feed_btn.pressed.connect(_feed)
	fh.add_child(_feed_btn)

	# 모이 사기
	var buy_card := _card()
	v.add_child(buy_card)
	var bh := UiKit.hbox(UiKit.SPACE_LG)
	bh.alignment = BoxContainer.ALIGNMENT_CENTER
	buy_card.add_child(bh)
	var bt := UiKit.paragraph("모이 한 포대 (%d번 줄 수 있어요)\n경자상회에서 배달해 줘요" % Coop.FEED_PACK, "body", UiKit.INK)
	bt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bh.add_child(bt)
	_buy_btn = UiKit.action(GameState.format_won(Coop.FEED_PRICE), "primary", true)
	_buy_btn.custom_minimum_size.x = 120
	_buy_btn.pressed.connect(_buy)
	bh.add_child(_buy_btn)

	v.add_child(UiKit.spacer())
	v.add_child(UiKit.divider())
	_basket = UiKit.text("", "label", UiKit.INK)
	v.add_child(_basket)
	UiKit.rise_in(sheet, 0.1, 30.0)


func _card() -> PanelContainer:
	var c := PanelContainer.new()
	c.add_theme_stylebox_override("panel", UiKit.inset_box(UiKit.SPACE_LG, UiKit.RADIUS_LG))
	return c


func _refresh() -> void:
	_header.refresh()
	for c in _hens_row.get_children():
		c.queue_free()
	for i in GameState.hens:
		var thumb := PanelContainer.new()
		thumb.add_theme_stylebox_override("panel", UiKit.box(Color.WHITE, UiKit.RADIUS_MD, Color.TRANSPARENT, 0, 6))
		thumb.custom_minimum_size = Vector2(84, 84)
		thumb.add_child(ArtSlot.make("hen", "닭", Vector2(72, 72)))
		_hens_row.add_child(thumb)
	_hens_text.text = "닭 %d마리" % GameState.hens
	var eggs: int = GameState.coop_eggs
	_egg_text.text = "닭장에 달걀 %d개" % eggs if eggs > 0 else "아직 달걀이 없어요"
	_egg_btn.disabled = eggs <= 0
	if GameState.hens_fed_today:
		_feed_text.text = "오늘 모이를 줬어요\n남은 모이 %d번" % GameState.chicken_feed
	else:
		_feed_text.text = "아직 모이를 안 줬어요\n남은 모이 %d번" % GameState.chicken_feed
	_feed_btn.disabled = GameState.hens_fed_today or GameState.chicken_feed <= 0 or GameState.hens <= 0
	_buy_btn.disabled = GameState.money < Coop.FEED_PRICE
	_basket.text = "모아 둔 달걀 %d개" % int(GameState.produce.get("egg", 0))
	if eggs > 0:
		_hint.text = "꼬꼬댁. 밤새 알을 낳았어요."
	elif not GameState.hens_fed_today and GameState.chicken_feed > 0:
		_hint.text = "모이를 주면 내일 아침 달걀이 생겨요."
	elif GameState.chicken_feed <= 0 and not GameState.hens_fed_today:
		_hint.text = "모이가 떨어졌어요. 한 포대 시켜 볼까요?"
	else:
		_hint.text = "배부른 닭들이 볕을 쬐고 있어요."


func _collect() -> void:
	var n := Coop.collect(GameState)
	if n <= 0:
		return
	Sound.play_sfx("good")
	_refresh()
	_hint.text = "달걀 %d개를 주웠어요." % n


func _feed() -> void:
	var err := Coop.feed(GameState)
	if not err.is_empty():
		Sound.play_sfx("bad", 0.0, -6.0)
		_hint.text = err
		return
	Sound.play_sfx("tap", 0.05, -4.0)
	_refresh()
	_hint.text = "모이를 줬어요. 내일 아침 달걀 %d개를 기대해 봐요." % GameState.hens


func _buy() -> void:
	var err := Coop.buy_feed(GameState)
	if not err.is_empty():
		Sound.play_sfx("bad", 0.0, -6.0)
		_hint.text = err
		return
	Sound.play_sfx("sold")
	_refresh()
	_hint.text = "모이 한 포대가 왔어요."
