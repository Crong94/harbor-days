extends Control
## 챕터 1: 낡은 나무판에 가게 이름을 쓰고 간판을 다는 장면. 여기서 {shop}이 정해진다.

const TITLE_SCENE := "res://scenes/title/title.tscn"

var _board: PanelContainer
var _shop_edit: LineEdit
var _shop_label: Label
var _prompt: Label
var _error: Label
var _hint: Label
var _buttons: HBoxContainer
var _dialogue: DialogueBox
var _end_buttons: HBoxContainer


func _ready() -> void:
	var bg := SeaBackdrop.new()
	bg.mode = SeaBackdrop.Mode.DUSK
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.offset_bottom = -120
	add_child(center)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 18)
	center.add_child(v)

	_prompt = UiKit.shadowed(UiKit.label("간판 자리가 비어 있다. 낡은 나무판에 가게 이름을 적어 보자.", UiKit.SIZE_BODY, UiKit.CREAM, HORIZONTAL_ALIGNMENT_CENTER), Color(UiKit.NAVY_DEEP, 0.6), 2)
	v.add_child(_prompt)

	_board = PanelContainer.new()
	_board.custom_minimum_size = Vector2(720, 150)
	_board.add_theme_stylebox_override("panel", UiKit.box(UiKit.WOOD, 10, UiKit.WOOD_DARK, 8, 28))
	v.add_child(_board)

	var board_stack := VBoxContainer.new()
	board_stack.alignment = BoxContainer.ALIGNMENT_CENTER
	_board.add_child(board_stack)

	_shop_edit = UiKit.line_edit(GameState.DEFAULT_SHOP_NAME, 56, UiKit.CREAM, GameState.SHOP_NAME_MAX)
	_shop_edit.text_submitted.connect(func(_t): _hang_sign())
	_shop_edit.text_changed.connect(func(_t): _error.text = "")
	board_stack.add_child(_shop_edit)

	_shop_label = UiKit.shadowed(UiKit.label("", 64, UiKit.CREAM, HORIZONTAL_ALIGNMENT_CENTER), Color(0, 0, 0, 0.4), 3)
	_shop_label.hide()
	board_stack.add_child(_shop_label)

	_error = UiKit.shadowed(UiKit.label("", UiKit.SIZE_SMALL, Color("ffd1c4"), HORIZONTAL_ALIGNMENT_CENTER), Color(0, 0, 0, 0.5), 1)
	_error.custom_minimum_size.y = 24
	v.add_child(_error)

	_hint = UiKit.shadowed(UiKit.label("비워 두면 ‘%s’(으)로 정해져요. 한글 %d자까지, 띄어쓰기 가능." % [GameState.DEFAULT_SHOP_NAME, GameState.SHOP_NAME_MAX], UiKit.SIZE_SMALL, UiKit.CREAM, HORIZONTAL_ALIGNMENT_CENTER), Color(0, 0, 0, 0.5), 1)
	v.add_child(_hint)

	_buttons = HBoxContainer.new()
	_buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	_buttons.add_theme_constant_override("separation", 14)
	var random_btn := UiKit.button("이름 추천", false)
	random_btn.pressed.connect(func():
		_shop_edit.text = GameState.random_shop_name()
		_error.text = "")
	_buttons.add_child(random_btn)
	var hang_btn := UiKit.button("간판 달기")
	hang_btn.pressed.connect(_hang_sign)
	_buttons.add_child(hang_btn)
	v.add_child(_buttons)

	_end_buttons = HBoxContainer.new()
	_end_buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	var back_btn := UiKit.button("처음으로")
	back_btn.pressed.connect(func(): UiKit.go_to(self, TITLE_SCENE))
	_end_buttons.add_child(back_btn)
	_end_buttons.hide()
	v.add_child(_end_buttons)

	_dialogue = DialogueBox.new()
	add_child(_dialogue)
	_dialogue.finished.connect(_on_dialogue_finished)

	_shop_edit.grab_focus()
	UiKit.fade_in(self)


func _hang_sign() -> void:
	var problem := GameState.validate_shop_name(_shop_edit.text)
	if not problem.is_empty():
		_error.text = problem
		return
	var n := _shop_edit.text.strip_edges()
	GameState.shop_name = n if not n.is_empty() else GameState.DEFAULT_SHOP_NAME

	_shop_edit.hide()
	_buttons.hide()
	_hint.hide()
	_error.text = ""
	_prompt.text = ""
	_shop_label.text = GameState.shop_name
	_shop_label.show()

	# 간판이 걸리는 느낌으로 살짝 튕기게
	_board.pivot_offset = _board.size / 2
	_board.scale = Vector2(0.85, 0.85)
	var tw := create_tween()
	tw.tween_property(_board, "scale", Vector2(1.04, 1.04), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_board, "scale", Vector2.ONE, 0.15)
	tw.tween_interval(0.4)
	tw.tween_callback(func(): _dialogue.play([
		{"speaker": "{player}", "text": "{shop}. 오늘부터 여기가 내 자리다."},
		{"speaker": "{player}", "text": "통장에는 %s, 갚아야 할 대출은 %s." % [GameState.format_won(GameState.money), GameState.format_won(GameState.debt)]},
		{"speaker": "{player}", "text": "...일단 팔 게 있어야 하는데. 방파제에 가 보자."},
		{"speaker": "", "text": "다음 이야기 〈첫 번째 손님〉은 준비 중이에요."},
	]))


func _on_dialogue_finished() -> void:
	_prompt.text = GameState.line("{player}의 작은 식당, {shop}")
	_end_buttons.show()
	_end_buttons.get_child(0).grab_focus()
