extends Control
## 프롤로그 2 (챕터 1): 낡은 나무판에 가게 이름을 쓰고 간판을 다는 장면. 여기서 {shop}이 정해진다.
## 그림: bg_shop_front (식당 외관), ui_signboard (빈 나무 간판, 투명 배경). 사용자에게 받는다.
## 그림이 없으면 마을 그림을 어둡게 깔고, 간판은 나무색 판으로 대신 보여 준다.

const NEXT_SCENE := "res://scenes/fishing/fishing.tscn"

var _board: Control
var _shop_label: Label
var _form: PanelContainer
var _shop_edit: LineEdit
var _error: Label
var _lead: Label
var _dialogue: DialogueBox
var _next_btn: Button


func _ready() -> void:
	var base := ColorRect.new()
	base.color = UiKit.NAVY_DEEP
	base.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(base)
	var art := UiKit.cover_art("bg_shop_front" if ArtSlot.has_art("bg_shop_front") else "map_village")
	if art:
		if not ArtSlot.has_art("bg_shop_front"):
			art.modulate = Color(0.55, 0.5, 0.6) # 임시 배경은 노을빛으로 눌러 둔다
		add_child(art)
	add_child(UiKit.shade([[0.0, 0.6], [0.4, 0.15], [1.0, 0.85]]))

	var root := UiKit.vbox(UiKit.SPACE_LG)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 36
	root.offset_right = -36
	root.offset_top = 72
	root.offset_bottom = -48
	add_child(root)

	var step := UiKit.chip("프롤로그 2 / 2", "간판")
	step.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	root.add_child(step)
	_lead = UiKit.paragraph("간판 자리가 비어 있다.\n낡은 나무판에 가게 이름을 적어 보자.", "body", UiKit.FOAM_SOFT, 0.0, HORIZONTAL_ALIGNMENT_CENTER)
	root.add_child(_lead)

	var top_space := Control.new()
	top_space.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(top_space)

	_board = _make_board()
	root.add_child(_board)

	var mid_space := Control.new()
	mid_space.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(mid_space)

	# 입력 카드 (유리)
	_form = UiKit.glass_panel(28, UiKit.RADIUS_LG, true)
	root.add_child(_form)
	var fv := UiKit.vbox(UiKit.SPACE_MD)
	_form.add_child(fv)
	fv.add_child(UiKit.text("가게 이름", "label", UiKit.FOAM_SOFT))
	_shop_edit = UiKit.line_edit(GameState.DEFAULT_SHOP_NAME, 28, UiKit.FOAM, GameState.SHOP_NAME_MAX, true)
	_shop_edit.custom_minimum_size.y = 64
	_shop_edit.text_submitted.connect(func(_t): _hang_sign())
	_shop_edit.text_changed.connect(_on_typed)
	fv.add_child(_shop_edit)
	_error = UiKit.text("", "caption", Color("ffb4a6"))
	fv.add_child(_error)
	fv.add_child(UiKit.text("비워 두면 ‘%s’(으)로 정해져요. 한글 %d자까지, 띄어쓰기 가능." % [GameState.DEFAULT_SHOP_NAME, GameState.SHOP_NAME_MAX], "caption", UiKit.FOAM_SOFT))
	fv.add_child(UiKit.gap(4))
	var buttons := UiKit.hbox(UiKit.SPACE_MD)
	var random_btn := UiKit.action("이름 추천", "glass")
	random_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	random_btn.pressed.connect(func():
		Sound.play_sfx("page", 0.05)
		_shop_edit.text = GameState.random_shop_name()
		_on_typed(_shop_edit.text))
	buttons.add_child(random_btn)
	var hang_btn := UiKit.action("간판 달기")
	hang_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hang_btn.size_flags_stretch_ratio = 1.6
	hang_btn.pressed.connect(_hang_sign)
	buttons.add_child(hang_btn)
	fv.add_child(buttons)

	_next_btn = UiKit.action("다음 날 새벽으로")
	_next_btn.custom_minimum_size.y = 60
	_next_btn.pressed.connect(func(): UiKit.go_to(self, NEXT_SCENE, 0.8))
	_next_btn.hide()
	root.add_child(_next_btn)

	_dialogue = DialogueBox.new()
	add_child(_dialogue)
	_dialogue.finished.connect(_on_dialogue_finished)

	_shop_edit.grab_focus()
	UiKit.fade_in(self)
	UiKit.rise_in(_form, 0.2)


## 간판: 그림(ui_signboard)이 있으면 그 위에 글씨를, 없으면 나무색 판에 글씨를 쓴다
func _make_board() -> Control:
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(0, 220)
	holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var plate: Control
	var sign_art := UiKit.cover_art("ui_signboard")
	if sign_art:
		sign_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		plate = sign_art
	else:
		var p := PanelContainer.new()
		var s := UiKit.box(UiKit.WOOD, 18, UiKit.WOOD_DARK, 6, 0)
		UiKit.elevate(s, 3)
		p.add_theme_stylebox_override("panel", s)
		plate = p
	plate.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	plate.offset_left = 10
	plate.offset_right = -10
	holder.add_child(plate)
	_shop_label = UiKit.text(GameState.DEFAULT_SHOP_NAME, "h1", Color(UiKit.FOAM, 0.35), HORIZONTAL_ALIGNMENT_CENTER)
	_shop_label.add_theme_font_size_override("font_size", 58)
	_shop_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_shop_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	UiKit.shadowed(_shop_label, Color(0, 0, 0, 0.45), 3)
	holder.add_child(_shop_label)
	return holder


## 입력하는 대로 간판에 글씨가 미리 비친다
func _on_typed(t: String) -> void:
	_error.text = ""
	var s := t.strip_edges()
	_shop_label.text = s if not s.is_empty() else GameState.DEFAULT_SHOP_NAME
	_shop_label.add_theme_color_override("font_color", UiKit.FOAM if not s.is_empty() else Color(UiKit.FOAM, 0.35))


func _hang_sign() -> void:
	var problem := GameState.validate_shop_name(_shop_edit.text)
	if not problem.is_empty():
		_error.text = problem
		Sound.play_sfx("bad", 0.0, -8.0)
		return
	var n := _shop_edit.text.strip_edges()
	GameState.shop_name = n if not n.is_empty() else GameState.DEFAULT_SHOP_NAME
	_shop_label.text = GameState.shop_name
	_shop_label.add_theme_color_override("font_color", UiKit.FOAM)
	_lead.text = ""
	var tw_form := create_tween()
	tw_form.tween_property(_form, "modulate:a", 0.0, UiKit.MOTION_BASE)
	tw_form.tween_callback(_form.hide)

	# 간판이 걸리는 느낌으로 살짝 튕기게
	Sound.play_sfx("stamp")
	_board.pivot_offset = _board.size / 2
	_board.scale = Vector2(0.88, 0.88)
	var tw := create_tween()
	tw.tween_property(_board, "scale", Vector2(1.04, 1.04), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_board, "scale", Vector2.ONE, 0.15)
	tw.tween_interval(0.4)
	tw.tween_callback(func(): _dialogue.play([
		{"speaker": "{player}", "text": "{shop}. 오늘부터 여기가 내 자리다."},
		{"speaker": "{player}", "text": "통장에는 %s, 갚아야 할 대출은 %s." % [GameState.format_won(GameState.money), GameState.format_won(GameState.debt)]},
		{"speaker": "{player}", "text": "...일단 팔 게 있어야 하는데. 내일 새벽에 방파제로 가 보자."},
	]))


func _on_dialogue_finished() -> void:
	_lead.text = GameState.line("{player}의 작은 식당, {shop}")
	_next_btn.show()
	UiKit.rise_in(_next_btn)
	_next_btn.grab_focus()
