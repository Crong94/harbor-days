extends Control
## 저녁 영업 (2일차부터). 하루 흐름은 DayFlow.
##   1. 문을 연다 (18:00). 특별 손님 몫 생선을 먼저 하나 빼 둔다
##   2. 보통 손님: 아이스박스 생선으로 알아서 구워 팔린다. 손님 줄이 하나씩 차오른다
##   3. 특별 손님(오늘 주문서를 낸 마을 사람): 직접 간을 맞추고 굽는다 (CookingLogic). 별점만큼 값과 평판
##   4. 장부: 매출, 지출, 순이익, 평판. 밤 낚시를 갈지 집에 가서 잘지 고른다
## 재료는 직접 낚은 생선만 쓴다. 생선이 모자라면 손님이 그냥 돌아간다.
## 그림: 식당 내부 저녁 bg_shop_inside_night (없으면 식당 외관을 어둡게 깐다)

const MAP_SCENE := "res://scenes/map/map.tscn"
const FISHING_SCENE := "res://scenes/fishing/fishing.tscn"
const GUEST_W := 300.0
const GUEST_H := 400.0

enum Step { INTRO, REGULARS, SPECIAL_TALK, COOK, SPECIAL_DONE, LEDGER }

var step := Step.INTRO
var cook := CookingLogic.new()
var result := {} # DayFlow.serve_regulars 결과
var special := {} # {"name", "fish"}
var special_fish := {} # 특별 손님에게 낼 생선 {"id", "size"}
var special_price := 0
var rep_change := 0

var _header: GameHeader
var _dialogue: DialogueBox
var _list_panel: PanelContainer
var _list: VBoxContainer
var _list_total: Label
var _cook_panel: PanelContainer
var _cook_title: Label
var _cook_step: PanelContainer
var _cook_art: ArtSlot
var _cook_hint: Label
var _stars: Label
var _gauge: Control
var _ledger: Control
var _ledger_rows: VBoxContainer
var _night_btn: Button
var _guest: GuestSD # 특별 손님 SD (대화창 오른쪽 위, 얼굴 그림 자리에 선다)
var _held := false
var _sizzle := 0.0
var _recipe := {}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var base := ColorRect.new()
	base.color = Color("1e1826")
	base.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(base)
	var has_inside := ArtSlot.has_art("bg_shop_inside_night")
	var bg := UiKit.cover_art("bg_shop_inside_night" if has_inside else "bg_shop_front")
	if bg:
		if not has_inside:
			bg.modulate = Color(0.62, 0.55, 0.72) # 외관을 저녁빛으로 눌러 임시 배경으로
		add_child(bg)
	add_child(UiKit.shade([[0.0, 0.55], [0.2, 0.1], [0.6, 0.1], [1.0, 0.7]], Color("1a1410")))

	GameState.time_minutes = maxi(GameState.time_minutes, DayFlow.SHOP_OPEN)
	GameState.opened_today = true
	GameState.current_location = "shop"
	_header = GameHeader.new()
	add_child(_header)

	_build_list()
	_build_cook_panel()
	_build_ledger()
	_guest = GuestSD.new()
	_guest.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	_guest.offset_left = -GUEST_W - 4
	_guest.offset_right = -4
	_guest.offset_top = -DialogueBox.BOTTOM - DialogueBox.HEIGHT - GUEST_H + 26
	_guest.offset_bottom = -DialogueBox.BOTTOM - DialogueBox.HEIGHT + 26
	_guest.hide()
	add_child(_guest)
	_dialogue = DialogueBox.new()
	add_child(_dialogue)
	_dialogue.finished.connect(_on_dialogue_finished)

	_reserve_special()
	Sound.play_bgm("town")
	UiKit.fade_in(self, 0.6)
	var n := GameState.inventory.size() + (1 if not special_fish.is_empty() else 0)
	var lines := [{"speaker": "", "text": "저녁 여섯 시. {shop} 문을 열었다."}]
	if n == 0:
		lines.append({"speaker": "{player}", "text": "아이스박스가 텅 비었네. 오늘은 팔 게 없다."})
	else:
		lines.append({"speaker": "{player}", "text": "아이스박스에 생선 %d마리. 오늘도 잘 팔려야 할 텐데." % n})
	_dialogue.play(lines)


## 특별 손님이 찾는 생선이 있으면 그걸, 없으면 가장 좋은 생선을 먼저 빼 둔다
func _reserve_special() -> void:
	special = DayFlow.special_guest(GameState.day)
	if special.is_empty() or GameState.inventory.is_empty():
		return
	special_fish = GameState.take_fish(special.fish)
	if special_fish.is_empty():
		var best := 0
		for i in GameState.inventory.size():
			var e: Dictionary = GameState.inventory[i]
			var b: Dictionary = GameState.inventory[best]
			if FishDB.value_of(e.id, e.size) > FishDB.value_of(b.id, b.size):
				best = i
		special_fish = GameState.inventory[best]
		GameState.inventory.remove_at(best)


# ─── 진행 ───────────────────────────────────────────

func _on_dialogue_finished() -> void:
	match step:
		Step.INTRO:
			_serve_regulars()
		Step.SPECIAL_TALK:
			_start_cooking()
		Step.SPECIAL_DONE:
			_guest_leaves()
			_show_ledger()


## 보통 손님: 한 명씩 줄에 차오른다
func _serve_regulars() -> void:
	step = Step.REGULARS
	result = DayFlow.serve_regulars(GameState.day, GameState.inventory)
	# 쓴 생선을 아이스박스에서 뺀다 (뒤에서부터 지워야 순서가 안 꼬인다)
	var used: Array = result.used.duplicate()
	used.sort()
	used.reverse()
	for i in used:
		GameState.inventory.remove_at(i)
	GameState.earn(result.sales)
	rep_change += result.served.size() * DayFlow.REP_SERVED + result.missed * DayFlow.REP_MISS
	if result.missed > 0:
		GameState.note("생선이 모자라 손님 %d명이 그냥 돌아갔다. 내일은 더 잡아 와야지." % result.missed, 2)
	elif result.served.size() >= DayFlow.GUESTS_MAX:
		GameState.note("손님 %d명이 다 생선구이를 먹고 갔다. 가게가 북적였다." % result.served.size(), 1)
	_list_panel.show()
	UiKit.rise_in(_list_panel)
	var tw := create_tween()
	tw.tween_interval(0.4)
	for g in result.served:
		tw.tween_callback(_add_guest_row.bind(g))
		tw.tween_interval(0.55)
	for i in result.missed:
		tw.tween_callback(_add_missed_row)
		tw.tween_interval(0.45)
	tw.tween_callback(func():
		_list_total.text = "보통 손님 %d명 · %s" % [result.served.size(), GameState.format_won(result.sales)]
		_header.refresh())
	tw.tween_interval(1.0)
	tw.tween_callback(_special_arrives)


func _add_guest_row(g: Dictionary) -> void:
	Sound.play_sfx("coin", 0.08, -6.0)
	Haptics.play("tap")
	var row := _row(g.guest, "%s구이 %dcm" % [FishDB.get_fish(g.fish).name, int(g.size)], "+" + GameState.format_won(g.price), UiKit.SEA)
	_list.add_child(row)
	UiKit.pop_in(row)


func _add_missed_row() -> void:
	Sound.play_sfx("bad", 0.0, -10.0)
	var row := _row("돌아간 손님", "생선이 다 떨어졌어요", "", UiKit.INK_MUTED)
	row.modulate.a = 0.7
	_list.add_child(row)
	UiKit.pop_in(row)


func _special_arrives() -> void:
	if special.is_empty() or special_fish.is_empty():
		step = Step.SPECIAL_DONE
		_list_panel.hide()
		_show_ledger()
		return
	step = Step.SPECIAL_TALK
	_list_panel.hide()
	Sound.play_sfx("door")
	_guest_enters()
	var fname: String = FishDB.get_fish(special_fish.id).name
	var want_name: String = FishDB.get_fish(special.fish).name
	var wanted: bool = special_fish.id == special.fish
	var ask := ""
	if GameState.order_done:
		ask = "아까 보내 준 %s 잘 받았어. 오늘 저녁은 여기서 먹고 갈게." % want_name
	elif wanted:
		ask = "%s 있나? 오늘은 그게 땡기네." % want_name
	else:
		ask = "%s 없나 보네. 그럼 있는 걸로 줘." % Josa.attach(want_name, "은/는")
	_dialogue.play([
		{"speaker": "", "text": "문에 단 종이 딸랑 울렸다. %s다." % Orders.call_name(special.name)},
		{"speaker": special.name, "text": ask},
		{"speaker": "{player}", "text": "%s 좋은 걸로 하나 남겨 뒀어요. 바로 구워 드릴게요." % fname},
	])


func _start_cooking() -> void:
	step = Step.COOK
	_recipe = Catalog.recipe(FishDB.get_fish(special_fish.id).get("grill", "bollak-gui"))
	cook.setup(_recipe)
	_cook_title.text = _recipe.get("name", "생선구이")
	UiKit.set_chip(_cook_step, "1 / 2 간 맞추기")
	_cook_art.set_art("kitchen/grill", "화로")
	_cook_hint.text = "꾹 누르면 %s을 뿌려요. 적당하다 싶을 때 손을 떼요" % Catalog.flavor(cook.flavor).get("tool", "소금")
	_stars.hide()
	_gauge.show()
	_cook_panel.show()
	UiKit.fade_in(_cook_panel, 0.3)
	_guest.hide() # 굽는 동안은 화로만


func _on_phase_changed() -> void:
	match cook.phase:
		CookingLogic.Phase.GRILL:
			_held = false
			Sound.play_sfx("tap")
			Haptics.play("tap")
			_cook_hint.text = "노릇하게 익었을 때 눌러서 불에서 내려요"
			UiKit.set_chip(_cook_step, "2 / 2 굽기")
			_sizzle = 0.0
		CookingLogic.Phase.DONE:
			_held = false
			_special_served()


func _special_served() -> void:
	step = Step.SPECIAL_DONE
	var st := cook.stars()
	Sound.play_sfx("good" if st >= 3 else "okay")
	Haptics.play("catch" if st >= 3 else "hook")
	_cook_art.set_art(Catalog.dish_art(_recipe.get("id", "")), _recipe.get("name", "생선구이"))
	UiKit.set_chip(_cook_step, "완성")
	_stars.text = "★".repeat(st) + "☆".repeat(3 - st)
	_stars.show()
	_gauge.hide()
	_cook_hint.text = {3: "완벽해요", 2: "괜찮아요", 1: "아쉬워요"}.get(st, "")
	UiKit.pop_in(_cook_panel)
	special_price = DayFlow.special_price(special_fish.id, special_fish.size, st)
	GameState.earn(special_price)
	var who := Orders.call_name(special.name)
	if st >= 3:
		GameState.note("%s 내 생선구이를 먹고 또 오겠다고 했다." % Josa.attach(who, "이/가"), 3)
	elif st <= 1:
		GameState.note("%s 아쉬운 얼굴로 돌아갔다. 불 앞에서 더 참아야겠다." % Josa.attach(who, "이/가"), 2)
	rep_change += st
	_header.refresh()
	if not _guest.guest_id.is_empty():
		_guest.set_pose(GuestSD.pose_for_stars(st))
		_guest.show()
		UiKit.fade_in(_guest, 0.25)
	var react: Array = Orders.customer(special.name).get("react", ["잘 먹었어요.", "잘 먹었어요.", "잘 먹었어요."])
	_dialogue.play([
		{"speaker": special.name, "text": react[clampi(3 - st, 0, 2)]},
		{"speaker": "", "text": "%s %s을 내고 갔다." % [Josa.attach(Orders.call_name(special.name), "이/가"), GameState.format_won(special_price)]},
	])


## 특별 손님 SD: 시트가 있는 사람만 서고, 그동안은 대화창 얼굴 그림을 띄우지 않는다
func _guest_enters() -> void:
	var id := GuestSD.id_for(special.get("name", ""))
	if not GuestSD.has_sheet(id):
		return
	_guest.guest_id = id
	_guest.set_pose("stand")
	_guest.show()
	UiKit.rise_in(_guest, 0.0, 40.0)
	_dialogue.on_stage = [id]


func _guest_leaves() -> void:
	_dialogue.on_stage = []
	if _guest.visible:
		var tw := _guest.create_tween()
		tw.tween_property(_guest, "modulate:a", 0.0, 0.3)
		tw.tween_callback(_guest.hide)


# ─── 입력 (굽기) ────────────────────────────────────

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


# ─── 장부와 밤 ──────────────────────────────────────

func _show_ledger() -> void:
	step = Step.LEDGER
	_cook_panel.hide()
	GameState.reputation += rep_change
	GameState.time_minutes = DayFlow.SHOP_CLOSE
	_header.refresh()
	Sound.play_sfx("coin")
	for c in _ledger_rows.get_children():
		c.queue_free()
	var served: int = result.get("served", []).size()
	_ledger_rows.add_child(_row("보통 손님", "%d명" % served, "+" + GameState.format_won(int(result.get("sales", 0))), UiKit.SEA))
	if special_price > 0:
		_ledger_rows.add_child(_row(special.name, "직접 구운 한 접시", "+" + GameState.format_won(special_price), UiKit.SEA))
	if int(result.get("missed", 0)) > 0:
		_ledger_rows.add_child(_row("돌아간 손님", "%d명" % result.missed, "", UiKit.INK_MUTED))
	_ledger_rows.add_child(_row("지출", "미끼, 장비", ("-" if GameState.spent_today > 0 else "") + GameState.format_won(GameState.spent_today), UiKit.DANGER))
	_ledger_rows.add_child(UiKit.divider())
	_ledger_rows.add_child(_row("순이익", "", GameState.format_won(GameState.sales_today - GameState.spent_today), UiKit.INK, true))
	_ledger_rows.add_child(_row("평판", "", ("+%d" % rep_change) if rep_change >= 0 else str(rep_change), UiKit.CORAL if rep_change >= 0 else UiKit.DANGER))
	if not GameState.inventory.is_empty():
		var old := GameState.spoiling_tonight().size()
		var note := "남은 생선 %d마리는 내일 팔아요" % GameState.inventory.size()
		if old > 0:
			note = "남은 생선 %d마리 중 %d마리는 오늘 밤 상해요" % [GameState.inventory.size(), old]
		_ledger_rows.add_child(UiKit.text(note, "caption", UiKit.CORAL_DEEP if old > 0 else UiKit.INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER))
	_ledger.show()
	UiKit.fade_in(_ledger, 0.4)
	_night_btn.grab_focus()


func _go_night_fishing() -> void:
	GameState.time_minutes = DayFlow.FISHING_SLOTS[2][2] # 21:00
	GameState.current_location = "breakwater"
	UiKit.go_to(self, FISHING_SCENE, 0.8)


func _go_sleep() -> void:
	GameState.current_location = "home"
	GameState.end_day()
	UiKit.go_to(self, MAP_SCENE, 0.8)


# ─── 화면 구성 ──────────────────────────────────────

func _build_list() -> void:
	var holder := CenterContainer.new()
	holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.offset_top = GameHeader.BOTTOM + 20
	holder.offset_bottom = -300 # 대사창 자리
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(holder)
	_list_panel = UiKit.paper_panel(28)
	_list_panel.custom_minimum_size = Vector2(640, 0)
	_list_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(_list_panel)
	var v := UiKit.vbox(UiKit.SPACE_MD)
	_list_panel.add_child(v)
	v.add_child(UiKit.text("오늘 저녁 손님", "h2", UiKit.INK))
	_list = UiKit.vbox(UiKit.SPACE_SM)
	v.add_child(_list)
	_list_total = UiKit.text("", "title", UiKit.INK_SOFT, HORIZONTAL_ALIGNMENT_RIGHT)
	v.add_child(_list_total)
	_list_panel.hide()


func _build_cook_panel() -> void:
	var holder := CenterContainer.new()
	holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.offset_top = GameHeader.BOTTOM + 10
	holder.offset_bottom = -280
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
	_cook_art = ArtSlot.make("kitchen/grill", "화로", Vector2(540, 300))
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


## 판정 게이지. 간 맞추기는 뿌린 양만(감으로 친다), 굽기는 노릇한 구간을 보여 준다
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
	var panel := UiKit.paper_panel(32)
	UiKit.elevate(panel.get_theme_stylebox("panel"), 3)
	panel.custom_minimum_size = Vector2(640, 0)
	center.add_child(panel)
	var v := UiKit.vbox(UiKit.SPACE_LG)
	panel.add_child(v)
	v.add_child(UiKit.badge(Calendar.text(GameState.day) + " 저녁",UiKit.NAVY_DEEP, UiKit.FOAM))
	v.add_child(UiKit.text("오늘 장부", "h1", UiKit.INK, HORIZONTAL_ALIGNMENT_CENTER))
	_ledger_rows = UiKit.vbox(UiKit.SPACE_SM)
	v.add_child(_ledger_rows)
	v.add_child(UiKit.text("밤 낚시를 가면 내일 새벽엔 늦잠을 자요", "caption", UiKit.INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER))
	var row := UiKit.hbox(UiKit.SPACE_MD)
	var sleep_btn := UiKit.action("집에 가서 자기", "secondary")
	sleep_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sleep_btn.pressed.connect(_go_sleep)
	row.add_child(sleep_btn)
	_night_btn = UiKit.action("밤 낚시 가기")
	_night_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_night_btn.pressed.connect(_go_night_fishing)
	row.add_child(_night_btn)
	v.add_child(row)
	_ledger.hide()


## 한 줄: 이름, 설명, 금액
func _row(key: String, note: String, amount: String, color: Color, strong := false) -> HBoxContainer:
	var h := UiKit.hbox(UiKit.SPACE_MD)
	h.add_child(UiKit.text(key, "title" if strong else "body", UiKit.INK))
	if not note.is_empty():
		h.add_child(UiKit.text(note, "caption", UiKit.INK_MUTED))
	h.add_child(UiKit.spacer())
	if not amount.is_empty():
		h.add_child(UiKit.text(amount, "h2" if strong else "title", color))
	return h
