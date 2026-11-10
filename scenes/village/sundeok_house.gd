extends Control
## 순덕 할머니 집 (세로). 할머니 부탁을 듣고 들어준다. 부탁 세 가지를 다 들어주면 병아리를 받고 닭장이 열린다.
## 규칙과 대사는 Coop (scripts/data/coop.gd). 이 스크립트는 화면과 순서만 맡는다.
## 그림: 할머니 집 마루 bg_sundeok_house, 순덕 초상화 npc_sundeok (사용자에게 받음. 없으면 그림 자리만 보인다)

const MAP_SCENE := "res://scenes/map/map.tscn"
const COOP_SCENE := "res://scenes/coop/coop.tscn"

var _header: GameHeader
var _dialogue: DialogueBox
var _card: PanelContainer
var _card_title: Label
var _card_desc: Label
var _card_have: Label
var _card_btn: Button
var _card_action := "" # give(드리기), coop(닭장 가 보기), out(나가기)
var _just_opened := false


func _ready() -> void:
	var base := ColorRect.new()
	base.color = Color("3a2c26")
	base.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(base)
	var bg := UiKit.cover_art("bg_sundeok_house")
	if bg:
		add_child(bg)
	add_child(UiKit.shade([[0.0, 0.5], [0.2, 0.0], [0.7, 0.0], [1.0, 0.6]], Color("1a1410")))

	var who := ArtSlot.make("npc_sundeok", "최순덕", Vector2(420, 560))
	who.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	who.offset_left = -210
	who.offset_right = 210
	who.offset_top = GameHeader.BOTTOM + 90.0
	who.offset_bottom = GameHeader.BOTTOM + 650.0
	add_child(who)

	_build_top_bar()
	_build_card()
	_dialogue = DialogueBox.new()
	add_child(_dialogue)
	_dialogue.finished.connect(_on_dialogue_finished)
	Sound.play_bgm("town")
	UiKit.fade_in(self)
	_dialogue.play(_greeting())


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
	var title := UiKit.text("순덕 할머니 집", "h2", UiKit.FOAM)
	UiKit.outlined(title, 10)
	row.add_child(title)
	row.add_child(UiKit.spacer())
	var out := UiKit.action("나가기", "secondary", true)
	out.custom_minimum_size.x = 104
	out.pressed.connect(func(): UiKit.go_to(self, MAP_SCENE))
	row.add_child(out)


## 아래 종이 카드: 지금 부탁과 드리기 버튼
func _build_card() -> void:
	_card = PanelContainer.new()
	_card.add_theme_stylebox_override("panel", UiKit.paper_box(24, UiKit.RADIUS_LG, 3))
	_card.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_card.offset_left = 16
	_card.offset_right = -16
	_card.offset_top = -300
	_card.offset_bottom = -24
	add_child(_card)
	var v := UiKit.vbox(UiKit.SPACE_SM)
	_card.add_child(v)
	_card_title = UiKit.text("", "h2", UiKit.INK)
	v.add_child(_card_title)
	_card_desc = UiKit.paragraph("", "body", UiKit.INK_SOFT)
	v.add_child(_card_desc)
	_card_have = UiKit.text("", "label", UiKit.INK)
	v.add_child(_card_have)
	v.add_child(UiKit.spacer())
	_card_btn = UiKit.action("")
	_card_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_card_btn.pressed.connect(_on_card_pressed)
	v.add_child(_card_btn)
	_card.hide()


## 들어오면 듣는 말: 부탁이 있으면 부탁, 없으면 짧은 인사
func _greeting() -> Array:
	var q := Coop.current_quest(GameState)
	if q >= 0:
		return Coop.QUESTS[q].ask
	if GameState.has_flag("coop_open"):
		return [{"speaker": "순덕", "text": "닭들은 잘 크고 있어? 알 낳으면 하나 갖다 줘."}]
	return [{"speaker": "순덕", "text": "오늘은 됐어. 내일 또 와. 할 얘기 있으면 할게."}]


func _on_dialogue_finished() -> void:
	_show_card()


func _show_card() -> void:
	_header.refresh()
	var q := Coop.current_quest(GameState)
	_card_btn.disabled = false
	if _just_opened:
		_card_title.text = "닭장이 열렸어요"
		_card_desc.text = "병아리 두 마리와 모이 한 포대를 받았어요. 모이를 준 날 밤마다 한 마리가 알을 하나씩 낳아요."
		_card_have.text = ""
		_card_btn.text = "닭장 가 보기"
		_card_action = "coop"
	elif q >= 0:
		var quest: Dictionary = Coop.QUESTS[q]
		var need: Dictionary = quest.need
		var have := Coop.have_count(GameState, need)
		_card_title.text = "부탁 %d/%d  ·  %s" % [q + 1, Coop.QUESTS.size(), quest.title]
		_card_desc.text = "필요한 것: %s %d%s" % [_need_name(need), need.count, _unit(need)]
		_card_have.text = "가진 것 %d%s" % [have, _unit(need)]
		_card_btn.text = "드리기" if have >= int(need.count) else "아직 모자라요"
		_card_btn.disabled = have < int(need.count)
		_card_action = "give"
	else:
		_card_title.text = "오늘은 부탁이 없어요" if not GameState.has_flag("coop_open") else "할머니와 차 한잔"
		_card_desc.text = "내일 다시 와 보면 다른 부탁이 있을지도 몰라요." if not GameState.has_flag("coop_open") else "부탁을 모두 들어드렸어요. 닭장은 텃밭 아래에 있어요."
		_card_have.text = ""
		_card_btn.text = "나가기"
		_card_action = "out"
	_card.show()
	UiKit.rise_in(_card, 0.0, 30.0)


func _on_card_pressed() -> void:
	match _card_action:
		"give":
			var was_open := GameState.has_flag("coop_open")
			var q := Coop.current_quest(GameState)
			var err := Coop.give(GameState)
			if not err.is_empty():
				Sound.play_sfx("bad", 0.0, -6.0)
				_card_have.text = err
				return
			Sound.play_sfx("good")
			_card.hide()
			var lines: Array = Coop.QUESTS[q].thanks.duplicate()
			if GameState.has_flag("coop_open") and not was_open:
				_just_opened = true
				lines.append_array(Coop.GIFT_LINES)
			_dialogue.play(lines)
		"coop":
			GameState.time_minutes += Locations.travel_minutes(GameState.current_location, "coop")
			GameState.current_location = "coop"
			UiKit.go_to(self, COOP_SCENE)
		_:
			UiKit.go_to(self, MAP_SCENE)


func _need_name(need: Dictionary) -> String:
	if need.kind == "produce":
		return CropDB.crop(need.id).name
	return "생선" if str(need.id).is_empty() else FishDB.get_fish(need.id).name


func _unit(need: Dictionary) -> String:
	if need.kind == "produce":
		return "단" if need.id == "daepa" else "개"
	return "마리"
