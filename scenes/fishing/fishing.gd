extends Control
## 챕터 2: 새벽 북쪽 방파제 찌낚시. 첫 물고기는 볼락.
## 규칙은 FishingLogic, 이 스크립트는 입력, 시간, 화면 표시만 맡는다.

const NEXT_SCENE := "res://scenes/map/map.tscn" # 〈첫 번째 손님〉이 생기면 식당으로 바꾼다

const START_MIN := 5 * 60 # 05:00
const END_MIN := 7 * 60 # 07:00
const REAL_SEC_PER_GAME_MIN := 1.2

const HINTS := {
	FishingLogic.State.READY: "꾹 눌러 힘을 모으고, 손을 떼서 던져요",
	FishingLogic.State.CHARGING: "적당하다 싶을 때 손을 떼요",
	FishingLogic.State.CASTING: "",
	FishingLogic.State.WAITING: "찌를 지켜봐요. 쑥 잠기면 바로 누르기",
	FishingLogic.State.BITE: "지금!",
	FishingLogic.State.REELING: "누르고 있으면 감고, 떼면 풀어 줘요. 줄이 빨개지면 잠깐 손을 떼요",
}

var logic := FishingLogic.new()
var minutes := float(START_MIN)

var _bg: SeaBackdrop
var _layer: Control
var _player: PlayerRig
var _clock: Label
var _count: Label
var _hint: Label
var _dialogue: DialogueBox
var _card: PanelContainer
var _card_art: ArtSlot
var _card_title: Label
var _card_size: Label
var _card_new: Label
var _card_desc: Label
var _summary: PanelContainer
var _summary_list: Label

## 뒤쪽 시점 낚시 화면. 아래 위치는 배경 그림(bg_fishing_dawn) 크기 대비 비율이다.
## 배경 그림이 바뀌면 이 숫자들만 그림에 맞춰 고친다.
const BG_ART := "bg_fishing_dawn"
const BG_ART_BLEND := "bg_fishing_morning"
const WATER_NEAR_Y := 0.84 # 방파제 바로 앞 바다
const WATER_FAR_Y := 0.40 # 가장 멀리 던졌을 때 (수평선 0.35 바로 아래)
const FEET := Vector2(0.5, 0.985) # 주인공 발 위치
const FLOAT_NEAR_SCALE := 1.0
const FLOAT_FAR_SCALE := 0.4

## SD 주인공 몸 그림 크기 (낚싯대와 릴은 PlayerRig가 따로 붙인다)
const PLAYER_SIZE := Vector2(150.0, 230.0)

var _held := false
var _in_story := true
var _ending := false
var _met_mansu := false
var _last_state := -1
var _t := 0.0
var _splashes: Array = []


func _ready() -> void:
	# 바깥 노드가 클릭을 먹지 않게 해야 _unhandled_input으로 낚시 입력이 들어온다
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	logic.rng.randomize()

	_bg = SeaBackdrop.new()
	_bg.mode = SeaBackdrop.Mode.DAWN
	_bg.art_base = BG_ART
	_bg.art_blend = BG_ART_BLEND
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
			_close_card()
		else:
			logic.press()
	else:
		logic.release()


# ─── 진행 ───────────────────────────────────────────

func _process(delta: float) -> void:
	_t += delta
	if not _in_story and not _summary.visible and logic.state != FishingLogic.State.CAUGHT:
		minutes = minf(minutes + delta / REAL_SEC_PER_GAME_MIN, END_MIN)
		logic.brightness = (minutes - START_MIN) / float(END_MIN - START_MIN)
		logic.update(delta, _held)
	_bg.brightness = (minutes - START_MIN) / float(END_MIN - START_MIN)

	if logic.state != _last_state:
		_on_state_changed()
		_last_state = logic.state

	_clock.text = "새벽 %02d:%02d" % [int(minutes) / 60, int(minutes) % 60]
	_count.text = "잡은 고기 %d마리" % GameState.caught_today.size()

	if logic.state == FishingLogic.State.REELING and randf() < delta * 6.0:
		_splashes.append({"t": 0.0, "off": Vector2(randf_range(-18, 18), randf_range(-4, 4))})
	for s in _splashes:
		s.t += delta
	_splashes = _splashes.filter(func(s): return s.t < 0.5)

	_place_player()
	_layer.queue_redraw()
	_expose_state_for_tests()

	if not _in_story and not _ending and logic.state == FishingLogic.State.READY \
			and minutes >= END_MIN and not GameState.caught_today.is_empty():
		_start_ending()


func _on_state_changed() -> void:
	var s := logic.state
	if _in_story:
		_hint.text = ""
		return
	if s == FishingLogic.State.FAILED:
		_hint.text = FishingLogic.fail_message(logic.fail_reason)
		_hint.add_theme_color_override("font_color", Color("ffd1c4"))
	else:
		_hint.text = HINTS.get(s, "")
		_hint.add_theme_color_override("font_color", UiKit.MUSTARD if s == FishingLogic.State.BITE else UiKit.CREAM)
	if s == FishingLogic.State.CAUGHT:
		_held = false
		_record_catch()
		_show_card()


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
	var n := GameState.caught_today.size()
	_play_story([
		{"speaker": "", "text": "해가 수평선 위로 완전히 올라왔다. 찌 주변이 조용해졌다."},
		{"speaker": "{player}", "text": "볼락은 밝아지면 숨는다고 했지. 오늘은 여기까지." if n > 0 else "오늘은 여기까지."},
		{"speaker": "{player}", "text": "%d마리. 이걸로 {shop} 문을 열어 보자." % n},
	])


# ─── 화면 구성 ──────────────────────────────────────

func _build_hud() -> void:
	_clock = UiKit.shadowed(UiKit.label("", 26, UiKit.CREAM), Color(0, 0, 0, 0.5), 2)
	_clock.position = Vector2(32, 24)
	add_child(_clock)

	_count = UiKit.shadowed(UiKit.label("", 22, UiKit.CREAM, HORIZONTAL_ALIGNMENT_RIGHT), Color(0, 0, 0, 0.5), 2)
	_count.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_count.offset_left = -300
	_count.offset_right = -32
	_count.offset_top = 28
	add_child(_count)

	_hint = UiKit.shadowed(UiKit.label("", 24, UiKit.CREAM, HORIZONTAL_ALIGNMENT_CENTER), Color(0, 0, 0, 0.6), 2)
	# 화면 아래쪽은 주인공 자리라 안내 문구는 위쪽 장력 막대 아래에 둔다
	_hint.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_hint.offset_top = 128
	_hint.offset_bottom = 168
	add_child(_hint)


func _build_card() -> void:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	_card = PanelContainer.new()
	_card.custom_minimum_size = Vector2(520, 0)
	_card.add_theme_stylebox_override("panel", UiKit.box(UiKit.PAPER, 16, UiKit.MUSTARD, 3, 28))
	_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(_card)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	_card.add_child(v)
	_card_new = UiKit.label("새로운 물고기!", UiKit.SIZE_SMALL, UiKit.CORAL, HORIZONTAL_ALIGNMENT_CENTER)
	v.add_child(_card_new)
	_card_art = ArtSlot.make("fish_bolak", "볼락", Vector2(320, 150))
	_card_art.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(_card_art)
	_card_title = UiKit.label("", UiKit.SIZE_HEADING, UiKit.INK, HORIZONTAL_ALIGNMENT_CENTER)
	v.add_child(_card_title)
	_card_size = UiKit.label("", 22, UiKit.INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER)
	v.add_child(_card_size)
	_card_desc = UiKit.label("", 20, UiKit.INK, HORIZONTAL_ALIGNMENT_CENTER)
	_card_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_card_desc.custom_minimum_size.x = 460
	v.add_child(_card_desc)
	v.add_child(UiKit.label("누르면 계속", UiKit.SIZE_SMALL, UiKit.INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER))
	_card.hide()


func _show_card() -> void:
	var f := FishDB.get_fish(logic.fish_id)
	_card_art.set_art("fish_" + logic.fish_id, f.name)
	_card_title.text = f.name
	_card_size.text = "%.1fcm" % logic.fish_size
	_card_desc.text = f.desc
	_card.show()
	_card.pivot_offset = _card.size / 2
	_card.scale = Vector2(0.8, 0.8)
	_card.create_tween().tween_property(_card, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _close_card() -> void:
	_card.hide()
	logic.acknowledge()
	if not _met_mansu and GameState.caught_today.size() == 1:
		_met_mansu = true
		_play_story([
			{"speaker": "{player}", "text": "잡았다...! 진짜 잡았어!"},
			{"speaker": "???", "text": "어이 서울 양반. 그 낚싯대로 고기 잡으려면 해 지겠다 싶었는데."},
			{"speaker": "박만수", "text": "볼락이네. 새벽 볼락은 눈이 커서 날 밝으면 귀신같이 숨어."},
			{"speaker": "박만수", "text": "해 뜨기 전에 몇 마리 더 해 봐라. ...그래도 한 마리는 잡았네."},
		])


func _build_summary() -> void:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	_summary = PanelContainer.new()
	_summary.custom_minimum_size = Vector2(480, 0)
	_summary.add_theme_stylebox_override("panel", UiKit.box(UiKit.PAPER, 16, UiKit.NAVY, 2, 32))
	center.add_child(_summary)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	_summary.add_child(v)
	v.add_child(UiKit.label("오늘 새벽의 기록", UiKit.SIZE_HEADING, UiKit.INK, HORIZONTAL_ALIGNMENT_CENTER))
	_summary_list = UiKit.label("", 22, UiKit.INK, HORIZONTAL_ALIGNMENT_CENTER)
	v.add_child(_summary_list)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	var btn := UiKit.button("마을 지도로")
	btn.pressed.connect(func():
		GameState.flags["first_fishing_done"] = true
		GameState.time_minutes = END_MIN
		GameState.current_location = "breakwater"
		UiKit.go_to(self, NEXT_SCENE))
	row.add_child(btn)
	v.add_child(row)
	_summary.hide()


func _show_summary() -> void:
	var lines: Array[String] = []
	for e in GameState.caught_today:
		lines.append("%s  %.1fcm" % [FishDB.get_fish(e.id).name, e.size])
	lines.append("")
	lines.append("다음 이야기 〈첫 번째 손님〉은 준비 중이에요.")
	_summary_list.text = "\n".join(lines)
	_summary.show()
	_summary.get_child(0).get_child(2).get_child(0).grab_focus()


func _place_player() -> void:
	_player.size = PLAYER_SIZE
	var feet := _bg.art_point(FEET)
	_player.position = feet - Vector2(_player.size.x / 2.0, _player.size.y)
	# 상태에 따라 낚싯대 각도와 몸 기울기를 바꾼다 (낚싯대 -90은 수직 위)
	var rod := -70.0
	var lean := 0.0
	match logic.state:
		FishingLogic.State.CHARGING:
			rod = lerpf(-70.0, -105.0, logic.power) # 머리 뒤로 젖힘
			lean = -4.0 * logic.power
		FishingLogic.State.CASTING:
			var k := minf(logic.progress * 2.5, 1.0)
			rod = lerpf(-105.0, -55.0, k) # 앞으로 휘두름
			lean = lerpf(-4.0, 3.0, k)
		FishingLogic.State.WAITING:
			rod = -64.0
		FishingLogic.State.BITE:
			rod = -60.0
		FishingLogic.State.REELING:
			rod = -82.0 + logic.fish_pull() * 14.0 # 세우고 버티다 당기면 숙여짐
			lean = -2.0
	_player.rod_angle = lerpf(_player.rod_angle, rod, 0.3)
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
			return target + Vector2(0, (sin(_t * 2.2) * 2.0 + logic.nibble * 7.0) * sc)
		FishingLogic.State.BITE:
			return target + Vector2(0, 14 * sc)
		FishingLogic.State.REELING:
			return _water_point(_float_depth())
	return target


func _draw_layer() -> void:
	var s := logic.state
	var tip := _rod_tip()

	if s in [FishingLogic.State.CASTING, FishingLogic.State.WAITING, FishingLogic.State.BITE, FishingLogic.State.REELING]:
		var fp := _float_pos()
		var sag := 0.0 if s == FishingLogic.State.REELING else 14.0
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

	if s == FishingLogic.State.CHARGING:
		_draw_power_gauge()
	if s == FishingLogic.State.REELING:
		_draw_tension_bar()


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
	# 머리 위 가로 게이지
	var r := Rect2(_player.position + Vector2(_player.size.x * 0.25, -10), Vector2(_player.size.x * 0.7, 14))
	_layer.draw_rect(r, Color(0, 0, 0, 0.45))
	var col := UiKit.TEAL.lerp(UiKit.MUSTARD, logic.power)
	_layer.draw_rect(Rect2(r.position, Vector2(r.size.x * logic.power, r.size.y)), col)
	_layer.draw_rect(r, Color(1, 1, 1, 0.8), false, 2.0)


func _draw_tension_bar() -> void:
	var w := 420.0
	var r := Rect2((size.x - w) / 2.0, 90, w, 22)
	_layer.draw_rect(r, Color(0, 0, 0, 0.45))
	var col := UiKit.TEAL
	if logic.tension > 0.85:
		col = Color("e2483a")
	elif logic.tension > 0.65:
		col = UiKit.MUSTARD
	_layer.draw_rect(Rect2(r.position, Vector2(w * logic.tension, r.size.y)), col)
	_layer.draw_rect(r, Color(1, 1, 1, 0.85), false, 2.0)
	var font := get_theme_default_font()
	_layer.draw_string(font, r.position + Vector2(0, -8), "줄 장력", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, UiKit.CREAM)
	_layer.draw_string(font, r.position + Vector2(w - 120, -8), "거리 %dm" % int(logic.distance * 25.0), HORIZONTAL_ALIGNMENT_RIGHT, 120, 18, UiKit.CREAM)


## 웹 빌드 자동 테스트용으로 현재 상태를 페이지에 알려 준다.
func _expose_state_for_tests() -> void:
	if not OS.has_feature("web"):
		return
	var key := "%s|%d|%s|%d|%d" % [FishingLogic.State.keys()[logic.state], int(logic.tension * 100), str(_in_story), GameState.caught_today.size(), int(logic.cast_power * 100)]
	if key != get_meta("_last_key", ""):
		set_meta("_last_key", key)
		JavaScriptBridge.eval("window.__fish = '%s';" % key)
