extends Control
## 메뉴 개발 (세로, 11-19). 낮에 식당에서 배워 온 요리법을 세라에게 전하고, 세라가 시험해 메뉴판에 올린다. 규칙은 Menu.
## 주인공은 요리에 소질이 없어서(사용자 11-19) 재료를 구해 오고 맛만 본다. 생선 한 마리와 재료를 쓰고 한 시간이 걸린다.
## 그림: 식당 낮 배경 bg_shop_inside_day, 요리 dish/<id>
##
## 구성: 맨 위 헤더 / 제목과 나가기 / 종이 시트(배운 요리 목록 → 고르면 시험 조리판)

const MAP_SCENE := "res://scenes/map/map.tscn"
const SPEED := 0.9 # 바늘이 한 번 가로지르는 데 걸리는 초의 역수

var _header: GameHeader
var _list: VBoxContainer
var _lab: VBoxContainer
var _title: Label
var _say: Label
var _bar: Control
var _needle := 0.0
var _dir := 1.0
var _running := false
var _recipe := ""
var _targets: Array = []
var _try := 0
var _hits := 0


func _ready() -> void:
	var base := ColorRect.new()
	base.color = UiKit.WOOD_DARK
	base.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(base)
	var art := UiKit.cover_art("bg_shop_inside_day")
	if art:
		add_child(art)
	add_child(UiKit.shade([[0.0, 0.5], [0.2, 0.15], [1.0, 0.55]]))
	_header = GameHeader.new()
	add_child(_header)
	var row := UiKit.hbox(UiKit.SPACE_MD)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	row.offset_left = 22
	row.offset_right = -20
	row.offset_top = GameHeader.BOTTOM + 12.0
	add_child(row)
	var t := UiKit.text("메뉴 개발", "h2", UiKit.FOAM)
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
	_title = UiKit.text("배운 요리", "h2", UiKit.NOTE_INK)
	v.add_child(_title)
	_say = UiKit.paragraph("", "body", UiKit.NOTE_INK_SOFT)
	_say.add_theme_font_size_override("font_size", 18)
	v.add_child(_say)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	_list = UiKit.vbox(UiKit.SPACE_MD)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list)
	_lab = UiKit.vbox(UiKit.SPACE_LG)
	_lab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lab.hide()
	v.add_child(_lab)
	_show_list()
	Sound.play_bgm("town")
	UiKit.fade_in(self)


func _show_list() -> void:
	_header.refresh()
	_lab.hide()
	_list.get_parent().show()
	_title.text = "배운 요리"
	_say.text = "배워 온 요리법을 세라에게 전해요. 재료를 주면 세라가 한 시간 동안 시험해서 메뉴판에 올려요"
	for c in _list.get_children():
		c.queue_free()
	var ids: Array = Menu.RECIPES.keys().filter(func(id): return Menu.learned(GameState.flags, id))
	if ids.is_empty():
		_list.add_child(UiKit.paragraph("아직 배운 요리가 없어요. 마을 사람과 친해지면 알려 줘요", "body", UiKit.NOTE_INK_SOFT))
	for id in ids:
		_list.add_child(_recipe_card(id))


func _fish_for(id: String) -> Dictionary:
	var best := {}
	for e in GameState.inventory:
		if not Menu.fits_fish(id, e.id):
			continue
		if Menu.recipe(id).get("fresh", false) and int(e.get("day", 0)) != GameState.day:
			continue
		if best.is_empty() or FishDB.value_of(e.id, e.size) < FishDB.value_of(best.id, best.size):
			best = e
	return best


func _recipe_card(id: String) -> PanelContainer:
	var r := Menu.recipe(id)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UiKit.box(Color(UiKit.NOTE_DARK, 0.28), 18, Color(UiKit.NOTE_DARK, 0.6), 1, 14))
	var h := UiKit.hbox(UiKit.SPACE_LG)
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(h)
	var ic := UiKit.icon_rect("dish/" + Menu.art(id, ""), 84)
	if ic:
		h.add_child(ic)
	var info := UiKit.vbox(UiKit.SPACE_XS)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_child(UiKit.text(r.name, "title", UiKit.INK))
	info.add_child(UiKit.paragraph("%s · \"%s\"" % [Friends.person(r.who).get("call", r.who), GameState.line(r.tip)], "caption", UiKit.INK_SOFT))
	var fish_names := "아무 생선" if (r.fish as Array).is_empty() else ", ".join(PackedStringArray((r.fish as Array).map(func(f): return FishDB.get_fish(f).name)))
	info.add_child(UiKit.paragraph("재료: %s + %s · 값 구이의 %d%%" % [fish_names, Menu.needs_text(id), int(float(r.mult) * 100)], "caption", UiKit.NOTE_INK_SOFT))
	h.add_child(info)
	if Menu.on_menu(GameState.flags, id):
		h.add_child(UiKit.status_tag("메뉴판", UiKit.GOLD_SOFT, UiKit.GOLD_DARK, Vector2(124, 52)))
	else:
		var ok := not _fish_for(id).is_empty() and Menu.can_make(id, GameState.produce, GameState.seafood) and GameState.time_minutes + Menu.LAB_MINUTES <= DayFlow.SHOP_OPEN
		var b := UiKit.game_button("세라에게", UiKit.CORAL_DEEP, Vector2(132, 52), 19)
		b.disabled = not ok
		b.pressed.connect(_start.bind(id))
		h.add_child(b)
	return card


func _start(id: String) -> void:
	_recipe = id
	var fish := _fish_for(id)
	GameState.inventory.erase(fish)
	Menu.take(id, GameState.produce, GameState.seafood)
	GameState.time_minutes += Menu.LAB_MINUTES
	# 세라가 시험한다 (간 맞추기 판 없이 바로 메뉴판에)
	var nm: String = Menu.recipe(id).name
	GameState.flags["menu_" + id] = true
	GameState.note("세라가 %s 메뉴판에 올렸다." % Josa.attach(nm, "을/를"), 3)
	Sound.play_sfx("newfish")
	_title.text = "%s 시험 조리" % nm
	_say.text = "세라: \"%s 할 만하네요. 오늘 저녁부터 내 볼게요.\" 메뉴판에 올라갔어요. 영업 전에 메뉴판에서 고를 수 있어요" % nm
	_header.refresh()
	_show_list_keep_say()
	return
	_targets = Menu.targets(GameState.day, id)
	_try = 0
	_hits = 0
	_list.get_parent().hide()
	_title.text = "%s 시험 조리" % Menu.recipe(id).name
	_say.text = "바늘이 초록 칸에 왔을 때 간 보기를 눌러요. 세 번 중 두 번 맞추면 메뉴판에 올라가요"
	for c in _lab.get_children():
		c.queue_free()
	_bar = Control.new()
	_bar.custom_minimum_size = Vector2(0, 90)
	_bar.draw.connect(_draw_bar)
	_lab.add_child(_bar)
	var b := UiKit.game_button("간 보기", UiKit.CORAL_DEEP, Vector2(260, 72), 24)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.pressed.connect(_taste)
	_lab.add_child(b)
	_lab.show()
	_header.refresh()
	_needle = 0.0
	_running = true


func _process(delta: float) -> void:
	if not _running:
		return
	_needle += _dir * delta * SPEED * (1.0 + 0.25 * _try)
	if _needle >= 1.0 or _needle <= 0.0:
		_needle = clampf(_needle, 0.0, 1.0)
		_dir = -_dir
	_bar.queue_redraw()


## 간 막대: 판정 표시라 코드로 그린다 (CLAUDE.md: 게이지는 코드로)
func _draw_bar() -> void:
	var w := _bar.size.x
	var h := 40.0
	var y := 26.0
	_bar.draw_rect(Rect2(0, y, w, h), Color(UiKit.NOTE_DARK, 0.7))
	if _try < _targets.size():
		var tz: float = _targets[_try]
		_bar.draw_rect(Rect2((tz - Menu.ZONE / 2.0) * w, y, Menu.ZONE * w, h), Color(UiKit.LEAF, 0.85))
	_bar.draw_rect(Rect2(_needle * w - 4.0, y - 14.0, 8.0, h + 28.0), UiKit.CORAL_DEEP)
	for i in Menu.TRIES:
		var col := UiKit.NOTE_INK_SOFT
		if i < _try:
			col = UiKit.LEAF if i < _hits_list.size() and _hits_list[i] else UiKit.DANGER
		_bar.draw_circle(Vector2(w / 2.0 + (i - 1) * 30.0, 8.0), 8.0, col)


var _hits_list: Array = []


func _taste() -> void:
	if not _running or _try >= Menu.TRIES:
		return
	var ok := Menu.hit(_needle, _targets[_try])
	_hits_list.append(ok)
	if ok:
		_hits += 1
	Sound.play_sfx("catch" if ok else "bad", 0.0, -4.0)
	_try += 1
	_say.text = ("간이 딱이다." if ok else "음, 좀 아닌데.") + "  (%d/%d)" % [_hits, Menu.TRIES]
	if _try >= Menu.TRIES or _hits >= Menu.PASS or _try - _hits > Menu.TRIES - Menu.PASS:
		_running = false
		_bar.queue_redraw()
		var name: String = Menu.recipe(_recipe).name
		if _hits >= Menu.PASS:
			GameState.flags["menu_" + _recipe] = true
			GameState.note("%s 메뉴판에 올렸다." % Josa.attach(name, "을/를"), 3)
			Sound.play_sfx("newfish")
			_say.text = "성공! %s 오늘 저녁부터 메뉴판에 올라가요." % Josa.attach(name, "이/가")
		else:
			_say.text = "이번엔 실패. 재료를 다시 모아 와요."
		_hits_list.clear()
		var back := UiKit.action("목록으로", "secondary")
		back.pressed.connect(_show_list)
		_lab.add_child(back)


## 목록을 다시 채우되 위 안내 글은 그대로 둔다
func _show_list_keep_say() -> void:
	var keep := _say.text
	_show_list()
	_say.text = keep
