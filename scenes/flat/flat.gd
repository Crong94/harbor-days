extends Control
## 물빛 갯벌 (세로, 11-19). 규칙은 Flat.
## 그림: 갯벌 배경 bg_flat, 캔 것 flat/<id> (그림 요청 중. 없으면 나무색 바탕과 글자)
##
## 구성: 맨 위 공통 헤더 / 이름과 나가기, 물 들어오는 시각 / 가운데 갯벌 칸 4x5 / 아래 바구니(캔 것)와 남은 호미질

const MAP_SCENE := "res://scenes/map/map.tscn"
const CELL := Vector2(150, 132)

var _header: GameHeader
var _board: Array = []
var _cells: Array = []
var _digs := 0
var _until := 0
var _got: Dictionary = {}
var _info: Label
var _basket: Label
var _tip: Label


func _ready() -> void:
	var base := ColorRect.new()
	base.color = UiKit.WOOD_DARK
	base.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(base)
	var art := UiKit.cover_art("bg_flat")
	if art:
		add_child(art)
	add_child(UiKit.shade([[0.0, 0.45], [0.2, 0.05], [1.0, 0.35]]))
	_header = GameHeader.new()
	add_child(_header)

	_until = Flat.open_until(GameState.day, GameState.time_minutes)
	if _until < 0:
		_until = GameState.time_minutes + 60 # 지도에서 막지만 혹시 몰라
	var visit := int(GameState.flags.get("flat_visit_%d" % GameState.day, 0))
	GameState.flags["flat_visit_%d" % GameState.day] = visit + 1
	_board = Flat.board(GameState.day, visit)

	var row := UiKit.hbox(UiKit.SPACE_MD)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	row.offset_left = 22
	row.offset_right = -20
	row.offset_top = GameHeader.BOTTOM + 12.0
	add_child(row)
	var title := UiKit.text("물빛 갯벌", "h2", UiKit.FOAM)
	UiKit.outlined(title, 10)
	row.add_child(title)
	row.add_child(UiKit.spacer())
	var out := UiKit.game_button("나가기", UiKit.GRAY_DARK)
	out.pressed.connect(_leave)
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
	_info = UiKit.text("", "title", UiKit.NOTE_INK)
	v.add_child(_info)
	_tip = UiKit.paragraph("숨구멍이 뽕뽕 난 칸을 파 봐요. 그냥 구멍일 때도 있어요", "body", UiKit.NOTE_INK_SOFT)
	_tip.add_theme_font_size_override("font_size", 17)
	v.add_child(_tip)
	var grid := GridContainer.new()
	grid.columns = Flat.COLS
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(grid)
	for i in _board.size():
		var b := Button.new()
		b.custom_minimum_size = CELL
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(_dig.bind(i))
		grid.add_child(b)
		_cells.append(b)
		_paint(i)
	v.add_child(UiKit.gap(6))
	_basket = UiKit.paragraph("", "body", UiKit.NOTE_INK)
	_basket.add_theme_font_size_override("font_size", 19)
	v.add_child(_basket)
	_refresh()
	Sound.play_bgm("sea")
	UiKit.fade_in(self)


## 칸 모양: 파기 전에는 모래색(숨구멍이 보이면 작은 점 셋), 판 뒤에는 나온 것
func _paint(i: int) -> void:
	var b: Button = _cells[i]
	var c: Dictionary = _board[i]
	for ch in b.get_children():
		ch.queue_free()
	var col := Color(UiKit.NOTE_DARK, 0.55) if not c.dug else Color(UiKit.NOTE_DARK, 0.25)
	for st in ["normal", "hover", "pressed", "disabled"]:
		b.add_theme_stylebox_override(st, UiKit.chunky(col, UiKit.RADIUS_MD, 6, 0 if c.dug else 4))
	b.text = ""
	if not c.dug:
		b.text = "· · ·" if c.hole else ""
		b.add_theme_font_size_override("font_size", 34)
		b.add_theme_color_override("font_color", UiKit.NOTE_INK)
		return
	b.disabled = true
	if str(c.item).is_empty():
		b.text = "빈 칸"
		b.add_theme_font_size_override("font_size", 18)
		b.add_theme_color_override("font_disabled_color", UiKit.NOTE_INK_SOFT)
		return
	var slot := ArtSlot.make("flat/" + str(c.item), Flat.name_of(c.item), CELL - Vector2(24, 24))
	slot.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(slot)


func _dig(i: int) -> void:
	if _digs >= Flat.DIGS or GameState.time_minutes >= _until:
		return
	var it := Flat.dig(_board, i)
	if it == "dug":
		return
	_digs += 1
	GameState.time_minutes += Flat.DIG_MIN
	if it.is_empty():
		Sound.play_sfx("bad", 0.0, -10.0)
	else:
		Flat.keep(GameState, it)
		_got[it] = int(_got.get(it, 0)) + 1
		Sound.play_sfx("catch" if it != "nakji" else "newfish")
		if it == "nakji":
			_tip.text = "낙지다! 손목을 휘감는다."
	_paint(i)
	_refresh()


func _refresh() -> void:
	_header.refresh()
	var left := Flat.DIGS - _digs
	var tide_in := GameState.time_minutes >= _until
	if tide_in:
		_info.text = "물이 들어와요. 이제 나가요"
	elif left <= 0:
		_info.text = "팔이 아파요. 오늘은 여기까지"
	else:
		_info.text = "호미질 %d번 남음 · 물 들어오는 %s" % [left, Bus.clock(_until)]
	var parts := PackedStringArray()
	for id in _got:
		parts.append("%s %d" % [Flat.name_of(id), _got[id]])
	_basket.text = "바구니: " + (", ".join(parts) if not parts.is_empty() else "아직 비었어요")
	for i in _cells.size():
		if tide_in or left <= 0:
			(_cells[i] as Button).disabled = true


func _leave() -> void:
	if not _got.is_empty():
		var parts := PackedStringArray()
		for id in _got:
			parts.append("%s %d" % [Flat.name_of(id), _got[id]])
		GameState.note("갯벌에서 %s 캤다." % ", ".join(parts), 2)
	GameState.current_location = "flat"
	UiKit.go_to(self, MAP_SCENE)
