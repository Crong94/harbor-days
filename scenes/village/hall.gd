extends Control
## 마을회관 (세로). 게시판에 붙은 마을 의뢰를 보고, 가진 물건을 맡겨 의뢰를 들어준다. 규칙은 Board.
## 그림: 회관 안 bg_hall, 이장 초상 npc_taesik (아직 없음. 없으면 나무색 바탕과 그림 자리)
##
## 구성: 맨 위 공통 헤더 / 회관 이름과 나가기 / 이장과 말풍선 / 아래 종이 시트(의뢰 쪽지 목록)

const MAP_SCENE := "res://scenes/map/map.tscn"

const GREETINGS := [
	"오셨습니까. 오늘도 게시판 한번 봐 주세요.",
	"요새 게시판 종이가 덜 바래서 좋습니다. 다 {player} 사장님 덕이지요.",
	"맡겨 주시면 제가 저녁 전에 다 전해 드립니다.",
]
const THANKS := [
	"아이고 고맙습니다. 좋아하시겠네요.",
	"잘 받았습니다. 저녁 전에 바로 갖다드릴게요.",
]

var _header: GameHeader
var _talk: Label
var _list: VBoxContainer
var _count: Label


func _ready() -> void:
	var base := ColorRect.new()
	base.color = UiKit.WOOD_DARK
	base.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(base)
	var art := UiKit.cover_art("bg_hall")
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
	var title := UiKit.text("마을회관", "h2", UiKit.FOAM)
	UiKit.outlined(title, 10)
	row.add_child(title)
	row.add_child(UiKit.spacer())
	var out := UiKit.game_button("나가기", UiKit.GRAY_DARK)
	out.pressed.connect(func(): UiKit.go_to(self, MAP_SCENE))
	row.add_child(out)

	_build_taesik()
	_build_sheet()
	_refresh()
	Sound.play_bgm("town")
	UiKit.fade_in(self)


func _build_taesik() -> void:
	var row := UiKit.hbox(UiKit.SPACE_MD)
	row.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	row.offset_left = 20
	row.offset_right = -20
	row.offset_top = GameHeader.BOTTOM + 76.0
	row.offset_bottom = GameHeader.BOTTOM + 300.0
	add_child(row)
	row.add_child(ArtSlot.make("npc_taesik", "정태식", Vector2(170, 220)))
	var holder := UiKit.vbox()
	holder.alignment = BoxContainer.ALIGNMENT_END
	holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(holder)
	var bubble := UiKit.glass_panel(22, UiKit.RADIUS_LG, true)
	holder.add_child(bubble)
	var bv := UiKit.vbox(UiKit.SPACE_SM)
	bubble.add_child(bv)
	var tag := UiKit.name_label("정태식 이장", Color(0, 0, 0, 0), 28)
	tag.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	bv.add_child(tag)
	_talk = UiKit.paragraph(GameState.line(GREETINGS.pick_random()), "body", UiKit.FOAM)
	_talk.add_theme_font_size_override("font_size", 20)
	bv.add_child(_talk)
	holder.add_child(UiKit.gap(18))


func _build_sheet() -> void:
	var sheet := UiKit.note_paper()
	sheet.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sheet.offset_left = 22
	sheet.offset_right = -22
	sheet.offset_top = GameHeader.BOTTOM + 314.0
	sheet.offset_bottom = -24
	add_child(sheet)
	var v := UiKit.vbox(UiKit.SPACE_SM)
	sheet.add_child(v)
	var head := UiKit.hbox(UiKit.SPACE_MD)
	head.alignment = BoxContainer.ALIGNMENT_CENTER
	head.add_child(UiKit.text("마을 게시판", "h2", UiKit.NOTE_INK))
	head.add_child(UiKit.spacer())
	_count = UiKit.text("", "body", UiKit.NOTE_INK_SOFT)
	_count.add_theme_font_size_override("font_size", 18)
	head.add_child(_count)
	v.add_child(head)
	var tip := UiKit.paragraph("의뢰는 붙은 날부터 사흘 동안 남아요. 물건을 맡기면 이장님이 전해 주고 사례를 받아요", "body", UiKit.NOTE_INK_SOFT)
	tip.add_theme_font_size_override("font_size", 16)
	v.add_child(tip)
	v.add_child(UiKit.gap(4))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	_list = UiKit.vbox(UiKit.SPACE_MD)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list)
	UiKit.rise_in(sheet, 0.1, 30.0)


func _refresh() -> void:
	_header.refresh()
	for c in _list.get_children():
		c.queue_free()
	var posts := Board.open_on(GameState.day, GameState.flags)
	_count.text = "쪽지 %d장" % posts.size()
	if posts.is_empty():
		var l := UiKit.paragraph("오늘은 붙은 의뢰가 없어요. 내일 또 와 봐요", "body", UiKit.NOTE_INK_SOFT, 0.0, HORIZONTAL_ALIGNMENT_CENTER)
		l.custom_minimum_size.y = 120
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_list.add_child(l)
		return
	for p in posts:
		_list.add_child(_post_line(p))


## 쪽지 한 장: 물건 그림 · 누가, 쪽지 글, 가진 수와 남은 날 · 맡기기 단추(사례금)
func _post_line(p: Dictionary) -> PanelContainer:
	var row := UiKit.note_row()
	var h: HBoxContainer = row.get_child(0)
	var icon_id: String = ("fish_" if p.kind == "fish" else "crop_") + p.item
	if p.item == "egg":
		icon_id = "egg"
	var icon: Control = UiKit.icon_rect(icon_id, 50)
	if icon == null:
		icon = Control.new() # 그림이 없어도 글줄이 나란하게 자리만 둔다
	icon.custom_minimum_size = Vector2(84, 50)
	h.add_child(icon)
	var text := UiKit.vbox(-2)
	text.alignment = BoxContainer.ALIGNMENT_CENTER
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var who := UiKit.text(p.who, "title", UiKit.NOTE_INK)
	who.add_theme_font_size_override("font_size", 22)
	text.add_child(who)
	var body := UiKit.paragraph(GameState.line(p.text), "body", UiKit.NOTE_INK)
	body.add_theme_font_size_override("font_size", 18)
	text.add_child(body)
	var have := Board.have(p, GameState.inventory, GameState.produce)
	var left := Board.days_left(p, GameState.day)
	var info := UiKit.text("가진 것 %d/%d  ·  %s" % [mini(have, int(p.count)), int(p.count), "오늘까지" if left <= 0 else "%d일 남음" % (left + 1)], "body", UiKit.NOTE_INK_SOFT)
	info.add_theme_font_size_override("font_size", 16)
	text.add_child(info)
	h.add_child(text)
	var give := UiKit.game_button(GameState.format_won(int(p.reward)), UiKit.CORAL_DEEP)
	give.disabled = not Board.can_deliver(p, GameState.inventory, GameState.produce)
	give.pressed.connect(_deliver.bind(p))
	h.add_child(give)
	return row


func _deliver(p: Dictionary) -> void:
	var got := Board.deliver(p, GameState)
	if got <= 0:
		return
	Sound.play_sfx("coin")
	Haptics.play("tap")
	_say(THANKS.pick_random())
	_refresh()


func _say(t: String) -> void:
	_talk.text = GameState.line(t)
	_talk.visible_ratio = 0.0
	create_tween().tween_property(_talk, "visible_ratio", 1.0, 0.4)
