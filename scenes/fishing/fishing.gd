extends Control
## 북쪽 방파제 찌낚시.
## 첫날(튜토리얼): 챕터 2 새벽 05:00~07:00, 첫 물고기는 볼락, 끝나면 〈첫 번째 손님〉 식당 장면으로 간다.
## 그 뒤(자유 낚시): 지도에서 들어온 시각부터 시작해 그만하기를 누르거나 밤 11시가 되면 끝나고 지도로 돌아간다.
## 규칙은 FishingLogic, 이 스크립트는 입력, 시간, 화면 표시만 맡는다.

const TUTORIAL_NEXT := "res://scenes/restaurant/first_guest.tscn"
const FREE_NEXT := "res://scenes/map/map.tscn"

const START_MIN := 5 * 60 # 05:00
const END_MIN := 7 * 60 # 07:00
const LATE_MIN := 23 * 60 # 자유 낚시는 밤 11시까지
const REAL_SEC_PER_GAME_MIN := 1.2

const HINTS := {
	FishingLogic.State.READY: "꾹 누르면 낚싯대를 머리 뒤로 넘기며 힘을 모아요. 손을 떼면 던져요",
	FishingLogic.State.CHARGING: "적당하다 싶을 때 손을 떼서 앞으로 휘둘러요",
	FishingLogic.State.CASTING: "",
	FishingLogic.State.WAITING: "찌를 지켜봐요. 오른쪽 클릭이나 Shift를 누르고 있으면 뒷줄 견제",
	FishingLogic.State.BITE: "찌가 계속 잠겨요. 지금 챔질!",
	FishingLogic.State.REELING: "누르면 낚싯대를 숙이며 감고, 떼면 낚싯대를 세워 버텨요",
}

var logic := FishingLogic.new()
var minutes := float(START_MIN)
## 첫날 새벽 튜토리얼인지. first_fishing_done 표시가 없으면 튜토리얼이다.
var tutorial := true

var _bg: SeaBackdrop
var _layer: Control
var _player: PlayerRig
var _clock: PanelContainer
var _count: PanelContainer
var _hint_pill: PanelContainer
var _hint: Label
var _dialogue: DialogueBox
var _card_root: Control
var _card: PanelContainer
var _card_art: ArtSlot
var _card_title: Label
var _card_size: PanelContainer
var _card_new: Control
var _card_desc: Label
var _summary: Control
var _summary_title: Label
var _summary_list: VBoxContainer
var _summary_btn: Button
var _quit_btn: Button

## 뒤쪽 시점 세로 낚시 화면. 아래 위치는 배경 그림 크기 대비 비율이다.
## 배경 그림이 바뀌면 이 숫자들만 그림에 맞춰 고친다.
## 지금 그림은 바다 한 접시에서 가져온 임시 그림(방파제 밤, 낮). 밝기만큼 낮 그림을 겹친다.
## 오늘의 바다 전용 세로 그림(bg_fishing_dawn_v, bg_fishing_morning_v)이 오면 이름과 비율을 바꾼다.
const BG_ART := "bg_fishing_night"
const BG_ART_BLEND := "bg_fishing_day"
const WATER_NEAR_Y := 0.665 # 방파제 바로 앞 바다
const WATER_FAR_Y := 0.36 # 가장 멀리 던졌을 때 (수평선 0.33 바로 아래)
const FEET := Vector2(0.5, 0.765) # 주인공 발 위치 (방파제 끝, 바다 바로 앞)
## 그림에서 보일 부분. 방파제 아래쪽을 잘라 내고 확대해서 바다를 넓게 보여 준다
const ART_VIEW := Rect2(0.1, 0.0, 0.8, 0.8)
const FLOAT_NEAR_SCALE := 1.0
const FLOAT_FAR_SCALE := 0.4

## SD 주인공 몸 그림 크기 (낚싯대와 릴은 PlayerRig가 따로 붙인다)
const PLAYER_SIZE := Vector2(150.0, 360.0)

var _held := false
var _mend_held := false # 뒷줄 견제 버튼
var _hook_flash := 0.0 # 챔질 순간 낚싯대를 확 세우는 연출 시간
var _slack := 0.0 # 착수 직후 늘어진 줄 (베일을 닫고 여유줄을 감으며 줄어든다)
var _landing := 0.0 # 잡은 물고기를 들어 올리는 연출 남은 시간
const LANDING_TIME := 0.8
var _fish_tex: Texture2D
var _in_story := true
var _ending := false
var _met_mansu := false
var _last_state := -1
var _t := 0.0
var _splashes: Array = []
var _reel_sound := 0.0 # 릴 감는 소리 간격
var _was_nibble := false


func _ready() -> void:
	# 바깥 노드가 클릭을 먹지 않게 해야 _unhandled_input으로 낚시 입력이 들어온다
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	logic.rng.randomize()
	tutorial = not GameState.has_flag("first_fishing_done")
	if not tutorial:
		minutes = float(GameState.time_minutes)
		logic.forgiving = false
		logic.force_first_fish = ""
	logic.brightness = FishingLogic.brightness_at(minutes)

	_bg = SeaBackdrop.new()
	_bg.mode = SeaBackdrop.Mode.DAWN
	_bg.art_base = BG_ART
	_bg.art_blend = BG_ART_BLEND
	_bg.art_view = ART_VIEW
	add_child(_bg)

	_player = PlayerRig.new()
	_player.size = PLAYER_SIZE
	_player.set_gear(GameState.equipped_rod, GameState.equipped_reel)
	add_child(_player)
	GearDB.apply(logic, GameState.equipped_rod, GameState.equipped_reel)

	_layer = Control.new()
	_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer.draw.connect(_draw_layer)
	add_child(_layer)

	_build_hud()
	_build_card()
	_build_summary()

	_dialogue = DialogueBox.new()
	add_child(_dialogue)
	_dialogue.finished.connect(_on_dialogue_finished)

	UiKit.fade_in(self, 1.0)
	Sound.play_bgm("sea")
	if not tutorial:
		_play_story([
			{"speaker": "", "text": "북쪽 방파제. 빨간 등대 아래 늘 앉던 자리."},
			{"speaker": "{player}", "text": "오늘은 뭐가 물려나."},
		])
		return
	_play_story([
		{"speaker": "", "text": "다음 날 새벽 다섯 시. 물빛울포 북쪽 방파제."},
		{"speaker": "{player}", "text": "창고에서 찾은 낚싯대 하나에 크릴 한 봉지. 이게 전부다."},
		{"speaker": "{player}", "text": "영상에서 본 대로라면... 던지고, 찌를 보다가, 찌가 들어가면 챈다."},
		{"speaker": "", "text": "마우스 왼쪽 버튼이나 스페이스바를 꾹 누르면 던질 힘이 모여요. 손을 떼면 던져요."},
	])


# ─── 입력 ───────────────────────────────────────────

func _unhandled_input(event: InputEvent) -> void:
	if _in_story or _summary.visible:
		return
	# 견제: 오른쪽 클릭 또는 Shift
	if (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT) \
			or (event is InputEventKey and event.keycode == KEY_SHIFT and not event.echo):
		get_viewport().set_input_as_handled()
		_mend_held = event.pressed
		return
	var is_action := false
	var pressed := false
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		is_action = true
		pressed = event.pressed
	elif event is InputEventKey and event.keycode == KEY_SPACE and not event.echo:
		is_action = true
		pressed = event.pressed
	if not is_action:
		return
	get_viewport().set_input_as_handled()
	_held = pressed
	if pressed:
		if logic.state == FishingLogic.State.CAUGHT:
			if _landing <= 0.0:
				_close_card()
		else:
			var was_bite := logic.state == FishingLogic.State.BITE
			logic.press()
			if was_bite and logic.state == FishingLogic.State.REELING:
				_hook_flash = 0.22
	else:
		logic.release()


# ─── 진행 ───────────────────────────────────────────

func _process(delta: float) -> void:
	_t += delta
	if not _in_story and not _summary.visible and logic.state != FishingLogic.State.CAUGHT:
		minutes = minf(minutes + delta / REAL_SEC_PER_GAME_MIN, END_MIN if tutorial else LATE_MIN)
		logic.brightness = FishingLogic.brightness_at(minutes)
		logic.update(delta, _held, _mend_held)
		_play_loop_sounds(delta)
	_hook_flash = maxf(0.0, _hook_flash - delta)
	_slack = maxf(0.0, _slack - delta / 0.6)
	if _landing > 0.0:
		_landing -= delta
		if _landing <= 0.0:
			_show_card()
	_bg.brightness = FishingLogic.brightness_at(minutes)

	if logic.state != _last_state:
		_on_state_changed()
		_last_state = logic.state

	UiKit.set_chip(_clock, _clock_text())
	_quit_btn.visible = not tutorial and not _in_story and not _ending \
			and logic.state in [FishingLogic.State.READY, FishingLogic.State.WAITING, FishingLogic.State.FAILED]
	UiKit.set_chip(_count, "%d마리" % GameState.caught_today.size())
	_hint_pill.visible = not _hint.text.is_empty()

	if logic.state == FishingLogic.State.REELING and randf() < delta * 6.0:
		_splashes.append({"t": 0.0, "off": Vector2(randf_range(-18, 18), randf_range(-4, 4))})
	for s in _splashes:
		s.t += delta
	_splashes = _splashes.filter(func(s): return s.t < 0.5)

	_place_player()
	_layer.queue_redraw()
	_expose_state_for_tests()

	if not _in_story and not _ending and logic.state == FishingLogic.State.READY:
		if tutorial and minutes >= END_MIN and not GameState.caught_today.is_empty():
			_start_ending()
		elif not tutorial and minutes >= LATE_MIN:
			_start_ending()


func _clock_text() -> String:
	var h := int(minutes) / 60
	var period := "새벽" if h < 6 else ("오전" if h < 12 else ("오후" if h < 18 else ("저녁" if h < 21 else "밤")))
	return "%s %02d:%02d" % [period, h, int(minutes) % 60]


## 찌 톡톡, 릴 감는 소리처럼 상태 안에서 반복되는 소리
func _play_loop_sounds(delta: float) -> void:
	var nib := logic.state == FishingLogic.State.WAITING and logic.nibble > 0.0
	if nib and not _was_nibble:
		Sound.play_sfx("nibble", 0.1)
	_was_nibble = nib
	if logic.state == FishingLogic.State.REELING and _held:
		_reel_sound -= delta
		if _reel_sound <= 0.0:
			Sound.play_sfx("reel", 0.08, -6.0)
			_reel_sound = 0.32
	else:
		_reel_sound = 0.0


func _on_state_changed() -> void:
	var s := logic.state
	if _in_story:
		_hint.text = ""
		return
	if s == FishingLogic.State.FAILED:
		_hint.text = FishingLogic.fail_message(logic.fail_reason)
		_hint.add_theme_color_override("font_color", Color("ffc2b4"))
	else:
		_hint.text = HINTS.get(s, "")
		_hint.add_theme_color_override("font_color", UiKit.SUN if s == FishingLogic.State.BITE else UiKit.FOAM)
	if not _hint.text.is_empty():
		_hint_pill.modulate.a = 0.0
		_hint_pill.create_tween().tween_property(_hint_pill, "modulate:a", 1.0, UiKit.MOTION_BASE)
	_play_state_sound(s)
	if s == FishingLogic.State.WAITING:
		_slack = 1.0
	if s == FishingLogic.State.CAUGHT:
		_held = false
		_record_catch()
		_landing = LANDING_TIME # 들어 올리는 연출 뒤에 카드를 보여 준다
		var art := "fish_" + logic.fish_id
		_fish_tex = load(ArtSlot.art_path(art)) if ArtSlot.has_art(art) else null


func _play_state_sound(s: int) -> void:
	match s:
		FishingLogic.State.CASTING:
			Sound.play_sfx("whoosh", 0.05)
		FishingLogic.State.WAITING:
			Sound.play_sfx("plop", 0.1)
		FishingLogic.State.BITE:
			Sound.play_sfx("bite")
		FishingLogic.State.REELING:
			Sound.play_sfx("strike")
		FishingLogic.State.CAUGHT:
			Sound.play_sfx("land")
		FishingLogic.State.FAILED:
			match logic.fail_reason:
				"broke":
					Sound.play_sfx("snap")
				"slack":
					Sound.play_sfx("slip")
				_:
					Sound.play_sfx("bad", 0.0, -6.0)


func _record_catch() -> void:
	var entry := {"id": logic.fish_id, "size": logic.fish_size}
	GameState.caught_today.append(entry)
	GameState.inventory.append(entry)
	var best: float = GameState.dex.get(logic.fish_id, 0.0)
	_card_new.visible = best == 0.0
	GameState.dex[logic.fish_id] = maxf(best, logic.fish_size)


# ─── 이야기 ─────────────────────────────────────────

func _play_story(lines: Array) -> void:
	_in_story = true
	_held = false
	_hint.text = ""
	_dialogue.play(lines)


func _on_dialogue_finished() -> void:
	_in_story = false
	_last_state = -1
	if _ending:
		_show_summary()


func _start_ending() -> void:
	_ending = true
	_held = false
	var n := GameState.caught_today.size()
	if not tutorial:
		_play_story([
			{"speaker": "{player}", "text": "늦었다. 오늘은 여기까지." if minutes >= LATE_MIN else "오늘 낚시는 여기까지."},
		])
		return
	_play_story([
		{"speaker": "", "text": "해가 수평선 위로 완전히 올라왔다. 찌 주변이 조용해졌다."},
		{"speaker": "{player}", "text": "볼락은 밝아지면 숨는다고 했지. 오늘은 여기까지." if n > 0 else "오늘은 여기까지."},
		{"speaker": "{player}", "text": "%d마리. 이걸로 {shop} 문을 열어 보자." % n},
	])


# ─── 화면 구성 ──────────────────────────────────────

func _build_hud() -> void:
	# 위: 시계와 잡은 수 (유리 칩)
	var bar := UiKit.hbox(UiKit.SPACE_SM)
	bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	bar.offset_left = 20
	bar.offset_right = -20
	bar.offset_top = 24
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bar)
	_clock = UiKit.chip("", "", "icon_clock")
	bar.add_child(_clock)
	bar.add_child(UiKit.spacer())
	_count = UiKit.chip("잡은 고기", "", "icon_fish")
	bar.add_child(_count)

	_quit_btn = UiKit.action("그만하기", "glass", true)
	_quit_btn.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_quit_btn.offset_left = -140
	_quit_btn.offset_right = -20
	_quit_btn.offset_top = 82
	_quit_btn.offset_bottom = 82 + UiKit.BUTTON_H_SM
	_quit_btn.pressed.connect(_start_ending)
	_quit_btn.hide()
	add_child(_quit_btn)

	# 안내: 장력 막대 아래 유리 알약
	var hint_row := CenterContainer.new()
	hint_row.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	hint_row.offset_top = 216
	hint_row.offset_bottom = 300
	hint_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hint_row)
	_hint_pill = UiKit.glass_panel(0, UiKit.RADIUS_LG)
	var hs: StyleBoxFlat = _hint_pill.get_theme_stylebox("panel")
	hs.content_margin_left = 22
	hs.content_margin_right = 22
	hs.content_margin_top = 12
	hs.content_margin_bottom = 13
	_hint_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint_row.add_child(_hint_pill)
	_hint = UiKit.paragraph("", "body", UiKit.FOAM, 0.0, HORIZONTAL_ALIGNMENT_CENTER)
	_hint.add_theme_font_size_override("font_size", 19)
	_hint.custom_minimum_size.x = 560
	_hint_pill.add_child(_hint)
	_hint_pill.hide()


func _build_card() -> void:
	_card_root = Control.new()
	_card_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_card_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_card_root)
	var dim := UiKit.scrim(0.35)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card_root.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card_root.add_child(center)
	_card = UiKit.paper_panel(32)
	UiKit.elevate(_card.get_theme_stylebox("panel"), 3)
	_card.custom_minimum_size = Vector2(600, 0)
	_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(_card)
	var v := UiKit.vbox(UiKit.SPACE_MD)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.add_child(v)
	_card_new = UiKit.badge("새로운 물고기")
	v.add_child(_card_new)
	var art_box := PanelContainer.new()
	art_box.add_theme_stylebox_override("panel", UiKit.inset_box(UiKit.SPACE_LG, UiKit.RADIUS_LG))
	art_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(art_box)
	_card_art = ArtSlot.make("fish_bolak", "볼락", Vector2(480, 220))
	art_box.add_child(_card_art)
	_card_title = UiKit.text("", "h1", UiKit.INK, HORIZONTAL_ALIGNMENT_CENTER)
	v.add_child(_card_title)
	_card_size = UiKit.chip("크기", "", "", false)
	_card_size.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(_card_size)
	_card_desc = UiKit.paragraph("", "body", UiKit.INK_SOFT, 520, HORIZONTAL_ALIGNMENT_CENTER)
	v.add_child(_card_desc)
	v.add_child(UiKit.gap(4))
	v.add_child(UiKit.text("눌러서 계속", "caption", UiKit.INK_MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	_card_root.hide()


func _show_card() -> void:
	var f := FishDB.get_fish(logic.fish_id)
	_card_art.set_art("fish_" + logic.fish_id, f.name)
	_card_title.text = f.name
	UiKit.set_chip(_card_size, "%.1fcm" % logic.fish_size)
	_card_desc.text = f.desc
	Sound.play_sfx("newfish" if _card_new.visible else "catch")
	_card_root.show()
	UiKit.pop_in(_card)


func _close_card() -> void:
	_card_root.hide()
	logic.acknowledge()
	if tutorial and not _met_mansu and GameState.caught_today.size() == 1:
		_met_mansu = true
		_play_story([
			{"speaker": "{player}", "text": "잡았다...! 진짜 잡았어!"},
			{"speaker": "???", "text": "어이 서울 양반. 그 낚싯대로 고기 잡으려면 해 지겠다 싶었는데."},
			{"speaker": "박만수", "text": "볼락이네. 새벽 볼락은 눈이 커서 날 밝으면 귀신같이 숨어."},
			{"speaker": "박만수", "text": "해 뜨기 전에 몇 마리 더 해 봐라. ...그래도 한 마리는 잡았네."},
		])


func _build_summary() -> void:
	_summary = Control.new()
	_summary.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_summary)
	_summary.add_child(UiKit.scrim())
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_summary.add_child(center)
	var panel := UiKit.paper_panel(36)
	UiKit.elevate(panel.get_theme_stylebox("panel"), 3)
	panel.custom_minimum_size = Vector2(600, 0)
	center.add_child(panel)
	var v := UiKit.vbox(UiKit.SPACE_LG)
	panel.add_child(v)
	_summary_title = UiKit.text("", "h1", UiKit.INK, HORIZONTAL_ALIGNMENT_CENTER)
	v.add_child(_summary_title)
	_summary_list = UiKit.vbox(UiKit.SPACE_SM)
	v.add_child(_summary_list)
	_summary_btn = UiKit.action("")
	_summary_btn.custom_minimum_size.y = 60
	_summary_btn.pressed.connect(_leave)
	v.add_child(_summary_btn)
	_summary.hide()


func _leave() -> void:
	GameState.time_minutes = int(minutes)
	if tutorial:
		GameState.flags["first_fishing_done"] = true
		GameState.current_location = "shop" # 잡은 볼락을 들고 식당으로 돌아간다
		UiKit.go_to(self, TUTORIAL_NEXT)
	else:
		GameState.current_location = "breakwater"
		UiKit.go_to(self, FREE_NEXT)


func _show_summary() -> void:
	for c in _summary_list.get_children():
		c.queue_free()
	for e in GameState.caught_today:
		_summary_list.add_child(_catch_row(FishDB.get_fish(e.id).name, "%.1fcm" % e.size, "fish_" + e.id))
	if GameState.caught_today.is_empty():
		_summary_list.add_child(UiKit.text("오늘은 한 마리도 못 잡았다.", "body", UiKit.INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER))
	_summary_title.text = "오늘 새벽의 기록" if tutorial else "오늘의 조과"
	_summary_btn.text = "식당으로" if tutorial else "마을 지도로"
	_summary.show()
	UiKit.fade_in(_summary, UiKit.MOTION_BASE)
	_summary_btn.grab_focus()


## 조과 한 줄: 물고기 그림, 이름, 크기
func _catch_row(fish_name: String, size_text: String, art: String) -> PanelContainer:
	var row := PanelContainer.new()
	row.add_theme_stylebox_override("panel", UiKit.inset_box(UiKit.SPACE_MD, UiKit.RADIUS_MD))
	var h := UiKit.hbox(UiKit.SPACE_MD)
	row.add_child(h)
	var thumb := UiKit.icon_rect(art, 44)
	if thumb:
		thumb.custom_minimum_size = Vector2(88, 44)
		h.add_child(thumb)
	h.add_child(UiKit.text(fish_name, "title", UiKit.INK))
	h.add_child(UiKit.spacer())
	h.add_child(UiKit.text(size_text, "title", UiKit.SEA))
	return row


func _place_player() -> void:
	_player.size = PLAYER_SIZE
	var feet := _bg.art_point(FEET)
	_player.position = feet - Vector2(_player.size.x / 2.0, _player.size.y)
	# 실제 찌낚시 자세 (docs/찌낚시_동작_조사.md)
	# pitch: 낚싯대 높이 (0 바다 쪽 수평, 90 수직, 120 머리 뒤 1시 방향)
	var pitch := 55.0
	var lean := 0.0
	match logic.state:
		FishingLogic.State.READY:
			pitch = 60.0 # 베일을 열고 검지에 줄을 건 준비 자세
		FishingLogic.State.CHARGING:
			pitch = lerpf(75.0, 125.0, logic.power) # 머리 뒤 1시 방향으로 넘긴다
			lean = -4.0 * logic.power
		FishingLogic.State.CASTING:
			# 앞으로 휘둘러 10~11시 방향에서 줄을 놓고, 앞쪽 30도 정도에서 멈춘다
			var k := minf(logic.progress * 3.0, 1.0)
			pitch = lerpf(125.0, 30.0, k)
			lean = lerpf(-4.0, 3.0, k)
		FishingLogic.State.WAITING:
			# 찌를 볼 때는 45도. 견제할 때는 뒷줄을 잡고 70도까지 천천히 세운다
			pitch = 70.0 if logic.mending else 45.0
		FishingLogic.State.BITE:
			pitch = 45.0
		FishingLogic.State.REELING:
			# 펌핑: 떼면 낚싯대를 세워 버티고, 누르면 숙이며 감는다. 물고기가 당기면 끌려 숙여진다
			pitch = (42.0 if _held else 68.0) - logic.fish_pull() * 8.0
			lean = -2.0
		FishingLogic.State.CAUGHT:
			pitch = 82.0 # 들어 올리기
		FishingLogic.State.FAILED:
			pitch = 55.0
	if _hook_flash > 0.0:
		pitch = 85.0 # 챔질: 팔 전체로 낚싯대를 45도 이상 확 세운다 (귀 뒤로 넘기지 않는다)
	var follow := 0.45 if _hook_flash > 0.0 or logic.state == FishingLogic.State.CASTING else 0.2
	_player.pitch = lerpf(_player.pitch, pitch, follow)
	_player.lean = lerpf(_player.lean, lean, 0.25)


# ─── 낚싯대, 줄, 찌 ─────────────────────────────────
# 낚싯줄과 찌는 게임 판정을 보여 주는 요소라 선과 점으로만 그린다.

func _rod_tip() -> Vector2:
	return _player.tip_global()


## 바다 위 깊이(0 = 방파제 앞, 1 = 가장 멀리)를 화면 좌표로 바꾼다.
func _water_point(depth: float) -> Vector2:
	var near := _bg.art_point(Vector2(0.48, WATER_NEAR_Y))
	var far := _bg.art_point(Vector2(0.52, WATER_FAR_Y))
	# 멀수록 화면에서 덜 움직이도록 (원근감)
	var k := 1.0 - pow(1.0 - clampf(depth, 0.0, 1.0), 1.6)
	return near.lerp(far, k)


## 찌가 조류에 흘러간 거리 (화면 px)
func _drift_px() -> float:
	return logic.drift * size.x * _depth_scale(logic.cast_power)


func _depth_scale(depth: float) -> float:
	return lerpf(FLOAT_NEAR_SCALE, FLOAT_FAR_SCALE, clampf(depth, 0.0, 1.0))


## 지금 찌(또는 물고기)가 있는 깊이
func _float_depth() -> float:
	if logic.state == FishingLogic.State.REELING:
		return logic.cast_power * logic.distance
	return logic.cast_power


func _float_pos() -> Vector2:
	var target := _water_point(logic.cast_power)
	var sc := _depth_scale(logic.cast_power)
	match logic.state:
		FishingLogic.State.CASTING:
			var tip := _rod_tip()
			var k := logic.progress
			var p := tip.lerp(target, k)
			p.y -= sin(k * PI) * 220.0 * (0.4 + logic.cast_power)
			return p
		FishingLogic.State.WAITING:
			return target + Vector2(_drift_px(), (sin(_t * 2.2) * 2.0 + logic.nibble * 7.0) * sc)
		FishingLogic.State.BITE:
			return target + Vector2(_drift_px(), 18.0 * logic.bite_depth * sc)
		FishingLogic.State.REELING:
			return _water_point(_float_depth())
	return target


func _draw_layer() -> void:
	var s := logic.state
	var tip := _rod_tip()

	if s in [FishingLogic.State.CASTING, FishingLogic.State.WAITING, FishingLogic.State.BITE, FishingLogic.State.REELING]:
		var fp := _float_pos()
		var sag := 0.0 if s == FishingLogic.State.REELING else 10.0 + 50.0 * _slack
		if logic.mending:
			sag = 2.0 # 견제: 뒷줄을 잡아 팽팽하게
		var tension_col := Color(1, 1, 1, 0.7)
		if s == FishingLogic.State.REELING:
			tension_col = Color(1, 1, 1, 0.8).lerp(Color("ff5a4a"), clampf((logic.tension - 0.7) / 0.3, 0.0, 1.0))
		var pts := PackedVector2Array()
		for i in 21:
			var k := i / 20.0
			var p := tip.lerp(fp, k)
			p.y += sin(k * PI) * sag
			pts.append(p)
		_layer.draw_polyline(pts, tension_col, 1.5, true)

		if s == FishingLogic.State.REELING:
			var ssc := _depth_scale(_float_depth())
			for sp in _splashes:
				var a: float = 1.0 - sp.t / 0.5
				_layer.draw_arc(fp + sp.off * ssc, (6.0 + sp.t * 30.0) * ssc, PI, TAU, 12, Color(1, 1, 1, a * 0.8), 2.0)
		else:
			var fsc := 1.0 if s == FishingLogic.State.CASTING else _depth_scale(logic.cast_power)
			_draw_float(fp, s == FishingLogic.State.BITE, fsc)

	if s == FishingLogic.State.CAUGHT and _landing > 0.0:
		_draw_landing(tip)

	if s == FishingLogic.State.CHARGING:
		_draw_power_gauge()
	if s == FishingLogic.State.REELING:
		_draw_tension_bar()


## 들어 올리기: 발 앞까지 끌려온 물고기를 낚싯대 탄력으로 방파제 위로 올린다
func _draw_landing(tip: Vector2) -> void:
	var k := 1.0 - _landing / LANDING_TIME
	k = 1.0 - pow(1.0 - k, 2.0)
	var start := _water_point(0.0)
	var end := tip + Vector2(0, 70)
	var pos := start.lerp(end, k) + Vector2(0, -sin(k * PI) * 40.0)
	_layer.draw_line(tip, pos, Color(1, 1, 1, 0.8), 1.5, true)
	var w := 72.0
	var h := 36.0
	if _fish_tex:
		var ts := _fish_tex.get_size()
		h = w * ts.y / ts.x
		# 바늘에 걸려 머리가 위로 가게 매달린 모습 (그림은 머리가 왼쪽)
		_layer.draw_set_transform(pos, PI / 2.0 + sin(_t * 18.0) * 0.25)
		_layer.draw_texture_rect(_fish_tex, Rect2(0, -h / 2.0, w, h), false)
		_layer.draw_set_transform_matrix(Transform2D.IDENTITY)
	else:
		_layer.draw_circle(pos + Vector2(0, 20), 10.0, Color("6b5a4a"))
	# 물보라
	if k < 0.3:
		_layer.draw_arc(start, 10.0 + k * 60.0, PI, TAU, 12, Color(1, 1, 1, 1.0 - k * 3.0), 2.0)


func _draw_float(p: Vector2, sunk: bool, k := 1.0) -> void:
	if sunk:
		var r := (8.0 + fmod(_t * 40.0, 24.0)) * k
		_layer.draw_arc(p + Vector2(0, -6) * k, r, 0, TAU, 24, Color(1, 1, 1, 0.6), 2.0)
		_layer.draw_circle(p + Vector2(0, -12) * k, 4.0 * k, Color("ff6a3d"))
		return
	_layer.draw_line(p + Vector2(0, -22) * k, p + Vector2(0, -8) * k, Color("ff6a3d"), maxf(1.5, 4.0 * k))
	_layer.draw_circle(p + Vector2(0, -6) * k, 6.0 * k, Color("ff6a3d"))
	_layer.draw_circle(p + Vector2(0, 2) * k, 6.0 * k, Color("f6efe0"))
	_layer.draw_line(p + Vector2(-14, 6) * k, p + Vector2(14, 6) * k, Color(1, 1, 1, 0.5), 1.5)


func _draw_power_gauge() -> void:
	# 머리 위 둥근 게이지
	var w := _player.size.x * 1.1
	var r := Rect2(_player.position + Vector2((_player.size.x - w) / 2.0, -26), Vector2(w, 16))
	UiKit.draw_bar(_layer, r, logic.power, UiKit.SEA.lerp(UiKit.SUN, logic.power))


func _draw_tension_bar() -> void:
	# 위쪽 유리 패널 안에 장력 막대와 거리
	var w := size.x - 40.0
	var panel := Rect2(20, 136, w, 70)
	_layer.draw_style_box(UiKit.glass_box(0, UiKit.RADIUS_MD), panel)
	var font := UiKit.font("semibold")
	_layer.draw_string(font, panel.position + Vector2(18, 26), "줄 장력", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, UiKit.FOAM_SOFT)
	_layer.draw_string(font, panel.position + Vector2(w - 18 - 160, 26), "거리 %dm" % int(logic.distance * 25.0), HORIZONTAL_ALIGNMENT_RIGHT, 160, 16, UiKit.FOAM)
	var col := UiKit.SEA
	if logic.tension > 0.85:
		col = UiKit.DANGER
	elif logic.tension > 0.65:
		col = UiKit.SUN
	UiKit.draw_bar(_layer, Rect2(panel.position + Vector2(18, 38), Vector2(w - 36, 18)), logic.tension, col)


## 웹 빌드 자동 테스트용으로 현재 상태를 페이지에 알려 준다.
func _expose_state_for_tests() -> void:
	if not OS.has_feature("web"):
		return
	var key := "%s|%d|%s|%d|%d" % [FishingLogic.State.keys()[logic.state], int(logic.tension * 100), str(_in_story), GameState.caught_today.size(), int(logic.cast_power * 100)]
	if key != get_meta("_last_key", ""):
		set_meta("_last_key", key)
		JavaScriptBridge.eval("window.__fish = '%s';" % key)
