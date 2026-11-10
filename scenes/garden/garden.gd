extends Control
## 우리 텃밭 (세로). 이랑 네 줄에 씨앗을 심고, 다 자라면 거둔다. 규칙은 CropDB, 설계는 docs/텃밭_설계.md
## 그림: 위쪽은 마을 지도(map_village)에서 텃밭 자리만 크게 보여 준다. 텃밭 전용 그림 bg_garden이 오면 그것을 쓴다.
##       작물 그림 crop_<id> (사용자에게 받음). 오기 전에는 ArtSlot 빈 자리로 둔다.
##
## 구성: 맨 위 공통 헤더 / 텃밭 그림과 제목 / 아래 종이 시트(이랑 네 줄, 거둔 채소) / 씨앗 고르기 창

const MAP_SCENE := "res://scenes/map/map.tscn"
## 지도 그림에서 텃밭이 있는 자리 (1536x1024 기준 픽셀)
const MAP_REGION := Rect2(835, 380, 420, 250)
const ART_H := 330.0

var _header: GameHeader
var _rows: VBoxContainer
var _produce: Label
var _hint: Label
var _picker: Control
var _picker_panel: PanelContainer
var _picker_list: VBoxContainer
var _picker_title: Label
var _pick_index := -1


func _ready() -> void:
	var base := ColorRect.new()
	base.color = UiKit.INK
	base.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(base)
	_build_art()
	_build_top_bar()
	_build_sheet()
	_build_picker()
	_refresh()
	Sound.play_bgm("market")
	UiKit.fade_in(self)


## 위쪽 텃밭 그림. 전용 그림이 없으면 지도에서 텃밭 자리를 잘라 보여 준다
func _build_art() -> void:
	var r := TextureRect.new()
	if ArtSlot.has_art("bg_garden"):
		r.texture = load(ArtSlot.art_path("bg_garden"))
	elif ArtSlot.has_art("map_village"):
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
	var title := UiKit.text("우리 텃밭", "h2", UiKit.FOAM)
	UiKit.outlined(title, 10)
	row.add_child(title)
	row.add_child(UiKit.spacer())
	var out := UiKit.action("나가기", "secondary", true)
	out.custom_minimum_size.x = 104
	out.pressed.connect(func(): UiKit.go_to(self, MAP_SCENE))
	row.add_child(out)


## 아래 종이 시트: 이랑 네 줄과 거둔 채소
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
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	_rows = UiKit.vbox(UiKit.SPACE_MD)
	_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_rows)
	v.add_child(UiKit.divider())
	v.add_child(UiKit.text("거둔 채소", "label", UiKit.INK))
	_produce = UiKit.paragraph("", "body", UiKit.INK_SOFT)
	v.add_child(_produce)
	UiKit.rise_in(sheet, 0.1, 30.0)


func _refresh() -> void:
	_header.refresh()
	for c in _rows.get_children():
		c.queue_free()
	var ready := 0
	var empty := 0
	for i in CropDB.SLOTS:
		var st := CropDB.stage(GameState.garden[i], GameState.day)
		ready += int(st == CropDB.READY)
		empty += int(st == CropDB.EMPTY)
		_rows.add_child(_row_card(i))
	if ready > 0:
		_hint.text = "다 자란 이랑이 %d줄 있어요. 거둬 볼까요?" % ready
	elif empty == CropDB.SLOTS:
		_hint.text = "이랑이 네 줄이라 한 번에 네 가지를 기를 수 있어요."
	elif empty > 0:
		_hint.text = "빈 이랑이 %d줄 남았어요." % empty
	else:
		_hint.text = "네 줄 모두 잘 자라고 있어요."
	var parts: Array = []
	for id in CropDB.CROPS:
		var n := int(GameState.produce.get(id, 0))
		if n > 0:
			parts.append("%s %d" % [CropDB.crop(id).name, n])
	_produce.text = "  ·  ".join(parts) if not parts.is_empty() else "아직 거둔 채소가 없어요."


## 그림 자리가 든 흰 칸
func _thumb(crop_id: String) -> PanelContainer:
	var thumb := PanelContainer.new()
	thumb.add_theme_stylebox_override("panel", UiKit.box(Color.WHITE, UiKit.RADIUS_MD, Color.TRANSPARENT, 0, 6))
	thumb.custom_minimum_size = Vector2(84, 84)
	if not crop_id.is_empty():
		thumb.add_child(ArtSlot.make("crop_" + crop_id, CropDB.crop(crop_id).name, Vector2(72, 72)))
	return thumb


## 이랑 한 줄: 작물 그림 자리, 이름과 상태, 할 일 버튼
func _row_card(index: int) -> PanelContainer:
	var slot: Dictionary = GameState.garden[index]
	var st := CropDB.stage(slot, GameState.day)
	var card := PanelContainer.new()
	var s := UiKit.inset_box(UiKit.SPACE_LG, UiKit.RADIUS_LG)
	if st == CropDB.READY:
		s.border_color = UiKit.LEAF
		s.set_border_width_all(3)
	card.add_theme_stylebox_override("panel", s)
	var h := UiKit.hbox(UiKit.SPACE_LG)
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(h)
	h.add_child(_thumb("" if st == CropDB.EMPTY else str(slot.crop)))

	var info := UiKit.vbox(UiKit.SPACE_XS)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(info)
	info.add_child(UiKit.text("%d번 이랑" % (index + 1), "caption", UiKit.INK_SOFT))

	if st == CropDB.EMPTY:
		info.add_child(UiKit.text("빈 이랑", "title", UiKit.INK_MUTED))
		info.add_child(UiKit.text("씨앗을 심을 수 있어요", "caption", UiKit.INK_SOFT))
		var plant := UiKit.action("심기", "mint", true)
		plant.custom_minimum_size.x = 112
		plant.pressed.connect(_open_picker.bind(index))
		h.add_child(plant)
		return card

	var c := CropDB.crop(slot.crop)
	info.add_child(UiKit.text(c.name, "title", UiKit.INK))
	if st == CropDB.GROWING:
		var bar := ProgressBar.new()
		bar.show_percentage = false
		bar.custom_minimum_size = Vector2(0, 14)
		bar.max_value = 1.0
		bar.value = maxf(CropDB.growth(slot, GameState.day), 0.06)
		bar.add_theme_stylebox_override("background", UiKit.box(UiKit.PAPER_LINE, UiKit.RADIUS_PILL, Color.TRANSPARENT, 0, 0))
		bar.add_theme_stylebox_override("fill", UiKit.box(UiKit.LEAF, UiKit.RADIUS_PILL, Color.TRANSPARENT, 0, 0))
		info.add_child(bar)
		h.add_child(UiKit.badge("%d일 남음" % CropDB.days_left(slot, GameState.day), UiKit.PAPER, UiKit.INK))
	else:
		info.add_child(UiKit.text("다 자랐어요. %d개 거둘 수 있어요" % c.amount, "caption", UiKit.INK_SOFT))
		var pick := UiKit.action("거두기", "primary", true)
		pick.custom_minimum_size.x = 112
		pick.pressed.connect(_harvest.bind(index))
		h.add_child(pick)
	return card


func _harvest(index: int) -> void:
	var id := GameState.harvest_crop(index)
	if id.is_empty():
		return
	Sound.play_sfx("good")
	_refresh()
	_hint.text = "%s %d개를 거뒀어요." % [CropDB.crop(id).name, CropDB.crop(id).amount]


# ─── 씨앗 고르기 ────────────────────────────────────

func _build_picker() -> void:
	_picker = Control.new()
	_picker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_picker)
	var dim := UiKit.scrim()
	dim.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.pressed:
			_close_picker())
	_picker.add_child(dim)
	_picker_panel = PanelContainer.new()
	_picker_panel.add_theme_stylebox_override("panel", UiKit.paper_box(22, UiKit.RADIUS_LG, 3))
	_picker_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_picker_panel.offset_left = 12
	_picker_panel.offset_right = -12
	_picker_panel.offset_top = GameHeader.BOTTOM + 90.0
	_picker_panel.offset_bottom = -16
	_picker.add_child(_picker_panel)
	var v := UiKit.vbox(UiKit.SPACE_MD)
	_picker_panel.add_child(v)
	var head := UiKit.hbox(UiKit.SPACE_MD)
	head.alignment = BoxContainer.ALIGNMENT_CENTER
	_picker_title = UiKit.text("", "h2", UiKit.INK)
	head.add_child(_picker_title)
	head.add_child(UiKit.spacer())
	var close := UiKit.action("닫기", "secondary", true)
	close.custom_minimum_size.x = 96
	close.pressed.connect(_close_picker)
	head.add_child(close)
	v.add_child(head)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	_picker_list = UiKit.vbox(UiKit.SPACE_MD)
	_picker_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_picker_list)
	_picker.hide()


func _open_picker(index: int) -> void:
	_pick_index = index
	Sound.play_sfx("tap", 0.05, -6.0)
	_picker_title.text = "%d번 이랑 씨앗" % (index + 1)
	for c in _picker_list.get_children():
		c.queue_free()
	for id in CropDB.CROPS:
		_picker_list.add_child(_seed_card(id))
	_picker.show()
	UiKit.rise_in(_picker_panel, 0.0, 40.0)


func _close_picker() -> void:
	_picker.hide()
	_pick_index = -1


func _seed_card(id: String) -> PanelContainer:
	var c := CropDB.crop(id)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UiKit.inset_box(UiKit.SPACE_LG, UiKit.RADIUS_LG))
	var h := UiKit.hbox(UiKit.SPACE_LG)
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(h)
	h.add_child(_thumb(id))
	var info := UiKit.vbox(UiKit.SPACE_XS)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_child(UiKit.text(c.name, "title", UiKit.INK))
	info.add_child(UiKit.paragraph(c.desc, "caption", UiKit.INK_SOFT))
	var stat_row := UiKit.hbox(UiKit.SPACE_XS)
	stat_row.add_child(UiKit.badge("%d일" % c.days, Color(UiKit.SEA, 0.18), UiKit.INK))
	stat_row.add_child(UiKit.badge("%d개 수확" % c.amount, Color(UiKit.SEA, 0.18), UiKit.INK))
	info.add_child(stat_row)
	h.add_child(info)
	var buy := UiKit.action(GameState.format_won(c.price), "primary", true)
	buy.custom_minimum_size.x = 120
	buy.disabled = GameState.money < int(c.price)
	buy.pressed.connect(_plant.bind(id))
	h.add_child(buy)
	return card


func _plant(id: String) -> void:
	var index := _pick_index
	var err := GameState.plant_crop(index, id)
	_close_picker()
	if not err.is_empty():
		Sound.play_sfx("bad", 0.0, -6.0)
		_hint.text = err
		return
	Sound.play_sfx("sold")
	_refresh()
	var c := CropDB.crop(id)
	_hint.text = "%d번 이랑에 %s 씨앗을 심었어요. %d일 뒤에 거둘 수 있어요." % [index + 1, c.name, c.days]
