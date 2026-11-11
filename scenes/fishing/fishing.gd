extends Control
## 북쪽 방파제 찌낚시.
## 첫날(튜토리얼): 챕터 2 새벽 05:00~07:00, 첫 물고기는 볼락, 끝나면 〈첫 번째 손님〉 식당 장면으로 간다.
## 그 뒤(자유 낚시): 지도에서 들어온 시각의 낚시 시간대(DayFlow: 새벽, 아침, 밤)가 끝나거나 그만하기를 누르면 끝나고 지도로 돌아간다.
## 밤 낚시를 마치면 잠자리에 들고 다음 날은 늦잠(새벽 낚시 건너뜀)
## 규칙은 FishingLogic, 이 스크립트는 입력, 시간, 화면 표시만 맡는다.
##
## 조작 (휴대폰 기준, PC는 괄호)
##   던지기: 꾹 눌러 힘 모으기 → 오른쪽 거리 게이지의 포인트에 맞춰 떼기 (왼쪽 클릭, 스페이스)
##   견제: 기다리는 동안 견제 버튼을 누르고 있기 (오른쪽 클릭, Shift)
##   챔질: 찌가 잠기며 줄어드는 고리가 찌에 딱 맞을 때 누르기
##   줄다리기: 누르고 있으면 감기. 물고기가 옆으로 차고 나가면 누른 채 반대쪽으로 끌기 (A/D, 방향키)
##   실패 뒤: 안내가 잠깐 뜬 다음 다시 누르면 바로 힘 모으기
##
## 손맛 (2026-11-10)
##   게이지: 아래 엄지 자리 남색 판에 남은 거리 길(물고기 그림이 발밑으로 다가옴)과 큰 장력 막대. 물고기 둘레 장력 고리, 그 위에 물고기 힘 막대
##     줄 끊김 직전(장력 위험)에는 빨강 깜빡임, 판 떨림, 화면 가장자리 빨간 테, 반복 진동
##   진동: Haptics 한 곳에서 (입질, 챔질, PERFECT, 당김, 끊김, 낚아 올림). 설정에서 끌 수 있다
##   반응: 누른 자리 고리, 입질 때 찌가 쏙 들어가며 물결, 챔질 순간 멈춤(hit stop)과 확대, 판정 글자 튀어 오름
##   화면 흔들림과 확대는 설정의 화면 흔들림을 따른다 (GameState.screen_shake_on)

const TUTORIAL_NEXT := "res://scenes/restaurant/first_guest.tscn"
const FREE_NEXT := "res://scenes/map/map.tscn"

const START_MIN := 5 * 60 # 05:00
const END_MIN := 7 * 60 # 07:00
const LATE_MIN := 23 * 60 + 30 # 시간대를 모를 때 끝나는 시각
const REAL_SEC_PER_GAME_MIN := 1.2

const HINTS := {
	FishingLogic.State.READY: "꾹 눌러 힘을 모으고, 오른쪽 게이지가 포인트에 오면 손을 떼요",
	FishingLogic.State.CHARGING: "반짝이는 포인트에 맞춰 손을 떼요",
	FishingLogic.State.CASTING: "",
	FishingLogic.State.WAITING: "찌를 지켜봐요. 톡톡 떨릴 땐 참고, 쭉 잠길 때 채요. 조용할 때 누르면 줄을 거둬요",
	FishingLogic.State.BITE: "지금! 고리가 찌에 딱 맞을 때 눌러요",
	FishingLogic.State.REELING: "", # 첫 줄다리기 안내는 화면 가운데에 그린다 (_draw_fight_guide)
}

## 뒤쪽 시점 세로 낚시 화면. 북쪽 방파제 끝에서 동쪽 바다를 본다 (왼쪽 북, 오른쪽 남, 등 뒤 서).
## 아래 위치는 배경 그림 크기 대비 비율이다.
## 배경 그림이 바뀌면 이 숫자들만 그림에 맞춰 고친다.
## 그림: 오늘의 바다 전용 세로 새벽, 아침 그림 (2026-11-09 받음, 같은 구도, 해 없음). 밝기만큼 아침 그림을 겹친다.
## 해는 따로 받은 sun.png를 SeaBackdrop이 시각에 따라 움직인다 (sun_path).
## 밤 그림이 오면 어두운 시간(저녁 이후)에 쓸 수 있게 SeaBackdrop에 한 장 더 붙인다.
const BG_ART := "bg_fishing_dawn_v"
const BG_ART_BLEND := "bg_fishing_morning_v"
const WATER_NEAR_Y := 0.665 # 방파제 끝 바로 앞 바다 (테트라포드 사이)
const WATER_FAR_Y := 0.37 # 가장 멀리 던졌을 때 (수평선 0.338 바로 아래)
## 물결이 일렁이는 바다 범위 (그림 세로 비율). 수평선 바로 아래부터 방파제 끝까지
const WATER_TOP_Y := 0.345
const WATER_BOTTOM_Y := 0.70
const FEET := Vector2(0.5, 0.875) # 주인공 발 위치 (방파제 끝 콘크리트 바닥 가운데)
## 그림에서 보일 부분 (세로 9:16 그림이라 전부)
const ART_VIEW := Rect2(0.0, 0.0, 1.0, 1.0)
const FLOAT_NEAR_SCALE := 1.0
const FLOAT_FAR_SCALE := 0.55 # 멀리 던져도 찌가 잘 보이게 (0.42에서 키움)
const FLOAT_H := 70.0 # 가까이 있을 때 찌 그림 높이 (물 위로 보이는 부분 기준 아님, 그림 전체)
const FLOAT_WATERLINE := 0.6 # 찌 그림에서 물 높이 (위에서부터 비율)

## SD 주인공 높이 (폭은 그림 비율대로)
const PLAYER_H := 330.0
## 줄다리기: 누른 자리에서 이만큼 끌면 끝까지 끈 것
const STEER_RANGE := 110.0
## 물고기가 옆으로 끌고 가는 화면 거리 (가까이 있을 때)
const FISH_SWAY_PX := 190.0

var logic := FishingLogic.new()
var minutes := float(START_MIN)
## 첫날 새벽 튜토리얼인지. first_fishing_done 표시가 없으면 튜토리얼이다.
var tutorial := true
## 자유 낚시가 끝나는 시각 (DayFlow 시간대 끝)
var session_end := float(LATE_MIN)
var night := false
var sea := {}
var order := {}

var _world: Control # 배경, 주인공, 줄 (흔들림은 여기만)
var _bg: SeaBackdrop
var _player: PlayerRig
var _layer: Control
var _fx: Control # 판정 글자 (PERFECT 등)
var _hud_draw: Control # 게이지 그리기

var _header: GameHeader # 맨 위 공통 헤더 (날짜, 시각, 날씨, 돈, 메뉴)
var _quit_btn: Button
var _order_card: PanelContainer
var _order_text: Label
var _order_prog: Label
var _calm_row: HBoxContainer
var _hint_pill: PanelContainer
var _hint: Label
var _bait_btn: Button
var _bait_icon: TextureRect
var _bait_label: Label
var _mend_btn: Button
var _prompt_row: CenterContainer # 아래 가운데 지금 할 일 (짧게)
var _prompt_pill: PanelContainer
var _prompt: Label
var _prompt_style: StyleBoxFlat
var _prompt_style_hot: StyleBoxFlat
var _flash: ColorRect # 챔질 순간 번쩍
var _hint_row: CenterContainer
var _bait_sheet: Control
var _bait_list: VBoxContainer
var _dialogue: DialogueBox

var _card_root: Control
var _card: PanelContainer
var _card_art: ArtSlot
var _card_title: Label
var _card_rarity: PanelContainer
var _card_size: Label
var _card_badges: HBoxContainer
var _card_value: Label
var _card_star_row: HBoxContainer
var _card_continue: Label
var _card_lock := 0.0 # 카드가 튀어나오는 동안은 눌러도 닫히지 않게
var _card_order: PanelContainer
var _card_new := false
var _card_record := false
var _card_released := {} # 아이스박스가 꽉 차서 놓아준 고기
var _card_box: Label
var _summary: Control
var _summary_title: Label
var _summary_list: VBoxContainer
var _summary_total: Label
var _summary_btn: Button

var _held := false
var _mend_held := false
var _press_x := 0.0
var _drag_steer := 0.0
var _key_steer := 0.0
var _hook_flash := 0.0 # 챔질 순간 낚싯대를 확 세우는 연출 시간
var _slack := 0.0 # 착수 직후 늘어진 줄
var _landing := 0.0 # 잡은 물고기를 들어 올리는 연출 남은 시간
const LANDING_TIME := 0.8
var _fish_tex: Texture2D
var _float_tex: Texture2D
var _in_story := true
var _ending := false
var _met_mansu := false
var _last_state := -1
var _t := 0.0
var _splashes: Array = []
var _reel_sound := 0.0
var _was_nibble := false
var _shake := 0.0
var _hitstop := 0.0
var _was_exhausted := false
var _last_run := 0
var _last_jumps := 0
var _hint_sticky := false # 실패 안내를 READY에서도 남겨 두는지
var _was_countering := false
var _tutor_fight_shown := false
var _bite_dip := 0.0 # 입질 순간 찌가 쏙 들어갔다 올라오는 연출 (1에서 0으로)
var _ripples: Array = [] # 찌 둘레 물결 {t, p(바다 좌표), r}
var _touches: Array = [] # 누른 자리 고리 {t, p(화면 좌표)}
var _trail: Array = [] # 줄다리기 중 손가락이 지나간 자취 {t, p(화면 좌표)}
var _guide_on := false # 첫 줄다리기 조작 안내를 보여 주는 중인지
var _in_nice_zone := false
var _haptic_pull := 0.0 # 줄다리기 반복 진동 간격
var _haptic_danger := 0.0
var _last_tension_level := 0
var _bend_base := 0.0 # 떨림을 빼고 따라가는 낚싯대 휨
const RIPPLE_TIME := 0.7
const TOUCH_TIME := 0.32
const TRAIL_TIME := 0.45
const ROLL_BASE := 22.0 # 낚싯대가 평소 오른쪽으로 벌어진 정도 (도)
const ROLL_STEER := 26.0 # 좌우로 버틸 때 낚싯대가 그쪽으로 눕는 정도 (도)
## 줄다리기 판 기본 여백 (위험할 때 이 자리에서 떨린다)


func _ready() -> void:
	# 바깥 노드가 클릭을 먹지 않게 해야 _unhandled_input으로 낚시 입력이 들어온다
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	logic.rng.randomize()
	tutorial = not GameState.has_flag("first_fishing_done")
	if not tutorial:
		minutes = float(GameState.time_minutes)
		var slot := DayFlow.fishing_slot(GameState.time_minutes)
		session_end = float(slot.end) if not slot.is_empty() else minf(minutes + 120.0, float(LATE_MIN))
		night = not slot.is_empty() and slot.id == "night"
		logic.forgiving = false
		logic.force_first_fish = ""
	else:
		GameState.equipped_bait = BaitDB.DEFAULT
	logic.brightness = FishingLogic.brightness_at(minutes)
	sea = SeaDay.of(GameState.day)
	order = {} if tutorial else GameState.today_order()
	logic.weather = sea.weather
	logic.bite_mult = sea.bite
	logic.bait = GameState.equipped_bait

	_world = Control.new()
	_world.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_world.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_world)

	_bg = SeaBackdrop.new()
	_bg.mode = SeaBackdrop.Mode.DAWN
	_bg.art_base = BG_ART
	_bg.art_blend = BG_ART_BLEND
	_bg.art_view = ART_VIEW
	_bg.sun_art = "sun"
	_bg.art_schedule = SeaBackdrop.FISHING_SCHEDULE # 밤, 새벽, 아침, 저녁 그림을 시각에 따라 이어 붙인다
	_bg.water_band = Vector2(WATER_TOP_Y, WATER_BOTTOM_Y)
	_bg.minutes = minutes
	_world.add_child(_bg)

	_layer = Control.new()
	_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer.draw.connect(_draw_layer)

	_player = PlayerRig.new()
	_player.set_gear(GameState.equipped_rod, GameState.equipped_reel)
	_world.add_child(_layer) # 찌, 포인트는 주인공 뒤 (바다 위)
	_world.add_child(_player)
	GearDB.apply(logic, GameState.equipped_rod, GameState.equipped_reel)
	logic.new_point()
	var fa := GearDB.float_art(GameState.equipped_rod)
	_float_tex = load(ArtSlot.art_path(fa)) if ArtSlot.has_art(fa) else null

	# 줄은 주인공 앞에 그려야 낚싯대 끝에서 이어진다
	var line_layer := Control.new()
	line_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	line_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line_layer.draw.connect(_draw_line_layer.bind(line_layer))
	line_layer.name = "LineLayer"
	_world.add_child(line_layer)

	_build_hud()
	_hud_draw = Control.new()
	_hud_draw.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_hud_draw.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud_draw.draw.connect(_draw_hud)
	add_child(_hud_draw)
	_flash = ColorRect.new()
	_flash.color = Color(UiKit.FOAM, 0.0)
	_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_flash)
	_fx = Control.new()
	_fx.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fx)
	_build_bait_sheet()
	_build_card()
	_build_summary()

	_dialogue = DialogueBox.new()
	add_child(_dialogue)
	_dialogue.finished.connect(_on_dialogue_finished)

	UiKit.fade_in(self, 1.0)
	Sound.play_bgm("sea")
	if not tutorial:
		var best: Array = SeaDay.best_fish(sea, logic.brightness, 2)
		var names := ", ".join(PackedStringArray(best.map(func(id): return FishDB.get_fish(id).name)))
		_play_story([
			{"speaker": "", "text": "북쪽 방파제. 빨간 등대 아래 늘 앉던 자리."},
			{"speaker": "", "text": "오늘의 바다는 %s. 이런 날엔 %s 입질이 좋다." % [SeaDay.summary(sea), names]},
			{"speaker": "{player}", "text": "오늘은 뭐가 물려나."},
		])
		return
	_play_story([
		{"speaker": "", "text": "다음 날 새벽 다섯 시. 물빛울포 북쪽 방파제."},
		{"speaker": "{player}", "text": "창고에서 찾은 낚싯대 하나에 크릴 한 봉지. 이게 전부다."},
		{"speaker": "{player}", "text": "영상에서 본 대로라면... 물고기 모인 데 던지고, 찌가 쭉 들어가면 챈다."},
		{"speaker": "", "text": "화면을 꾹 누르면 힘이 모여요. 오른쪽 게이지가 반짝이는 포인트에 닿을 때 손을 떼요."},
	])


# ─── 입력 ───────────────────────────────────────────

func _unhandled_input(event: InputEvent) -> void:
	if _in_story or _summary.visible or _bait_sheet.visible or _header.is_menu_open():
		return
	# 견제: 오른쪽 클릭 또는 Shift
	if (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT) \
			or (event is InputEventKey and event.keycode == KEY_SHIFT and not event.echo):
		get_viewport().set_input_as_handled()
		_mend_held = event.pressed
		return
	# 줄다리기 방향키
	if event is InputEventKey and event.keycode in [KEY_A, KEY_D, KEY_LEFT, KEY_RIGHT]:
		get_viewport().set_input_as_handled()
		var left := Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT)
		var right := Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT)
		_key_steer = (1.0 if right else 0.0) - (1.0 if left else 0.0)
		return
	if event is InputEventMouseMotion and _held:
		# 처음 누른 곳보다 왼쪽(오른쪽)에 있는 동안 낚싯대를 그쪽으로 눕혀 버틴다
		_drag_steer = FightView.steer_from_drag(event.position.x - _press_x, STEER_RANGE)
		if logic.state == FishingLogic.State.REELING:
			if _trail.is_empty() or _trail[-1].p.distance_to(event.position) > 14.0:
				_trail.append({"t": 0.0, "p": event.position})
		return
	var is_action := false
	var pressed := false
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		is_action = true
		pressed = event.pressed
		if pressed:
			_press_x = event.position.x
			_drag_steer = 0.0
	elif event is InputEventKey and event.keycode == KEY_SPACE and not event.echo:
		is_action = true
		pressed = event.pressed
	if not is_action:
		return
	get_viewport().set_input_as_handled()
	_held = pressed
	if pressed:
		# 누르는 순간 바로 반응: 누른 자리에 고리가 퍼진다
		var at: Vector2 = event.position if event is InputEventMouseButton else Vector2(size.x / 2.0, size.y - 160.0)
		_touches.append({"t": 0.0, "p": at})
		if logic.state == FishingLogic.State.CAUGHT:
			if _landing <= 0.0 and _card_lock <= 0.0:
				Sound.play_sfx("tap", 0.05, -6.0)
				_close_card()
		else:
			var before := logic.state
			logic.press()
			if before == FishingLogic.State.BITE and logic.state == FishingLogic.State.REELING:
				_on_hooked()
			elif logic.state == FishingLogic.State.CHARGING and before != FishingLogic.State.CHARGING:
				# 힘 모으기 시작 (실패 안내를 건너뛴 경우도)
				Haptics.play("tap")
				Sound.play_sfx("tap", 0.08, -8.0)
				_in_nice_zone = false
	else:
		_drag_steer = 0.0
		var was_charging := logic.state == FishingLogic.State.CHARGING
		logic.release()
		if was_charging and logic.state == FishingLogic.State.CASTING:
			Haptics.play("cast")
			if not tutorial:
				GameState.use_bait()
				_refresh_bait()


func _steer() -> float:
	return clampf(_drag_steer + _key_steer, -1.0, 1.0) if _held else 0.0


# ─── 진행 ───────────────────────────────────────────

func _process(delta: float) -> void:
	_t += delta
	var playing := not _in_story and not _summary.visible and logic.state != FishingLogic.State.CAUGHT and not _header.is_menu_open()
	if _hitstop > 0.0:
		_hitstop -= delta
		playing = false
	if playing:
		minutes = minf(minutes + delta / REAL_SEC_PER_GAME_MIN, END_MIN if tutorial else session_end)
		logic.brightness = FishingLogic.brightness_at(minutes)
		logic.steer = _steer()
		logic.update(delta, _held, _mend_held)
		_play_loop_sounds(delta)
		_watch_fight_events(delta)
		_watch_charge()
	_hook_flash = maxf(0.0, _hook_flash - delta)
	_slack = maxf(0.0, _slack - delta / 0.6)
	_bite_dip = maxf(0.0, _bite_dip - delta / 0.35)
	_card_lock = maxf(0.0, _card_lock - delta)
	for r in _ripples:
		r.t += delta
	_ripples = _ripples.filter(func(r): return r.t < RIPPLE_TIME)
	for tc in _touches:
		tc.t += delta
	_touches = _touches.filter(func(tc): return tc.t < TOUCH_TIME)
	for tr in _trail:
		tr.t += delta
	_trail = _trail.filter(func(tr): return tr.t < TRAIL_TIME)
	if logic.state != FishingLogic.State.REELING:
		_guide_on = false
	if _landing > 0.0:
		_landing -= delta
		if _landing <= 0.0:
			_show_card()
	_bg.brightness = FishingLogic.brightness_at(minutes)
	_bg.minutes = minutes

	if logic.state != _last_state:
		_on_state_changed()
		_last_state = logic.state

	_header.set_minutes(minutes)
	var n := GameState.caught_today.size()
	_header.set_badge("%d마리" % n if n > 0 else "")
	# 화면은 지금 할 일만 보여 준다: 조용할 때는 주문과 오늘의 바다, 싸울 때는 판도 글자도 없이 낚싯대와 줄만
	var calm := logic.state in [FishingLogic.State.READY, FishingLogic.State.FAILED] and not _in_story and not _ending
	var fighting := logic.state == FishingLogic.State.REELING
	_header.show_bar(not fighting)
	_calm_row.visible = calm
	_quit_btn.visible = not tutorial
	_order_card.visible = calm and not order.is_empty()
	_bait_btn.visible = calm
	_mend_btn.visible = not _in_story and logic.state == FishingLogic.State.WAITING
	# 안내 말풍선 (튜토리얼 설명, 실패 이유): 줄다리기 중에는 헤더가 숨으니 맨 위, 조용할 때는 주문 쪽지와 그만하기 줄 아래, 나머지는 헤더 바로 아래
	var below := GameHeader.BOTTOM + 12.0
	if fighting:
		below = GameHeader.TOP_PAD
	elif _calm_row.visible and (_order_card.visible or _quit_btn.visible):
		below = maxf(_order_card.position.y + _order_card.size.y if _order_card.visible else 0.0, _calm_row.position.y + _calm_row.size.y) + 12.0
	_hint_row.offset_top = below
	_hint_pill.visible = not _hint.text.is_empty() and not _in_story
	_update_order_card()
	_update_prompt()

	for s in _splashes:
		s.t += delta
	_splashes = _splashes.filter(func(s): return s.t < 0.5)
	if logic.state == FishingLogic.State.REELING and randf() < delta * (5.0 if logic.run_dir != 0 else 2.0):
		_splashes.append({"t": 0.0, "off": Vector2(randf_range(-18, 18), randf_range(-4, 4))})

	# 화면 흔들림 (바다와 주인공만). 설정에서 끄면 흔들지 않는다
	_shake = maxf(0.0, _shake - delta * 2.5)
	var fight_shake := 0.0
	if logic.state == FishingLogic.State.REELING and _hitstop <= 0.0:
		fight_shake = maxf(0.0, logic.tension - 0.8) * 12.0
		if logic.run_dir != 0 and not logic.countering:
			fight_shake += logic.fish_pull() * 1.6 # 물고기가 차고 나갈 때 화면도 끌려간다
	var amp := (_shake * 14.0 + fight_shake) if GameState.screen_shake_on else 0.0
	_world.position = Vector2(randf_range(-amp, amp), randf_range(-amp, amp)) if amp > 0.2 else Vector2.ZERO

	_place_player()
	_layer.queue_redraw()
	_world.get_node("LineLayer").queue_redraw()
	_hud_draw.queue_redraw()
	_expose_state_for_tests()

	if not _in_story and not _ending and logic.state == FishingLogic.State.READY:
		if tutorial and minutes >= END_MIN and not GameState.caught_today.is_empty():
			_start_ending()
		elif not tutorial and minutes >= session_end:
			_start_ending()


## 찌 톡톡, 릴 감는 소리처럼 상태 안에서 반복되는 소리
func _play_loop_sounds(delta: float) -> void:
	var nib := logic.state == FishingLogic.State.WAITING and logic.nibble > 0.0
	if nib and not _was_nibble:
		Sound.play_sfx("nibble", 0.1)
		Haptics.play("nibble")
		_add_ripple(0.5)
	_was_nibble = nib
	if logic.state == FishingLogic.State.REELING and _held:
		_reel_sound -= delta
		if _reel_sound <= 0.0:
			Sound.play_sfx("reel", 0.08, -6.0)
			_reel_sound = 0.18 if logic.exhausted else 0.32
	else:
		_reel_sound = 0.0


## 줄다리기 중 바뀌는 순간 (차고 나감, 지침, 장력 위험)과 반복 진동
func _watch_fight_events(delta: float) -> void:
	if logic.state != FishingLogic.State.REELING:
		_last_run = 0
		_last_tension_level = 0
		return
	# 어종 버릇: 바늘털이 (학공치), 첫 파고들기 (우럭)
	if logic.jumps != _last_jumps:
		_last_jumps = logic.jumps
		if logic.jumps > 0:
			Sound.play_sfx("pop", 0.1)
			Haptics.play("surge")
			_kick(0.3)
			for i in 6:
				_splashes.append({"t": 0.0, "off": Vector2(randf_range(-30, 30), randf_range(-14, 4))})
			_pop_text("바늘털이! 계속 감아요", UiKit.SUN, _to_screen(_fish_point()) + Vector2(0, -90), 34, true)
	if logic.run_dir != 0 and _last_run == 0:
		Sound.play_sfx("surge", 0.1, -4.0)
		Haptics.play("surge")
		_kick(0.35)
		_haptic_pull = 0.25
		if logic.run_count == 1 and logic.habit() == "dive":
			_kick(0.6)
			_pop_text("바위로 파고들어요!", UiKit.CORAL, _to_screen(_fish_point()) + Vector2(0, -90), 34, true)
		elif logic.run_count == 1 and logic.habit() == "long":
			_pop_text("길게 차고 나가요!", UiKit.CORAL, _to_screen(_fish_point()) + Vector2(0, -90), 32, true)
	_last_run = logic.run_dir
	if logic.countering and not _was_countering:
		Sound.play_sfx("tick", 0.05)
		Haptics.play("tick") # 원이 "여기까지" 칸에 들어가는 순간
	_was_countering = logic.countering
	if logic.exhausted and not _was_exhausted:
		Sound.play_sfx("pop")
		Haptics.play("exhausted")
		_pop_text("지쳤어요!", UiKit.LEAF, _to_screen(_fish_point()) + Vector2(0, -80), 44)
	_was_exhausted = logic.exhausted

	# 장력 위험: 들어가는 순간 소리, 있는 동안 짧은 진동을 빠르게 반복
	var lvl := FishingLogic.tension_level(logic.tension)
	if lvl == 2 and _last_tension_level < 2:
		Sound.play_sfx("tick", 0.0, -2.0)
		_haptic_danger = 0.0
	_last_tension_level = lvl
	_haptic_danger -= delta
	_haptic_pull -= delta
	if lvl == 2:
		if _haptic_danger <= 0.0:
			Haptics.play("danger")
			_haptic_danger = 0.16
		return
	# 물고기가 당길 때 약하게 반복. 반대로 잘 버티는 중이면 드물게, 쉬는 중에는 힘센 고기만 가끔
	if logic.exhausted or _haptic_pull > 0.0:
		return
	if logic.run_dir != 0:
		Haptics.play("pull")
		_haptic_pull = 0.45 if logic.countering else 0.22
	elif _held and logic.fish_pull() > 0.75:
		Haptics.play("pull")
		_haptic_pull = 0.6


## 힘 모으는 중 게이지가 포인트(NICE) 구간에 들어가는 순간 톡
func _watch_charge() -> void:
	if logic.state != FishingLogic.State.CHARGING:
		_in_nice_zone = false
		return
	var inside := absf(logic.power * logic.cast_mult - logic.point_depth) <= FishingLogic.CAST_NICE
	if inside and not _in_nice_zone:
		Sound.play_sfx("tick", 0.05)
		Haptics.play("tick")
	_in_nice_zone = inside


func _on_state_changed() -> void:
	var s := logic.state
	if _in_story:
		_hint.text = ""
		return
	if s == FishingLogic.State.FAILED:
		_set_hint(FishingLogic.fail_message(logic.fail_reason), UiKit.INK if logic.fail_reason == "retrieved" else UiKit.CORAL_DEEP)
		_hint_sticky = true
	elif s == FishingLogic.State.READY and _hint_sticky:
		pass # 실패 안내는 다시 던지기 시작할 때까지 남긴다
	elif tutorial:
		_hint_sticky = false
		_set_hint(HINTS.get(s, ""), UiKit.CORAL_DEEP if s == FishingLogic.State.BITE else UiKit.INK)
	else:
		_hint_sticky = false
		_set_hint("", UiKit.INK)
	_play_state_sound(s)
	match s:
		FishingLogic.State.WAITING:
			_slack = 1.0
			Haptics.play("plop")
			_add_ripple(1.0)
			match logic.cast_grade:
				"nice":
					_pop_text("NICE CAST!", UiKit.SUN, _to_screen(_float_pos()) + Vector2(0, -64), 46, true)
					Sound.play_sfx("good")
				"good":
					_pop_text("GOOD", UiKit.SKY, _to_screen(_float_pos()) + Vector2(0, -58), 36)
		FishingLogic.State.BITE:
			# 찌가 쏙 들어가며 물결이 퍼지고, 화면이 살짝 흔들리고, 쿵쿵 진동
			_bite_dip = 1.0
			_add_ripple(1.7)
			_kick(0.22)
			Haptics.play("bite")
			_pop_text("지금!", UiKit.CORAL, _to_screen(_float_pos()) + Vector2(0, -96), 50, true)
		FishingLogic.State.CAUGHT:
			_held = false
			_record_catch()
			_landing = LANDING_TIME # 들어 올리는 연출 뒤에 카드를 보여 준다
			var art := "fish_" + logic.fish_id
			_fish_tex = load(ArtSlot.art_path(art)) if ArtSlot.has_art(art) else null
			Haptics.play("catch")
			_kick(0.3)
		FishingLogic.State.FAILED:
			var at := _to_screen(_float_pos()) + Vector2(0, -70)
			if logic.fail_reason == "broke":
				_kick(0.8)
				Haptics.play("broke")
				_flash_screen(UiKit.DANGER, 0.22)
			elif logic.fail_reason == "retrieved":
				Haptics.play("tap") # 줄을 거둔 건 실패가 아니라 가볍게
			elif logic.fail_reason != "":
				Haptics.play("lost")
			var short := FishingLogic.fail_short(logic.fail_reason)
			if not short.is_empty():
				_pop_text(short, UiKit.PINK, Vector2(at.x, clampf(at.y, 360.0, 800.0)), 40, true)


func _on_hooked() -> void:
	_hook_flash = 0.22
	var perfect := logic.hook_grade == "perfect"
	# 챔질 순간: 아주 짧게 멈췄다가(hit stop) 확 당겨지는 확대, 번쩍
	_hitstop = 0.12 if perfect else 0.07
	_kick(0.7 if perfect else 0.4)
	_zoom_pop(0.07 if perfect else 0.04, _float_pos())
	_flash_screen(UiKit.FOAM, 0.4 if perfect else 0.2)
	Haptics.play("perfect" if perfect else "hook")
	_was_exhausted = false
	_last_tension_level = 0
	_trail.clear()
	# 조작 안내는 첫 줄다리기 때만 (첫날 튜토리얼의 첫 물고기)
	if tutorial and not _tutor_fight_shown:
		_tutor_fight_shown = true
		_guide_on = true
	GameState.best_streak = maxi(GameState.best_streak, logic.perfect_streak)
	# 앞서 뜬 "지금!" 같은 글자는 치우고 판정 글자만 또렷하게
	for c in _fx.get_children():
		c.queue_free()
	var at := _to_screen(_float_pos())
	if perfect:
		_pop_text("PERFECT!", UiKit.SUN, at + Vector2(0, -80), 60, true)
		Sound.play_sfx("good")
		if logic.perfect_streak >= 2:
			_pop_text("%d연속" % logic.perfect_streak, UiKit.CORAL, at + Vector2(0, -20), 30)
	else:
		_pop_text("GOOD", UiKit.SKY, at + Vector2(0, -64), 40, true)
	if logic.is_hot() and logic.perfect_streak == FishingLogic.STREAK_HOT:
		_pop_text("물 오름! 희귀한 고기가 잘 물어요", UiKit.CORAL, Vector2(size.x / 2.0, 380), 30)


## 화면 흔들기 (설정에서 끄면 흔들지 않는다)
func _kick(amount: float) -> void:
	if GameState.screen_shake_on:
		_shake = maxf(_shake, amount)


## 바다와 주인공을 한 점 기준으로 살짝 확대했다가 돌아온다 (챔질 손맛)
func _zoom_pop(amount: float, at: Vector2) -> void:
	if not GameState.screen_shake_on:
		return
	_world.pivot_offset = at
	_world.scale = Vector2.ONE * (1.0 + amount)
	_world.create_tween().tween_property(_world, "scale", Vector2.ONE, 0.32).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


## 화면 전체가 잠깐 번쩍인다
func _flash_screen(col: Color, alpha: float) -> void:
	_flash.color = Color(col, alpha)
	_flash.create_tween().tween_property(_flash, "color:a", 0.0, 0.22).set_trans(Tween.TRANS_SINE)


## 찌 자리에 물결 고리를 하나 퍼뜨린다
func _add_ripple(strength: float) -> void:
	_ripples.append({"t": 0.0, "p": _float_pos(), "r": strength})


## 바다 좌표(_world 안) → 화면 좌표. 흔들림과 확대를 반영한다
func _to_screen(p: Vector2) -> Vector2:
	return _world.get_global_transform() * p


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
				"slack", "escaped", "jumped":
					Sound.play_sfx("slip")
				"retrieved":
					Sound.play_sfx("reel", 0.05, -4.0)
				_:
					Sound.play_sfx("bad", 0.0, -6.0)


func _record_catch() -> void:
	var entry := {"id": logic.fish_id, "size": logic.fish_size, "perfect": logic.hook_grade == "perfect", "day": GameState.day}
	GameState.caught_today.append(entry)
	_card_released = GameState.store_catch(entry) # 아이스박스가 꽉 차면 가장 싼 고기를 놓아준다
	var best: float = GameState.dex.get(logic.fish_id, 0.0)
	_card_new = best == 0.0
	_card_record = best > 0.0 and logic.fish_size > best
	# 일지 메모 (오늘의 한 줄 후보)
	var fname: String = FishDB.get_fish(logic.fish_id).name
	if _card_new:
		GameState.note("처음으로 %s 잡았다. 도감에 한 칸이 찼다." % Josa.attach(fname, "을/를"), 4 if FishDB.get_fish(logic.fish_id).rarity != "common" else 3)
	elif FishDB.is_trophy(logic.fish_id, logic.fish_size):
		GameState.note("%s %.1fcm. 손이 떨릴 만큼 큰 놈이었다." % [fname, logic.fish_size], 3)
	elif _card_record:
		GameState.note("%s 최대 기록을 %.1fcm로 늘렸다." % [fname, logic.fish_size], 2)
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
			{"speaker": "{player}", "text": ("밤이 깊었다. 이제 들어가 자자." if night else "물때가 지났다. 이번 낚시는 여기까지.") if minutes >= session_end else "이번 낚시는 여기까지."},
		])
		return
	_play_story([
		{"speaker": "", "text": "해가 수평선 위로 완전히 올라왔다. 찌 주변이 조용해졌다."},
		{"speaker": "{player}", "text": "볼락은 밝아지면 숨는다고 했지. 오늘은 여기까지." if n > 0 else "오늘은 여기까지."},
		{"speaker": "{player}", "text": "%d마리. 이걸로 {shop} 문을 열어 보자." % n},
	])


# ─── 화면 구성 ──────────────────────────────────────

func _build_hud() -> void:
	# 맨 위 공통 헤더: 날짜와 시각, 오늘의 바다(날씨, 물때), 돈, 메뉴. 줄다리기 중에는 숨긴다
	_header = GameHeader.new()
	add_child(_header)
	_header.gear_changed.connect(_on_gear_changed)

	# 헤더 아래 (조용할 때만): 오른쪽에 그만하기
	_calm_row = UiKit.hbox(UiKit.SPACE_SM)
	_calm_row.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_calm_row.offset_left = 20
	_calm_row.offset_right = -20
	_calm_row.offset_top = GameHeader.BOTTOM + 14.0
	_calm_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_calm_row)
	_calm_row.add_child(UiKit.spacer())
	_quit_btn = UiKit.action("그만하기", "secondary", true)
	_quit_btn.pressed.connect(_start_ending)
	_calm_row.add_child(_quit_btn)

	# 주문서 쪽지 (조용할 때만)
	_order_card = PanelContainer.new()
	_order_card.add_theme_stylebox_override("panel", UiKit.chunky(UiKit.PAPER, UiKit.RADIUS_MD, 12, 4))
	_order_card.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	_order_card.position = Vector2(20, GameHeader.BOTTOM + 14.0)
	_order_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_order_card)
	var oh := UiKit.hbox(UiKit.SPACE_SM)
	oh.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_order_card.add_child(oh)
	if not order.is_empty():
		var oi := UiKit.icon_rect("fish_" + order.fish, 36)
		if oi:
			oi.custom_minimum_size = Vector2(58, 36)
			oh.add_child(oi)
	var ov := UiKit.vbox(-2)
	ov.mouse_filter = Control.MOUSE_FILTER_IGNORE
	oh.add_child(ov)
	ov.add_child(UiKit.text("%s의 주문" % order.get("customer", ""), "caption", UiKit.INK_SOFT))
	_order_text = UiKit.text(Orders.goal_text(order), "label", UiKit.INK)
	ov.add_child(_order_text)
	_order_prog = UiKit.text("", "number", UiKit.CORAL)
	oh.add_child(UiKit.gap(4))
	oh.add_child(_order_prog)
	_order_card.visible = false

	# 지금 할 일 (아래 가운데 엄지 자리, 짧게). 입질 때는 산호색으로 콩콩 뛴다
	_prompt_row = CenterContainer.new()
	_prompt_row.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_prompt_row.offset_top = -132
	_prompt_row.offset_bottom = -58
	_prompt_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_prompt_row)
	_prompt_pill = PanelContainer.new()
	_prompt_style = UiKit.chunky(UiKit.GLASS_STRONG, UiKit.RADIUS_PILL, 0, 4)
	_prompt_style.content_margin_left = 26
	_prompt_style.content_margin_right = 26
	_prompt_style.content_margin_top = 8
	_prompt_style.content_margin_bottom = 12
	_prompt_style_hot = _prompt_style.duplicate()
	_prompt_style_hot.bg_color = UiKit.CORAL
	_prompt_pill.add_theme_stylebox_override("panel", _prompt_style)
	_prompt_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_prompt_row.add_child(_prompt_pill)
	_prompt = UiKit.text("", "title", UiKit.FOAM, HORIZONTAL_ALIGNMENT_CENTER)
	_prompt.add_theme_font_size_override("font_size", 27)
	_prompt_pill.add_child(_prompt)
	_prompt_pill.hide()

	# 안내 말풍선 (위쪽. 아래는 주인공 자리). 튜토리얼이나 실패했을 때만 뜬다
	_hint_row = CenterContainer.new()
	_hint_row.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_hint_row.offset_top = GameHeader.BOTTOM + 12.0
	_hint_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hint_row)
	_hint_pill = PanelContainer.new()
	var hs := UiKit.chunky(UiKit.PAPER, UiKit.RADIUS_LG, 0, 4)
	hs.content_margin_left = 22
	hs.content_margin_right = 22
	hs.content_margin_top = 10
	hs.content_margin_bottom = 14
	_hint_pill.add_theme_stylebox_override("panel", hs)
	_hint_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hint_row.add_child(_hint_pill)
	_hint = UiKit.paragraph("", "body", UiKit.INK, 0.0, HORIZONTAL_ALIGNMENT_CENTER)
	_hint.add_theme_font_size_override("font_size", 19)
	_hint.custom_minimum_size.x = 500
	_hint_pill.add_child(_hint)
	_hint_pill.hide()

	# 미끼 버튼 (왼쪽 아래)
	_bait_btn = UiKit.action("", "secondary")
	_bait_btn.custom_minimum_size = Vector2(150, 64)
	_bait_btn.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	_bait_btn.offset_left = 20
	_bait_btn.offset_right = 170
	_bait_btn.offset_top = -130
	_bait_btn.offset_bottom = -60
	_bait_btn.pressed.connect(_open_bait_sheet)
	add_child(_bait_btn)
	var bh := UiKit.hbox(6)
	bh.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bh.offset_left = 12
	bh.offset_right = -12
	bh.offset_bottom = -5
	bh.alignment = BoxContainer.ALIGNMENT_CENTER
	bh.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bait_btn.add_child(bh)
	_bait_icon = TextureRect.new()
	_bait_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_bait_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_bait_icon.custom_minimum_size = Vector2(42, 42)
	_bait_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bh.add_child(_bait_icon)
	var bv := UiKit.vbox(-4)
	bv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bh.add_child(bv)
	bv.add_child(UiKit.text("미끼", "caption", UiKit.INK_SOFT))
	_bait_label = UiKit.text("", "label", UiKit.INK)
	bv.add_child(_bait_label)
	_refresh_bait()

	# 견제 버튼 (오른쪽 아래, 누르고 있기)
	_mend_btn = UiKit.action("견제", "mint")
	_mend_btn.custom_minimum_size = Vector2(130, 64)
	_mend_btn.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	_mend_btn.offset_left = -150
	_mend_btn.offset_right = -20
	_mend_btn.offset_top = -130
	_mend_btn.offset_bottom = -60
	_mend_btn.button_down.connect(func():
		_mend_held = true
		Haptics.play("tap"))
	_mend_btn.button_up.connect(func(): _mend_held = false)
	_mend_btn.hide()
	add_child(_mend_btn)


## 메뉴에서 낚싯대, 릴, 미끼를 바꾸면 주인공 그림과 낚시 능력치에 바로 반영한다
func _on_gear_changed() -> void:
	GearDB.apply(logic, GameState.equipped_rod, GameState.equipped_reel)
	_player.set_gear(GameState.equipped_rod, GameState.equipped_reel)
	var fa := GearDB.float_art(GameState.equipped_rod)
	_float_tex = load(ArtSlot.art_path(fa)) if ArtSlot.has_art(fa) else null
	if logic.state in [FishingLogic.State.READY, FishingLogic.State.FAILED]:
		logic.new_point()
	_refresh_bait()


func _set_hint(t: String, color: Color) -> void:
	_hint.text = t
	_hint.add_theme_color_override("font_color", color)
	if not t.is_empty():
		_hint_pill.modulate.a = 0.0
		_hint_pill.create_tween().tween_property(_hint_pill, "modulate:a", 1.0, UiKit.MOTION_BASE)


func _refresh_bait() -> void:
	var id := GameState.equipped_bait
	logic.bait = id
	var art := BaitDB.icon_art(id)
	_bait_icon.texture = load(ArtSlot.art_path(art)) if ArtSlot.has_art(art) else null
	var n := GameState.bait_count(id)
	_bait_label.text = BaitDB.bait(id).name + ("" if n < 0 else " %d" % n)


func _update_order_card() -> void:
	if order.is_empty():
		return
	if GameState.order_done:
		_order_prog.text = "완료!"
		_order_prog.add_theme_color_override("font_color", UiKit.SEA)
	else:
		_order_prog.text = "%d/%d" % [GameState.order_filled, order.count]


## 아래 가운데 지금 할 일. 입질 때는 산호색 알약이 콩콩 뛴다
func _update_prompt() -> void:
	var t := ""
	var hot := false
	if not _in_story and not _ending and not _summary.visible and not _bait_sheet.visible:
		match logic.state:
			FishingLogic.State.READY:
				t = "꾹 눌러서 힘 모으기"
			FishingLogic.State.CHARGING:
				t = "지금 떼요!" if _in_nice_zone else "포인트에서 손 떼기"
				hot = _in_nice_zone
			FishingLogic.State.WAITING:
				if logic.nibble > 0.0:
					t = "톡톡은 참아요"
				elif logic.over_mend:
					t = "너무 당겨요! 견제를 잠깐 떼요"
					hot = true
				elif logic.slipped() and not logic.mending:
					t = "찌가 흘러가요. 견제!"
				else:
					t = "찌가 쭉 잠기면 탭!"
			FishingLogic.State.BITE:
				t = "지금 탭!"
				hot = true
			FishingLogic.State.FAILED:
				t = "탭해서 다시 던지기" if logic.can_skip_fail() else ""
	if _prompt.text != t:
		_prompt.text = t
	_prompt_pill.visible = not t.is_empty()
	if _prompt_pill.get_meta("hot", false) != hot:
		_prompt_pill.set_meta("hot", hot)
		_prompt_pill.add_theme_stylebox_override("panel", _prompt_style_hot if hot else _prompt_style)
		_prompt.add_theme_color_override("font_color", UiKit.INK if hot else UiKit.FOAM)
	_prompt_pill.pivot_offset = _prompt_pill.size / 2.0
	var s := 1.0 + (0.09 * absf(sin(_t * 10.0)) if hot else 0.0)
	_prompt_pill.scale = Vector2(s, s)


## 판정 글자가 튀어 올랐다가 사라진다 (스티커처럼 굵은 외곽선).
## big이면 작게 시작해 크게 부풀었다가 자리 잡고, 살짝 기울었다가 바로 선다 (PERFECT, NICE CAST, 지금!)
func _pop_text(t: String, color: Color, at: Vector2, px := 40, big := false) -> void:
	var l := UiKit.text(t, "h1", color, HORIZONTAL_ALIGNMENT_CENTER)
	l.add_theme_font_size_override("font_size", px)
	UiKit.outlined(l, 14 if big else 12)
	_fx.add_child(l)
	l.reset_size()
	var w := maxf(l.size.x, 10.0)
	l.position = Vector2(clampf(at.x - w / 2.0, 12.0, size.x - w - 12.0), at.y - l.size.y / 2.0)
	l.pivot_offset = l.size / 2.0
	l.scale = Vector2(0.25, 0.25) if big else Vector2(0.4, 0.4)
	var tw := l.create_tween()
	if big:
		l.rotation = deg_to_rad(randf_range(-9.0, 9.0))
		tw.set_parallel()
		tw.tween_property(l, "scale", Vector2(1.22, 1.22), 0.13).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(l, "rotation", 0.0, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.chain().tween_property(l, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.chain().tween_interval(1.1)
	else:
		tw.tween_property(l, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_interval(1.0)
	tw.chain().tween_property(l, "position:y", l.position.y - 44.0, 0.4).set_trans(Tween.TRANS_SINE)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 0.4)
	tw.chain().tween_callback(l.queue_free)


# ─── 미끼 고르기 ───────────────────────────────────

func _build_bait_sheet() -> void:
	_bait_sheet = Control.new()
	_bait_sheet.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_bait_sheet)
	var dim := UiKit.scrim(0.45)
	dim.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed:
			_bait_sheet.hide())
	_bait_sheet.add_child(dim)
	var panel := UiKit.paper_panel(UiKit.SPACE_LG, UiKit.RADIUS_LG)
	panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_left = 16
	panel.offset_right = -16
	panel.offset_bottom = -20
	panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_bait_sheet.add_child(panel)
	var v := UiKit.vbox(UiKit.SPACE_MD)
	panel.add_child(v)
	v.add_child(UiKit.text("미끼 고르기", "h2", UiKit.INK))
	v.add_child(UiKit.text("미끼마다 잘 무는 고기가 달라요. 준호네 낚시방에서 살 수 있어요", "caption", UiKit.INK_SOFT))
	_bait_list = UiKit.vbox(UiKit.SPACE_SM)
	v.add_child(_bait_list)
	_bait_sheet.hide()


func _open_bait_sheet() -> void:
	if logic.state not in [FishingLogic.State.READY, FishingLogic.State.FAILED]:
		return
	Sound.play_sfx("tap")
	for c in _bait_list.get_children():
		c.queue_free()
	for id in BaitDB.ORDER:
		var n := GameState.bait_count(id)
		if n == 0:
			continue
		if tutorial and id != BaitDB.DEFAULT:
			continue
		var b := BaitDB.bait(id)
		var row := UiKit.action("", "secondary" if id != GameState.equipped_bait else "sun")
		row.custom_minimum_size = Vector2(0, 76)
		var h := UiKit.hbox(UiKit.SPACE_MD)
		h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		h.offset_left = 18
		h.offset_right = -22
		h.offset_bottom = -5
		h.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(h)
		var ic := UiKit.icon_rect(BaitDB.icon_art(id), 52)
		if ic:
			h.add_child(ic)
		var tv := UiKit.vbox(-2)
		tv.alignment = BoxContainer.ALIGNMENT_CENTER
		tv.mouse_filter = Control.MOUSE_FILTER_IGNORE
		h.add_child(tv)
		tv.add_child(UiKit.text(b.name, "title", UiKit.INK))
		tv.add_child(UiKit.text("잘 무는 고기: " + BaitDB.liked_names(id), "caption", UiKit.INK_SOFT))
		h.add_child(UiKit.spacer())
		h.add_child(UiKit.text("무제한" if n < 0 else "%d개" % n, "number", UiKit.INK))
		row.pressed.connect(func():
			GameState.equipped_bait = id
			_refresh_bait()
			Sound.play_sfx("tap")
			_bait_sheet.hide())
		_bait_list.add_child(row)
	_bait_sheet.show()
	UiKit.fade_in(_bait_sheet, UiKit.MOTION_BASE)


# ─── 잡은 물고기 카드 ───────────────────────────────

func _build_card() -> void:
	_card_root = Control.new()
	_card_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_card_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_card_root)
	var dim := UiKit.scrim(0.4)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card_root.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card_root.add_child(center)
	_card = UiKit.paper_panel(28)
	UiKit.elevate(_card.get_theme_stylebox("panel"), 3)
	_card.custom_minimum_size = Vector2(620, 0)
	_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(_card)
	var v := UiKit.vbox(UiKit.SPACE_MD)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.add_child(v)

	# 머리: 만세하는 주인공 + 희귀도와 이름
	var head := UiKit.hbox(UiKit.SPACE_MD)
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(head)
	var cheer := UiKit.icon_rect("sd/front_12", 112)
	if cheer:
		cheer.custom_minimum_size = Vector2(84, 118)
		head.add_child(cheer)
	var hv := UiKit.vbox(UiKit.SPACE_XS)
	hv.alignment = BoxContainer.ALIGNMENT_CENTER
	hv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head.add_child(hv)
	_card_badges = UiKit.hbox(UiKit.SPACE_SM)
	_card_badges.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hv.add_child(_card_badges)
	_card_title = UiKit.text("", "h1", UiKit.INK)
	hv.add_child(_card_title)

	var art_box := PanelContainer.new()
	art_box.add_theme_stylebox_override("panel", UiKit.inset_box(UiKit.SPACE_LG, UiKit.RADIUS_LG))
	art_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(art_box)
	_card_art = ArtSlot.make("fish_bolak", "볼락", Vector2(500, 210))
	art_box.add_child(_card_art)

	# 크기와 별점
	var size_row := UiKit.hbox(UiKit.SPACE_MD, BoxContainer.ALIGNMENT_CENTER)
	size_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(size_row)
	_card_size = UiKit.text("", "h1", UiKit.CORAL)
	_card_size.add_theme_font_size_override("font_size", 52)
	size_row.add_child(_card_size)
	# 별은 하나씩 톡톡 튀어나오게 세 칸으로 나눈다
	_card_star_row = UiKit.hbox(2)
	_card_star_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	size_row.add_child(_card_star_row)
	for i in 3:
		var star := UiKit.text("★", "h2", UiKit.SUN)
		UiKit.outlined(star, 6)
		_card_star_row.add_child(star)

	_card_value = UiKit.text("", "label", UiKit.INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER)
	v.add_child(_card_value)
	_card_order = UiKit.badge("", UiKit.SEA, Color.WHITE)
	v.add_child(_card_order)
	_card_box = UiKit.text("", "caption", UiKit.INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER)
	v.add_child(_card_box)
	_card_continue = UiKit.text("눌러서 계속", "label", UiKit.INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER)
	v.add_child(_card_continue)
	_card_root.hide()


func _show_card() -> void:
	var id := logic.fish_id
	var f := FishDB.get_fish(id)
	var rar := FishDB.rarity(id)
	_card_art.set_art("fish_" + id, f.name)
	_card_title.text = f.name
	_card_size.text = "%.1fcm" % logic.fish_size
	var st := FishDB.stars(id, logic.fish_size)
	for i in 3:
		(_card_star_row.get_child(i) as Label).text = "★" if i < st else "☆"
	for c in _card_badges.get_children():
		c.queue_free()
	_card_badges.add_child(UiKit.badge(rar.name, rar.color, Color.WHITE))
	if _card_new:
		_card_badges.add_child(UiKit.badge("NEW", UiKit.CORAL, Color.WHITE))
	if _card_record:
		_card_badges.add_child(UiKit.badge("최대 기록", UiKit.SUN, UiKit.INK))
	if FishDB.is_trophy(id, logic.fish_size):
		_card_badges.add_child(UiKit.badge("대물", UiKit.PINK, UiKit.INK))
	var tags: Array = []
	if logic.hook_grade == "perfect":
		tags.append("PERFECT 챔질")
	if logic.cast_grade == "nice":
		tags.append("NICE CAST")
	_card_value.text = "값 %s%s" % [GameState.format_won(FishDB.value_of(id, logic.fish_size)), ("  ·  " + "  ·  ".join(PackedStringArray(tags))) if not tags.is_empty() else ""]
	# 주문
	_card_order.hide()
	if not tutorial:
		var reward := GameState.offer_to_order(id, logic.fish_size)
		if Orders.matches(order, id, logic.fish_size) or reward > 0:
			var lbl := _card_order.get_child(0) as Label
			if reward > 0:
				lbl.text = "주문 완료! +%s" % GameState.format_won(reward)
				Sound.play_sfx("coin")
			else:
				lbl.text = "주문 %d/%d" % [GameState.order_filled, order.count]
			_card_order.show()
	# 아이스박스 자리
	var cap := GameState.icebox_size
	if not _card_released.is_empty():
		var rf: String = FishDB.get_fish(_card_released.id).name
		_card_box.text = ("아이스박스가 꽉 차서 방금 잡은 %s 놓아줬어요" % Josa.attach(rf, "을/를")) if _card_released.size == logic.fish_size and _card_released.id == id else ("아이스박스가 꽉 차서 %s 한 마리를 놓아줬어요" % rf)
		_card_box.add_theme_color_override("font_color", UiKit.CORAL_DEEP)
	else:
		_card_box.text = "아이스박스 %d / %d" % [GameState.inventory.size(), cap]
		_card_box.add_theme_color_override("font_color", UiKit.CORAL_DEEP if GameState.icebox_free() == 0 else UiKit.INK_SOFT)
	var rare := rar != FishDB.RARITY.common
	Sound.play_sfx("newfish" if (_card_new or rare) else "catch")
	_card_root.show()
	_card.modulate.a = 0.0
	_card_lock = 0.7 # 줄다리기 하던 손가락에 바로 닫히지 않게
	_animate_card.call_deferred(st)


## 결과 카드가 툭 튀어나온다: 작게 기울어진 채 나와서 부풀었다가 자리 잡고, 크기 숫자가 올라가고, 별이 하나씩
func _animate_card(stars: int) -> void:
	_card.pivot_offset = _card.size / 2.0
	_card.scale = Vector2(0.45, 0.45)
	_card.rotation = deg_to_rad(-7.0)
	var tw := _card.create_tween().set_parallel()
	tw.tween_property(_card, "modulate:a", 1.0, 0.12)
	tw.tween_property(_card, "scale", Vector2(1.06, 1.06), 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(_card, "rotation", 0.0, 0.34).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.chain().tween_property(_card, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# 크기 숫자가 0부터 올라간다 (자리 폭은 마지막 숫자에 맞춰 고정해 별이 흔들리지 않게)
	var final_size := logic.fish_size
	_card_size.custom_minimum_size.x = 0.0
	_card_size.text = "%.1fcm" % final_size
	_card_size.custom_minimum_size.x = _card_size.get_minimum_size().x
	_card_size.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var count := _card_size.create_tween()
	count.tween_interval(0.12)
	count.tween_method(func(v: float): _card_size.text = "%.1fcm" % v, 0.0, final_size, 0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	# 별이 하나씩 톡톡 (채운 별만 소리와 진동)
	for i in 3:
		var star := _card_star_row.get_child(i) as Label
		star.pivot_offset = star.get_combined_minimum_size() / 2.0
		star.scale = Vector2.ZERO
		var stw := star.create_tween()
		stw.tween_interval(0.36 + i * 0.15)
		if i < stars:
			stw.tween_callback(func():
				Sound.play_sfx("tick", 0.0, -2.0)
				Haptics.play("tap"))
		stw.tween_property(star, "scale", Vector2(1.35, 1.35), 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		stw.tween_property(star, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# 배지(NEW, 최대 기록, 대물)도 콩 튀어나온다
	for b in _card_badges.get_children():
		var bc := b as Control
		bc.pivot_offset = bc.get_combined_minimum_size() / 2.0
		bc.scale = Vector2(0.3, 0.3)
		bc.create_tween().tween_property(bc, "scale", Vector2.ONE, 0.3).set_delay(0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# 닫을 수 있을 때 "눌러서 계속"이 나타난다
	_card_continue.modulate.a = 0.0
	_card_continue.create_tween().tween_property(_card_continue, "modulate:a", 1.0, 0.25).set_delay(_card_lock)


func _close_card() -> void:
	_card_root.hide()
	logic.acknowledge()
	if tutorial and not _met_mansu and GameState.caught_today.size() == 1:
		_met_mansu = true
		_play_story([
			{"speaker": "{player}", "text": "잡았다...! 진짜 잡았어!"},
			{"speaker": "???", "text": "어이 서울 양반. 그 낚싯대로 고기 잡으려면 해 지겠다 싶었는데."},
			{"speaker": "박만수", "text": "볼락이네. 새벽 볼락은 눈이 커서 날 밝으면 귀신같이 숨어."},
			{"speaker": "박만수", "text": "고기 모인 자리에 던지고 찌 들어갈 때 딱 채 봐라. 손맛이 다를 거다."},
		])


# ─── 오늘의 조과 ───────────────────────────────────

func _build_summary() -> void:
	_summary = Control.new()
	_summary.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_summary)
	_summary.add_child(UiKit.scrim())
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_summary.add_child(center)
	var panel := UiKit.paper_panel(32)
	UiKit.elevate(panel.get_theme_stylebox("panel"), 3)
	panel.custom_minimum_size = Vector2(620, 0)
	center.add_child(panel)
	var v := UiKit.vbox(UiKit.SPACE_LG)
	panel.add_child(v)
	_summary_title = UiKit.text("", "h1", UiKit.INK, HORIZONTAL_ALIGNMENT_CENTER)
	v.add_child(_summary_title)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 0)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	_summary_list = UiKit.vbox(UiKit.SPACE_SM)
	_summary_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_summary_list)
	_summary_total = UiKit.text("", "title", UiKit.INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER)
	v.add_child(_summary_total)
	_summary_btn = UiKit.action("")
	_summary_btn.pressed.connect(_leave)
	v.add_child(_summary_btn)
	_summary.hide()


func _leave() -> void:
	GameState.time_minutes = int(minutes)
	if tutorial:
		GameState.flags["first_fishing_done"] = true
		GameState.current_location = "shop" # 잡은 볼락을 들고 식당으로 돌아간다
		UiKit.go_to(self, TUTORIAL_NEXT)
	elif night:
		# 밤 낚시를 마치면 잔다. 내일은 늦잠 (새벽 낚시 건너뜀)
		GameState.night_fished = true
		GameState.current_location = "home"
		GameState.end_day()
		UiKit.go_to(self, FREE_NEXT)
	else:
		GameState.current_location = "breakwater"
		UiKit.go_to(self, FREE_NEXT)


func _show_summary() -> void:
	for c in _summary_list.get_children():
		c.queue_free()
	var total := 0
	for e in GameState.caught_today:
		total += FishDB.value_of(e.id, e.size)
		_summary_list.add_child(_catch_row(e))
	if GameState.caught_today.is_empty():
		_summary_list.add_child(UiKit.text("오늘은 한 마리도 못 잡았다.", "body", UiKit.INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER))
	var rows := GameState.caught_today.size()
	(_summary_list.get_parent() as ScrollContainer).custom_minimum_size.y = clampf(rows * 74.0, 60.0, 520.0)
	_summary_title.text = "오늘 새벽의 기록" if tutorial else "오늘의 조과"
	var extra := ""
	if GameState.best_streak >= 2:
		extra = "  ·  최고 PERFECT %d연속" % GameState.best_streak
	_summary_total.text = "모두 %s어치%s" % [GameState.format_won(total), extra] if rows > 0 else ""
	_summary_btn.text = "식당으로" if tutorial else ("잠자리에 들기" if night else "마을 지도로")
	_summary.show()
	UiKit.fade_in(_summary, UiKit.MOTION_BASE)
	_summary_btn.grab_focus()


## 조과 한 줄: 물고기 그림, 이름, 희귀도, 별점, 크기
func _catch_row(e: Dictionary) -> PanelContainer:
	var row := PanelContainer.new()
	row.add_theme_stylebox_override("panel", UiKit.inset_box(UiKit.SPACE_MD, UiKit.RADIUS_MD))
	var h := UiKit.hbox(UiKit.SPACE_MD)
	row.add_child(h)
	var thumb := UiKit.icon_rect("fish_" + e.id, 44)
	if thumb:
		thumb.custom_minimum_size = Vector2(88, 44)
		h.add_child(thumb)
	h.add_child(UiKit.text(FishDB.get_fish(e.id).name, "title", UiKit.INK))
	var rar := FishDB.rarity(e.id)
	if rar != FishDB.RARITY.common:
		h.add_child(UiKit.badge(rar.name, rar.color, Color.WHITE))
	h.add_child(UiKit.spacer())
	var st := UiKit.text("★".repeat(FishDB.stars(e.id, e.size)), "label", UiKit.SUN)
	h.add_child(st)
	h.add_child(UiKit.text("%.1fcm" % e.size, "number", UiKit.CORAL))
	return row


# ─── 주인공 자세 ───────────────────────────────────

func _place_player() -> void:
	var aspect := _player.body_aspect()
	_player.size = Vector2(PLAYER_H * aspect, PLAYER_H)
	var feet := _bg.art_point(FEET)
	_player.position = feet - Vector2(_player.size.x / 2.0, _player.size.y)
	# 실제 찌낚시 자세 (docs/찌낚시_동작_조사.md)
	# pitch: 낚싯대 높이 (0 바다 쪽 수평, 90 수직, 120 머리 뒤 1시 방향)
	var pitch := 55.0
	var lean := 0.0
	var pose := "idle"
	var bend := 0.05
	match logic.state:
		FishingLogic.State.READY:
			pitch = 60.0 # 베일을 열고 검지에 줄을 건 준비 자세
		FishingLogic.State.CHARGING:
			pitch = lerpf(75.0, 125.0, minf(logic.power * 1.3, 1.0)) # 머리 뒤 1시 방향으로 넘긴다
			lean = -4.0 * logic.power
			pose = "charge" if logic.power < 0.45 else "charge_full"
		FishingLogic.State.CASTING:
			# 앞으로 휘둘러 10~11시 방향에서 줄을 놓고, 앞쪽 30도 정도에서 멈춘다
			var k := minf(logic.progress * 3.0, 1.0)
			pitch = lerpf(125.0, 30.0, k)
			lean = lerpf(-4.0, 3.0, k)
			pose = "cast" if logic.progress < 0.5 else "cast_end"
			bend = 0.25 * (1.0 - k)
		FishingLogic.State.WAITING:
			# 찌를 볼 때는 45도. 견제할 때는 뒷줄을 잡고 70도까지 천천히 세운다
			pitch = 70.0 if logic.mending else 45.0
			pose = "reel" if logic.mending else "wait"
			bend = 0.04 + logic.nibble * 0.12
		FishingLogic.State.BITE:
			pitch = 45.0
			pose = "bite"
			bend = 0.1 + logic.bite_depth * 0.25
		FishingLogic.State.REELING:
			# 누르면 숙이며 감고, 떼면 세워 버틴다. 물고기가 당기면 끌려 숙여진다
			pitch = (48.0 if _held else 68.0) - logic.fish_pull() * 8.0
			lean = -2.0 + logic.fish_x * 3.0
			bend = FightView.rod_bend(logic.tension) # 장력은 휨새로 읽는다
			if logic.exhausted:
				pose = "reel"
			elif logic.tension > 0.78:
				pose = "strain_hard"
			elif logic.run_dir != 0 or logic.tension > 0.5:
				pose = "strain"
			else:
				pose = "reel"
		FishingLogic.State.CAUGHT:
			pitch = 82.0 # 들어 올리기
			pose = "cheer" if _landing <= LANDING_TIME * 0.5 else "reel"
			bend = 0.2
		FishingLogic.State.FAILED:
			pitch = 55.0
			pose = "fail"
	if _hook_flash > 0.0:
		pitch = 85.0 # 챔질: 팔 전체로 낚싯대를 45도 이상 확 세운다
		pose = "strain"
		bend = 0.8
	var follow := 0.45 if _hook_flash > 0.0 or logic.state == FishingLogic.State.CASTING else 0.2
	# 물고기가 당기는 힘만큼 낚싯대 끝이 투둑투둑 떨린다 (버티는 손맛)
	var quiver := 0.0
	if logic.state == FishingLogic.State.REELING and not logic.exhausted:
		var k := logic.fish_pull() * (1.0 if logic.run_dir != 0 and not logic.countering else 0.45)
		quiver = k * 0.09 * sin(_t * 23.0) + k * 0.05 * sin(_t * 9.0)
		pitch += k * 2.5 * sin(_t * 17.0)
		# 위험: 대 끝이 덜덜 떤다
		if FishingLogic.tension_level(logic.tension) == 2:
			quiver += 0.07 * sin(_t * 47.0) + 0.04 * sin(_t * 31.0)
	elif logic.state == FishingLogic.State.BITE:
		quiver = 0.05 * sin(_t * 20.0) * (1.0 - logic.bite_depth * 0.5)
	_player.pitch = lerpf(_player.pitch, pitch, follow)
	_player.lean = lerpf(_player.lean, lean, 0.25)
	_bend_base = lerpf(_bend_base, bend, 0.3)
	_player.bend = clampf(_bend_base + quiver, 0.0, 1.0)
	_player.pose = pose
	# 누른 채 좌우로 끌면 낚싯대가 그쪽으로 눕는다. 대 끝 빛은 장력 (청록 알맞음, 빨강 위험은 깜빡임)
	var fighting := logic.state == FishingLogic.State.REELING
	var roll := ROLL_BASE + (_steer() * ROLL_STEER if fighting else 0.0)
	_player.roll = lerpf(_player.roll, roll, 0.2)
	var glow := FightView.tip_glow(logic.tension) if fighting and _hook_flash <= 0.0 else Color(0, 0, 0, 0)
	if fighting and FishingLogic.tension_level(logic.tension) == 2:
		glow.a *= 0.7 + 0.3 * sin(_t * 26.0)
	_player.tip_glow = glow
	_player.bend_toward = _float_pos() if logic.state in [FishingLogic.State.WAITING, FishingLogic.State.BITE, FishingLogic.State.REELING] else Vector2.ZERO


# ─── 바다 위: 포인트, 찌, 줄 ────────────────────────
# 낚싯줄, 찌 자리, 포인트 물결, 게이지는 게임 판정을 보여 주는 요소라 선으로 그린다.

func _rod_tip() -> Vector2:
	# 흔들림과 확대를 거꾸로 풀어 _world 안 좌표로
	return _world.get_global_transform().affine_inverse() * _player.tip_global()


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


## 줄다리기 중 물고기 자리
func _fish_point() -> Vector2:
	var d := _float_depth()
	return _water_point(d) + Vector2(logic.fish_x * FISH_SWAY_PX * _depth_scale(d), 0)


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
			return target + Vector2(_drift_px(), (sin(_t * 2.2) * 2.0 + logic.nibble * 8.0) * sc)
		FishingLogic.State.BITE:
			# 입질 순간 쏙 끌려 들어갔다가 조금 올라와 천천히 잠긴다
			return target + Vector2(_drift_px(), (6.0 * logic.bite_depth + sin(_bite_dip * PI * 0.5) * 9.0) * sc)
		FishingLogic.State.REELING:
			return _fish_point()
	return target


## 바다 위 (주인공 뒤): 포인트 물결, 찌, 입질 고리, 물보라
func _draw_layer() -> void:
	var s := logic.state
	# 캐스팅 포인트: 물고기가 모인 자리의 물결
	if s in [FishingLogic.State.READY, FishingLogic.State.CHARGING] and not _in_story:
		_draw_point()
	elif s == FishingLogic.State.WAITING and logic.landed_grade != "":
		_draw_point(0.35, false) # 기다리는 동안은 옅게: 찌가 포인트에서 흘러가는 게 보이게
	# 찌 둘레 물결 (착수, 톡톡, 입질)
	var rsc := _depth_scale(logic.cast_power)
	for rp in _ripples:
		var k: float = rp.t / RIPPLE_TIME
		var ease_k := 1.0 - pow(1.0 - k, 2.0)
		for ring in 2:
			var rr: float = (8.0 + ease_k * (34.0 + ring * 18.0) * rp.r) * rsc
			_draw_ellipse_arc(rp.p, rr, Color(1, 1, 1, (1.0 - k) * (0.85 - ring * 0.35)), 2.6 - ring * 0.8)
	if s in [FishingLogic.State.WAITING, FishingLogic.State.BITE]:
		var fsc := _depth_scale(logic.cast_power)
		_draw_float(_float_pos(), s == FishingLogic.State.BITE, fsc)
		if s == FishingLogic.State.BITE:
			_draw_bite_ring(_float_pos(), fsc)
	if s == FishingLogic.State.REELING:
		var fp := _fish_point()
		var ssc := _depth_scale(_float_depth())
		# 도망가는 물고기 뒤로 흰 물살 꼬리 (가는 쪽 반대편으로 길게)
		if logic.run_dir != 0 and not logic.exhausted:
			for i in 3:
				var k := fmod(_t * 3.0 + i / 3.0, 1.0)
				var y := fp.y + (i - 1) * 7.0 * ssc
				var x0 := fp.x - logic.run_dir * (14.0 + k * 50.0) * ssc
				var x1 := x0 - logic.run_dir * (18.0 + 14.0 * (1.0 - k)) * ssc
				_layer.draw_line(Vector2(x0, y), Vector2(x1, y), Color(1, 1, 1, (1.0 - k) * 0.75), 3.0, true)
		for sp in _splashes:
			var a: float = 1.0 - sp.t / 0.5
			_draw_ellipse_arc(fp + sp.off * ssc * 0.5, (6.0 + sp.t * 26.0) * ssc, Color(1, 1, 1, a * 0.6), 2.0)


func _draw_point(alpha := 1.0, show_label := true) -> void:
	var p := _water_point(logic.point_depth)
	var sc := _depth_scale(logic.point_depth)
	for i in 3:
		var k := fmod(_t * 0.6 + i / 3.0, 1.0)
		_draw_ellipse_arc(p, (14.0 + k * 46.0) * sc, Color(1, 1, 0.85, (1.0 - k) * 0.85 * alpha), 3.0)
	if not show_label:
		return
	# 반짝임
	var tw := 0.5 + 0.5 * sin(_t * 6.0)
	var r := (6.0 + tw * 5.0) * sc
	_layer.draw_line(p + Vector2(-r, 0), p + Vector2(r, 0), Color(1, 1, 0.9, 0.9), 2.0, true)
	_layer.draw_line(p + Vector2(0, -r * 1.4), p + Vector2(0, r * 0.6), Color(1, 1, 0.9, 0.9), 2.0, true)
	var font := UiKit.font("cute")
	var label := "포인트"
	var fs := int(22 * maxf(sc, 0.75))
	var w := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	_layer.draw_string_outline(font, p + Vector2(-w / 2.0, -26.0 * sc - 6), label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 8, UiKit.OUTLINE)
	_layer.draw_string(font, p + Vector2(-w / 2.0, -26.0 * sc - 6), label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, UiKit.SUN)


## 원근 때문에 납작한 물결 고리
func _draw_ellipse_arc(c: Vector2, r: float, col: Color, width: float) -> void:
	_layer.draw_set_transform(c, 0.0, Vector2(1.0, 0.36))
	_layer.draw_arc(Vector2.ZERO, r, 0.0, TAU, 32, col, width / 0.36 * 0.5, true)
	_layer.draw_set_transform_matrix(Transform2D.IDENTITY)


## 찌: 여울 찌 그림(float-n)의 물 위 부분만 보인다. 그림이 없으면 점으로
func _draw_float(p: Vector2, sunk: bool, k := 1.0) -> void:
	var sink := 0.0
	if sunk:
		sink = maxf(0.35 + 0.55 * logic.bite_depth, _bite_dip * 0.92)
	elif logic.state == FishingLogic.State.WAITING:
		sink = logic.nibble * 0.25
	_draw_ellipse_arc(p, 16.0 * k, Color(1, 1, 1, 0.55), 2.0)
	if _float_tex == null:
		_layer.draw_circle(p + Vector2(0, -6) * k, 6.0 * k, Color("ff6a3d"))
		return
	var ts := _float_tex.get_size()
	var h := FLOAT_H * k
	var w := h * ts.x / ts.y
	# 물 위로 보이는 높이 (그림 위쪽부터 waterline까지), 잠길수록 줄어든다
	var vis := clampf(FLOAT_WATERLINE * (1.0 - sink), 0.08, 1.0)
	var src := Rect2(0, 0, ts.x, ts.y * vis)
	var dst := Rect2(p.x - w / 2.0, p.y - h * vis, w, h * vis)
	_layer.draw_texture_rect_region(_float_tex, dst, src)


## 입질 고리: 찌로 줄어드는 고리. 찌 크기 고리와 딱 겹칠 때가 PERFECT
func _draw_bite_ring(p: Vector2, k: float) -> void:
	var z := logic.perfect_zone()
	var mid := (z.x + z.y) / 2.0
	var target_r := 30.0 * k + 8.0
	var r := target_r + (mid - logic.bite_depth) * 160.0 * k
	var c := p + Vector2(0, -FLOAT_H * k * 0.3)
	var in_zone := logic.bite_depth >= z.x and logic.bite_depth <= z.y
	# 과녁 고리 (외곽선을 둘러 어두운 바다에서도 또렷하게)
	_layer.draw_arc(c, target_r, 0, TAU, 40, Color(UiKit.OUTLINE, 0.55), 8.0, true)
	_layer.draw_arc(c, target_r, 0, TAU, 40, Color(UiKit.SUN, 0.95), 4.5, true)
	if r > 4.0:
		if in_zone:
			# 딱 맞는 순간: 굵어지고 밝게 번쩍
			_layer.draw_arc(c, r, 0, TAU, 48, Color(UiKit.OUTLINE, 0.6), 10.0, true)
			_layer.draw_arc(c, r, 0, TAU, 48, UiKit.SUN.lightened(0.35), 6.5, true)
		else:
			_layer.draw_arc(c, r, 0, TAU, 48, Color(UiKit.OUTLINE, 0.45), 6.5, true)
			_layer.draw_arc(c, r, 0, TAU, 48, Color(1, 1, 1, 0.92), 3.5, true)


## 줄과 날아가는 찌 (주인공 앞): 낚싯대 끝에서 나가야 해서 몸보다 나중에 그린다
func _draw_line_layer(ci: Control) -> void:
	var s := logic.state
	var tip := _rod_tip()
	if s in [FishingLogic.State.CASTING, FishingLogic.State.WAITING, FishingLogic.State.BITE, FishingLogic.State.REELING]:
		var fp := _float_pos()
		var sag := FightView.line_sag(logic.tension) if s == FishingLogic.State.REELING else 10.0 + 50.0 * _slack
		if logic.mending:
			sag = 2.0 # 견제: 뒷줄을 잡아 팽팽하게
		var col := Color(1, 1, 1, 0.75)
		var width := 1.6
		var buzz := 0.0
		if s == FishingLogic.State.REELING:
			# 느슨하면 처지고, 팽팽할수록 빨개지고 굵어지며, 위험하면 지그재그로 떤다
			col = Color(1, 1, 1, 0.85).lerp(FightView.RED, FightView.line_red(logic.tension))
			width = 1.6 + logic.tension * 1.8
			if FishingLogic.tension_level(logic.tension) == 2:
				buzz = (4.0 + 4.0 * logic.break_progress()) * (1.0 if fmod(_t * 22.0, 1.0) < 0.5 else -1.0)
		var pts := PackedVector2Array()
		for i in 25:
			var k := i / 24.0
			var p := tip.lerp(fp, k)
			p.y += sin(k * PI) * sag
			p.x += sin(k * PI) * buzz * (1.0 if i % 2 == 0 else -1.0)
			pts.append(p)
		ci.draw_polyline(pts, col, width, true)
		if s == FishingLogic.State.REELING:
			_draw_fish_mark(ci, fp)
		if s == FishingLogic.State.CASTING and _float_tex:
			var ts := _float_tex.get_size()
			var h := FLOAT_H * 0.8
			ci.draw_texture_rect(_float_tex, Rect2(fp.x - h * ts.x / ts.y / 2.0, fp.y - h / 2.0, h * ts.x / ts.y, h), false)
	if s == FishingLogic.State.CAUGHT and _landing > 0.0:
		_draw_landing(ci, tip)


## 물 위 물고기 표시 (T2): 줄이 들어가는 자리 위에 작은 힘 막대(분홍, 지치면 연두), 그 위에 남은 줄 숫자,
## 막대 옆에 물고기가 가는 방향 갈매기표. 사용자는 그 반대로 끌어 버틴다. 화면 밖으로 나가지 않게
func _draw_fish_mark(ci: Control, c: Vector2) -> void:
	var sc := _depth_scale(_float_depth())
	var w := 96.0
	var h := 16.0
	var side := 46.0 # 갈매기표 자리
	var top := c.y - 26.0 * sc - 20.0 - h
	var x := clampf(c.x - w / 2.0, 16.0 + side, size.x - 16.0 - side - w)
	top = clampf(top, GameHeader.TOP_PAD + 44.0, size.y - h - 8.0)
	UiKit.draw_bar(ci, Rect2(x, top, w, h), logic.fish_hp, UiKit.LEAF if logic.exhausted else UiKit.PINK, true)
	# 남은 줄
	var font := UiKit.font("number")
	var t := "%dm" % FightView.line_meters(logic.distance, logic.cast_power)
	var fs := 26
	var tw := font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var tp := Vector2(x + (w - tw) / 2.0, top - 8.0)
	ci.draw_string_outline(font, tp, t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 8, UiKit.OUTLINE)
	ci.draw_string(font, tp, t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, UiKit.FOAM)
	# 물고기가 가는 방향: 막대 옆에서 그쪽으로 흘러가는 갈매기표 둘. 잘 버티면 연두, 놓치기 직전이면 산호
	if logic.run_dir == 0 or logic.exhausted:
		return
	var d := float(logic.run_dir)
	var col: Color = UiKit.LEAF if logic.countering else (UiKit.CORAL if logic.escape > 0.55 else UiKit.SUN)
	var cy := top + h / 2.0
	var x0 := (x + w + 12.0) if d > 0.0 else (x - 12.0)
	var slide := 0.0 if logic.countering else fmod(_t * 2.2, 1.0) * 8.0
	for i in 2:
		var ax := x0 + d * (i * 14.0 + slide)
		var pts := PackedVector2Array([Vector2(ax, cy - 10.0), Vector2(ax + d * 10.0, cy), Vector2(ax, cy + 10.0)])
		ci.draw_polyline(pts, UiKit.OUTLINE, 9.0, true)
		ci.draw_polyline(pts, Color(col, 1.0 - 0.35 * i), 4.5, true)


## 들어 올리기: 발 앞까지 끌려온 물고기를 낚싯대 탄력으로 방파제 위로 올린다
func _draw_landing(ci: Control, tip: Vector2) -> void:
	var k := 1.0 - _landing / LANDING_TIME
	k = 1.0 - pow(1.0 - k, 2.0)
	var start := _water_point(0.0)
	var end := tip + Vector2(0, 80)
	var pos := start.lerp(end, k) + Vector2(0, -sin(k * PI) * 50.0)
	ci.draw_line(tip, pos, Color(1, 1, 1, 0.8), 1.6, true)
	var w := 96.0
	if _fish_tex:
		var ts := _fish_tex.get_size()
		var h := w * ts.y / ts.x
		# 바늘에 걸려 머리가 위로 가게 매달린 모습 (그림은 머리가 왼쪽)
		ci.draw_set_transform(pos, PI / 2.0 + sin(_t * 18.0) * 0.25)
		ci.draw_texture_rect(_fish_tex, Rect2(0, -h / 2.0, w, h), false)
		ci.draw_set_transform_matrix(Transform2D.IDENTITY)
	if k < 0.3:
		ci.draw_arc(start, 10.0 + k * 60.0, PI, TAU, 12, Color(1, 1, 1, 1.0 - k * 3.0), 2.0)


# ─── HUD 게이지 ────────────────────────────────────

func _draw_hud() -> void:
	if _in_story:
		return
	var s := logic.state
	if s == FishingLogic.State.REELING:
		_draw_danger_edge()
	if s == FishingLogic.State.CHARGING:
		_draw_cast_gauge()
	if s == FishingLogic.State.REELING:
		# 손가락이 지나간 자취: 작은 점이 남았다가 사라진다
		for tr in _trail:
			var tk: float = 1.0 - tr.t / TRAIL_TIME
			_hud_draw.draw_circle(tr.p, 3.0 + 4.0 * tk, Color(UiKit.FOAM, tk * 0.7))
		if _guide_on:
			_draw_fight_guide()
	# 누른 자리 고리 (누르는 순간 바로 보이는 반응)
	for tc in _touches:
		var k: float = tc.t / TOUCH_TIME
		var ek := 1.0 - pow(1.0 - k, 3.0)
		_hud_draw.draw_arc(tc.p, 14.0 + ek * 40.0, 0.0, TAU, 32, Color(UiKit.FOAM, (1.0 - k) * 0.9), 4.0 * (1.0 - k) + 1.0, true)


## 줄 끊김 직전: 화면 가장자리에 빨간 테가 숨 쉬듯 깜빡인다 (끊어지기까지 남은 시간이 짧을수록 진하게)
func _draw_danger_edge() -> void:
	var over := clampf((logic.tension - FishingLogic.TENSION_DANGER) / (1.0 - FishingLogic.TENSION_DANGER), 0.0, 1.0)
	if over <= 0.0:
		return
	var a := (0.25 + 0.45 * maxf(over, logic.break_progress())) * (0.65 + 0.35 * sin(_t * 16.0))
	var full := Rect2(Vector2.ZERO, size)
	var widths := [34, 20, 9]
	var alphas := [0.35, 0.5, 0.8]
	for i in 3:
		_hud_draw.draw_style_box(UiKit.box(Color.TRANSPARENT, 0, Color(UiKit.DANGER, a * float(alphas[i])), int(widths[i]), 0), full)


## 오른쪽 세로 거리 게이지: 아래가 발밑, 위가 가장 먼 물. 포인트 구간이 반짝인다
func _draw_cast_gauge() -> void:
	var r := Rect2(size.x - 84, 420, 44, 470)
	var track := UiKit.box(Color("1d1830"), 22, UiKit.OUTLINE, UiKit.OUTLINE_W, 0)
	_hud_draw.draw_style_box(track, r)
	var inner := r.grow(-5)
	var y_of := func(v: float) -> float: return inner.end.y - inner.size.y * clampf(v, 0.0, 1.0)
	# 던질 수 없는 거리 (장비 한계)
	var max_y: float = y_of.call(logic.cast_mult)
	if max_y > inner.position.y + 2:
		_hud_draw.draw_rect(Rect2(inner.position, Vector2(inner.size.x, max_y - inner.position.y)), Color(0, 0, 0, 0.45))
	# GOOD, NICE 구간
	var pd := logic.point_depth
	var g0: float = y_of.call(pd + FishingLogic.CAST_GOOD)
	var g1: float = y_of.call(pd - FishingLogic.CAST_GOOD)
	_hud_draw.draw_style_box(UiKit.box(Color(UiKit.SKY, 0.55), 10, Color.TRANSPARENT, 0, 0), Rect2(inner.position.x, g0, inner.size.x, g1 - g0))
	var n0: float = y_of.call(pd + FishingLogic.CAST_NICE)
	var n1: float = y_of.call(pd - FishingLogic.CAST_NICE)
	var glow := 0.75 + 0.25 * sin(_t * 8.0)
	_hud_draw.draw_style_box(UiKit.box(Color(UiKit.SUN, glow), 8, Color.TRANSPARENT, 0, 0), Rect2(inner.position.x, n0, inner.size.x, n1 - n0))
	# 지금 힘 표시. 포인트 구간에 들어오면 햇살 노랑으로 커진다
	var cy: float = y_of.call(logic.power * logic.cast_mult)
	var grow := 6.0 if _in_nice_zone else 0.0
	var knob := Rect2(r.position.x - 10 - grow, cy - 9 - grow * 0.5, r.size.x + 20 + grow * 2.0, 18 + grow)
	_hud_draw.draw_style_box(UiKit.chunky(UiKit.SUN if _in_nice_zone else UiKit.CORAL, 9, 0, 2), knob)
	var font := UiKit.font("cute")
	_hud_draw.draw_string_outline(font, Vector2(r.position.x - 6, r.position.y - 14), "거리", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, 8, UiKit.OUTLINE)
	_hud_draw.draw_string(font, Vector2(r.position.x - 6, r.position.y - 14), "거리", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, UiKit.FOAM)


## 첫 줄다리기 조작 안내: 주인공과 바다 사이, 낚싯대와 겹치지 않게 조금 왼쪽. 손가락 고리가 좌우로 오가며 자취를 남긴다
func _draw_fight_guide() -> void:
	var c := Vector2(size.x * 0.27, size.y * 0.735)
	var span := 62.0
	var ph := _t * 2.4
	for i in 5:
		var k := i / 5.0
		_hud_draw.draw_circle(c + Vector2(sin(ph - k * 0.9) * span, 0), 5.0 * (1.0 - k), Color(UiKit.FOAM, 0.55 * (1.0 - k)))
	var f := c + Vector2(sin(ph) * span, 0)
	_hud_draw.draw_arc(f, 22.0, 0.0, TAU, 32, UiKit.OUTLINE, 8.0, true)
	_hud_draw.draw_arc(f, 22.0, 0.0, TAU, 32, UiKit.FOAM, 4.0, true)
	_hud_draw.draw_circle(f, 9.0, Color(UiKit.FOAM, 0.9))
	var font := UiKit.font("cute")
	var t := "누르고 좌우로"
	var tw := font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, 26).x
	var tp := Vector2(c.x - tw / 2.0, c.y + 62.0)
	_hud_draw.draw_string_outline(font, tp, t, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, 10, UiKit.OUTLINE)
	_hud_draw.draw_string(font, tp, t, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, UiKit.FOAM)


## 웹 빌드 자동 테스트용으로 현재 상태를 페이지에 알려 준다.
func _expose_state_for_tests() -> void:
	if not OS.has_feature("web"):
		return
	var key := "%s|%d|%s|%d|%d" % [FishingLogic.State.keys()[logic.state], int(logic.tension * 100), str(_in_story), GameState.caught_today.size(), int(logic.cast_power * 100)]
	if key != get_meta("_last_key", ""):
		set_meta("_last_key", key)
		JavaScriptBridge.eval("window.__fish = '%s';" % key)
