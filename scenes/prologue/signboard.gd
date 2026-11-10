extends Control
## 프롤로그 2 (챕터 1): 낡은 나무판에 가게 이름을 쓰고 간판을 다는 장면. 여기서 {shop}이 정해진다.
## 그림: bg_shop_front (해 질 녘 식당 외관, 간판 자리 비어 있음), ui_signboard (빈 나무 간판, 투명 배경).
## 간판은 외관 그림 속 빈 간판 자리(쇠고리 두 개 아래)에 겹쳐 놓는다. 그림이 없으면 나무색 판으로 대신한다.

const NEXT_SCENE := "res://scenes/fishing/fishing.tscn"
## bg_shop_front 그림 속 간판 자리 (그림 크기 대비 비율). 가운데 x, 위쪽 y, 간판 너비
## 처마와 차양 사이 빈 벽에 붙는다. 아래 끝이 차양 윗선에 살짝 걸친다
const SIGN_SPOT := Vector3(0.543, 0.300, 0.46)
## 간판 그림의 가로:세로 (ui_signboard.png 2163x702, 위 가운데 물고기 장식 포함)
const SIGN_ASPECT := 3.08
## 외관 벽이 오른쪽으로 아주 조금 내려가 있어 간판도 그만큼 기울인다 (차양 윗선으로 쟀다)
const SIGN_TILT := 1.2
## 간판이 잘 보이게 외관 그림을 조금 당겨 보여 준다. 가로는 간판 자리를 가운데로, 세로는 하늘을 더 자른다
const ART_ZOOM := 1.3
const ART_CROP_TOP := 0.55

var _art: TextureRect
var _board: Control
var _shop_label: Label
var _form: PanelContainer
var _shop_edit: LineEdit
var _error: Label
var _lead: Label
var _dialogue: DialogueBox
var _next_btn: Button
var _hung := false
var _ink := UiKit.FOAM # 간판 글씨 색 (그림 간판은 남색, 대신 판은 크림)


func _ready() -> void:
	var base := ColorRect.new()
	base.color = UiKit.NAVY_DEEP
	base.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(base)
	var has_front := ArtSlot.has_art("bg_shop_front")
	_art = UiKit.cover_art("bg_shop_front" if has_front else "map_village")
	if _art:
		if not has_front:
			_art.modulate = Color(0.55, 0.5, 0.6) # 임시 배경은 노을빛으로 눌러 둔다
		add_child(_art)
	# 위는 안내 글자, 아래는 입력 카드가 잘 읽히게 가장자리만 살짝 어둡게
	add_child(UiKit.shade([[0.0, 0.5], [0.16, 0.0], [0.62, 0.0], [1.0, 0.55]]))

	var top := UiKit.vbox(UiKit.SPACE_MD)
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top.offset_left = 36
	top.offset_right = -36
	top.offset_top = 56
	add_child(top)
	var step := UiKit.chip("프롤로그 2 / 2", "간판")
	step.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	top.add_child(step)
	_lead = UiKit.text("간판 자리가 비어 있다.\n낡은 나무판에 가게 이름을 적어 보자.", "body", UiKit.FOAM, HORIZONTAL_ALIGNMENT_CENTER)
	UiKit.outlined(_lead, 8)
	top.add_child(_lead)

	_board = _make_board()
	_board.modulate.a = 0.6 # 달기 전에는 흐릿한 미리보기
	add_child(_board)

	_build_form()

	_next_btn = UiKit.action("다음 날 새벽으로")
	_next_btn.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_next_btn.offset_left = 36
	_next_btn.offset_right = -36
	_next_btn.offset_top = -48 - UiKit.BUTTON_H
	_next_btn.offset_bottom = -48
	_next_btn.pressed.connect(func(): UiKit.go_to(self, NEXT_SCENE, 0.8))
	_next_btn.hide()
	add_child(_next_btn)

	_dialogue = DialogueBox.new()
	add_child(_dialogue)
	_dialogue.finished.connect(_on_dialogue_finished)

	resized.connect(_layout_board)
	_layout_board.call_deferred()
	UiKit.fade_in(self)
	# 간판을 쓰기 전: 대출 승인, 싼 매물, 물빛울포 도착 (기획서 5장 끝, 챕터 1 처음)
	_form.hide()
	_board.hide()
	_lead.hide()
	_dialogue.play(INTRO)


const INTRO := [
	{"speaker": "", "text": "통장 잔고는 생각보다 적었다."},
	{"speaker": "은행 직원", "text": "{player} 고객님 귀농귀촌 창업 대출 승인되셨습니다. 상환은 다음 달부터 시작이에요."},
	{"speaker": "", "text": "부동산 앱을 뒤지다 터무니없이 싼 매물을 찾았다. 경남 물빛울포. 식당 겸 주택. 월세 협의 가능."},
	{"speaker": "", "text": "사진 속 바다에 빨간 등대가 보였다. 그게 무슨 뜻인지는 아직 몰랐다."},
	{"speaker": "", "text": "버스를 세 번 갈아타고 도착한 물빛울포. 정류장엔 아무도 없고 갈매기 소리만 들린다."},
	{"speaker": "{player}", "text": "여기가 내 가게구나. 사진보다 더 낡았네."},
	{"speaker": "", "text": "의자는 다리가 흔들리고 환풍기는 돌지 않는다. 창고 구석에서 먼지 쌓인 낚싯대 하나를 찾았다."},
	{"speaker": "", "text": "청소를 마치고 나오니 간판 자리가 텅 비어 있다."},
]

var _intro_done := false


## 아래 입력 카드 (크림 종이)
func _build_form() -> void:
	_form = UiKit.paper_panel(UiKit.SPACE_LG)
	_form.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_form.offset_left = 24
	_form.offset_right = -24
	_form.offset_top = -24
	_form.offset_bottom = -32
	_form.grow_vertical = Control.GROW_DIRECTION_BEGIN
	add_child(_form)
	var fv := UiKit.vbox(UiKit.SPACE_MD)
	_form.add_child(fv)
	fv.add_child(UiKit.text("가게 이름", "title", UiKit.INK))
	_shop_edit = UiKit.line_edit(GameState.DEFAULT_SHOP_NAME, 28, UiKit.INK, GameState.SHOP_NAME_MAX)
	_shop_edit.custom_minimum_size.y = 64
	_shop_edit.text_submitted.connect(func(_t): _hang_sign())
	_shop_edit.text_changed.connect(_on_typed)
	fv.add_child(_shop_edit)
	_error = UiKit.text("", "caption", UiKit.DANGER)
	_error.hide()
	fv.add_child(_error)
	fv.add_child(UiKit.text("비워 두면 ‘%s’(으)로 정해져요. 한글 %d자까지, 띄어쓰기 가능." % [GameState.DEFAULT_SHOP_NAME, GameState.SHOP_NAME_MAX], "caption", UiKit.INK_SOFT))
	fv.add_child(UiKit.gap(2))
	var buttons := UiKit.hbox(UiKit.SPACE_MD)
	var random_btn := UiKit.action("이름 추천", "secondary")
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


## 간판: 그림(ui_signboard)이 있으면 그 위에 글씨를, 없으면 나무색 판에 글씨를 쓴다
func _make_board() -> Control:
	var holder := Control.new()
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var plate: Control
	var sign_art := UiKit.cover_art("ui_signboard")
	if sign_art:
		sign_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		plate = sign_art
	else:
		var p := PanelContainer.new()
		var s := UiKit.chunky(UiKit.WOOD, 18, 0, 8)
		UiKit.elevate(s, 3)
		p.add_theme_stylebox_override("panel", s)
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		plate = p
	plate.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.add_child(plate)
	# 나무판에 페인트로 쓴 크림색 글씨 (짙은 나무색 테두리)
	_ink = UiKit.INK if sign_art else UiKit.FOAM
	_shop_label = UiKit.text(GameState.DEFAULT_SHOP_NAME, "h1", Color(_ink, 0.35), HORIZONTAL_ALIGNMENT_CENTER)
	_shop_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_shop_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if not sign_art:
		UiKit.outlined(_shop_label, 12, UiKit.WOOD_DARK)
	holder.add_child(_shop_label)
	return holder


## 외관 그림이 화면에 그려진 영역을 구해 간판을 그림 속 간판 자리에 맞춘다
func _layout_board() -> void:
	var art_rect := Rect2(Vector2.ZERO, size)
	if _art and _art.texture and ArtSlot.has_art("bg_shop_front"):
		var ts := _art.texture.get_size()
		var ds := ts * maxf(size.x / ts.x, size.y / ts.y) * ART_ZOOM
		var x := clampf(size.x / 2.0 - ds.x * SIGN_SPOT.x, size.x - ds.x, 0.0)
		var y := -(ds.y - size.y) * ART_CROP_TOP
		art_rect = Rect2(Vector2(x, y), ds)
		_art.set_anchors_preset(Control.PRESET_TOP_LEFT)
		_art.stretch_mode = TextureRect.STRETCH_SCALE
		_art.position = art_rect.position
		_art.size = art_rect.size
	var w := art_rect.size.x * SIGN_SPOT.z
	var h := w / SIGN_ASPECT
	var center_x := art_rect.position.x + art_rect.size.x * SIGN_SPOT.x
	var top_y := art_rect.position.y + art_rect.size.y * SIGN_SPOT.y
	_board.size = Vector2(w, h)
	_board.position = Vector2(center_x - w / 2.0, top_y)
	# 쇠고리에 매달린 듯 위 가운데를 축으로 흔들린다
	_board.pivot_offset = Vector2(w / 2.0, 0.0)
	_board.rotation_degrees = SIGN_TILT if ArtSlot.has_art("bg_shop_front") else 0.0
	if ArtSlot.has_art("ui_signboard"):
		# 위 물고기 장식과 아래 물결 사이 크림색 칸 가운데에 쓴다
		_shop_label.offset_top = h * 0.36
		_shop_label.offset_bottom = -h * 0.22
	_fit_label()


## 글자 수에 맞게 간판 글씨 크기를 줄인다 (판 안쪽 70%를 넘지 않게)
func _fit_label() -> void:
	var font := UiKit.font("cute")
	var px := mini(54, int(_board.size.y * 0.3)) if ArtSlot.has_art("ui_signboard") else 54
	var limit := _board.size.x * 0.74
	while px > 22 and font.get_string_size(_shop_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x > limit:
		px -= 2
	_shop_label.add_theme_font_size_override("font_size", px)


## 입력하는 대로 간판에 글씨가 미리 비친다
func _on_typed(t: String) -> void:
	_error.text = ""
	_error.hide()
	var s := t.strip_edges()
	_shop_label.text = s if not s.is_empty() else GameState.DEFAULT_SHOP_NAME
	_shop_label.add_theme_color_override("font_color", _ink if not s.is_empty() else Color(_ink, 0.35))
	_fit_label()


func _hang_sign() -> void:
	if _hung:
		return
	var problem := GameState.validate_shop_name(_shop_edit.text)
	if not problem.is_empty():
		_error.text = problem
		_error.show()
		Sound.play_sfx("bad", 0.0, -8.0)
		var tw_shake := create_tween()
		for dx in [10.0, -8.0, 5.0, 0.0]:
			tw_shake.tween_property(_shop_edit, "position:x", dx, 0.05)
		return
	_hung = true
	var n := _shop_edit.text.strip_edges()
	GameState.shop_name = n if not n.is_empty() else GameState.DEFAULT_SHOP_NAME
	_shop_label.text = GameState.shop_name
	_shop_label.add_theme_color_override("font_color", _ink)
	_fit_label()
	_lead.text = ""
	var tw_form := create_tween()
	tw_form.tween_property(_form, "modulate:a", 0.0, UiKit.MOTION_BASE)
	tw_form.tween_callback(_form.hide)

	# 간판이 위에서 내려와 쇠고리에 걸리고, 그네처럼 몇 번 흔들리다 멈춘다
	var rest_y := _board.position.y
	var tw := create_tween()
	tw.tween_property(_board, "position:y", rest_y - 50.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(_board, "modulate:a", 1.0, 0.18)
	tw.tween_property(_board, "position:y", rest_y, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func():
		Sound.play_sfx("stamp")
		Haptics.play("hook"))
	for deg in [6.0, -4.0, 2.5, -1.0, 0.0]:
		tw.tween_property(_board, "rotation_degrees", deg + (SIGN_TILT if ArtSlot.has_art("bg_shop_front") else 0.0), 0.22).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_interval(0.3)
	tw.tween_callback(func(): _dialogue.play([
		{"speaker": "{player}", "text": "{shop}. 오늘부터 여기가 내 자리다."},
		{"speaker": "{player}", "text": "통장에는 %s, 갚아야 할 대출은 %s." % [GameState.format_won(GameState.money), GameState.format_won(GameState.debt)]},
		{"speaker": "{player}", "text": "...일단 팔 게 있어야 하는데. 내일 새벽에 방파제로 가 보자."},
	]))


func _on_dialogue_finished() -> void:
	if not _intro_done:
		# 도착 이야기가 끝나면 간판 쓰기
		_intro_done = true
		_lead.show()
		_board.show()
		_form.show()
		UiKit.rise_in(_form, 0.1)
		_shop_edit.grab_focus()
		return
	_lead.text = GameState.line("{player}의 작은 식당, {shop}")
	_next_btn.show()
	UiKit.rise_in(_next_btn)
	_next_btn.grab_focus()
