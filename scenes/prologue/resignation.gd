extends Control
## 프롤로그: 사직서에 이름을 적는 장면. 여기서 {player}가 정해진다.

const NEXT_SCENE := "res://scenes/prologue/signboard.tscn"

var _name_edit: LineEdit
var _error: Label


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color("141c2b")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# 모니터 불빛처럼 은은한 빛
	var glow := ColorRect.new()
	glow.color = Color(0.45, 0.6, 0.9, 0.06)
	glow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	glow.offset_left = 220
	glow.offset_right = -220
	glow.offset_top = 40
	glow.offset_bottom = -40
	add_child(glow)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var paper := PanelContainer.new()
	paper.custom_minimum_size = Vector2(620, 0)
	paper.add_theme_stylebox_override("panel", UiKit.box(UiKit.PAPER, 6, Color("d8cfbd"), 1, 44))
	center.add_child(paper)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	paper.add_child(v)

	v.add_child(UiKit.label("사  직  서", UiKit.SIZE_HEADING, UiKit.INK, HORIZONTAL_ALIGNMENT_CENTER))
	v.add_child(_gap(10))
	v.add_child(_row("소속", "플랫폼개발본부 백엔드팀"))
	v.add_child(_row("직위", "선임 개발자 (근속 7년)"))
	v.add_child(_row("사유", "일신상의 사유"))
	v.add_child(_gap(8))
	var body := UiKit.label("위 본인은 상기 사유로 사직하고자 하오니\n재가하여 주시기 바랍니다.", 20, UiKit.INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER)
	v.add_child(body)
	v.add_child(UiKit.label("2027년 2월 28일", 20, UiKit.INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER))
	v.add_child(_gap(8))

	var sign_row := HBoxContainer.new()
	sign_row.alignment = BoxContainer.ALIGNMENT_CENTER
	sign_row.add_theme_constant_override("separation", 14)
	sign_row.add_child(UiKit.label("성명", UiKit.SIZE_BODY, UiKit.INK))
	_name_edit = UiKit.line_edit(GameState.DEFAULT_PLAYER_NAME, 32, UiKit.INK, GameState.PLAYER_NAME_MAX)
	_name_edit.custom_minimum_size = Vector2(220, 0)
	_name_edit.text_submitted.connect(func(_t): _sign())
	_name_edit.text_changed.connect(func(_t): _error.text = "")
	sign_row.add_child(_name_edit)
	sign_row.add_child(UiKit.label("(인)", UiKit.SIZE_BODY, UiKit.INK_SOFT))
	v.add_child(sign_row)

	_error = UiKit.label("", UiKit.SIZE_SMALL, UiKit.ERROR, HORIZONTAL_ALIGNMENT_CENTER)
	_error.custom_minimum_size.y = 26
	v.add_child(_error)

	var hint := UiKit.label("비워 두면 ‘%s’(으)로 서명해요. 한글 %d자까지." % [GameState.DEFAULT_PLAYER_NAME, GameState.PLAYER_NAME_MAX], UiKit.SIZE_SMALL, UiKit.INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER)
	v.add_child(hint)
	v.add_child(_gap(6))

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 14)
	var random_btn := UiKit.button("이름 추천", false)
	random_btn.pressed.connect(func():
		_name_edit.text = GameState.random_player_name()
		_error.text = "")
	buttons.add_child(random_btn)
	var sign_btn := UiKit.button("서명하기")
	sign_btn.pressed.connect(_sign)
	buttons.add_child(sign_btn)
	v.add_child(buttons)

	_name_edit.grab_focus()
	UiKit.fade_in(self)


func _sign() -> void:
	var problem := GameState.validate_player_name(_name_edit.text)
	if not problem.is_empty():
		_error.text = problem
		return
	var n := _name_edit.text.strip_edges()
	GameState.player_name = n if not n.is_empty() else GameState.DEFAULT_PLAYER_NAME
	UiKit.go_to(self, NEXT_SCENE, 0.8)


func _row(key: String, value: String) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 24)
	var k := UiKit.label(key, 22, UiKit.INK_SOFT)
	k.custom_minimum_size.x = 70
	h.add_child(k)
	h.add_child(UiKit.label(value, 22, UiKit.INK))
	return h


func _gap(px: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size.y = px
	return c
