extends Control
## 앱 만들기 (세로, 11-19). 규칙은 AppWork. 어느 앱인지는 GameState.flags["app_now"] (지도가 넣는다)
## 미니게임: 섞인 할 일 카드를 만드는 순서대로 누른다. 틀리면 실수, MAX_MISS번이면 그날은 접는다.
## 그림: 노트북 화면 bg_app_work (그림 요청 중. 없으면 나무색 바탕)

const MAP_SCENE := "res://scenes/map/map.tscn"

var _header: GameHeader
var _id := ""
var _st := 0
var _picked := 0
var _miss := 0
var _info: Label
var _done_list: Label
var _cards: VBoxContainer
var _over := false


func _ready() -> void:
	var base := ColorRect.new()
	base.color = UiKit.WOOD_DARK
	base.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(base)
	var art := UiKit.cover_art("bg_app_work")
	if art:
		add_child(art)
	add_child(UiKit.shade([[0.0, 0.5], [0.2, 0.15], [1.0, 0.55]]))
	_header = GameHeader.new()
	add_child(_header)
	_id = str(GameState.flags.get("app_now", "junho"))
	var a := AppWork.app(_id)
	_st = AppWork.stage(GameState, _id)

	var row := UiKit.hbox(UiKit.SPACE_MD)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	row.offset_left = 22
	row.offset_right = -20
	row.offset_top = GameHeader.BOTTOM + 12.0
	add_child(row)
	var t := UiKit.text("〈%s〉 %d/%d단계" % [a.title, _st + 1, a.stages.size()], "h2", UiKit.FOAM)
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
	v.add_child(UiKit.paragraph("%s · %s" % [Friends.person(a.who).get("call", a.who), a.why], "body", UiKit.NOTE_INK_SOFT))
	_info = UiKit.text("", "title", UiKit.NOTE_INK)
	v.add_child(_info)
	_done_list = UiKit.paragraph("", "body", UiKit.LEAF)
	_done_list.add_theme_font_size_override("font_size", 18)
	v.add_child(_done_list)
	_cards = UiKit.vbox(UiKit.SPACE_SM)
	_cards.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(_cards)
	for c in AppWork.shuffled(_id, _st, GameState.day):
		var b := UiKit.action(c, "secondary")
		b.custom_minimum_size = Vector2(0, 72)
		b.pressed.connect(_pick.bind(b, c))
		_cards.add_child(b)
	_refresh()
	Sound.play_bgm("town")
	UiKit.fade_in(self)


func _refresh() -> void:
	_header.refresh()
	var order: Array = AppWork.app(_id).stages[_st]
	_info.text = "만드는 순서대로 눌러요 · 실수 %d/%d" % [_miss, AppWork.MAX_MISS]
	_done_list.text = "  →  ".join(PackedStringArray(order.slice(0, _picked)))


func _pick(b: Button, card: String) -> void:
	if _over:
		return
	if AppWork.is_next(_id, _st, _picked, card):
		_picked += 1
		b.disabled = true
		Sound.play_sfx("tap")
	else:
		_miss += 1
		Sound.play_sfx("bad", 0.0, -6.0)
		var tw := b.create_tween()
		tw.tween_property(b, "position:x", b.position.x + 10.0, 0.05)
		tw.tween_property(b, "position:x", b.position.x, 0.05)
	_refresh()
	var total: int = AppWork.app(_id).stages[_st].size()
	if _picked >= total:
		_end(true)
	elif _miss >= AppWork.MAX_MISS:
		_end(false)


func _end(ok: bool) -> void:
	_over = true
	var reward := AppWork.finish_stage(GameState, _id, ok)
	var a := AppWork.app(_id)
	if not ok:
		_info.text = "버그가 너무 많아요. 오늘은 접고 내일 다시 해요"
	elif reward.is_empty():
		_info.text = "%d단계 완성! 내일 이어서 해요" % (_st + 1)
		Sound.play_sfx("coin")
	else:
		_info.text = reward
		GameState.note("〈%s〉 앱을 다 만들었다. %s 좋아했다." % [a.title, Josa.attach(Friends.person(a.who).get("call", a.who), "이/가")], 4)
		Sound.play_sfx("newfish")
	_header.refresh()
	var back := UiKit.action("지도로", "primary")
	back.pressed.connect(func(): UiKit.go_to(self, MAP_SCENE))
	_cards.add_child(back)
