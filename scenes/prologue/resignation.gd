extends Control
## 프롤로그 1: 사직서에 이름을 적는 장면. 여기서 {player}가 정해진다.
## 배경: bg_office_night (사용자에게 받음). 없으면 어두운 남색 바탕.

const NEXT_SCENE := "res://scenes/prologue/signboard.tscn"

var _name_edit: LineEdit
var _error: Label
var _seal: Label


func _ready() -> void:
	var base := ColorRect.new()
	base.color = UiKit.NAVY_DEEP
	base.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(base)
	var art := UiKit.cover_art("bg_office_night")
	if art:
		add_child(art)
	add_child(UiKit.shade([[0.0, 0.55], [0.5, 0.25], [1.0, 0.75]]))

	var root := UiKit.vbox(UiKit.SPACE_LG)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 36
	root.offset_right = -36
	root.offset_top = 72
	root.offset_bottom = -48
	add_child(root)

	root.add_child(_step_chip("프롤로그 1 / 2", "사직서"))
	var lead := UiKit.paragraph("7년을 다닌 회사. 마지막 서류에 이름을 적는다.", "body", UiKit.FOAM_SOFT, 0.0, HORIZONTAL_ALIGNMENT_CENTER)
	root.add_child(lead)

	var spacer_top := Control.new()
	spacer_top.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(spacer_top)

	var paper := UiKit.paper_panel(40, UiKit.RADIUS_MD)
	UiKit.elevate(paper.get_theme_stylebox("panel"), 3)
	root.add_child(paper)
	var v := UiKit.vbox(UiKit.SPACE_MD)
	paper.add_child(v)

	var head := UiKit.text("사 직 서", "h1", UiKit.INK, HORIZONTAL_ALIGNMENT_CENTER)
	v.add_child(head)
	v.add_child(UiKit.gap(4))
	v.add_child(UiKit.divider(UiKit.INK))
	v.add_child(_row("소속", "플랫폼개발본부 백엔드팀"))
	v.add_child(UiKit.divider())
	v.add_child(_row("직위", "선임 개발자 (근속 7년)"))
	v.add_child(UiKit.divider())
	v.add_child(_row("사유", "일신상의 사유"))
	v.add_child(UiKit.divider(UiKit.INK))
	v.add_child(UiKit.gap(6))
	var body := UiKit.text("위 본인은 상기 사유로 사직하고자 하오니\n재가하여 주시기 바랍니다.", "body", UiKit.INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER)
	body.add_theme_font_override("font", UiKit.font("serif"))
	body.add_theme_constant_override("line_spacing", 8)
	v.add_child(body)
	var date := UiKit.text("2027년 2월 28일", "body", UiKit.INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER)
	date.add_theme_font_override("font", UiKit.font("serif"))
	v.add_child(date)
	v.add_child(UiKit.gap(8))

	# 서명 줄
	var sign_row := UiKit.hbox(UiKit.SPACE_MD, BoxContainer.ALIGNMENT_CENTER)
	var who := UiKit.text("성명", "title", UiKit.INK)
	who.add_theme_font_override("font", UiKit.font("serif_bold"))
	sign_row.add_child(who)
	_name_edit = UiKit.line_edit(GameState.DEFAULT_PLAYER_NAME, 30, UiKit.INK, GameState.PLAYER_NAME_MAX)
	_name_edit.add_theme_font_override("font", UiKit.font("serif_bold"))
	_name_edit.custom_minimum_size = Vector2(250, 62)
	_name_edit.text_submitted.connect(func(_t): _sign())
	_name_edit.text_changed.connect(func(_t): _error.text = "")
	sign_row.add_child(_name_edit)
	_seal = UiKit.text("(인)", "title", UiKit.INK_MUTED)
	_seal.add_theme_font_override("font", UiKit.font("serif"))
	sign_row.add_child(_seal)
	v.add_child(sign_row)

	_error = UiKit.text("", "caption", UiKit.DANGER, HORIZONTAL_ALIGNMENT_CENTER)
	_error.custom_minimum_size.y = 20
	v.add_child(_error)
	v.add_child(UiKit.text("비워 두면 ‘%s’(으)로 서명해요. 한글 %d자까지." % [GameState.DEFAULT_PLAYER_NAME, GameState.PLAYER_NAME_MAX], "caption", UiKit.INK_MUTED, HORIZONTAL_ALIGNMENT_CENTER))

	var spacer_bottom := Control.new()
	spacer_bottom.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(spacer_bottom)

	var buttons := UiKit.hbox(UiKit.SPACE_MD)
	var random_btn := UiKit.action("이름 추천", "glass")
	random_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	random_btn.pressed.connect(func():
		Sound.play_sfx("page", 0.05)
		_name_edit.text = GameState.random_player_name()
		_error.text = "")
	buttons.add_child(random_btn)
	var sign_btn := UiKit.action("서명하기")
	sign_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sign_btn.size_flags_stretch_ratio = 1.6
	sign_btn.pressed.connect(_sign)
	buttons.add_child(sign_btn)
	root.add_child(buttons)

	_name_edit.grab_focus()
	UiKit.fade_in(self)
	UiKit.rise_in(paper, 0.15)


func _sign() -> void:
	var problem := GameState.validate_player_name(_name_edit.text)
	if not problem.is_empty():
		_error.text = problem
		Sound.play_sfx("bad", 0.0, -8.0)
		return
	var n := _name_edit.text.strip_edges()
	GameState.player_name = n if not n.is_empty() else GameState.DEFAULT_PLAYER_NAME
	_name_edit.text = GameState.player_name
	_name_edit.editable = false
	# 도장 찍듯 (인)이 붉게 바뀐다
	Sound.play_sfx("stamp")
	_seal.add_theme_color_override("font_color", UiKit.DANGER)
	_seal.add_theme_font_override("font", UiKit.font("serif_bold"))
	_seal.pivot_offset = _seal.size / 2.0
	_seal.scale = Vector2(1.6, 1.6)
	var tw := create_tween()
	tw.tween_property(_seal, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(0.6)
	tw.tween_callback(func(): UiKit.go_to(self, NEXT_SCENE, 0.8))


func _row(key: String, value: String) -> HBoxContainer:
	var h := UiKit.hbox(UiKit.SPACE_LG)
	var k := UiKit.text(key, "body", UiKit.INK_MUTED)
	k.add_theme_font_override("font", UiKit.font("serif"))
	k.custom_minimum_size.x = 64
	h.add_child(k)
	var val := UiKit.text(value, "body", UiKit.INK)
	val.add_theme_font_override("font", UiKit.font("serif_bold"))
	h.add_child(val)
	return h


## 진행 단계 표시 (프롤로그 1 / 2 · 사직서)
func _step_chip(step: String, name_text: String) -> Control:
	var c := UiKit.chip(step, name_text)
	c.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	return c
