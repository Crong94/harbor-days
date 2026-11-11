extends Control
## 챕터 2 〈첫 번째 손님〉. 새벽에 잡은 볼락을 소금구이로 굽고, 최순덕이 첫 손님으로 온다.
## 기획서 6장 챕터 2 끝부분. 요리 규칙은 CookingLogic, 이 스크립트는 이야기 순서와 화면 표시만 맡는다.
##
## 그림: 식당 내부 bg_shop_inside_day, 순덕 초상화 npc_sundeok (사용자에게 받음. 없으면 그림 자리만 보인다)
##       화로 kitchen/grill, 볼락구이 dish/bollak-gui (바다 한 접시에서 가져옴)

const NEXT_SCENE := "res://scenes/map/map.tscn"
const FIRST_SALE := 7000 # 기획서: 첫 매출 7,000원
const FIRST_COST := 4500 # 기획서: 지출 4,500원 (크릴 미끼, 가스비)

enum Step { INTRO, COOK, SERVED, GUEST, LEDGER }

var cook := CookingLogic.new()
var step := Step.INTRO

var _fish := {} # 굽는 물고기 {"id", "size"}
var _recipe := {}
var _dialogue: DialogueBox
var _guest: ArtSlot
var _cook_panel: PanelContainer
var _cook_title: Label
var _cook_step: PanelContainer
var _cook_art: ArtSlot
var _cook_hint: Label
var _stars: Label
var _gauge: Control
var _ledger: Control
var _ledger_rows: VBoxContainer
var _ledger_btn: Button
var _held := false
var _sizzle := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var base := ColorRect.new()
	base.color = Color("2b2420")
	base.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(base)
	var bg := UiKit.cover_art("bg_shop_inside_day")
	if bg:
		add_child(bg)
	add_child(UiKit.shade([[0.0, 0.5], [0.2, 0.0], [0.7, 0.0], [1.0, 0.6]], Color("1a1410")))

	# 위: 가게 이름과 시각
	var bar := UiKit.hbox(UiKit.SPACE_SM)
	bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	bar.offset_left = 20
	bar.offset_right = -20
	bar.offset_top = 24
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bar)
	bar.add_child(UiKit.chip("", GameState.shop_name, "icon_shop"))
	bar.add_child(UiKit.spacer())
	bar.add_child(UiKit.chip("", "오전 07:30", "icon_clock"))
	if not bg:
		var note := UiKit.text("식당 내부 그림 준비 중 · bg_shop_inside_day", "caption", Color(1, 1, 1, 0.35), HORIZONTAL_ALIGNMENT_CENTER)
		note.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
		note.offset_top = 92
		add_child(note)

	# 손님 초상화 (화면 가운데 위)
	_guest = ArtSlot.make("npc_sundeok", "최순덕", Vector2(420, 560))
	_guest.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_guest.offset_left = -210
	_guest.offset_right = 210
	_guest.offset_top = 210
	_guest.offset_bottom = 770
	_guest.hide()
	add_child(_guest)

	_pick_fish()
	_build_cook_panel()
	_build_ledger()

	_dialogue = DialogueBox.new()
	_dialogue.on_stage = ["sundeok"] # 할머니가 화면에 크게 서 있다
	add_child(_dialogue)
	_dialogue.finished.connect(_on_dialogue_finished)

	Sound.play_bgm("town")
	UiKit.fade_in(self, 0.8)
	_dialogue.play([
		{"speaker": "", "text": "아침 일곱 시 반. {shop}."},
		{"speaker": "{player}", "text": "문은 열었는데 팔 게 이것뿐이네."},
		{"speaker": "{player}", "text": "%s 한 마리. 소금 뿌려서 구워 보자." % FishDB.get_fish(_fish.id).name},
	])


## 아이스박스에서 구울 물고기를 꺼낸다. 첫날은 볼락이 반드시 있다.
func _pick_fish() -> void:
	_fish = GameState.take_fish("bolak")
	if _fish.is_empty() and not GameState.inventory.is_empty():
		_fish = GameState.take_fish(GameState.inventory[0].id)
	if _fish.is_empty():
		_fish = {"id": "bolak", "size": 15.0} # 테스트로 바로 이 장면을 열었을 때
	_recipe = Catalog.recipe(FishDB.get_fish(_fish.id).get("grill", "bollak-gui"))
	cook.setup(_recipe)


# ─── 입력 ───────────────────────────────────────────

func _unhandled_input(event: InputEvent) -> void:
	if step != Step.COOK or cook.phase == CookingLogic.Phase.DONE:
		return
	var pressed := false
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		pressed = event.pressed
	elif event is InputEventKey and event.keycode == KEY_SPACE and not event.echo:
		pressed = event.pressed
	else:
		return
	get_viewport().set_input_as_handled()
	_held = pressed
	var before := cook.phase
	if pressed:
		cook.press()
	else:
		cook.release()
	if cook.phase != before:
		_on_phase_changed()


func _process(delta: float) -> void:
	if step != Step.COOK:
		return
	var before := cook.phase
	cook.update(delta, _held)
	if cook.phase != before:
		_on_phase_changed()
	if cook.phase == CookingLogic.Phase.GRILL:
		_sizzle -= delta
		if _sizzle <= 0.0:
			Sound.play_sfx("sizzle", 0.05, -8.0)
			_sizzle = 1.4
	_gauge.queue_redraw()


# ─── 진행 ───────────────────────────────────────────

func _on_dialogue_finished() -> void:
	match step:
		Step.INTRO:
			_start_cooking()
		Step.SERVED:
			_guest_arrives()
		Step.GUEST:
			_show_ledger()


func _start_cooking() -> void:
	step = Step.COOK
	_cook_title.text = _recipe.get("name", "생선구이")
	UiKit.set_chip(_cook_step, "1 / 2 간 맞추기")
	_cook_art.set_art("kitchen/grill", "화로")
	_cook_hint.text = "꾹 누르면 %s을 뿌려요. 적당하다 싶을 때 손을 떼요" % Catalog.flavor(cook.flavor).get("tool", "소금")
	_cook_panel.show()
	UiKit.fade_in(_cook_panel, 0.3)


func _on_phase_changed() -> void:
	match cook.phase:
		CookingLogic.Phase.GRILL:
			_held = false
			Sound.play_sfx("tap")
			_cook_hint.text = "노릇하게 익었을 때 눌러서 불에서 내려요"
			UiKit.set_chip(_cook_step, "2 / 2 굽기")
			_sizzle = 0.0
		CookingLogic.Phase.DONE:
			_held = false
			_served()


func _served() -> void:
	step = Step.SERVED
	Sound.play_sfx("good" if cook.stars() >= 3 else "okay")
	_cook_art.set_art(Catalog.dish_art(_recipe.get("id", "")), _recipe.get("name", "생선구이"))
	_cook_hint.text = {3: "완벽해요", 2: "괜찮아요", 1: "아쉬워요"}.get(cook.stars(), "")
	UiKit.set_chip(_cook_step, "완성")
	_stars.text = "★".repeat(cook.stars()) + "☆".repeat(3 - cook.stars())
	_stars.show()
	UiKit.pop_in(_cook_panel)
	_gauge.hide()
	var grill_line := {
		"good": "겉은 노릇하고 속은 촉촉하다.",
		"raw": "속이 조금 덜 익은 것 같다.",
		"burnt": "껍질이 까맣게 탔다.",
	}
	_dialogue.play([
		{"speaker": "", "text": grill_line.get(cook.cooking, "")},
		{"speaker": "{player}", "text": "처음 치고는... 나쁘지 않은데?"},
	])


func _guest_arrives() -> void:
	step = Step.GUEST
	_cook_panel.hide()
	Sound.play_sfx("door")
	_guest.show()
	UiKit.fade_in(_guest, 0.6)
	var taste := {
		"good": "간이 딱 맞네.",
		"bland": "간이 좀 싱겁네.",
		"strong": "간이 좀 세네.",
	}
	var cooked := {
		"good": "",
		"raw": "속은 쪼매 덜 익었고.",
		"burnt": "껍데기는 좀 탔고.",
	}
	var lines := [
		{"speaker": "", "text": "그때 문에 단 종이 울렸다. 지팡이를 짚은 할머니가 들어왔다."},
		{"speaker": "할머니", "text": "불이 켜져 있길래. 여기 문 연 거 몇 년 만이여."},
		{"speaker": "{player}", "text": "아, 어서 오세요. 오늘은 볼락구이 하나밖에 없는데요."},
		{"speaker": "할머니", "face": "smile", "text": "그거면 됐어. 밥이나 한 그릇 줘."},
		{"speaker": "", "text": "할머니는 천천히 볼락 살을 발라 밥 위에 얹었다."},
		{"speaker": "최순덕", "face": "smile" if cook.stars() >= 3 else "sad", "text": (taste.get(cook.seasoning, "") + " " + cooked.get(cook.cooking, "")).strip_edges()},
		{"speaker": "최순덕", "face": "smile", "text": "따뜻한 밥 먹으니 좋구먼." if cook.stars() >= 3 else "그래도 따뜻한 밥 먹으니 좋구먼."},
		{"speaker": "", "text": "첫 매출 %s." % GameState.format_won(FIRST_SALE)},
		{"speaker": "", "text": "순덕은 계산을 마치고 나가다 간판을 올려다봤다."},
		{"speaker": "최순덕", "face": "smile", "text": "{shop|이/가}라... 이름 좋네. 오래 가라고."},
	]
	GameState.earn(FIRST_SALE)
	GameState.note("순덕 할머니가 첫 손님으로 왔다. 이 정도면 해볼 만하겠는데?", 9)
	GameState.spend(FIRST_COST)
	GameState.flags["met_sundeok"] = true
	_dialogue.play(lines)


func _show_ledger() -> void:
	step = Step.LEDGER
	_guest.hide()
	Sound.play_sfx("coin")
	var profit := GameState.sales_today - GameState.spent_today
	for c in _ledger_rows.get_children():
		c.queue_free()
	_ledger_rows.add_child(_ledger_row("매출", "볼락구이 1접시", "+" + GameState.format_won(GameState.sales_today), UiKit.SEA))
	_ledger_rows.add_child(_ledger_row("지출", "크릴 미끼, 가스비", "-" + GameState.format_won(GameState.spent_today), UiKit.DANGER))
	_ledger_rows.add_child(UiKit.divider())
	_ledger_rows.add_child(_ledger_row("순이익", "", GameState.format_won(profit), UiKit.INK, true))
	_ledger.show()
	UiKit.fade_in(_ledger, 0.4)
	_ledger_btn.grab_focus()


func _next_day() -> void:
	GameState.flags["first_guest_done"] = true
	GameState.flags["chapter2_done"] = true
	GameState.current_location = "shop"
	GameState.end_day() # 다음 날 새벽 5시
	UiKit.go_to(self, NEXT_SCENE)


# ─── 화면 구성 ──────────────────────────────────────

func _build_cook_panel() -> void:
	var holder := CenterContainer.new()
	holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.offset_top = 100
	holder.offset_bottom = -280 # 대사창 자리
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(holder)
	_cook_panel = UiKit.paper_panel(28)
	UiKit.elevate(_cook_panel.get_theme_stylebox("panel"), 3)
	_cook_panel.custom_minimum_size = Vector2(640, 0)
	_cook_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(_cook_panel)
	var v := UiKit.vbox(UiKit.SPACE_MD)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cook_panel.add_child(v)
	var head := UiKit.hbox(UiKit.SPACE_MD)
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cook_title = UiKit.text("", "h1", UiKit.INK)
	head.add_child(_cook_title)
	head.add_child(UiKit.spacer())
	_cook_step = UiKit.chip("", "", "", false)
	head.add_child(_cook_step)
	v.add_child(head)
	var art_box := PanelContainer.new()
	art_box.add_theme_stylebox_override("panel", UiKit.inset_box(UiKit.SPACE_LG, UiKit.RADIUS_LG))
	art_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(art_box)
	_cook_art = ArtSlot.make("kitchen/grill", "화로", Vector2(540, 320))
	art_box.add_child(_cook_art)
	_stars = UiKit.text("", "h1", UiKit.SUN, HORIZONTAL_ALIGNMENT_CENTER)
	_stars.add_theme_font_override("font", UiKit.font("bold"))
	_stars.hide()
	v.add_child(_stars)
	_gauge = Control.new()
	_gauge.custom_minimum_size = Vector2(0, 64)
	_gauge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_gauge.draw.connect(_draw_gauge)
	v.add_child(_gauge)
	_cook_hint = UiKit.paragraph("", "body", UiKit.INK_SOFT, 0.0, HORIZONTAL_ALIGNMENT_CENTER)
	v.add_child(_cook_hint)
	_cook_panel.hide()


## 판정 게이지. 간 맞추기는 뿌린 양만 보여 주고(감으로 친다), 굽기는 노릇한 구간을 보여 준다.
func _draw_gauge() -> void:
	var font := UiKit.font("semibold")
	var r := Rect2(Vector2(0, 34), Vector2(_gauge.size.x, 24))
	if cook.phase == CookingLogic.Phase.SEASON:
		_gauge.draw_string(font, Vector2(0, 20), Catalog.flavor(cook.flavor).get("name", "간"), HORIZONTAL_ALIGNMENT_LEFT, -1, 17, UiKit.INK_SOFT)
		UiKit.draw_bar(_gauge, r, cook.amount, UiKit.SEA, false)
	else:
		_gauge.draw_string(font, Vector2(0, 20), "익은 정도", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, UiKit.INK_SOFT)
		var col := UiKit.CORAL if cook.doneness > CookingLogic.GRILL_GOOD.y else UiKit.WOOD
		UiKit.draw_bar(_gauge, r, cook.doneness, col, false, CookingLogic.GRILL_GOOD)


func _build_ledger() -> void:
	_ledger = Control.new()
	_ledger.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_ledger)
	_ledger.add_child(UiKit.scrim())
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ledger.add_child(center)
	var panel := UiKit.paper_panel(36)
	UiKit.elevate(panel.get_theme_stylebox("panel"), 3)
	panel.custom_minimum_size = Vector2(620, 0)
	center.add_child(panel)
	var v := UiKit.vbox(UiKit.SPACE_LG)
	panel.add_child(v)
	v.add_child(UiKit.badge(Calendar.text(1) + " 밤",UiKit.NAVY_DEEP, UiKit.FOAM))
	v.add_child(UiKit.text("장부 첫 줄", "h1", UiKit.INK, HORIZONTAL_ALIGNMENT_CENTER))
	_ledger_rows = UiKit.vbox(UiKit.SPACE_SM)
	v.add_child(_ledger_rows)
	var quote := UiKit.text("\"이 정도면... 해볼 만하겠는데?\"", "body", UiKit.INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER)
	quote.add_theme_font_override("font", UiKit.font("serif"))
	v.add_child(quote)
	_ledger_btn = UiKit.action("다음 날로")
	_ledger_btn.custom_minimum_size.y = 60
	_ledger_btn.pressed.connect(_next_day)
	v.add_child(_ledger_btn)
	_ledger.hide()


## 장부 한 줄: 항목, 설명, 금액
func _ledger_row(key: String, note: String, amount: String, color: Color, strong := false) -> HBoxContainer:
	var h := UiKit.hbox(UiKit.SPACE_MD)
	h.add_child(UiKit.text(key, "title" if strong else "body", UiKit.INK))
	if not note.is_empty():
		h.add_child(UiKit.text(note, "caption", UiKit.INK_MUTED))
	h.add_child(UiKit.spacer())
	var a := UiKit.text(amount, "h2" if strong else "title", color)
	h.add_child(a)
	return h
