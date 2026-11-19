extends SceneTree
## 헤드리스 테스트. 실행: godot --headless --path . --script res://tests/run_tests.gd

var _fail := 0
var _pass := 0


func _init() -> void:
	_test_josa()
	_test_format()
	_test_validation()
	_test_won()
	_test_fish_db()
	_test_fishing()
	_test_fishing_feel()
	_test_fun()
	_test_sea_day()
	_test_header()
	_test_locations()
	_test_gear()
	_test_realism()
	_test_brightness()
	_test_catalog()
	_test_cooking()
	_test_economy()
	_test_sound()
	_test_day_flow()
	_test_garden()
	_test_coop()
	_test_save()
	_test_month()
	_test_icebox()
	_test_market()
	_test_brief()
	_test_story()
	_test_fishing_depth()
	_test_journal()
	_test_fight_view()
	_test_guest_sd()
	_test_dining()
	_test_shop_decor()
	_test_gear_help()
	_test_sides()
	_test_walkers()
	_test_kitchen()
	_test_staff()
	_test_seated()
	_test_decor_shop()
	_test_sundeok_art()
	_test_bus()
	_test_board()
	_test_quests()
	_test_kits()
	_test_shop4()
	_test_spots()
	print("\n결과: %d 통과, %d 실패" % [_pass, _fail])
	quit(1 if _fail > 0 else 0)


func _eq(actual, expected, label: String) -> void:
	if actual == expected:
		_pass += 1
	else:
		_fail += 1
		print("실패 %s: 기대 [%s] / 실제 [%s]" % [label, expected, actual])


func _test_josa() -> void:
	var cases := [
		["준", "이/가", "준이"], ["한바다", "이/가", "한바다가"],
		["준", "은/는", "준은"], ["한바다", "은/는", "한바다는"],
		["준", "을/를", "준을"], ["한바다", "을/를", "한바다를"],
		["준", "아/야", "준아"], ["한바다", "아/야", "한바다야"],
		["물빛식당", "으로/로", "물빛식당으로"], ["한 접시", "으로/로", "한 접시로"],
		["갯마을", "으로/로", "갯마을로"], ["오늘의 식탁", "이/가", "오늘의 식탁이"],
		["Bob", "이/가", "Bob가"], ["7", "은/는", "7는"], ["", "이/가", "가"],
	]
	for c in cases:
		_eq(Josa.attach(c[0], c[1]), c[2], "attach %s+%s" % [c[0], c[1]])


func _test_format() -> void:
	var v := {"player": "한바다", "shop": "물빛식당"}
	_eq(Josa.format("{shop|이/가}라... 이름 좋네.", v), "물빛식당이라... 이름 좋네.", "format 1")
	_eq(Josa.format("{player|아/야}, {shop|으로/로} 가자", v), "한바다야, 물빛식당으로 가자", "format 2")
	_eq(Josa.format("{player} 씨", v), "한바다 씨", "format 3")
	_eq(Josa.format("{unknown} 그대로", v), "{unknown} 그대로", "format unknown")
	_eq(Josa.format("괄호 없음", v), "괄호 없음", "format plain")


func _test_validation() -> void:
	var gs = load("res://scripts/autoload/game_state.gd").new()
	_eq(gs.validate_player_name(""), "", "빈 이름은 기본값 처리")
	_eq(gs.validate_player_name("한바다"), "", "정상 이름")
	_eq(gs.validate_player_name("Sea94"), "", "영문 숫자")
	_eq(gs.validate_player_name("일곱글자이름임"), "6자까지 쓸 수 있어요.", "길이 초과")
	_eq(gs.validate_player_name("한 바다"), "한글, 영문, 숫자만 쓸 수 있어요.", "이름 공백 금지")
	_eq(gs.validate_player_name("ㅋㅋ"), "한글, 영문, 숫자만 쓸 수 있어요.", "자모만 금지")
	_eq(gs.validate_player_name("바다!"), "한글, 영문, 숫자만 쓸 수 있어요.", "특수문자 금지")
	_eq(gs.validate_shop_name("오늘의 식탁"), "", "가게명 공백 허용")
	_eq(gs.validate_shop_name("병신식당"), "다른 이름을 써 주세요.", "금지어")
	_eq(gs.validate_shop_name("가나다라마바사아자차카"), "10자까지 쓸 수 있어요.", "가게명 길이")
	gs.free()


func _test_won() -> void:
	var gs = load("res://scripts/autoload/game_state.gd").new()
	_eq(gs.format_won(180000), "180,000원", "원 1")
	_eq(gs.format_won(30000000), "30,000,000원", "원 2")
	_eq(gs.format_won(500), "500원", "원 3")
	_eq(gs.format_won(-7000), "-7,000원", "원 4")
	gs.free()


func _test_fish_db() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	for id in FishDB.FISH:
		var f := FishDB.get_fish(id)
		for i in 200:
			var s := FishDB.roll_size(rng, id)
			if s < f.min_cm or s > f.max_cm:
				_eq(s, "범위 안", "%s 크기 범위" % id)
				return
	_eq(Josa.attach("볼락", "을/를"), "볼락을", "볼락 조사")
	var dark := 0
	var bright := 0
	for i in 3000:
		if FishDB.pick(rng, 0.0) == "bolak": dark += 1
		if FishDB.pick(rng, 1.0) == "bolak": bright += 1
	_eq(dark > bright + 300, true, "밝아지면 볼락이 덜 잡힘 (%d vs %d)" % [dark, bright])


## 상태가 바뀔 때까지 시간을 돌린다. 최대 max_sec초.
func _run_until(l: FishingLogic, states: Array, held_fn: Callable, max_sec := 60.0) -> void:
	var t := 0.0
	while t < max_sec and not (l.state in states):
		l.update(1.0 / 60.0, held_fn.call(l))
		t += 1.0 / 60.0


func _new_logic(seed_value: int) -> FishingLogic:
	var l := FishingLogic.new()
	l.rng.seed = seed_value
	return l


func _cast(l: FishingLogic) -> void:
	l.press()
	_run_until(l, [], func(_x): return true, 0.5)
	l.release()
	_run_until(l, [FishingLogic.State.WAITING], func(_x): return false, 2.0)


## 낚시 손맛: 진동 패턴, 진동과 화면 흔들림 설정 저장, 장력 단계, 실패 뒤 바로 다시 던지기
func _test_fishing_feel() -> void:
	var S := FishingLogic.State
	# 진동 패턴: [세기, 울림, 쉼, 울림 ...]. 울림으로 끝나고 길이와 세기가 알맞다
	for kind in Haptics.PATTERNS:
		var p: Array = Haptics.pattern(kind)
		_eq(p.size() >= 2 and p.size() % 2 == 0, true, "진동 %s 울림으로 끝남" % kind)
		_eq(Haptics.amplitude(kind) > 0.0 and Haptics.amplitude(kind) <= 1.0, true, "진동 %s 세기" % kind)
		var ok := true
		for i in range(1, p.size()):
			ok = ok and int(p[i]) >= Haptics.MIN_MS and int(p[i]) <= Haptics.MAX_MS
		_eq(ok, true, "진동 %s 길이" % kind)
	for kind in ["bite", "hook", "perfect", "pull", "danger", "broke", "lost", "catch"]:
		_eq(Haptics.PATTERNS.has(kind), true, "낚시 진동 %s 있음" % kind)
	_eq(Haptics.pulses("bite"), [[0, 45], [100, 75]], "입질 진동은 쿵쿵 두 번")
	_eq(Haptics.total_ms("bite"), 175, "입질 진동 전체 길이")
	_eq(Haptics.amplitude("pull") < Haptics.amplitude("hook"), true, "당김은 챔질보다 약하게")
	_eq(Haptics.amplitude("hook") < Haptics.amplitude("perfect"), true, "PERFECT는 챔질보다 세게")
	_eq(Haptics.total_ms("broke") > Haptics.total_ms("lost"), true, "끊김은 놓침보다 길게")
	_eq(Haptics.should_play("bite", true), true, "진동 켜짐이면 울림")
	_eq(Haptics.should_play("bite", false), false, "진동 꺼짐이면 안 울림")
	_eq(Haptics.should_play("없는진동", true), false, "없는 진동은 안 울림")
	_eq(Haptics.pattern("없는진동"), [], "없는 진동 패턴은 빈 배열")

	# 진동, 화면 흔들림 설정 저장과 불러오기 (테스트용 파일)
	var path := "user://test_settings_fishing.cfg"
	var gs = load("res://scripts/autoload/game_state.gd").new()
	_eq(gs.vibration_on, true, "진동 기본 켜짐")
	_eq(gs.screen_shake_on, true, "화면 흔들림 기본 켜짐")
	gs.vibration_on = false
	gs.screen_shake_on = false
	gs.save_settings(path)
	var gs2 = load("res://scripts/autoload/game_state.gd").new()
	gs2.load_settings(path)
	_eq(gs2.vibration_on, false, "진동 꺼짐 저장됨")
	_eq(gs2.screen_shake_on, false, "화면 흔들림 꺼짐 저장됨")
	var gs3 = load("res://scripts/autoload/game_state.gd").new()
	gs3.load_settings("user://없는_설정.cfg")
	_eq(gs3.vibration_on, true, "설정 파일이 없으면 기본값")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	gs.free()
	gs2.free()
	gs3.free()

	# 장력 단계: 안전 / 주의 / 위험
	_eq(FishingLogic.tension_level(0.3), 0, "장력 낮으면 안전")
	_eq(FishingLogic.tension_level(0.7), 1, "장력 중간이면 주의")
	_eq(FishingLogic.tension_level(0.9), 2, "장력 높으면 위험")
	_eq(FishingLogic.tension_level(FishingLogic.TENSION_DANGER), 2, "위험 경계값")

	# 실패 뒤: 바로 누르면 그대로, 조금 지나 누르면 바로 힘 모으기
	var l := _new_logic(5)
	_cast(l)
	l.press()
	_eq(l.state, S.FAILED, "기다리다 누르면 실패")
	_eq(l.can_skip_fail(), false, "실패 직후엔 못 건너뜀")
	l.press()
	_eq(l.state, S.FAILED, "실패 직후 누르면 그대로")
	l.update(FishingLogic.FAIL_SKIP_AFTER + 0.05, false)
	_eq(l.can_skip_fail(), true, "조금 지나면 건너뛸 수 있음")
	l.press()
	_eq(l.state, S.CHARGING, "실패 안내 건너뛰고 바로 힘 모으기")
	_eq(l.power, 0.0, "힘은 0부터")
	_eq(l.break_progress(), 0.0, "줄다리기 아닐 때 끊김 진행 0")
	for r in ["nibble", "early", "missed", "broke", "slack", "escaped"]:
		_eq(FishingLogic.fail_short(r).is_empty(), false, "실패 짧은 글자 %s" % r)
		_eq(FishingLogic.fail_message(r).is_empty(), false, "실패 안내 %s" % r)

	# 줄이 끊어지기 직전: 장력이 끝까지 찬 채로 버티면 끊김 진행이 차오른다
	var b := _new_logic(9)
	_cast(b)
	_run_until(b, [S.BITE], func(_x): return false, 30.0)
	b.press()
	_eq(b.state, S.REELING, "챔질하면 줄다리기")
	b.tension = 1.0
	b.update(FishingLogic.BREAK_HOLD * 0.5, true)
	_eq(b.state == S.REELING and b.break_progress() > 0.0, true, "장력 끝까지면 끊김 진행 (%.2f)" % b.break_progress())


func _test_fishing() -> void:
	var S := FishingLogic.State
	var never := func(_x): return false
	var always := func(_x): return true
	# 요령: 장력이 높으면 손을 떼고, 물고기가 옆으로 가면 반대로 끈다
	var smart := func(x):
		x.steer = -x.run_dir
		return x.tension < 0.8

	var l := _new_logic(3)
	l.press()
	_eq(l.state, S.CHARGING, "누르면 힘 모으기")
	_run_until(l, [], always, 0.5)
	l.release()
	_eq(l.state, S.CASTING, "떼면 던지기")
	_eq(l.cast_power > 0.25 and l.cast_power < 0.5, true, "0.5초 힘 (%.2f)" % l.cast_power)
	_run_until(l, [S.WAITING], never, 2.0)
	_eq(l.state, S.WAITING, "던진 뒤 기다리기")

	l.press()
	_eq(l.state, S.FAILED, "기다리는 중 누르면 끝남")
	_eq(l.fail_reason in ["retrieved", "nibble"], true, "조용할 땐 회수, 톡톡일 땐 헛챔질")
	_run_until(l, [S.READY], never, 3.0)
	_eq(l.state, S.READY, "실패 후 다시 준비")

	_cast(l)
	_run_until(l, [S.BITE], never, 10.0)
	_eq(l.state, S.BITE, "입질")
	_run_until(l, [S.FAILED], never, 3.0)
	_eq(l.fail_reason, "missed", "입질 놓침")
	_run_until(l, [S.READY], never, 3.0)

	_cast(l)
	_run_until(l, [S.BITE], never, 10.0)
	l.press()
	_eq(l.state, S.REELING, "챔질 성공")
	_eq(l.fish_id, "bolak", "첫 물고기는 볼락")
	_run_until(l, [S.CAUGHT, S.FAILED], smart, 60.0)
	_eq(l.state, S.CAUGHT, "장력 조절하면 잡힌다")
	_eq(l.catch_count, 1, "잡은 수")
	_eq(l.forgiving, false, "첫 물고기 뒤엔 판정 정상화")
	l.acknowledge()
	_eq(l.state, S.READY, "카드 닫기")

	var l2 := _new_logic(5)
	_cast(l2)
	_run_until(l2, [S.BITE], never, 10.0)
	l2.press()
	_run_until(l2, [S.CAUGHT, S.FAILED], always, 30.0)
	_eq(l2.fail_reason, "broke", "계속 감으면 줄이 끊김")

	var l3 := _new_logic(6)
	_cast(l3)
	_run_until(l3, [S.BITE], never, 10.0)
	l3.press()
	_run_until(l3, [S.CAUGHT, S.FAILED], never, 30.0)
	_eq(l3.fail_reason, "slack", "안 감으면 바늘이 빠짐")

	var caught := 0
	for seed_value in 20:
		var l4 := _new_logic(100 + seed_value)
		l4.catch_count = 1
		l4.forgiving = false
		_cast(l4)
		_run_until(l4, [S.BITE], never, 20.0)
		l4.press()
		_run_until(l4, [S.CAUGHT, S.FAILED], smart, 60.0)
		if l4.state == S.CAUGHT:
			caught += 1
	_eq(caught >= 16, true, "보통 판정에서도 요령 있게 하면 대부분 잡힘 (%d/20)" % caught)

	# 물고기가 차고 나갈 때 반대로 끌지 않으면 잘 못 잡는다
	var lazy_caught := 0
	var lazy := func(x):
		x.steer = 0.0
		return x.tension < 0.8
	for seed_value in 20:
		var l5 := _new_logic(100 + seed_value)
		l5.catch_count = 1
		l5.forgiving = false
		_cast(l5)
		_run_until(l5, [S.BITE], never, 20.0)
		l5.press()
		_run_until(l5, [S.CAUGHT, S.FAILED], lazy, 60.0)
		if l5.state == S.CAUGHT:
			lazy_caught += 1
	_eq(lazy_caught < caught, true, "반대로 끌어야 더 잘 잡힘 (%d < %d)" % [lazy_caught, caught])


## 재미 요소: 캐스팅 포인트, 챔질 판정, 연속 PERFECT, 줄다리기, 희귀도
func _test_fun() -> void:
	var S := FishingLogic.State
	var never := func(_x): return false

	# 포인트에 맞춰 던지면 NICE, 많이 빗나가면 판정 없음
	var a := _new_logic(31)
	a.point_depth = 0.5
	a.press()
	a.power = 0.5 / a.cast_mult
	a.release()
	_eq(a.cast_grade, "nice", "포인트에 딱 맞추면 NICE CAST")
	var b := _new_logic(31)
	b.point_depth = 0.9
	b.press()
	b.power = 0.2
	b.release()
	_eq(b.cast_grade, "", "많이 빗나가면 판정 없음")

	# NICE CAST는 입질이 빠르다 (같은 난수로 비교)
	var waits := []
	for depth in [0.5, 0.95]:
		var l := _new_logic(32)
		l.catch_count = 1
		l.forgiving = false
		l.point_depth = depth
		l.press()
		l.power = 0.5
		l.release()
		_run_until(l, [S.WAITING], never, 2.0)
		var t := 0.0
		while l.state == S.WAITING and t < 30.0:
			l.update(1.0 / 60.0, false)
			t += 1.0 / 60.0
		waits.append(t)
	_eq(waits[0] < waits[1], true, "NICE CAST면 입질이 빠름 (%.1fs < %.1fs)" % [waits[0], waits[1]])

	# 찌가 잠기는 한가운데에 채면 PERFECT, 너무 일찍 채면 GOOD
	var grades := []
	for when in [0.5, 0.1]:
		var l := _new_logic(33)
		_cast(l)
		_run_until(l, [S.BITE], never, 10.0)
		while l.bite_depth < when:
			l.update(1.0 / 60.0, false)
		l.press()
		grades.append(l.hook_grade)
		_eq(l.state, S.REELING, "챔질 성공 (%.1f)" % when)
	_eq(grades, ["perfect", "good"], "챔질 판정")

	# PERFECT로 시작하면 물고기 체력이 깎인 채로 시작
	var p := _new_logic(34)
	_cast(p)
	_run_until(p, [S.BITE], never, 10.0)
	while p.bite_depth < 0.5:
		p.update(1.0 / 60.0, false)
	p.press()
	_eq(p.fish_hp < 1.0, true, "PERFECT면 물고기 체력이 덜 찬 채로 시작")
	_eq(p.perfect_streak, 1, "연속 PERFECT 1")
	p.perfect_streak = FishingLogic.STREAK_HOT
	_eq(p.is_hot(), true, "연속 PERFECT 3번이면 물 오름")

	# 반대로 끌면 물고기 체력이 더 빨리 깎인다
	var hp := []
	for counter in [true, false]:
		var l := _new_logic(35)
		l.catch_count = 1
		l.forgiving = false
		_cast(l)
		_run_until(l, [S.BITE], never, 20.0)
		l.press()
		l.steer = -1.0 if counter else 0.0
		l.tension = 0.3
		for i in 30:
			l.run_dir = 1
			l._run_time = 5.0
			l.update(1.0 / 60.0, true)
		hp.append(l.fish_hp)
	_eq(hp[0] < hp[1], true, "반대로 버티면 체력이 더 깎임 (%.2f < %.2f)" % [hp[0], hp[1]])

	# 지친 물고기는 빨리 끌려온다
	var e := _new_logic(36)
	_cast(e)
	_run_until(e, [S.BITE], never, 10.0)
	e.press()
	e.fish_hp = 0.0
	e.update(1.0 / 60.0, true)
	_eq(e.exhausted, true, "체력이 0이면 지침")
	var d0 := e.distance
	for i in 30:
		e.update(1.0 / 60.0, true)
	_eq(d0 - e.distance > 0.15, true, "지친 물고기는 빨리 끌려옴 (%.2f)" % (d0 - e.distance))

	# 어종: 학공치는 먼 물, 볼락은 가까운 물. 미끼를 좋아하면 잘 나온다
	var near := FishDB.weight_of("hakgongchi", {"brightness": 1.0, "depth": 0.05})
	var far := FishDB.weight_of("hakgongchi", {"brightness": 1.0, "depth": 0.95})
	_eq(far > near * 3.0, true, "학공치는 먼 물")
	_eq(FishDB.weight_of("bolak", {"brightness": 0.0, "depth": 0.1}) > FishDB.weight_of("bolak", {"brightness": 0.0, "depth": 0.9}), true, "볼락은 가까운 물")
	_eq(FishDB.weight_of("ureok", {"bait": "worm"}) > FishDB.weight_of("ureok", {"bait": "krill"}), true, "우럭은 청갯지렁이를 좋아함")
	_eq(FishDB.weight_of("gamseongdom", {"rare_boost": 2.0}) > FishDB.weight_of("gamseongdom", {}), true, "물 오름은 희귀 어종을 늘림")
	_eq(FishDB.weight_of("bolak", {"rare_boost": 2.0}), FishDB.weight_of("bolak", {}), "물 오름은 일반 어종엔 영향 없음")
	for id in FishDB.FISH:
		var f := FishDB.get_fish(id)
		_eq(ArtSlot.has_art("fish_" + id), true, "%s 그림" % id)
		_eq(FishDB.RARITY.has(f.rarity), true, "%s 희귀도" % id)
		_eq(FishDB.stars(id, f.min_cm), 1, "%s 작으면 별 하나" % id)
		_eq(FishDB.stars(id, f.max_cm), 3, "%s 크면 별 셋" % id)
		_eq(FishDB.is_trophy(id, f.max_cm), true, "%s 최대 크기는 대물" % id)
		_eq(FishDB.value_of(id, f.max_cm) > FishDB.value_of(id, f.min_cm), true, "%s 클수록 비쌈" % id)
	_eq(FishDB.value_of("gamseongdom", 40.0) > FishDB.value_of("bolak", 20.0), true, "전설 어종은 비쌈")
	for id in BaitDB.BAITS:
		_eq(ArtSlot.has_art(BaitDB.icon_art(id)), true, "%s 미끼 그림" % id)
		for f in BaitDB.bait(id).likes:
			_eq(FishDB.FISH.has(f), true, "%s 미끼가 좋아하는 %s" % [id, f])


## 오늘의 바다 카드, 주문, 미끼 사기
func _test_sea_day() -> void:
	_eq(SeaDay.of(5), SeaDay.of(5), "같은 날은 같은 바다")
	_eq(SeaDay.of(1).tide, "7물", "첫날은 7물")
	_eq(SeaDay.of(1).weather, "sunny", "첫날은 맑음")
	var seen := {}
	for d in range(2, 40):
		seen[SeaDay.of(d).weather] = true
	_eq(seen.size() >= 3, true, "날씨가 여러 가지 (%d)" % seen.size())
	_eq(SeaDay.best_fish(SeaDay.of(1), 0.0, 2).size(), 2, "잘 무는 고기 두 종")
	_eq(Orders.of(1), {}, "첫날은 주문 없음")
	var o := Orders.of(3)
	_eq(FishDB.FISH.has(o.fish), true, "주문 어종")
	_eq(o.reward > 0, true, "주문 보상")
	_eq(Orders.matches(o, o.fish, o.min_cm), true, "조건 맞는 물고기")
	_eq(Orders.matches(o, o.fish, o.min_cm - 1.0), false, "너무 작으면 안 받음")

	var gs = load("res://scripts/autoload/game_state.gd").new()
	gs.flags = {"met_sundeok": true, "met_mansu": true, "met_junho": true, "met_kyungja": true, "met_bokja": true, "met_yongpal": true, "met_taesik": true}.duplicate()
	gs.day = 3
	gs.money = 0
	var got := 0
	for i in o.count:
		got = gs.offer_to_order(o.fish, o.min_cm + 1.0)
	_eq(got, o.reward, "주문을 다 채우면 보상")
	_eq(gs.order_done, true, "주문 완료")
	_eq(gs.money, o.reward, "보상만큼 돈")
	_eq(gs.offer_to_order(o.fish, o.min_cm + 1.0), 0, "완료 뒤에는 더 안 받음")
	gs.money = 5000
	_eq(gs.buy_bait("worm"), "", "청갯지렁이 사기")
	_eq(gs.bait_count("worm"), 10, "10개 들어옴")
	_eq(gs.buy_bait("krill"), "창고에 많이 있어요.", "크릴은 안 팜")
	_eq(gs.buy_bait("shrimp"), "돈이 모자라요.", "돈 모자람")
	gs.equipped_bait = "worm"
	gs.use_bait()
	_eq(gs.bait_count("worm"), 9, "미끼 하나 씀")
	gs.baits["worm"] = 1
	gs.use_bait()
	_eq(gs.equipped_bait, "krill", "다 쓰면 크릴로")
	gs.equipped_bait = "krill"
	gs.use_bait()
	_eq(gs.bait_count("krill"), -1, "크릴은 끝이 없음")
	gs.end_day()
	_eq(gs.order_filled + int(gs.order_done), 0, "다음 날 주문 새로")
	gs.free()


func _test_locations() -> void:
	for id in Locations.LIST:
		var loc := Locations.get_loc(id)
		var p: Vector2 = loc.pos
		_eq(p.x >= 0.0 and p.x <= 1.0 and p.y >= 0.0 and p.y <= 1.0, true, "%s 위치 범위" % id)
		var scene: String = loc.scene
		if not scene.is_empty():
			_eq(ResourceLoader.exists(scene), true, "%s 장면 파일 존재" % id)
	_eq(Locations.travel_minutes("shop", "shop"), 0, "같은 장소 이동 0분")
	_eq(Locations.travel_minutes("shop", "tackle"), 5, "바로 옆 가게는 최소 5분")
	_eq(Locations.travel_minutes("shop", "breakwater") > Locations.travel_minutes("shop", "tackle"), true, "방파제는 옆 가게보다 멀다")
	_eq(Locations.is_visible("cave", {}), false, "숨은 장소는 열리기 전에 안 보임")
	_eq(Locations.is_visible("cave", {"found_sea_cave": true}), true, "찾으면 숨은 장소가 보임")
	_eq(Locations.is_visible("rocks", {}), false, "잠긴 보통 장소도 지도에 안 보임 (점 없음)")
	_eq(Locations.is_visible("rocks", {"learned_tide": true}), true, "열리면 보임")
	_eq(Locations.travel_minutes("shop", "breakwater"), Locations.travel_minutes("breakwater", "shop"), "이동 시간 대칭")
	_eq(Locations.travel_minutes("shop", "breakwater") % 5, 0, "5분 단위")
	_eq(Locations.travel_minutes("shop", "island") > Locations.travel_minutes("shop", "rocks"), true, "섬은 배 시간 추가")
	_eq(Locations.is_unlocked("shop", {}), true, "식당은 처음부터 열림")
	_eq(Locations.is_unlocked("rocks", {}), false, "갯바위는 잠김")
	_eq(Locations.is_unlocked("rocks", {"learned_tide": true}), true, "물때 배우면 갯바위 열림")


func _test_gear() -> void:
	var S := FishingLogic.State
	_eq(GearDB.RODS.size(), 10, "낚싯대 10단계")
	_eq(GearDB.REELS.size(), 10, "릴 10단계")
	for id in GearDB.RODS:
		_eq(ArtSlot.has_art(GearDB.blank_art(id)), true, "%s 대 몸통 그림" % id)
		_eq(ArtSlot.has_art(GearDB.float_art(id)), true, "%s 찌 그림" % id)
	for id in GearDB.REELS:
		_eq(ArtSlot.has_art(GearDB.butt_art(id)), true, "%s 밑동 그림" % id)
	var prev := 0.0
	for i in range(1, 11):
		var r := GearDB.rod("rod_%d" % i)
		_eq(r.cast >= prev, true, "낚싯대 %d단계 던지기 거리" % i)
		prev = r.cast
	_eq(GearDB.rod("없는것").name, GearDB.rod(GearDB.DEFAULT_ROD).name, "없는 낚싯대는 기본값")
	_eq(GearDB.shop_list("rod").has(GearDB.DEFAULT_ROD), false, "처음 장비는 진열 안 함")
	_eq(GearDB.shop_list("rod").has("rod_8"), false, "다음 바다 장비는 진열 안 함")
	_eq(GearDB.shop_list("reel")[0], "reel_2", "릴 진열 순서")

	var basic := _new_logic(9)
	GearDB.apply(basic, "rod_1", "reel_1")
	var good := _new_logic(9)
	GearDB.apply(good, "rod_4", "reel_3")
	_eq(good.tension_mult < basic.tension_mult, true, "좋은 장비는 장력이 덜 오름")
	_eq(good.reel_mult > basic.reel_mult, true, "좋은 릴은 빨리 감김")

	# 같은 힘으로 던지면 좋은 낚싯대가 더 멀리
	for l in [basic, good]:
		l.press()
		_run_until(l, [], func(_x): return true, 0.5)
		l.release()
	_eq(good.cast_power > basic.cast_power, true, "좋은 낚싯대가 더 멀리 (%.2f > %.2f)" % [good.cast_power, basic.cast_power])

	# 계속 감기만 할 때 좋은 장비가 더 오래 버틴다
	var times := []
	for gear in [["rod_1", "reel_1"], ["rod_4", "reel_3"]]:
		var l := _new_logic(11)
		GearDB.apply(l, gear[0], gear[1])
		_cast(l)
		_run_until(l, [S.BITE], func(_x): return false, 10.0)
		l.press()
		var t := 0.0
		while l.state == S.REELING and t < 30.0:
			l.update(1.0 / 60.0, true)
			t += 1.0 / 60.0
		times.append(t)
	_eq(times[1] > times[0], true, "좋은 장비가 더 오래 버팀 (%.1fs > %.1fs)" % [times[1], times[0]])


## 실제 찌낚시 규칙 (docs/찌낚시_동작_조사.md)
func _test_realism() -> void:
	var S := FishingLogic.State
	# 견제하면 입질이 빨리 온다
	var waits := []
	for mend in [false, true]:
		var l := _new_logic(21)
		l.catch_count = 1
		l.forgiving = false
		_cast(l)
		var t := 0.0
		while l.state == S.WAITING and t < 30.0:
			l.update(1.0 / 60.0, false, mend)
			t += 1.0 / 60.0
		waits.append(t)
	_eq(waits[1] < waits[0], true, "견제하면 입질이 빨라짐 (%.1fs < %.1fs)" % [waits[1], waits[0]])

	# 견제하지 않으면 찌가 흘러가고, 견제하면 멈춘다
	var a := _new_logic(22)
	_cast(a)
	for i in 60:
		a.update(1.0 / 60.0, false, false)
	var drifted := a.drift
	for i in 60:
		a.update(1.0 / 60.0, false, true)
	_eq(drifted > 0.0, true, "찌가 조류에 흘러감")
	_eq(is_equal_approx(a.drift, drifted) or a.state != S.WAITING, true, "견제하면 흐름이 멈춤")

	# 입질 중에는 찌가 점점 깊이 잠긴다
	var b := _new_logic(23)
	_cast(b)
	_run_until(b, [S.BITE], func(_x): return false, 10.0)
	var d0 := b.bite_depth
	for i in 20:
		b.update(1.0 / 60.0, false)
	_eq(b.bite_depth > d0, true, "입질 중 찌가 점점 잠김")


func _test_brightness() -> void:
	_eq(SeaBackdrop.sun_path(4 * 60).z, 0.0, "새벽 4시에는 해 없음")
	_eq(SeaBackdrop.sun_path(6 * 60).y < SeaBackdrop.sun_path(5 * 60 + 10).y, true, "해가 떠오름")
	_eq(SeaBackdrop.sun_path(10 * 60).y < SeaBackdrop.sun_path(7 * 60).y, true, "아침 내내 올라감")
	_eq(SeaBackdrop.sun_path(10 * 60).x > SeaBackdrop.sun_path(6 * 60).x, true, "동쪽을 보니 해는 오른쪽(남쪽)으로 감")
	_eq(SeaBackdrop.sun_path(15 * 60).z, 0.0, "오후에는 해가 등 뒤(서쪽)로 넘어가 안 보임")
	_eq(SeaBackdrop.sun_path(21 * 60).z, 0.0, "밤에는 해 없음")
	var sch := SeaBackdrop.FISHING_SCHEDULE
	_eq(SeaBackdrop.schedule_mix(sch, 2 * 60)[2], 0.0, "새벽 2시는 밤 그림 그대로")
	_eq(sch[SeaBackdrop.schedule_mix(sch, 12 * 60)[0]][1], "bg_fishing_morning_v", "낮 12시는 아침 그림")
	var mx: Array = SeaBackdrop.schedule_mix(sch, 6 * 60 + 30)
	_eq(mx[2] > 0.0 and mx[2] < 1.0, true, "6시 반은 새벽과 아침 사이")
	_eq(sch[SeaBackdrop.schedule_mix(sch, 23 * 60)[0]][1], "bg_fishing_night_v", "밤 11시는 밤 그림")
	for e in sch:
		_eq(ArtSlot.has_art(e[1]), true, "%s 그림" % e[1])
	var z := SeaBackdrop.sun_path(5 * 60 + 30).z
	_eq(z > 0.0 and z < 1.0, true, "해는 서서히 나타남 (%.2f)" % z)
	var prev := SeaBackdrop.sun_path(5 * 60)
	var smooth := true
	for m in range(5 * 60 + 1, 19 * 60 + 30):
		var p := SeaBackdrop.sun_path(m)
		if Vector2(p.x, p.y).distance_to(Vector2(prev.x, prev.y)) > 0.01:
			smooth = false
		prev = p
	_eq(smooth, true, "해가 1분에 조금씩만 움직임 (갑자기 튀지 않음)")
	_eq(FishingLogic.brightness_at(3 * 60), 0.0, "새벽 3시는 어두움")
	_eq(FishingLogic.brightness_at(6 * 60), 0.5, "새벽 6시는 반쯤 밝음")
	_eq(FishingLogic.brightness_at(12 * 60), 1.0, "낮 12시는 밝음")
	_eq(FishingLogic.brightness_at(18.5 * 60), 0.5, "저녁 6시 반은 반쯤 어두움")
	_eq(FishingLogic.brightness_at(22 * 60), 0.0, "밤 10시는 어두움")
	_eq(FishingLogic.brightness_at(25 * 60), 0.0, "자정 넘김도 처리")


## 바다 한 접시에서 가져온 어종, 레시피 데이터
func _test_catalog() -> void:
	_eq(Catalog.species_ids().size(), 71, "어종 71종")
	_eq(Catalog.recipe_ids().size(), 50, "레시피 50개")
	_eq(Catalog.species("bollak").get("name", ""), "볼락", "볼락 데이터")
	_eq(Catalog.flavor("salty").get("name", ""), "짠맛", "짠맛 데이터")
	_eq(Catalog.month_factor("bollak", 7) < Catalog.month_factor("bollak", 12), true, "볼락은 여름보다 겨울")
	for id in Catalog.recipe_ids():
		var r := Catalog.recipe(id)
		if not Catalog.species(r.species).has("id"):
			_eq(r.species, "있는 어종", "%s 레시피 어종" % id)
		if not ArtSlot.has_art(Catalog.dish_art(id)):
			_eq(id, "그림 있음", "요리 그림")
		if not ArtSlot.has_art(Catalog.tool_art(r.tool)):
			_eq(r.tool, "그림 있음", "조리도구 그림")
	for id in FishDB.FISH:
		var f := FishDB.get_fish(id)
		_eq(Catalog.species(f.catalog).has("id"), true, "%s 카탈로그 연결" % id)
		_eq(Catalog.recipe(f.grill).get("species", ""), f.catalog, "%s 구이 레시피" % id)
	_eq(ArtSlot.has_art("kitchen/grill"), true, "화로 그림")


func _test_cooking() -> void:
	var P := CookingLogic.Phase
	_eq(CookingLogic.judge_season(0.58, 0.58), "good", "간 딱 맞음")
	_eq(CookingLogic.judge_season(0.2, 0.58), "bland", "싱거움")
	_eq(CookingLogic.judge_season(0.9, 0.58), "strong", "짬")
	_eq(CookingLogic.judge_grill(0.3), "raw", "덜 익음")
	_eq(CookingLogic.judge_grill(0.75), "good", "노릇함")
	_eq(CookingLogic.judge_grill(0.95), "burnt", "탐")

	var c := CookingLogic.new()
	c.setup(Catalog.recipe("bollak-gui"))
	_eq(c.flavor, "salty", "볼락구이는 짠맛")
	_eq(is_equal_approx(c.target, 0.58), true, "볼락구이 목표 간")
	c.update(1.0, true)
	_eq(c.amount, 0.0, "누르기 전에는 간이 안 들어감")
	c.press()
	var t := 0.0
	while c.amount < c.target and t < 5.0:
		c.update(1.0 / 60.0, true)
		t += 1.0 / 60.0
	c.release()
	_eq(c.phase, P.GRILL, "간 맞추면 굽기로")
	_eq(c.seasoning, "good", "목표만큼 뿌리면 딱 맞음")
	_eq(c.flavor_review(), "간이 딱 맞아요", "손님 평")
	while c.doneness < 0.74:
		c.update(1.0 / 60.0, false)
	c.press()
	_eq(c.phase, P.DONE, "불에서 내리면 끝")
	_eq(c.cooking, "good", "노릇하게 구움")
	_eq(c.stars(), 3, "별 셋")

	var b := CookingLogic.new()
	b.press()
	for i in 600:
		b.update(1.0 / 60.0, true)
	_eq(b.seasoning, "strong", "계속 누르면 짬")
	for i in 1200:
		b.update(1.0 / 60.0, false)
	_eq(b.cooking, "burnt", "내버려 두면 탐")
	_eq(b.stars(), 1, "별 하나")


func _test_economy() -> void:
	var gs = load("res://scripts/autoload/game_state.gd").new()
	gs.money = 85000
	_eq(gs.buy_gear("rod", "rod_2"), "", "갯바위 찌낚싯대 구매")
	_eq(gs.money, 5000, "값만큼 빠짐")
	_eq("rod_2" in gs.owned_rods, true, "가진 낚싯대에 추가")
	_eq(gs.spent_today, 80000, "장부 지출")
	_eq(gs.buy_gear("rod", "rod_2"), "이미 가지고 있어요.", "중복 구매 막기")
	_eq(gs.buy_gear("reel", "reel_2"), "돈이 모자라요.", "돈 모자람")
	_eq(gs.buy_gear("reel", "없는것"), "없는 물건이에요.", "없는 물건")
	gs.earn(7000)
	_eq(gs.money, 12000, "매출")
	gs.inventory = [{"id": "mangsang", "size": 20.0}, {"id": "bolak", "size": 16.0}]
	_eq(gs.take_fish("bolak").get("size", 0.0), 16.0, "볼락 꺼내기")
	_eq(gs.inventory.size(), 1, "아이스박스에서 빠짐")
	_eq(gs.take_fish("noraemi"), {}, "없는 어종")
	gs.caught_today = [{"id": "bolak", "size": 16.0}]
	gs.end_day(6 * 60)
	_eq(gs.day, 2, "다음 날")
	_eq(gs.time_minutes, 360, "아침 6시")
	_eq(gs.caught_today.size() + gs.sales_today + gs.spent_today, 0, "하루 기록 비움")
	gs.free()
	for id in GearDB.RODS:
		_eq(ArtSlot.has_art(GearDB.icon_art(GearDB.rod(id))), true, "%s 아이콘" % id)
	for id in GearDB.REELS:
		_eq(ArtSlot.has_art(GearDB.icon_art(GearDB.reel(id))), true, "%s 아이콘" % id)


func _test_sound() -> void:
	var SoundScript = load("res://scripts/autoload/sound.gd")
	for id in SoundScript.BGM:
		_eq(SoundScript.has_bgm(id), true, "배경음악 %s" % id)
	for id in ["whoosh", "plop", "nibble", "bite", "strike", "reel", "land", "catch", "newfish", "snap", "slip", "bad",
			"sizzle", "tap", "good", "okay", "door", "coin", "sold", "surge", "pop"]:
		_eq(SoundScript.has_sfx(id), true, "효과음 %s" % id)
	_eq(SoundScript.has_sfx("없는소리"), false, "없는 효과음")


## 공통 헤더와 메뉴의 글자, 가방 묶기
func _test_header() -> void:
	_eq(HudText.date_text(3), "3월 3일", "날짜")
	_eq(HudText.clock_text(5 * 60 + 7), "새벽 05:07", "새벽 시각")
	_eq(HudText.clock_text(9 * 60 + 30), "오전 09:30", "오전 시각")
	_eq(HudText.clock_text(13 * 60 + 5), "오후 13:05", "오후 시각")
	_eq(HudText.clock_text(19 * 60), "저녁 19:00", "저녁 시각")
	_eq(HudText.clock_text(22 * 60 + 40), "밤 22:40", "밤 시각")
	_eq(HudText.clock_text(24 * 60 + 10), "새벽 00:10", "자정 넘김")
	var info := SeaDay.of(1)
	_eq(HudText.sea_text(info), "맑음 · 7물 물때 좋음", "날씨와 물때")
	var g: Dictionary = HudText.group_inventory([{"id": "bolak", "size": 18.0}, {"id": "bolak", "size": 22.5}, {"id": "ureok", "size": 30.0}])
	_eq(g.size(), 2, "가방은 어종별로 묶음")
	_eq(g.bolak.count, 2, "볼락 두 마리")
	_eq(g.bolak.best, 22.5, "가장 큰 볼락")
	_eq(g.bolak.value, FishDB.value_of("bolak", 18.0) + FishDB.value_of("bolak", 22.5), "볼락 값 합")
	_eq(HudText.group_inventory([]), {}, "빈 가방")


func _test_day_flow() -> void:
	# 시간대: 아침 05~09, 밤 21~23:30 (11-19 하루 두 번으로 줄임)
	_eq(DayFlow.FISHING_SLOTS.size(), 2, "낚시 시간대는 아침과 밤 두 개")
	_eq(DayFlow.fishing_slot(5 * 60).get("id", ""), "morning", "05:00 아침 낚시")
	_eq(DayFlow.fishing_slot(8 * 60).get("id", ""), "morning", "08:00도 아침 낚시")
	_eq(DayFlow.can_fish(9 * 60), false, "9시부터는 낚시 못 함")
	_eq(DayFlow.can_fish(12 * 60), false, "한낮엔 낚시 못 함")
	_eq(DayFlow.can_fish(19 * 60), false, "영업 시간엔 낚시 못 함")
	_eq(DayFlow.fishing_slot(22 * 60).get("id", ""), "night", "22:00 밤 낚시")
	_eq(DayFlow.fishing_end(6 * 60), 9 * 60, "아침 낚시는 9시에 끝")
	_eq(DayFlow.fishing_end(7 * 60), 9 * 60, "늦잠 잔 날도 9시에 끝")
	# 밤 낚시하면 늦잠
	_eq(DayFlow.wake_time(false), 5 * 60, "보통은 새벽 5시 기상")
	_eq(DayFlow.wake_time(true), 7 * 60, "밤 낚시 뒤엔 7시 기상 (아침 낚시 두 시간 줄어듦)")
	var gs = load("res://scripts/autoload/game_state.gd").new()
	gs.night_fished = true
	gs.opened_today = true
	gs.end_day()
	_eq(gs.time_minutes, 7 * 60, "end_day: 밤 낚시 다음 날 늦잠")
	_eq(gs.night_fished or gs.opened_today, false, "end_day: 하루 표시 초기화")
	gs.end_day()
	_eq(gs.time_minutes, 5 * 60, "end_day: 그다음 날은 새벽 5시")
	gs.free()
	# 가게
	_eq(DayFlow.can_open_shop(12 * 60, false), true, "낮에도 가게 열기(18시로 건너뜀)")
	_eq(DayFlow.can_open_shop(19 * 60, true), false, "이미 열었으면 못 엶")
	_eq(DayFlow.can_open_shop(22 * 60, false), false, "21시 넘으면 못 엶")
	# 값
	_eq(DayFlow.dish_price("bolak", 15.0) >= DayFlow.DISH_MIN, true, "구이 최소값")
	_eq(DayFlow.dish_price("gamseongdom", 40.0) > DayFlow.dish_price("bolak", 15.0), true, "감성돔 구이가 더 비쌈")
	_eq(DayFlow.special_price("bolak", 20.0, 3) > DayFlow.special_price("bolak", 20.0, 1), true, "별 많을수록 비쌈")
	var n := DayFlow.guest_count(5)
	_eq(n >= DayFlow.GUESTS_MIN and n <= DayFlow.GUESTS_MAX, true, "손님 수 범위")
	_eq(DayFlow.guest_count(5), n, "같은 날 같은 손님 수")
	# 보통 손님: 생선이 넉넉하면 모두 받고, 모자라면 돌아간다
	var many := []
	for i in 8:
		many.append({"id": "bolak", "size": 14.0 + i})
	var r := DayFlow.serve_regulars(5, many)
	_eq(r.served.size(), n, "생선 넉넉하면 다 받음")
	_eq(r.missed, 0, "돌아간 손님 없음")
	_eq(r.served[0].size, 21.0, "큰 생선부터 낸다")
	var sum := 0
	for g in r.served:
		sum += g.price
	_eq(r.sales, sum, "매출 합계")
	var few := DayFlow.serve_regulars(5, [{"id": "bolak", "size": 15.0}])
	_eq(few.served.size(), 1, "생선 하나면 한 명만")
	_eq(few.missed, n - 1, "나머지는 돌아감")
	_eq(DayFlow.serve_regulars(5, []).sales, 0, "생선 없으면 매출 0")
	# 특별 손님: 첫날은 없고 둘째 날부터 주문서 낸 사람
	_eq(DayFlow.special_guest(1).is_empty(), true, "첫날 특별 손님 없음")
	_eq(DayFlow.special_guest(2).get("name", ""), Orders.of(2).customer, "특별 손님은 주문서 낸 사람")
	# 안내
	_eq(DayFlow.next_hint(5 * 60, false).contains("아침 낚시"), true, "아침 안내")
	_eq(DayFlow.next_hint(13 * 60, false).contains("저녁 6시"), true, "낮 안내: 가게 여는 시각")
	_eq(DayFlow.next_hint(13 * 60, false).contains("마을"), true, "낮 안내: 마을 일")
	_eq(DayFlow.next_hint(21 * 60 + 30, true).contains("늦잠"), true, "밤 낚시 안내")


func _test_garden() -> void:
	_eq(CropDB.SLOTS, 4, "텃밭은 네 칸")
	for id in CropDB.CROPS:
		var c := CropDB.crop(id)
		_eq(c.price > 0 and c.days > 0 and c.amount > 0, true, "%s 값, 날, 양" % id)
	var g := CropDB.new_garden()
	_eq(g.size(), 4, "빈 칸 네 개")
	_eq(CropDB.stage(g[0], 1), CropDB.EMPTY, "처음엔 빈 칸")
	_eq(CropDB.plant_error(g, 4, "mu", 10000), "없는 이랑이에요.", "다섯째 이랑은 없음")
	_eq(CropDB.plant_error(g, 0, "sugar", 10000), "없는 씨앗이에요.", "없는 씨앗")
	_eq(CropDB.plant_error(g, 0, "mu", 100), "돈이 모자라요.", "씨앗 값 모자람")
	var gs = load("res://scripts/autoload/game_state.gd").new()
	gs.money = 20000
	gs.day = 3
	_eq(gs.plant_crop(0, "daepa"), "", "대파 심기")
	_eq(gs.plant_crop(1, "mu"), "", "무 심기")
	_eq(gs.plant_crop(2, "baechu"), "", "배추 심기")
	_eq(gs.plant_crop(3, "gochu"), "", "고추 심기")
	_eq(CropDB.kinds(gs.garden).size(), 4, "한 번에 네 종류")
	_eq(gs.money, 20000 - 1000 - 2000 - 3000 - 2000, "씨앗 값이 나감")
	_eq(gs.plant_crop(0, "mu"), "이미 심은 이랑이에요.", "심은 이랑에는 못 심음")
	_eq(CropDB.stage(gs.garden[0], gs.day), CropDB.GROWING, "심은 날은 자라는 중")
	_eq(gs.harvest_crop(0), "", "덜 자라면 못 거둠")
	gs.end_day()
	gs.end_day()
	_eq(CropDB.stage(gs.garden[0], gs.day), CropDB.READY, "대파는 이틀이면 다 자람")
	_eq(CropDB.stage(gs.garden[1], gs.day), CropDB.GROWING, "무는 사흘 걸림")
	_eq(CropDB.days_left(gs.garden[1], gs.day), 1, "무는 하루 남음")
	_eq(CropDB.growth(gs.garden[2], gs.day), 0.5, "배추는 절반 자람")
	_eq(gs.harvest_crop(0), "daepa", "대파 수확")
	_eq(int(gs.produce.get("daepa", 0)), 4, "대파 네 단")
	_eq(CropDB.stage(gs.garden[0], gs.day), CropDB.EMPTY, "거두면 빈 칸")
	_eq(gs.plant_crop(0, "kkaennip"), "", "빈 칸에 다시 심기")
	_eq(CropDB.row_art({}, 5, 0), "", "빈 이랑은 지도 조각 없음")
	for id in CropDB.CROPS:
		for st in [CropDB.GROWING, CropDB.READY]:
			for k in CropDB.SLOTS:
				var p := CropDB.ROW_ART_DIR + "%s_%s_%d.png" % [id, st, k]
				_eq(ResourceLoader.exists(p), true, "지도 조각 " + p.get_file())
	_eq(CropDB.row_art({"crop": "mu", "day": 1}, 1, 2).get_file(), "mu_growing_2.png", "자라는 무 조각")
	_eq(CropDB.row_art({"crop": "mu", "day": 1}, 9, 3).get_file(), "mu_ready_3.png", "다 자란 무 조각")
	gs.free()
	_eq(Locations.is_unlocked("garden", {}), true, "텃밭은 처음부터 열림")
	_eq(Locations.is_unlocked("coop", {}), false, "닭장은 처음엔 잠김")
	_eq(Locations.is_unlocked("coop", {"coop_open": true}), true, "이야기가 진행되면 닭장 열림")


func _test_save() -> void:
	var path := "user://test_save.dat"
	DirAccess.remove_absolute(path)
	var gs = load("res://scripts/autoload/game_state.gd").new()
	_eq(gs.has_save(path), false, "저장이 없으면 없다고")
	_eq(gs.load_game(path), false, "저장이 없으면 불러오기 실패")
	var names := SaveGame.fields(gs)
	_eq("money" in names and "garden" in names and "flags" in names, true, "돈, 텃밭, 진행 표시를 저장")
	_eq("vibration_on" in names or "_player_regex" in names, false, "설정과 안쪽 변수는 저장 안 함")
	gs.player_name = "하늘"
	gs.shop_name = "갯내음"
	gs.money = 123456
	gs.day = 7
	gs.time_minutes = 11 * 60 + 5
	gs.current_location = "breakwater"
	gs.inventory.append({"id": "ureok", "size": 31.4, "perfect": true})
	gs.dex["ureok"] = 31.4
	gs.owned_rods.append("rod_2")
	gs.equipped_rod = "rod_2"
	gs.baits["worm"] = 7
	gs.flags["first_guest_done"] = true
	gs.opened_today = true
	gs.reputation = 12
	gs.garden[1] = {"crop": "mu", "day": 6}
	gs.produce["daepa"] = 4
	gs.vibration_on = false
	_eq(gs.save_game(path), true, "저장")
	_eq(gs.has_save(path), true, "저장이 생김")

	var gs2 = load("res://scripts/autoload/game_state.gd").new()
	_eq(gs2.load_game(path), true, "불러오기")
	_eq(gs2.player_name, "하늘", "이름")
	_eq(gs2.shop_name, "갯내음", "가게 이름")
	_eq(gs2.money, 123456, "돈")
	_eq(typeof(gs2.money), TYPE_INT, "돈은 정수 그대로")
	_eq(gs2.day, 7, "날짜")
	_eq(gs2.time_minutes, 11 * 60 + 5, "시각")
	_eq(gs2.current_location, "breakwater", "있던 곳")
	_eq(gs2.inventory.size(), 1, "아이스박스")
	_eq(gs2.inventory[0].size, 31.4, "생선 크기")
	_eq(gs2.dex.get("ureok", 0.0), 31.4, "도감 기록")
	_eq(gs2.equipped_rod, "rod_2", "쓰던 낚싯대")
	_eq("rod_2" in gs2.owned_rods, true, "가진 낚싯대")
	_eq(gs2.bait_count("worm"), 7, "미끼 수")
	_eq(gs2.bait_count("krill"), -1, "크릴은 그대로 무제한")
	_eq(gs2.has_flag("first_guest_done"), true, "진행 표시")
	_eq(gs2.opened_today, true, "오늘 가게를 열었는지")
	_eq(gs2.reputation, 12, "평판")
	_eq(CropDB.stage(gs2.garden[1], gs2.day), CropDB.GROWING, "텃밭에 심은 무")
	_eq(int(gs2.produce.get("daepa", 0)), 4, "거둔 채소")
	_eq(gs2.vibration_on, true, "설정은 진행 저장에 안 들어감")
	# 불러온 것은 복사본이라 저장한 쪽을 바꿔도 영향이 없다
	gs.inventory.clear()
	_eq(gs2.inventory.size(), 1, "불러온 값은 따로")

	# 새로 시작: 진행만 처음으로, 설정은 그대로
	gs2.vibration_on = false
	gs2.reset_game()
	_eq(gs2.money, 180000, "새로 시작하면 처음 돈")
	_eq(gs2.day, 1, "새로 시작하면 1일차")
	_eq(gs2.player_name, gs2.DEFAULT_PLAYER_NAME, "이름도 처음으로")
	_eq(gs2.inventory.is_empty() and gs2.flags.is_empty() and gs2.dex.is_empty(), true, "가방, 진행, 도감 비움")
	_eq(gs2.owned_rods, [GearDB.DEFAULT_ROD], "장비도 처음으로")
	_eq(CropDB.kinds(gs2.garden).size(), 0, "텃밭도 비움")
	_eq(gs2.vibration_on, false, "설정은 남음")

	# 형이 다른 값이나 모르는 항목이 섞여도 멀쩡한 것만 받는다
	var gs3 = load("res://scripts/autoload/game_state.gd").new()
	SaveGame.restore(gs3, {"money": "많음", "day": 4, "inventory": 3, "없는것": 1})
	_eq(gs3.money, 180000, "형이 다른 돈은 무시")
	_eq(gs3.day, 4, "멀쩡한 날짜는 받음")
	_eq(gs3.inventory.size(), 0, "형이 다른 가방은 무시")

	# 망가진 파일은 저장이 없는 것으로 본다
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string("망가진 파일")
	f.close()
	_eq(gs3.has_save(path), false, "망가진 파일은 없는 셈")
	_eq(gs3.load_game(path), false, "망가진 파일은 불러오지 않음")
	DirAccess.remove_absolute(path)
	gs.free()
	gs2.free()
	gs3.free()



## 달력과 대출 상환
func _test_month() -> void:
	_eq(Calendar.text(1), "3월 1일 (월)", "1일차는 2027년 3월 1일 월요일")
	_eq(Calendar.short_text(31), "3월 31일", "3월은 31일까지")
	_eq(Calendar.short_text(32), "4월 1일", "32일차는 4월 1일")
	_eq(Calendar.short_text(62), "5월 1일", "4월은 30일까지")
	_eq(Calendar.season(1), "봄", "3월은 봄")
	_eq(Calendar.season(93), "여름", "6월은 여름")
	_eq(Calendar.is_month_start(32), true, "4월 1일은 달 첫날")
	_eq(Calendar.next_month_start(1), 32, "다음 상환일은 32일차")
	_eq(Loan.days_left(25), 7, "상환까지 이레")
	_eq(Loan.settle(1, 0, 100, 10, 0), {}, "첫날은 상환 없음")
	_eq(Loan.settle(20, 999999, 100, 10, 0), {}, "달 중간엔 상환 없음")
	var ok := Loan.settle(32, 900000, 30000000, 550000, 0)
	_eq(ok.paid, 550000 + Loan.RENT + 50000, "통장이 넉넉하면 대출, 월세, 봄 공과금을 냄")
	_eq(ok.debt, 30000000 - 550000, "갚은 만큼 대출이 줄어듦")
	var bad := Loan.settle(32, 100000, 30000000, 550000, 0)
	_eq(bad.paid, 0, "모자라면 못 갚음")
	_eq(bad.arrears, 800000, "못 낸 돈은 밀림")
	var catch_up := Loan.settle(62, 2000000, 30000000, 550000, 800000)
	_eq(catch_up.paid, 1600000, "다음 달엔 밀린 돈까지 냄")
	_eq(catch_up.arrears, 0, "밀린 돈 정리")
	_eq(Loan.settle(32, 999999, 300000, 550000, 0).loan, 300000, "남은 대출보다 더 내지 않음")
	_eq(Loan.settle(32, 999999, 0, 550000, 0).paid, 250000, "대출을 다 갚아도 월세와 공과금은 나감")
	_eq(Loan.bills(Calendar.next_month_start(150)) > Loan.bills(32), true, "여름 공과금이 더 비쌈")
	_eq(Loan.header_text(10, 550000, 0, 30000000), "", "상환일이 멀면 헤더에 안 보임")
	_eq(Loan.header_text(29, 550000, 0, 30000000), "고정비 D-3 · 80만", "1일이 가까우면 보임")
	_eq(Loan.notice(ok).contains("냈어요"), true, "고정비 알림")
	_eq(Loan.notice(bad).contains("못 냈어요"), true, "연체 알림")

	var gs = load("res://scripts/autoload/game_state.gd").new()
	gs.day = 31
	gs.money = 900000
	gs.end_day()
	_eq(gs.day, 32, "4월 1일 아침")
	_eq(gs.money, 100000, "고정비가 빠짐")
	_eq(gs.debt, 30000000 - 550000, "대출 잔액")
	_eq(gs.notices.size(), 1, "상환 알림이 쌓임")
	_eq(gs.pop_notices().size(), 1, "알림 꺼내기")
	_eq(gs.notices.size(), 0, "꺼내면 비움")
	gs.day = 61
	gs.money = 100000
	gs.end_day()
	_eq(gs.money, 100000, "모자라면 그대로")
	_eq(gs.arrears, 800000, "연체")
	_eq(gs.missed_payments, 1, "연체한 달 수")
	gs.free()


## 아이스박스 칸 수, 신선도, 주문 생선 보내기, 보통 손님 값 끝
func _test_icebox() -> void:
	var gs = load("res://scripts/autoload/game_state.gd").new()
	gs.day = 4
	gs.icebox_size = 3
	_eq(gs.store_catch({"id": "bolak", "size": 20.0}), {}, "자리가 있으면 들어감")
	_eq(gs.inventory[0].day, 4, "잡은 날을 적음")
	gs.store_catch({"id": "noraemi", "size": 25.0})
	gs.store_catch({"id": "ureok", "size": 30.0})
	_eq(gs.icebox_free(), 0, "꽉 참")
	var out: Dictionary = gs.store_catch({"id": "mangsang", "size": 13.0})
	_eq(out.id, "mangsang", "방금 잡은 게 제일 싸면 그걸 놓아줌")
	out = gs.store_catch({"id": "gamseongdom", "size": 40.0})
	_eq(out.id, "bolak", "비싼 걸 잡으면 제일 싼 걸 놓아줌")
	_eq(gs.inventory.size(), 3, "칸 수를 넘지 않음")
	# 신선도: 잡은 날 밤은 괜찮고, 다음 날 밤에 상한다
	gs.inventory = [{"id": "bolak", "size": 20.0, "day": 3}, {"id": "bolak", "size": 18.0, "day": 4}]
	_eq(gs.spoiling_tonight().size(), 1, "어제 잡은 건 오늘 밤 상함")
	gs.end_day()
	_eq(gs.inventory.size(), 1, "상한 생선은 버림")
	_eq(gs.inventory[0].day, 4, "오늘 잡은 건 남음")
	_eq(gs.notices.size(), 1, "상한 생선 알림")
	gs.free()

	# 주문을 다 채우면 그 생선을 보낸다 (저녁에 또 팔지 않게)
	var o := Orders.of(3)
	var g2 = load("res://scripts/autoload/game_state.gd").new()
	g2.flags = {"met_sundeok": true, "met_mansu": true, "met_junho": true, "met_kyungja": true, "met_bokja": true, "met_yongpal": true, "met_taesik": true}.duplicate()
	g2.day = 3
	for i in o.count:
		g2.store_catch({"id": o.fish, "size": o.min_cm + 1.0 + i})
	g2.store_catch({"id": o.fish, "size": o.min_cm - 2.0})
	for i in o.count:
		g2.offer_to_order(o.fish, o.min_cm + 1.0 + i)
	_eq(g2.order_done, true, "주문 완료")
	_eq(g2.inventory.size(), 1, "주문한 생선은 아이스박스에서 빠짐")
	_eq(g2.inventory[0].size, o.min_cm - 2.0, "조건에 안 맞는 건 남음")
	g2.free()

	# 보통 손님은 비싼 고기를 안 산다
	_eq(DayFlow.too_pricey("gamseongdom", 40.0), true, "감성돔은 보통 손님에게 비쌈")
	_eq(DayFlow.too_pricey("bolak", 20.0), false, "볼락은 괜찮음")
	var r := DayFlow.serve_regulars(5, [{"id": "gamseongdom", "size": 40.0}, {"id": "bolak", "size": 20.0}])
	_eq(r.served.size(), 1, "볼락만 팔림")
	_eq(r.served[0].fish, "bolak", "감성돔은 남김")
	_eq(r.used, [1], "쓴 생선 자리")
	_eq(DayFlow.special_price("gamseongdom", 52.0, 3), DayFlow.SPECIAL_MAX, "특별 손님 값에도 끝이 있음")
	_eq(DayFlow.DISH_MIN > DayFlow.DISH_COST, true, "가장 싼 접시도 재료비보다 비싸다")
	_eq(DayFlow.too_pricey("ureok", 40.0), true, "큰 우럭은 보통 손님에게 안 낸다 (돈 균형 11-16)")
	_eq(Orders.call_name("최순덕"), "순덕 할머니", "부르는 이름")
	for c in Orders.CUSTOMERS:
		_eq(c.react.size(), 3, "%s 반응 세 가지" % c.name)


func _test_market() -> void:
	_eq(Market.is_open(5 * 60), true, "새벽 5시 엶")
	_eq(Market.is_open(16 * 60 + 59), true, "오후 5시 전까지")
	_eq(Market.is_open(17 * 60), false, "오후 5시 닫음")
	_eq(Market.is_open(22 * 60), false, "밤엔 닫음")
	_eq(Market.price("bolak", 20.0) < DayFlow.dish_price("bolak", 20.0) - DayFlow.DISH_COST, true, "흔한 고기는 재료비를 빼도 식당이 더 남음")
	_eq(Market.price("gamseongdom", 45.0) > DayFlow.special_price("gamseongdom", 45.0, 3), true, "감성돔은 시장이 더 남음")
	_eq(Market.better_here("gamseongdom", 45.0), true, "시장이 나은 고기 표시")
	_eq(Locations.get_loc("market").scene.is_empty(), false, "지도에서 시장으로 감")
	var gs = load("res://scripts/autoload/game_state.gd").new()
	gs.money = 0
	var e := {"id": "ureok", "size": 30.0, "day": 1}
	gs.inventory = [e, {"id": "bolak", "size": 15.0, "day": 1}]
	var got: int = gs.sell_fish(gs.inventory[0])
	_eq(got, Market.price("ureok", 30.0), "판 값")
	_eq(gs.money, got, "돈이 들어옴")
	_eq(gs.sales_today, got, "장부 매출")
	_eq(gs.inventory.size(), 1, "판 생선은 빠짐")
	_eq(gs.sell_fish({"id": "ureok", "size": 99.0}), 0, "없는 생선은 못 팜")
	gs.free()


## 하루 서랍 내용
func _test_brief() -> void:
	var gs = load("res://scripts/autoload/game_state.gd").new()
	gs.flags["first_guest_done"] = true
	gs.day = 30
	gs.sales_today = 50000
	gs.spent_today = 8000
	gs.money = 700000
	gs.inventory = [{"id": "bolak", "size": 20.0, "day": 29}, {"id": "bolak", "size": 18.0, "day": 30}]
	gs.end_day()
	_eq(gs.yesterday_sales - gs.yesterday_spent, 42000, "어제 번 돈")
	_eq(gs.news_today.size(), 1, "상한 생선 소식이 서랍에 남음")
	gs.pop_notices()
	_eq(gs.news_today.size(), 1, "토스트를 띄워도 서랍 소식은 남음")
	gs.time_minutes = 6 * 60
	var b := DayBrief.build(gs)
	_eq(b.title, "3월 31일 (수) 오늘", "서랍 제목")
	_eq(b.stats[0].value, "42,000원", "맨 위 어제 번 돈")
	_eq(b.stats[2].name, "고정비 D-1", "다음 달 고정비")
	var names: Array = b.sections.map(func(s): return s.name)
	_eq(names, ["지금 할 일", "메인 이야기", "오늘의 바다", "아침 소식"], "서랍 분류 (만난 사람이 없으면 오늘 부탁 없음)")
	var todo: Array = b.sections[0].rows
	_eq(todo[0].target, "breakwater", "아침 6시엔 먼저 낚시")
	_eq(todo[0].state, "~9:00", "낚시 끝 시각")
	_eq(todo.any(func(r): return r.target == "market"), true, "시장 열려 있으면 팔기")
	_eq(todo.any(func(r): return r.target == "shop"), true, "저녁 장사")
	_eq(todo.any(func(r): return r.target == "home"), false, "아침엔 자러 가지 않음")
	gs.time_minutes = 21 * 60 + 30
	gs.opened_today = true
	todo = DayBrief.build(gs).sections[0].rows
	_eq(todo.map(func(r): return r.target), ["breakwater", "home"], "밤엔 밤 낚시나 잠")
	# 텃밭에 다 자란 줄
	gs.time_minutes = 13 * 60
	gs.garden[0] = {"crop": "daepa", "day": gs.day - 5}
	todo = DayBrief.build(gs).sections[0].rows
	_eq(todo.any(func(r): return r.target == "garden"), true, "다 자라면 거두기")
	# 돈이 모자란 채 상환일이 가까우면 빨강
	gs.money = 1000
	_eq(DayBrief.build(gs).stats[2].tone, "bad", "상환 못 할 것 같으면 빨강")
	gs.free()
	_eq(FishLine.stage({"day": 5}, 5).name, "오늘 잡음", "오늘 잡은 생선")
	_eq(FishLine.stage({"day": 4}, 5).name, "오늘 밤 상함", "어제 잡은 생선")


func _test_coop() -> void:
	var gs = load("res://scripts/autoload/game_state.gd").new()
	gs.day = 4
	gs.money = 10000
	_eq(Locations.is_unlocked("coop", gs.flags), false, "닭장은 처음엔 잠김")
	_eq(Coop.current_quest(gs), 0, "첫 부탁")
	_eq(Coop.give(gs), "아직 모자라요.", "생선이 없으면 못 드림")
	gs.inventory.append({"id": "mangsang", "size": 20.0, "day": 4})
	_eq(Coop.have_count(gs, Coop.QUESTS[0].need), 1, "아무 생선 한 마리")
	_eq(Coop.give(gs), "", "첫 부탁 들어줌")
	_eq(gs.inventory.size(), 0, "생선을 드림")
	_eq(Coop.current_quest(gs), -1, "하루에 하나만")
	gs.end_day()
	_eq(Coop.current_quest(gs), 1, "다음 날 둘째 부탁")
	gs.produce["daepa"] = 3
	_eq(Coop.give(gs), "", "대파 드림")
	_eq(int(gs.produce["daepa"]), 1, "대파 두 단 빠짐")
	gs.end_day()
	gs.inventory.append({"id": "bolak", "size": 18.0, "day": gs.day})
	gs.inventory.append({"id": "noraemi", "size": 25.0, "day": gs.day})
	_eq(Coop.give(gs), "아직 모자라요.", "볼락 한 마리로는 모자람")
	gs.inventory.append({"id": "bolak", "size": 16.0, "day": gs.day})
	_eq(Coop.give(gs), "", "볼락 두 마리 드림")
	_eq(gs.inventory.size(), 1, "볼락만 빠지고 노래미는 남음")
	_eq(Locations.is_unlocked("coop", gs.flags), true, "부탁 셋을 들어주면 닭장 열림")
	_eq(gs.hens, 2, "병아리 두 마리")
	_eq(Coop.current_quest(gs), -1, "부탁 끝")
	_eq(Coop.collect(gs), 0, "처음엔 달걀 없음")
	_eq(Coop.feed(gs), "", "모이 주기")
	_eq(Coop.feed(gs), "오늘은 벌써 모이를 줬어요.", "하루 한 번")
	gs.end_day()
	_eq(gs.coop_eggs, 2, "모이 먹은 닭은 알을 하나씩")
	gs.end_day()
	_eq(gs.coop_eggs, 2, "모이를 안 준 날은 알이 없음")
	_eq(Coop.collect(gs), 2, "달걀 두 개 줍기")
	_eq(int(gs.produce["egg"]), 2, "주운 달걀은 모아 둠")
	for i in 5:
		Coop.feed(gs)
		gs.end_day()
	_eq(gs.coop_eggs, Coop.EGG_MAX, "안 주우면 여섯 개까지만")
	gs.chicken_feed = 0
	_eq(Coop.feed(gs), "모이가 다 떨어졌어요.", "모이 없음")
	gs.money = 10000
	_eq(Coop.buy_feed(gs), "", "모이 한 포대 사기")
	_eq(gs.chicken_feed, Coop.FEED_PACK, "열 번 분")
	gs.free()



## 봄 첫 주 이야기 사건과 잡담
func _test_story() -> void:
	var f := {"first_guest_done": true}
	_eq(Story.pending("breakwater", 1, 6 * 60, f).is_empty(), true, "첫날엔 만수 사건 없음")
	_eq(Story.pending("breakwater", 2, 6 * 60, f).get("id", ""), "mansu_mend", "둘째 날 아침 방파제에서 만수")
	_eq(Story.pending("breakwater", 2, 22 * 60, f).is_empty(), true, "밤엔 만수가 없음")
	_eq(Story.pending("breakwater", 5, 6 * 60, f).get("id", ""), "mansu_mend", "앞 사건을 먼저 봄")
	var gs = load("res://scripts/autoload/game_state.gd").new()
	gs.flags = f.duplicate()
	Story.finish(Story.pending("breakwater", 2, 6 * 60, gs.flags), gs)
	_eq(gs.has_flag("met_mansu"), true, "만수를 만남")
	_eq(gs.has_flag("ev_mansu_mend"), true, "본 사건 표시")
	_eq(Story.pending("breakwater", 3, 6 * 60, gs.flags).is_empty(), true, "같은 사건은 한 번만")
	_eq(Story.pending("breakwater", 5, 6 * 60, gs.flags).get("id", ""), "mansu_tide", "닷새째 물때 이야기")
	_eq(Story.pending("market", 2, 9 * 60, {}).get("id", ""), "yongpal_first", "시장 첫 방문에 용팔")
	gs.free()
	var ids := {}
	for ev in Story.EVENTS:
		_eq(ids.has(ev.id), false, "사건 이름 겹침 없음 %s" % ev.id)
		ids[ev.id] = true
		_eq(Locations.LIST.has(ev.place), true, "%s 장소가 있음" % ev.id)
		_eq(ev.lines.size() >= 3, true, "%s 대사" % ev.id)
		for l in ev.lines:
			_eq(l.text.contains("—") or l.text.contains("ㅡ"), false, "줄표 없음 %s" % ev.id)
	for place in Story.SMALL_TALK:
		_eq(Locations.LIST.has(place), true, "잡담 장소 %s" % place)
		_eq(Story.small_talk(place, 3).is_empty(), false, "%s 잡담" % place)
	_eq(Story.small_talk("없는곳", 1), [], "잡담 없는 곳")
	# 해솔: 복자를 만난 뒤 엿새째 오후 밥집에서 처음 만나고, 분교가 열리고, 지도에 걷기 시작한다
	var hf := {"met_bokja": true, "ev_bokja_diner": true}
	_eq(Story.pending("diner", 6, 15 * 60, {}).get("id", ""), "bokja_diner", "복자를 먼저 만남")
	_eq(Story.pending("diner", 5, 15 * 60, hf).get("id", ""), "bokja_flat", "닷새째엔 해솔 대신 복자가 갯벌 얘기")
	_eq(Story.pending("diner", 6, 10 * 60, hf).get("id", "") != "haesol_first", true, "오전엔 학교 가서 없음")
	_eq(Story.pending("diner", 6, 15 * 60, hf).get("id", ""), "haesol_first", "엿새째 오후 밥집에서 해솔")
	_eq(Locations.is_unlocked("school", hf), false, "만나기 전엔 분교 잠김")
	_eq(Walkers.active(15 * 60, hf).any(func(w): return w.id == "haesol"), false, "만나기 전엔 지도에 없음")
	var hgs = load("res://scripts/autoload/game_state.gd").new()
	hgs.flags = hf.duplicate()
	Story.finish(Story.pending("diner", 6, 15 * 60, hf), hgs)
	_eq(Locations.is_unlocked("school", hgs.flags), true, "만나면 분교 열림")
	_eq(Walkers.active(15 * 60, hgs.flags).any(func(w): return w.id == "haesol"), true, "만난 뒤 오후엔 지도에서 걷기")
	_eq(Walkers.active(10 * 60, hgs.flags).any(func(w): return w.id == "haesol"), false, "오전엔 학교")
	_eq(Story.small_talk("school", 3).is_empty(), false, "분교 잡담")
	_eq(Portraits.path("김해솔") != "", true, "해솔 얼굴 그림")
	# 〈해솔이의 숙제〉: 분교 → 자랑 세 곳 → 방파제 첫 볼락 → 다음 날 분교 발표 → 밥집 복자
	hgs.flags["met_yongpal"] = true
	hgs.flags["met_kyungja"] = true
	hgs.flags["ev_yongpal_first"] = true
	hgs.flags["ev_kyungja_store"] = true
	hgs.day = 7
	_eq(Story.pending("lookout", 7, 15 * 60, hgs.flags).is_empty(), true, "숙제 받기 전엔 전망대 사건 없음")
	_eq(Story.pending("school", 6, 15 * 60, hgs.flags).is_empty(), true, "엿새째엔 숙제 안 받음")
	_eq(Story.pending("school", 7, 10 * 60, hgs.flags).is_empty(), true, "오전엔 수업 중")
	var hw: Dictionary = Story.pending("school", 7, 15 * 60, hgs.flags)
	_eq(hw.get("id", ""), "haesol_hw_start", "이레째 오후 분교에서 숙제")
	Story.finish(hw, hgs)
	_eq(Story.pending("breakwater", 7, 15 * 60, hgs.flags).get("id", "") == "hw_fishing", false, "자랑 셋 모으기 전엔 낚시 안 함")
	_eq(Story.pending("market", 7, 18 * 60, hgs.flags).is_empty(), true, "시장 닫은 뒤엔 없음")
	for p in [["lookout", "hw_lookout"], ["market", "hw_market"], ["store", "hw_store"]]:
		var e: Dictionary = Story.pending(p[0], 7, 15 * 60, hgs.flags)
		_eq(e.get("id", ""), p[1], "자랑 %s" % p[0])
		Story.finish(e, hgs)
	var fe: Dictionary = Story.pending("breakwater", 7, 15 * 60, hgs.flags)
	_eq(fe.get("id", ""), "hw_fishing", "자랑 셋 뒤 방파제에서 해솔 첫 볼락")
	Story.finish(fe, hgs)
	_eq(Story.pending("school", 7, 16 * 60, hgs.flags).is_empty(), true, "발표는 다음 날")
	hgs.day = 8
	var de: Dictionary = Story.pending("school", 8, 15 * 60, hgs.flags)
	_eq(de.get("id", ""), "haesol_hw_done", "다음 날 분교에서 발표")
	Story.finish(de, hgs)
	var be: Dictionary = Story.pending("diner", 8, 12 * 60, hgs.flags)
	_eq(be.get("id", ""), "haesol_bokja_thanks", "밥집에서 복자가 고마워함")
	Story.finish(be, hgs)
	_eq(hgs.has_flag("recipe_fish_fry"), true, "생선튀김 비법")
	_eq(Story.pending("school", 9, 15 * 60, hgs.flags).is_empty(), true, "숙제는 한 번만")
	hgs.free()


## 견제의 이득과 손해, 회수, 거리별 어종, 어종 버릇
func _test_fishing_depth() -> void:
	var S := FishingLogic.State
	# 흘러가면 포인트에서 벗어나 판정이 내려간다
	var a := _new_logic(41)
	a.forgiving = false
	a.catch_count = 1
	a.point_depth = 0.5
	a.state = S.CHARGING
	a.power = 0.5 / a.cast_mult
	a.release()
	_eq(a.cast_grade, "nice", "포인트에 떨어짐")
	_run_until(a, [S.WAITING], func(_x): return false, 2.0)
	a._timer = 999.0
	for i in 60 * 8:
		a.update(1.0 / 60.0, false, false)
	_eq(a.cast_grade != "nice", true, "흘러가면 NICE가 사라짐 (%s)" % a.cast_grade)
	_eq(a.slipped(), true, "벗어났다고 알림")
	# 견제를 짧게 끊어 잡으면 그대로, 오래 잡으면 찌가 끌려온다
	var b := _new_logic(42)
	b.point_depth = 0.5
	b.state = S.CHARGING
	b.power = 0.5 / b.cast_mult
	b.release()
	_run_until(b, [S.WAITING], func(_x): return false, 2.0)
	b._timer = 999.0
	var p0 := b.cast_power
	for i in 60:
		b.update(1.0 / 60.0, false, true)
	_eq(is_equal_approx(b.cast_power, p0), true, "1초 견제는 괜찮음")
	_eq(b.over_mend, false, "아직 안 당김")
	for i in 60 * 2:
		b.update(1.0 / 60.0, false, true)
	_eq(b.over_mend, true, "오래 잡으면 너무 당김")
	_eq(b.cast_power < p0, true, "찌가 발밑 쪽으로 끌려옴")
	# 조용할 때 누르면 회수: 연속 PERFECT를 깨지 않는다
	var c := _new_logic(43)
	c.perfect_streak = 2
	_cast(c)
	c.nibble = 0.0
	c.press()
	_eq(c.fail_reason, "retrieved", "회수")
	_eq(c.perfect_streak, 2, "회수는 실패로 치지 않음")
	_eq(FishingLogic.fail_message("retrieved").is_empty(), false, "회수 안내")
	# 거리별 대표 어종
	var night := {"brightness": 0.0, "bait": "krill", "weather": "sunny"}
	var day := {"brightness": 1.0, "bait": "krill", "weather": "sunny"}
	_eq(FishDB.top_at(night, 0.1), "bolak", "어두운 발밑은 볼락")
	_eq(FishDB.top_at(day, 0.95) != "bolak", true, "밝은 먼 물은 볼락이 아님 (%s)" % FishDB.top_at(day, 0.95))
	# 어종 버릇
	for id in FishDB.FISH:
		_eq(FishDB.habit_text(id).is_empty(), false, "%s 버릇 설명" % id)
	_eq(FishDB.get_fish("bolak").beat > FishDB.get_fish("mangsang").beat, true, "볼락 박자가 망상어보다 잘다")
	# 박자: 볼락은 같은 시간에 망상어보다 박자가 더 많이 돈다
	var beats := {}
	for id in ["bolak", "mangsang"]:
		var bl := _new_logic(90)
		bl.forgiving = false
		bl.force_first_fish = id
		_cast(bl)
		_run_until(bl, [S.BITE], func(_x): return false, 20.0)
		bl.press()
		for i in 180:
			if bl.state == S.REELING:
				bl.update(1.0 / 60.0, bl.tension < 0.5)
		beats[id] = bl.beat_ticks
	_eq(beats.bolak > beats.mangsang, true, "볼락 박자 %d > 망상어 %d" % [beats.bolak, beats.mangsang])
	# 쏨뱅이: 발밑에 오면 지쳤어도 한 번 바위틈으로 처박는다
	var sb := _new_logic(91)
	sb.forgiving = false
	sb.force_first_fish = "ssombaengi"
	_cast(sb)
	_run_until(sb, [S.BITE], func(_x): return false, 20.0)
	sb.press()
	sb.fish_hp = 0.0
	sb.update(1.0 / 60.0, true)
	_eq(sb.exhausted, true, "쏨뱅이 지침")
	sb.distance = FishingLogic.HOLE_AT - 0.01
	sb.update(1.0 / 60.0, true)
	_eq(sb.hole_dived and not sb.exhausted and sb.run_dir != 0, true, "쏨뱅이 발밑 처박기")
	var runs := sb.run_count
	sb.run_dir = 0
	sb.update(1.0 / 60.0, true)
	_eq(sb.run_count, runs, "처박기는 한 번만")
	# 망상어: 거의 늘 같은 쪽으로 차고 나간다
	var same := 0
	var total := 0
	for sd in 6:
		var m := _new_logic(120 + sd)
		m.forgiving = false
		m.force_first_fish = "mangsang"
		_cast(m)
		_run_until(m, [S.BITE], func(_x): return false, 20.0)
		m.press()
		var prev := 0
		var last_count := 0
		for i in 1200:
			if m.state != S.REELING:
				break
			m.update(1.0 / 60.0, m.tension < 0.5)
			if m.run_count != last_count and m.run_dir != 0:
				if prev != 0:
					total += 1
					if m.run_dir == prev:
						same += 1
				prev = m.run_dir
				last_count = m.run_count
	_eq(total > 0 and same * 10 >= total * 6, true, "망상어는 같은 쪽으로 (%d/%d)" % [same, total])
	# 우럭은 물자마자 파고든다
	var u := _new_logic(44)
	u.forgiving = false
	u.force_first_fish = "ureok"
	_cast(u)
	_run_until(u, [S.BITE], func(_x): return false, 20.0)
	u.press()
	_eq(u.fish_id, "ureok", "우럭")
	for i in 30:
		u.update(1.0 / 60.0, true)
	_eq(u.run_count >= 1, true, "우럭은 물자마자 차고 나감")
	# 학공치는 바늘털이를 한다. 손을 떼고 있으면 빠진다
	var jumped := 0
	var lost_by_jump := 0
	for sd in 12:
		var h := _new_logic(60 + sd)
		h.forgiving = false
		h.force_first_fish = "hakgongchi"
		_cast(h)
		_run_until(h, [S.BITE], func(_x): return false, 20.0)
		h.press()
		var t := 0.0
		while h.state == S.REELING and t < 20.0:
			h.update(1.0 / 60.0, h.jump_t <= 0.0 and h.tension < 0.6)
			t += 1.0 / 60.0
		jumped += h.jumps
		if h.fail_reason == "jumped":
			lost_by_jump += 1
	_eq(jumped > 0, true, "학공치 바늘털이 (%d번)" % jumped)
	_eq(lost_by_jump > 0, true, "바늘털이 때 손을 떼면 놓침 (%d번)" % lost_by_jump)
	# 지친 물고기는 감아도 장력이 오르지 않는다
	var e := _new_logic(80)
	e.forgiving = false
	_cast(e)
	_run_until(e, [S.BITE], func(_x): return false, 20.0)
	e.press()
	e.fish_hp = 0.0
	e.tension = 0.8
	e.update(1.0 / 60.0, true)
	_eq(e.exhausted, true, "지침")
	var start := e.tension
	var top := start
	for i in 120:
		e.update(1.0 / 60.0, true)
		top = maxf(top, e.tension) if e.state == S.REELING else top
	_eq(top <= start + 0.0001, true, "지친 뒤 감아도 장력이 오르지 않음 (%.3f → %.3f)" % [start, top])
	_eq(e.state == S.CAUGHT or e.tension < start, true, "알맞은 장력으로 돌아옴")


## 장부 일지와 도감 자세히
func _test_journal() -> void:
	_eq(Journal.line([], 0, 0, 0).contains("못 잡고"), true, "아무것도 안 한 날")
	_eq(Journal.line([], 5, 40000, 4000), "5마리 잡고 36,000원 남겼다.", "숫자로 짓는 한 줄")
	_eq(Journal.line([{"p": 1, "text": "a"}, {"p": 3, "text": "b"}, {"p": 2, "text": "c"}], 5, 0, 0), "b", "가장 중요한 메모")
	_eq(Journal.caught_text({"mangsang": 2, "bolak": 4}), "볼락 4, 망상어 2", "잡은 고기 한 줄 (도감 순서)")
	var gs = load("res://scripts/autoload/game_state.gd").new()
	gs.day = 12
	gs.caught_today = [{"id": "bolak", "size": 15.0}, {"id": "bolak", "size": 17.0}]
	gs.sales_today = 30000
	gs.note("처음으로 볼락을 잡았다.", 3)
	gs.note("그냥 메모", 1)
	gs.end_day()
	_eq(gs.journal.size(), 1, "하루가 끝나면 한 장")
	_eq(gs.journal[0].day, 12, "그날 날짜")
	_eq(gs.journal[0].caught, {"bolak": 2}, "잡은 고기 셈")
	_eq(gs.journal[0].line, "처음으로 볼락을 잡았다.", "오늘의 한 줄")
	_eq(gs.notes_today.size(), 0, "다음 날 메모 비움")
	# 주문을 채우면 메모가 남는다
	gs.flags["met_sundeok"] = true
	var o: Dictionary = gs.today_order()
	for i in o.count:
		gs.offer_to_order(o.fish, o.min_cm + 1.0)
	_eq(gs.notes_today.size(), 1, "주문 메모")
	gs.free()
	# 도감 자세히
	for id in FishDB.FISH:
		_eq(DexInfo.facts(id).size() >= 5, true, "%s 낚는 요령" % id)
	_eq(DexInfo.facts("bolak")[1][1], "어두운 새벽과 밤", "볼락은 어두울 때")
	_eq(DexInfo.facts("hakgongchi")[0][1], "먼 물", "학공치는 먼 물")
	_eq(DexInfo.facts("ureok").back()[0], "버릇", "우럭 버릇")
	_eq(Locations.is_unlocked("hall", {"chapter2_done": true}), false, "마을회관은 할 일이 생길 때까지 잠김")


## 줄다리기 화면 T2: 장력을 낚싯대 휨, 대 끝 빛, 줄 처짐으로 바꾸는 규칙 (FightView)
func _test_fight_view() -> void:
	var slack := FishingLogic.TENSION_SLACK
	var danger := FishingLogic.TENSION_DANGER
	# 휨은 장력을 따라 끊김 없이 커진다
	var prev := -1.0
	var smooth := true
	var rising := true
	for i in 101:
		var b := FightView.rod_bend(i / 100.0)
		if b < prev:
			rising = false
		if prev >= 0.0 and b - prev > 0.05:
			smooth = false
		prev = b
	_eq(rising, true, "휨은 장력이 오를수록 커짐")
	_eq(smooth, true, "휨은 단계 없이 부드럽게 바뀜")
	_eq(FightView.rod_bend(0.0) < 0.1, true, "느슨하면 거의 곧음")
	_eq(FightView.rod_bend(0.5) > 0.3 and FightView.rod_bend(0.5) < 0.68, true, "알맞으면 활처럼")
	_eq(FightView.rod_bend(danger) >= 0.68, true, "위험하면 크게 꺾임")
	_eq(FightView.rod_bend(1.0), 1.0, "끝까지 당기면 최대 휨")
	_eq(FightView.rod_bend(1.7), 1.0, "범위를 넘어도 최대 휨")
	# 장력 게이지 구간: 아래부터 느슨, 알맞음, 드랙, 위험 (대 끝 빛과 붉은 줄은 2026-11-12 뺐다)
	_eq(FightView.gauge_zone(slack * 0.5), "slack", "느슨 구간")
	_eq(FightView.gauge_zone(0.4), "good", "알맞음 구간")
	_eq(FightView.gauge_zone(FishingLogic.TENSION_WARN + 0.01), "drag", "드랙 구간")
	_eq(FightView.gauge_zone(danger + 0.01), "danger", "위험 구간")
	_eq(FightView.gauge_zone(1.0), "danger", "끝까지 차면 위험")
	_eq(FightView.gauge_zones().size(), 4, "게이지는 네 구간")
	# 줄: 느슨할 때만 처진다
	_eq(FightView.line_sag(0.0), FightView.SAG_MAX, "장력 없으면 줄이 가장 처짐")
	_eq(FightView.line_sag(slack), 0.0, "알맞음부터 줄이 곧음")
	_eq(FightView.line_sag(0.9), 0.0, "위험해도 줄은 곧음")
	# 드랙: 위험 구간에서는 릴이 줄을 내줘 물고기가 멀어진다
	var dl := FishingLogic.new()
	dl.rng.seed = 7
	dl.force_first_fish = "bolak"
	dl.state = FishingLogic.State.BITE
	dl.bite_depth = 0.5
	dl._timer = 1.0
	dl.press()
	dl.run_dir = 0
	dl._rest_time = 99.0
	dl.distance = 0.5
	dl.tension = 0.95
	dl.update(0.1, false)
	_eq(dl.drag_slip, true, "위험 구간이면 드랙이 줄을 내줌")
	_eq(dl.distance > 0.5, true, "드랙이 미끄러지면 물고기가 멀어짐 (%.3f)" % dl.distance)
	dl.tension = 0.4
	dl.update(0.1, false)
	_eq(dl.drag_slip, false, "알맞으면 드랙 멈춤")
	# 남은 줄 숫자
	_eq(FightView.line_meters(1.0, 1.0), 30, "가장 멀리 던지면 30m")
	_eq(FightView.line_meters(0.5, 0.6), 9, "절반 감으면 9m")
	_eq(FightView.line_meters(0.0, 0.6), 0, "다 감으면 0m")
	# 누른 채 끈 거리 → 버티기. 물고기가 오른쪽으로 가면 왼쪽으로 끌어야 버틴다
	_eq(FightView.steer_from_drag(0.0, 110.0), 0.0, "제자리면 버티기 없음")
	_eq(FightView.steer_from_drag(-400.0, 110.0), -1.0, "많이 끌어도 -1까지")
	var st := FightView.steer_from_drag(-60.0, 110.0)
	_eq(st * 1.0 <= -FishingLogic.COUNTER_STEER, true, "왼쪽으로 60px 끌면 오른쪽으로 가는 물고기를 버팀")
	_eq(FightView.steer_from_drag(-20.0, 110.0) <= -FishingLogic.COUNTER_STEER, false, "살짝 끈 건 버티기가 아님")


## 손님 SD: 반응 시트 세 칸 자르기, 별 수에 따른 몸짓
func _test_guest_sd() -> void:
	# 빈 열이 1/3, 2/3 근처에 있으면 그 자리에서 자른다
	var cols := PackedFloat32Array()
	cols.resize(300)
	for x in 300:
		cols[x] = 5.0
	cols[95] = 0.0
	cols[210] = 1.0
	_eq(GuestSD.find_cuts(cols), [0, 95, 210, 300], "가장 빈 열에서 자름")
	# 빈 열이 범위 밖이면 3등분 자리 그대로
	cols.fill(5.0)
	cols[10] = 0.0
	_eq(GuestSD.find_cuts(cols), [0, 100, 200, 300], "빈 열이 멀면 3등분")
	_eq(GuestSD.id_for("김복자"), "bokja", "주문 손님 이름으로 그림 id")
	_eq(GuestSD.id_for("모르는 사람"), "", "모르는 사람은 그림 없음")
	_eq(GuestSD.has_sheet(""), false, "id 없으면 시트 없음")
	_eq(GuestSD.pose_for_stars(3), "happy", "별 셋이면 만족")
	_eq(GuestSD.pose_for_stars(2), "stand", "별 둘이면 그냥 서 있음")
	_eq(GuestSD.pose_for_stars(1), "sad", "별 하나면 아쉬움")


func _fish_box(n: int) -> Array:
	var box := []
	for i in n:
		box.append({"id": "bolak", "size": 18.0 + i, "day": 1})
	return box


## 영업 한 판을 돌린다. good이면 완성 접시가 나오는 대로 그 손님에게 갖다주고, 한가하면 빈 그릇을 치운다.
## 주인공이 굽는 판(helper_kitchen false)이면 노릇할 때 담는다
func _run_dining(d: DiningLogic, good: bool) -> void:
	var t := 0.0
	while not d.is_over() and t < 400.0:
		if good:
			if not d.helper_kitchen:
				for c in d.cooking:
					if float(c.t) - float(c.total) >= 0.3:
						d.plate(int(c.burner))
			for i in d.pass_dishes.size():
				if not d._dish_reserved(d.pass_dishes[i]) and d._task_count() < DiningLogic.MAX_TASKS:
					d.take(i)
					break
			if d._task_count() == 0:
				for seat in d.dirty:
					d.clear_seat(seat)
					break
		d.update(1.0 / 30.0)
		t += 1.0 / 30.0


## 저녁 영업: 손님이 앉아 주문, 자동 조리, 들고 가서 서빙 (DiningLogic)
func _test_dining() -> void:
	var names := ["동네 아저씨", "민박 손님"]
	var a := DiningLogic.new()
	a.setup(4, _fish_box(DiningLogic.GUESTS_MAX + 1), names)
	var b := DiningLogic.new()
	b.setup(4, _fish_box(DiningLogic.GUESTS_MAX + 1), names)
	_eq(a.schedule.size(), b.schedule.size(), "같은 날은 손님 수가 같음")
	_eq(a.schedule.size() >= DiningLogic.GUESTS_MIN and a.schedule.size() <= DiningLogic.GUESTS_MAX, true, "손님 수 범위 (%d)" % a.schedule.size())
	_eq(a.schedule[a.schedule.size() - 1].t <= DiningLogic.OPEN_SECONDS * DiningLogic.LAST_ARRIVAL, true, "마지막 손님은 문 닫기 전에")
	# 잘하면 다 받고 화난 손님 없음
	var n := a.schedule.size()
	_run_dining(a, true)
	_eq(a.served.size(), n, "잘 나르면 손님 다 받음 (%d/%d)" % [a.served.size(), n])
	_eq(a.angry, 0, "잘 나르면 화난 손님 없음")
	_eq(a.missed, 0, "생선 넉넉하면 돌아간 손님 없음")
	_eq(a.inventory.size(), DiningLogic.GUESTS_MAX + 1 - n, "쓴 만큼 아이스박스에서 빠짐")
	# 손님은 무리 지어 온다: 2초 안에 잇달아 들어오는 손님이 있다
	var bunched := 0
	for i in range(1, b.schedule.size()):
		if b.schedule[i].t - b.schedule[i - 1].t < 2.0:
			bunched += 1
	_eq(bunched > 0, true, "손님이 무리 지어 옴 (%d)" % bunched)
	var hearts := a.served.filter(func(e): return e.heart).size()
	_eq(hearts > 0, true, "빨리 받으면 하트 (%d)" % hearts)
	var sum := 0
	for e in a.served:
		sum += e.price
	_eq(a.sales, sum, "매출 = 받은 값 합")
	_eq(a.is_over(), true, "영업이 끝남")
	_eq(a.time < DiningLogic.OPEN_SECONDS, true, "손님을 다 받으면 문 닫기 전에 끝남 (%.0f초)" % a.time)
	# 손님은 문에서 걸어 들어와 자리에 닿아야 주문한다
	for i in DiningLogic.SEATS.size():
		var path := DiningLogic.entry_path(i)
		_eq(path[path.size() - 1], DiningLogic.SEATS[i], "%d번 자리까지 가는 길 끝은 자리" % i)
		_eq(path[0], DiningLogic.LANE[DiningLogic.ENTRY_LANE], "%d번 길은 문 앞 길에서 시작" % i)
		_eq(path[path.size() - 2], DiningLogic.SPOTS[i], "%d번 손님은 서빙 자리를 거쳐 앉음" % i)
	var wk := DiningLogic.new()
	wk.setup(4, _fish_box(12), names)
	while wk.guests.is_empty():
		wk.update(1.0 / 30.0)
	_eq(wk.guests[0].state, DiningLogic.GuestState.WALKING, "들어온 손님은 먼저 걷는다")
	_eq(wk.queue.is_empty(), true, "걷는 동안은 주문 없음")
	for k in 300:
		wk.update(1.0 / 30.0)
	_eq(wk.guests[0].state, DiningLogic.GuestState.SEATED, "10초 안에 자리에 앉음")
	_eq(wk.guests[0].pos, DiningLogic.SEATS[wk.guests[0].seat], "앉은 자리에 서 있음")
	# 빈자리를 고루 쓴다 (한쪽부터 채우지 않는다)
	var sides := {}
	for g in a.guests:
		sides["L" if DiningLogic.SEATS[g.seat].x < 0.5 else "R"] = true
	_eq(sides.size(), 2, "손님이 홀 양쪽에 고루 앉음")
	# 이름 없는 손님 그림: 이름마다 정해진 그림, 모르는 이름도 다섯 중 하나
	_eq(GuestSD.face_for("물질 마친 해녀"), "guest_haenyeo" if GuestSD.has_sheet("guest_haenyeo") else GuestSD.face_for("물질 마친 해녀"), "해녀 손님 그림")
	for gname in DayFlow.GUESTS:
		_eq(GuestSD.has_sheet(GuestSD.face_for(gname)), true, "%s 그림 있음" % gname)
	_eq(GuestSD.has_sheet(GuestSD.face_for("처음 보는 사람")), true, "모르는 이름도 그림 있음")
	# 걷기 칸: 옆 4~7, 위로 뒤 2·3, 아래로 앞 0·1
	_eq(GuestSD.walk_cell(Vector2.RIGHT, 0.0) >= 4, true, "옆으로 걸으면 옆모습 칸")
	_eq(GuestSD.walk_cell(Vector2.UP, 0.0) in [2, 3], true, "위로 걸으면 뒷모습 칸")
	_eq(GuestSD.walk_cell(Vector2.DOWN, 0.0) in [0, 1], true, "아래로 걸으면 앞모습 칸")
	# 가만히 있으면 손님이 화나서 가고, 굽지 않은 생선은 돌아온다
	var c := DiningLogic.new()
	c.setup(4, _fish_box(12), names)
	_run_dining(c, false)
	_eq(c.served.size(), 0, "안 나르면 아무도 못 받음")
	_eq(c.angry, c.guests.size(), "안 나르면 다 화나서 감")
	_eq(c.pass_dishes.size() <= DiningLogic.PASS_MAX, true, "내놓는 자리는 세 접시까지")
	_eq(c.pass_dishes.is_empty(), true, "간 손님 접시는 내놓는 자리에서 치움")
	var q := DiningLogic.new()
	q.setup(4, _fish_box(3), names)
	q.guests = [{"name": "x", "seat": 0, "fish": "bolak", "size": 20.0, "entry": {"id": "bolak", "size": 20.0}, "price": 9000, "state": DiningLogic.GuestState.SEATED, "wait": 0.0, "eat": 0.0, "cooked": false}]
	q.queue = [0]
	q._leave_angry(0)
	_eq([q.inventory.size(), q.queue.size()], [4, 0], "굽기 전에 간 손님 생선은 아이스박스로")
	_eq(c.cooking.is_empty(), true, "간 손님 생선은 화구에서 내림")
	# 생선튀김: 비법을 모르면 다 구이, 배우면 손님 일부가 튀김을 시키고 값을 더 낸다
	_eq(a.served.filter(func(x): return x.dish == "fry").size(), 0, "비법 없으면 튀김 주문 없음")
	var fr := DiningLogic.new()
	fr.fry = true
	fr.setup(4, _fish_box(DiningLogic.GUESTS_MAX + 1), names)
	var fr_n := fr.schedule.size()
	_run_dining(fr, true)
	var fried := fr.served.filter(func(x): return x.dish == "fry")
	_eq(fried.size() > 0 and fried.size() < fr_n, true, "비법을 배우면 일부만 튀김 (%d/%d)" % [fried.size(), fr_n])
	_eq(fr.served.size(), fr_n, "튀김이 섞여도 잘 나르면 다 받음")
	_eq(DiningLogic.dish_price_of("bolak", 20.0, "fry") > DiningLogic.dish_price_of("bolak", 20.0, "grill"), true, "튀김이 구이보다 비쌈")
	_eq(DiningLogic.dish_price_of("bolak", 20.0, "grill"), DayFlow.dish_price("bolak", 20.0), "구이 값은 그대로")
	_eq(ResourceLoader.exists("res://assets/art/" + Catalog.dish_art(DiningLogic.dish_art_id("bolak", "fry")) + ".png"), true, "튀김 그림 있음")
	var fs := DiningLogic.new()
	fs.guests = [{"fish": "bolak", "dish": "fry"}, {"fish": "bolak", "dish": "grill"}, {"fish": "bolak"}]
	_eq([fs.same_order(0, 1), fs.same_order(1, 2)], [false, true], "튀김 접시는 구이 손님에게 못 냄")
	# 생선이 없으면 재료 소진으로 문을 닫는다 (평판 깎이는 돌아간 손님 없음)
	var e0 := DiningLogic.new()
	e0.setup(4, [], names)
	var e0_n := e0.schedule.size()
	_run_dining(e0, true)
	_eq([e0.sold_out, e0.missed, e0.sales], [true, 0, 0], "생선 없으면 바로 재료 소진")
	_eq(e0.turned_away, e0_n, "못 받은 손님 수 (%d)" % e0_n)
	_eq(e0.is_over(), true, "재료 소진이면 영업 끝")
	# 두 마리뿐이면 둘만 받고 닫는다
	var f := DiningLogic.new()
	f.setup(4, _fish_box(2), names)
	var f_n := f.schedule.size()
	_run_dining(f, true)
	_eq(f.served.size(), 2, "생선 두 마리면 둘만")
	_eq([f.missed, f.turned_away, f.sold_out], [0, f_n - 2, true], "나머지는 재료 소진으로 못 받음")
	# 비싼 생선은 보통 손님에게 내지 않는다
	var g := DiningLogic.new()
	g.setup(4, [{"id": "gamseongdom", "size": 40.0}], names)
	_eq(g.pick_fish(), -1, "감성돔은 보통 손님에게 안 냄")
	# 값: 빨리 받으면 더, 아슬아슬하면 덜
	_eq(DiningLogic.pay(10000, 5.0), 11500, "빨리 받으면 하트 값")
	_eq(DiningLogic.pay(10000, 20.0), 10000, "보통이면 제값")
	_eq(DiningLogic.pay(10000, DiningLogic.PATIENCE), 8500, "오래 기다리면 깎임")
	_eq(DiningLogic.cook_time(30.0) > DiningLogic.cook_time(15.0), true, "큰 고기는 더 오래 구움")
	# 고르고 갖다주기: 같은 생선을 시킨 손님이면 누구에게 줘도 되고 다른 요리는 안 받는다
	var h := DiningLogic.new()
	h.guests = [
		{"name": "a", "seat": 0, "fish": "bolak", "size": 18.0, "entry": {}, "price": 6000, "state": DiningLogic.GuestState.SEATED, "wait": 0.0, "eat": 0.0, "cooked": true, "quality": "perfect"},
		{"name": "b", "seat": 4, "fish": "bolak", "size": 19.0, "entry": {}, "price": 6000, "state": DiningLogic.GuestState.SEATED, "wait": 0.0, "eat": 0.0, "cooked": false, "quality": ""},
		{"name": "c", "seat": 8, "fish": "noraemi", "size": 20.0, "entry": {}, "price": 7000, "state": DiningLogic.GuestState.SEATED, "wait": 0.0, "eat": 0.0, "cooked": false, "quality": ""},
	]
	h.pass_dishes = [0]
	h.queue = [1, 2]
	_eq(h.deliver_to(0), "none", "고른 접시가 없으면 못 냄")
	_eq(h.select(0), true, "접시 고르기")
	_eq(h.selected, 0, "고른 접시")
	_eq(h.deliver_to(2), "wrong", "다른 요리를 시킨 손님은 안 받음")
	_eq(h.deliver_to(1), "ok", "같은 볼락을 시킨 다른 손님에게 줌")
	_eq([h.pass_dishes, h.queue, h.guests[1].quality, h.guests[0].quality], [[1], [0, 2], "perfect", ""], "두 손님 주문을 맞바꿈")
	_eq(h.tasks.size(), 1, "할 일 하나")
	for i in 120:
		h.update(1.0 / 30.0)
	_eq(h.guests[1].state, DiningLogic.GuestState.EATING, "걸어가서 냄")
	_eq(h.served[0].quality, "perfect", "노릇한 접시 값")
	_eq(h.select(0), false, "내놓는 자리에 없는 접시는 못 고름")
	# 다 먹고 간 자리는 치워야 손님이 앉는다
	var dz := DiningLogic.new()
	dz.dirty = {3: true}
	_eq(dz.free_seats().has(3), false, "빈 그릇 자리엔 못 앉음")
	_eq(dz.clear_seat(5), false, "깨끗한 자리는 치울 것 없음")
	_eq(dz.clear_seat(3), true, "빈 그릇 치우러 감")
	_eq(dz.clear_seat(3), false, "같은 자리를 두 번 맡지 않음")
	for i in 200:
		dz.update(1.0 / 30.0)
	_eq([dz.dirty.is_empty(), dz.free_seats().has(3), dz.task.is_empty()], [true, true, true], "치우고 홀 자리로 돌아옴")
	_eq(dz.player.distance_to(DiningLogic.HALL_HOME) < 0.001, true, "주인공은 홀 자리에서 기다림")
	# 손님 앞까지 가는 길은 길(LANE)을 따라 서빙 자리로, 돌아올 때도 길로 홀 자리까지
	_eq([DiningLogic.SEATS.size(), DiningLogic.SEAT_VIEW.size(), DiningLogic.SEAT_FLIP.size(), DiningLogic.SPOTS.size(),
		DiningLogic.PLATE_SPOTS.size(), DiningLogic.SEAT_ACCESS.size()], [16, 16, 16, 16, 16, 16], "홀 16석 자리표 길이가 맞음")
	for i in DiningLogic.SEATS.size():
		var go := DiningLogic._path_to_guest(DiningLogic.HALL_HOME, i)
		_eq(go[go.size() - 1], DiningLogic.serve_spot(i), "%d번 손님에게 가는 길 끝은 서빙 자리" % i)
		_eq(DiningLogic.LANE.has(go[0]), true, "%d번 손님에게 갈 때 길로 먼저 감" % i)
		var back := DiningLogic._path_home(i, DiningLogic.HALL_HOME)
		_eq(back[back.size() - 1], DiningLogic.HALL_HOME, "%d번 자리에서 홀 자리로 돌아옴" % i)
		if DiningLogic.SEAT_VIEW[i] == "back":
			_eq(Shop4.SEAT_STOOL[i] >= 0, true, "%d번 뒷모습 손님은 스툴 덮개가 있음" % i)
			var st: Array = Shop4.STOOLS[Shop4.SEAT_STOOL[i]]
			_eq(absf(DiningLogic.SEATS[i].x * DiningLogic.W - float(st[1])) < 1.0, true, "%d번 자리는 그 스툴 가운데" % i)
		_eq(Shop4.SEAT_KEY[i] > 0.0, true, "%d번 자리 그리는 순서" % i)
	var kp := DiningLogic._path_to_guest(DiningLogic.COOK_SPOT, 0)
	_eq(kp[0], DiningLogic.KITCHEN_EXIT, "주방에서 나갈 땐 주방 출구로")
	# 알바가 서빙을 맡으면 알아서 갖다준다
	var al := DiningLogic.new()
	al.setup(4, _fish_box(12), names)
	al.helper_serve = true
	al.place_staff()
	_run_dining(al, false)
	_eq(al.served.size(), al.served.size() + al.angry - al.angry, "알바 셈")
	_eq(al.angry, 0, "알바가 나르면 화난 손님 없음")
	# 조이스틱: 가운데는 멈춤, 미는 쪽으로, 원판 끝까지 밀면 세기 1
	_eq(Joystick.dir_from(Vector2(3, 2), 100.0), Vector2.ZERO, "조이스틱 가운데는 멈춤")
	_eq(Joystick.dir_from(Vector2(0, -100), 100.0), Vector2.UP, "끝까지 위로 밀면 위로 세기 1")
	_eq(Joystick.dir_from(Vector2(300, 0), 100.0), Vector2.RIGHT, "원판 밖이어도 세기 1까지")
	var half := Joystick.dir_from(Vector2(-50, 0), 100.0)
	_eq(half.x < 0.0 and half.length() < 1.0 and half.length() > 0.3, true, "반만 밀면 반쯤 (%.2f)" % half.length())


## 식당 가구 슬롯: 상점에서 산 의자, 장식을 자리마다 갈아 끼운다 (ShopDecor)
func _test_shop_decor() -> void:
	var decor := {}
	var owned := []
	_eq(DiningLogic.SEATS.size(), 16, "손님 자리 16석 (식당 4안)")
	var chairs := ShopDecor.slots().filter(func(s): return s.kind == "chair").size()
	_eq(chairs, 16, "의자 슬롯은 자리마다")
	_eq(ShopDecor.item_in(decor, "chair_3"), "chair_basic", "안 놓으면 기본 의자")
	_eq(ShopDecor.item_in(decor, "bar_0"), "bar_none", "바 위는 기본 빈 자리")
	_eq(ShopDecor.art_of("bar_none"), "", "빈 자리는 그리지 않음")
	_eq(ShopDecor.art_of("chair_wood"), "decor/chair_wood", "그림 경로")
	_eq(ShopDecor.place(decor, owned, "chair_0", "chair_wood"), false, "안 산 의자는 못 놓음")
	owned.append("chair_wood")
	_eq(ShopDecor.place(decor, owned, "chair_0", "chair_wood"), true, "산 의자 놓기")
	_eq(ShopDecor.place(decor, owned, "bar_0", "chair_wood"), false, "의자를 바 위에 놓을 순 없음")
	_eq(ShopDecor.place(decor, owned, "nope", "chair_wood"), false, "없는 슬롯")
	_eq(ShopDecor.place_all(decor, owned, "chair", "chair_wood"), 16, "의자 한 번에 바꾸기")
	_eq(ShopDecor.place(decor, owned, "wall_0", "wall_none"), true, "기본 물건은 사지 않아도 놓음")
	decor["bar_1"] = "chair_wood" # 망가진 저장값
	_eq(ShopDecor.item_in(decor, "bar_1"), "bar_none", "종류가 틀린 값은 기본으로")
	# 편한 의자는 손님이 더 오래 기다려 준다
	var comfort := ShopDecor.seat_comfort(decor)
	_eq(comfort[0], 5.0, "나무 의자 편안함")
	var d := DiningLogic.new()
	d.seat_bonus = comfort
	_eq(d.patience_of(0), DiningLogic.PATIENCE + 5.0, "편한 의자 자리는 더 참음")
	_eq(d.patience_of(99), DiningLogic.PATIENCE, "모르는 자리는 기본")
	_eq(ShopDecor.item_in(decor, "table"), "", "4안은 바 슬롯 없음 (Shop4 낱장)")
	_eq(ShopDecor.slots().filter(func(s): return s.kind == "lamp").size(), 0, "4안은 천장 등을 Shop4가 그림")
	for sl in ShopDecor.slots():
		_eq(sl.pos.x >= 0.0 and sl.pos.x <= 1.0 and sl.pos.y >= 0.0 and sl.pos.y <= 1.0, true, "%s 자리는 배경 안" % sl.id)
	for k in ShopDecor.SHOP_KINDS:
		_eq(ShopDecor.slots().any(func(s): return s.kind == k), true, "상점 종류 %s는 자리가 있음" % k)
	for k in ShopDecor.DRAWN_KINDS:
		_eq(ShopDecor.SHOP_KINDS.has(k), true, "그리는 종류 %s는 상점에 있음" % k)
	# 4안 자리: 그리는 종류는 모두 순서(key)가 있고, 손님 서빙 자리와 겹치지 않는다
	for sl in ShopDecor.EXTRA_SLOTS:
		_eq(sl.has("key"), true, "%s 그리는 순서" % sl.id)
		var big := ""
		for id in ShopDecor.items_of(sl.kind):
			if not ShopDecor.art_of(id).is_empty() and ArtSlot.has_art(ShopDecor.art_of(id)):
				big = ShopDecor.art_of(id)
		if big.is_empty():
			continue
		var r := ShopDecor.draw_rect(sl, (load(ArtSlot.art_path(big)) as Texture2D).get_size())
		for i in DiningLogic.SPOTS.size():
			var sp: Vector2 = DiningLogic.SPOTS[i] * Shop4.SIZE
			_eq(r.has_point(sp), false, "%s 자리가 %d번 서빙 자리를 막지 않음" % [sl.id, i])
	var wr := ShopDecor.draw_rect({"kind": "wall", "pos": Vector2(0.5, 0.5)}, Vector2(100, 200))
	_eq(wr.get_center().y, 0.5 * Shop4.SIZE.y, "벽 장식은 가운데 기준")
	var pr := ShopDecor.draw_rect({"kind": "plant", "pos": Vector2(0.5, 0.5)}, Vector2(100, 200))
	_eq([pr.end.y, pr.size.y], [0.5 * Shop4.SIZE.y, 112.0], "화분은 아래 가운데 기준, 높이 112")
	# 저장된다
	var gs = load("res://scripts/autoload/game_state.gd").new()
	_eq(SaveGame.fields(gs).has("shop_decor") and SaveGame.fields(gs).has("owned_decor"), true, "가구는 저장됨")
	gs.free()


## 감성돔은 장비 덕을 덜 본다: 단계가 오를수록 장력이 덜 오르지만, 보통 고기보다 덜 준다
func _test_gear_help() -> void:
	var prev := 2.0
	var mono := true
	for tier in range(1, 11):
		var l := FishingLogic.new()
		GearDB.apply(l, "rod_%d" % tier, "reel_%d" % tier)
		l.fish_id = "gamseongdom"
		var g := l.gear_tension()
		if g > prev:
			mono = false
		prev = g
		if tier == 1:
			_eq(g, l.tension_mult, "1단계는 감성돔도 장비 그대로")
		if tier == 4:
			_eq(g > l.tension_mult, true, "감성돔은 장비 덕을 덜 봄")
			l.fish_id = "bolak"
			_eq(l.gear_tension(), l.tension_mult, "보통 고기는 장비 그대로")
	_eq(mono, true, "장비 단계가 오를수록 감성돔 장력도 덜 오름")


## 식당 곁들임: 텃밭 채소와 달걀이 접시 값을 올린다. 부탁 몫은 남긴다 (Sides)
func _test_sides() -> void:
	_eq(Sides.bonus("egg"), Sides.EGG_BONUS, "달걀 곁들임 값")
	_eq(Sides.bonus("baechu"), int(CropDB.crop("baechu").bonus), "채소 곁들임 값은 CropDB")
	_eq(Sides.bonus("없는것"), 0, "모르는 것은 0")
	var pantry := {"daepa": 3, "egg": 2, "baechu": 0}
	_eq(Sides.pick(pantry, {}), "egg", "값 큰 것부터 (달걀 700 > 대파 500)")
	_eq(Sides.take(pantry, {}), "egg", "꺼내기")
	_eq(pantry.egg, 1, "하나 줄어듦")
	var only_daepa := {"daepa": 2}
	_eq(Sides.pick(only_daepa, {"daepa": 2}), "", "부탁 몫 대파 2단은 남김")
	_eq(Sides.pick({"daepa": 3}, {"daepa": 2}), "daepa", "남는 대파는 곁들임")
	_eq(Sides.take({}, {}), "", "없으면 빈 문자열")
	var gs = load("res://scripts/autoload/game_state.gd").new()
	gs.sundeok_quest = 1 # 둘째 부탁: 대파 2단
	_eq(Sides.reserve_for(gs), {"daepa": 2}, "대파 부탁이면 남겨 둠")
	gs.sundeok_quest = 3
	_eq(Sides.reserve_for(gs), {}, "부탁을 다 들어주면 남길 것 없음")
	gs.free()
	# 영업: 곁들임이 있으면 값이 오르고 보관에서 빠진다
	var a := DiningLogic.new()
	a.setup(4, _fish_box(12), ["손님"])
	a.pantry = {"egg": 2}
	_run_dining(a, true)
	var with_side := a.served.filter(func(e): return e.side == "egg").size()
	_eq(with_side, 2, "달걀 두 개는 두 접시에")
	_eq(a.pantry.egg, 0, "달걀 다 씀")
	_eq(a.side_sales, Sides.EGG_BONUS * 2, "곁들임 매출")
	var b := DiningLogic.new()
	b.setup(4, _fish_box(12), ["손님"])
	_run_dining(b, true)
	_eq(a.sales - b.sales, Sides.EGG_BONUS * 2, "곁들임만큼 매출이 더 많음")


## 지도 위 걷는 주민 (Walkers)
func _test_walkers() -> void:
	var path := [Vector2(0.0, 0.0), Vector2(0.06, 0.0)]
	_eq(is_equal_approx(Walkers.path_length(path), 0.06), true, "길 길이")
	var walk := 0.06 / Walkers.SPEED
	var p0 := Walkers.pose(path, 0.0)
	_eq([p0.pos, p0.dir], [Vector2(0, 0), Vector2.RIGHT], "처음엔 시작점에서 오른쪽으로")
	var mid := Walkers.pose(path, walk / 2.0)
	_eq(is_equal_approx(mid.pos.x, 0.03), true, "반쯤 가면 가운데")
	_eq(Walkers.pose(path, walk + 0.5).dir, Vector2.ZERO, "끝에서 잠깐 섬")
	var back := Walkers.pose(path, walk + Walkers.PAUSE + walk / 2.0)
	_eq(back.dir, Vector2.LEFT, "되돌아올 땐 왼쪽으로")
	_eq(Walkers.frame(Vector2.ZERO, 3.0), [0, false], "서 있으면 앞모습")
	_eq(Walkers.frame(Vector2.LEFT, 0.0), [4, true], "왼쪽은 옆모습 뒤집기")
	_eq(Walkers.frame(Vector2.UP, 0.0)[0] in [2, 3], true, "위로 가면 뒷모습")
	_eq(Walkers.active(6 * 60).map(func(w): return w.id), ["mansu"], "새벽엔 만수만")
	_eq(Walkers.active(23 * 60).is_empty(), true, "밤엔 아무도 없음")
	var all_have := true
	for w in Walkers.LIST:
		if not ResourceLoader.exists("res://assets/art/sd_guest/%s_walk.png" % w.id):
			all_have = false
	_eq(all_have, true, "걷는 주민 모두 걷기 그림 있음")
	# 여덟 칸 자르기
	var cols := PackedFloat32Array()
	cols.resize(800)
	cols.fill(5.0)
	for k in range(1, 8):
		cols[k * 100 + 7] = 0.0
	_eq(GuestSD.find_cuts_n(cols, 8), [0, 107, 207, 307, 407, 507, 607, 707, 800], "여덟 칸 경계")


## 주방: 세라가 늘 굽고 노릇할 때 담는다. 주인공이 굽는 판(첫날, 시험)은 노릇할 때 눌러 담는다
func _test_kitchen() -> void:
	var g0 := {"name": "x", "seat": 0, "fish": "bolak", "size": 15.0, "entry": {}, "price": 6000, "state": DiningLogic.GuestState.SEATED, "wait": 0.0, "eat": 0.0, "cooked": false, "quality": ""}
	var e := DiningLogic.new()
	_eq(e.helper_kitchen, true, "요리는 세라가 기본")
	e.guests = [g0.duplicate()]
	e.queue = [0]
	for i in 120:
		e.update(1.0 / 10.0)
	_eq([e.pass_dishes, e.guests[0].quality], [[0], "perfect"], "세라는 노릇할 때 담음")
	# 주인공이 굽는 판
	var d := DiningLogic.new()
	d.helper_kitchen = false
	d.place_staff()
	d.guests = [g0.duplicate()]
	d.queue = [0]
	d.update(0.1)
	_eq(d.plate(0), "early", "덜 익으면 못 담음")
	for i in int(DiningLogic.COOK_TIME * 10.0) + 2:
		d.update(0.1)
	_eq(d.at_stove(), true, "주인공은 조리대 뒤")
	_eq(d.plate(0), "perfect", "다 익자마자 담으면 노릇노릇")
	var b := DiningLogic.new()
	b.helper_kitchen = false
	b.place_staff()
	b.guests = [g0.duplicate()]
	b.queue = [0]
	for i in int((DiningLogic.COOK_TIME + DiningLogic.BURN) * 10.0) + 3:
		b.update(0.1)
	_eq([b.pass_dishes, b.guests[0].quality, b.burnt], [[0], "burnt", 1], "너무 두면 타서 저절로 내려옴")
	_eq(DiningLogic.QUALITY_PRICE.burnt < 1.0 and DiningLogic.QUALITY_PRICE.perfect > 1.0, true, "탄 건 싸고 노릇한 건 비쌈")
	# 서빙 알바는 맨 앞 접시를 알아서 나른다
	var a := DiningLogic.new()
	a.helper_serve = true
	a.place_staff()
	a.guests = [g0.duplicate()]
	a.guests[0].cooked = true
	a.pass_dishes = [0]
	a.update(0.1)
	_eq(a.helper_dish, 0, "서빙 알바가 접시를 집음")
	for i in 60:
		a.update(0.1)
	_eq([a.guests[0].state, a.served.size()], [DiningLogic.GuestState.EATING, 1], "서빙 알바가 갖다줌")
	# 혼자 잘하면 다 받는다
	var s := DiningLogic.new()
	s.setup(4, _fish_box(12), ["손님"])
	_run_dining(s, true)
	_eq(s.angry, 0, "혼자서도 잘 나르면 화난 손님 없음")


## 알바 (StaffDB): 한 번 뽑으면 계속, 역할마다 한 명, 일당
func _test_staff() -> void:
	var staff := {}
	_eq(StaffDB.wages(staff), 0, "알바 없으면 일당 0")
	_eq(StaffDB.hire(staff, "yeoul"), true, "여울 뽑기")
	_eq(StaffDB.in_role(staff, "serve"), "yeoul", "여울은 서빙")
	_eq(StaffDB.wages(staff), 20000, "여울 일당 2만")
	_eq(StaffDB.hire(staff, "sera"), false, "세라는 알바가 아니라 요리사 (뽑지 않음)")
	_eq(StaffDB.wages({"kitchen": "sera"}), 0, "예전 저장의 주방 알바는 일당 없음")
	_eq(ArtSlot.has_art(StaffDB.COOK.sd_cook), true, "요리사 세라 조리 그림")
	_eq(ArtSlot.has_art(StaffDB.COOK.sd_walk), true, "요리사 세라 걷기 그림")
	_eq(ArtSlot.has_art(StaffDB.COOK.sd_react), true, "요리사 세라 반응 그림")
	StaffDB.fire(staff, "yeoul")
	_eq([StaffDB.is_hired(staff, "yeoul"), StaffDB.wages(staff)], [false, 0], "그만두면 일당도 빠짐")
	_eq(Story.SERA_ARRIVES.size() > 3, true, "세라가 오는 이야기")
	_eq(StaffDB.hire(staff, "없는사람"), false, "없는 알바는 못 뽑음")
	for id in StaffDB.LIST:
		_eq(ArtSlot.has_art(StaffDB.LIST[id].art), true, "%s 그림" % id)
	var gs = load("res://scripts/autoload/game_state.gd").new()
	_eq(SaveGame.fields(gs).has("staff"), true, "알바는 저장됨")
	gs.free()


## 앉은 손님 그림: 앉은 시트가 있으면 앉고, 없으면 서 있는 그림
func _test_seated() -> void:
	_eq(GuestSD.has_seat("mansu", "back") and GuestSD.has_seat("mansu", "side"), true, "만수 앉은 그림 두 장")
	_eq(GuestSD.has_seat("mansu", ""), false, "앉는 방향이 없으면 앉은 그림 아님")
	var sd := GuestSD.new()
	sd.guest_id = "mansu"
	sd.seat = "side"
	_eq(sd.seated(), true, "옆모습 앉기")
	sd.guest_id = "없는사람"
	_eq(sd.seated(), false, "그림 없으면 서 있는 그림으로")
	sd.free()
	_eq(GuestSD.SEAT_POSES.size(), 4, "앉은 자세 네 가지 (기다림, 먹는 중, 만족, 화남)")
	var views := {}
	for v in DiningLogic.SEAT_VIEW:
		views[v] = int(views.get(v, 0)) + 1
	_eq(views, {"back": 8, "side": 4, "front": 4}, "홀 자리 방향: 등 8, 옆 4, 얼굴 4")
	# 앞모습 시트가 없는 손님은 옆모습으로 대신 앉는다
	var fr := GuestSD.new()
	fr.guest_id = "mansu"
	fr.seat = "front"
	_eq(fr.seat_kind(), "front", "만수는 앞모습 시트 있음")
	fr.guest_id = "guest_fisher"
	_eq(fr.seat_kind(), "front" if GuestSD.has_seat("guest_fisher", "front") else "side", "앞모습 없으면 옆모습")
	fr.free()
	# 엉덩이 자리 맞추기: 칸마다 그림 사각형과 엉덩이 비율
	var cells := GuestSD.seat_cells("mansu", "side")
	_eq(cells.cells.size(), 4, "앉은 시트 네 칸")
	_eq(is_equal_approx(float(cells.hip), 0.20), true, "만수 옆모습 엉덩이 비율")
	_eq(float(cells.butt[0]) >= 0.0 and float(cells.butt[0]) < cells.cells[0].size.x * 0.5, true, "엉덩이 뒤쪽 끝은 칸 왼쪽 절반 안 (%.0f)" % float(cells.butt[0]))


## 순덕 할머니 집 그림: 부탁에 맞는 동작
func _test_sundeok_art() -> void:
	var gs = load("res://scripts/autoload/game_state.gd").new()
	var arts := []
	for q in [0, 1, 2, 3]:
		gs.sundeok_quest = q
		arts.append(Coop.sundeok_art(gs))
	_eq(arts, ["npc_sundeok_pot", "npc_sundeok_pot", "npc_sundeok_photo", "npc_sundeok"], "부탁마다 할머니 동작")
	for a in arts:
		_eq(ArtSlot.has_art(a), true, "%s 그림 있음" % a)
	gs.free()


## 가게 꾸미기: 사기, 종류 전체 놓기, 그림
func _test_decor_shop() -> void:
	var owned := []
	var decor := {}
	_eq(ShopDecor.buy(owned, "chair_wood", 10000), -1, "돈 모자라면 못 삼")
	_eq(ShopDecor.buy(owned, "chair_wood", 50000), 30000, "나무 의자 3만")
	_eq(ShopDecor.buy(owned, "chair_wood", 50000), -1, "이미 있으면 또 안 삼")
	_eq(ShopDecor.buy(owned, "chair_basic", 50000), -1, "기본 물건은 안 삼")
	ShopDecor.place_all(decor, owned, "chair", "chair_wood")
	_eq(ShopDecor.kind_item(decor, "chair"), "chair_wood", "의자 한 번에 바뀜")
	_eq(ShopDecor.kind_item(decor, "wall"), "wall_none", "벽은 그대로 빈 벽")
	_eq(ShopDecor.items_of("chair"), ["chair_basic", "chair_wood", "chair_cushion"], "의자 값 싼 순")
	for id in ShopDecor.ITEMS:
		var art := ShopDecor.art_of(id)
		if not art.is_empty():
			_eq(ArtSlot.has_art(art), true, "%s 그림" % id)


## 버스와 읍내 장터, 옆마을 손님 (2026-11-18)
func _test_bus() -> void:
	_eq(Bus.next_departure(7 * 60), 8 * 60, "아침 7시면 8시 첫차")
	_eq(Bus.next_departure(8 * 60), 8 * 60, "딱 8시면 그 차를 탄다")
	_eq(Bus.next_departure(8 * 60 + 1), 11 * 60, "8시를 놓치면 11시")
	_eq(Bus.next_departure(17 * 60 + 5), -1, "막차 뒤엔 없음")
	_eq(Bus.returns_after(8 * 60 + Bus.RIDE), [10 * 60, 13 * 60, 16 * 60, 19 * 60], "첫차로 오면 네 대 다 남음")
	_eq(Bus.returns_after(17 * 60 + Bus.RIDE), [19 * 60], "막차로 오면 돌아갈 버스 하나")
	for t in Bus.TO_TOWN:
		_eq(Bus.returns_after(int(t) + Bus.RIDE).is_empty(), false, "읍내에 갇히지 않음 %d" % t)
	_eq(Bus.TO_VILLAGE[-1] + Bus.RIDE < DayFlow.SHOP_CLOSE, true, "막차로 와도 가게 닫기 전")
	_eq(Bus.clock(8 * 60 + 5), "08:05", "시각 글자")
	_eq(Bus.fish_price("bolak", 20.0) > Market.price("bolak", 20.0), true, "읍내 도매상이 시장보다 조금 비쌈")
	_eq(Bus.fish_price("bolak", 20.0) < DayFlow.dish_price("bolak", 20.0) - DayFlow.DISH_COST + Bus.FARE, true, "흔한 고기는 여전히 식당이 나음 (차비 감안)")
	_eq(Bus.bait_price("worm") < int(BaitDB.bait("worm").price), true, "읍내 미끼가 쌈")
	_eq(Bus.visitors(0, 5), 0, "평판 0이면 외지 손님 없음")
	_eq(Bus.visitors(Bus.VISIT_STEP - 1, 5), 0, "평판이 모자라면 없음")
	var most := 0
	for d in 30:
		var v := Bus.visitors(9999, d)
		_eq(v >= Bus.VISIT_MAX - 1 and v <= Bus.VISIT_MAX, true, "평판 높으면 %d~%d명" % [Bus.VISIT_MAX - 1, Bus.VISIT_MAX])
		most = maxi(most, v)
	_eq(most, Bus.VISIT_MAX, "가끔 꽉 차게 옴")
	# GameState 값 바꿔 사고팔기
	var gs = load("res://scripts/autoload/game_state.gd").new()
	var money0: int = gs.money
	gs.money = 50000
	var before: int = gs.bait_count("worm")
	_eq(gs.buy_bait("worm", Bus.bait_price("worm")), "", "도매값으로 미끼 삼")
	_eq(gs.money, 50000 - Bus.bait_price("worm"), "도매값만큼 나감")
	_eq(gs.bait_count("worm"), before + int(BaitDB.bait("worm").amount), "묶음 수만큼 늘어남")
	var e := {"id": "bolak", "size": 20.0, "day": gs.day}
	gs.inventory.append(e)
	var m1: int = gs.money
	_eq(gs.sell_fish(e, Bus.fish_price("bolak", 20.0)), Bus.fish_price("bolak", 20.0), "읍내 값으로 팖")
	_eq(gs.money, m1 + Bus.fish_price("bolak", 20.0), "돈이 들어옴")
	gs.money = money0
	gs.free()
	# 영업: 외지 손님은 명단 끝에 붙고 버스 손님 이름이다
	var a := DiningLogic.new()
	a.setup(7, [], DayFlow.GUESTS)
	var b := DiningLogic.new()
	b.setup(7, [], DayFlow.GUESTS, 2)
	_eq(b.schedule.size(), a.schedule.size() + 2, "외지 손님 두 명 더")
	var names_a := a.schedule.map(func(x): return x.name)
	var c := DiningLogic.new()
	c.setup(7, [], DayFlow.GUESTS, 0)
	_eq(c.schedule.map(func(x): return x.name), names_a, "외지 손님 0이면 예전 명단 그대로")
	var bus_guests := b.schedule.filter(func(x): return x.name in Bus.VISITOR_NAMES)
	_eq(bus_guests.size(), 2, "버스 손님 이름 둘")
	var last_local := 0.0
	for x in b.schedule:
		if not x.name in Bus.VISITOR_NAMES:
			last_local = maxf(last_local, x.t)
	_eq(bus_guests.all(func(x): return x.t >= last_local - 8.0), true, "버스 손님은 늦게 온다")


## 마을회관 의뢰 게시판 (2026-11-18)
func _test_board() -> void:
	_eq(Board.posted_on(10), Board.posted_on(10), "같은 날은 같은 의뢰")
	var total := 0
	var eggs_before := 0
	for d in range(2, 60):
		var ps := Board.posted_on(d)
		_eq(ps.size() >= 1 and ps.size() <= 2, true, "하루 1~2장 %d" % d)
		total += ps.size()
		for p in ps:
			_eq(p.reward >= Board.MIN_REWARD, true, "사례금 최소 %s" % p.id)
			_eq(p.item != "egg", true, "닭장 전엔 달걀 의뢰 없음 %s" % p.id)
			_eq(Board.item_name(p.kind, p.item).is_empty(), false, "물건 이름 %s" % p.id)
			_eq(p.text.contains("%"), false, "쪽지 글 완성 %s" % p.id)
			_eq(p.text.contains("—") or p.text.contains("ㅡ"), false, "줄표 없음 %s" % p.id)
	var with_egg := 0
	for d in range(2, 60):
		for p in Board.posted_on(d, true):
			if p.item == "egg":
				with_egg += 1
	_eq(with_egg > 0, true, "닭장 열리면 달걀 의뢰도 나옴")
	_eq(Board.thing_text("fish", "bolak", 2), "볼락 두 마리", "생선 세는 말")
	_eq(Board.thing_text("produce", "egg", 3), "달걀 세 알", "달걀 세는 말")
	_eq(Board.thing_text("produce", "daepa", 3), "대파 세 단", "대파 세는 말")
	# 붙어 있는 기간 (모두 만난 뒤)
	var flags := {"met_sundeok": true, "met_mansu": true, "met_junho": true, "met_kyungja": true, "met_bokja": true, "met_yongpal": true, "met_taesik": true}.duplicate()
	var p0: Dictionary = Board.posted_on(10)[0]
	_eq(Board.open_on(10, flags).has(p0), true, "붙은 날 보임")
	_eq(Board.open_on(12, flags).has(p0), true, "사흘째까지 보임")
	_eq(Board.open_on(13, flags).has(p0), false, "나흘째엔 떨어짐")
	_eq(Board.days_left(p0, 12), 0, "사흘째가 마지막 날")
	_eq(Board.open_on(1, flags).is_empty(), true, "첫날엔 의뢰 없음")
	# 갖다주기
	var gs = load("res://scripts/autoload/game_state.gd").new()
	var fp := {"id": "t-0", "day": 10, "who": "박만수", "kind": "fish", "item": "bolak", "count": 2, "text": "", "reward": 9000}
	gs.inventory = [{"id": "bolak", "size": 20.0, "day": 10}, {"id": "noraemi", "size": 25.0, "day": 10}]
	_eq(Board.can_deliver(fp, gs.inventory, gs.produce), false, "볼락 한 마리로는 못 줌")
	_eq(Board.deliver(fp, gs), 0, "모자라면 안 줌")
	gs.inventory.append({"id": "bolak", "size": 25.0, "day": 9})
	var m0: int = gs.money
	var r0: int = gs.reputation
	_eq(Board.deliver(fp, gs), 9000, "볼락 두 마리 갖다줌")
	_eq(gs.money, m0 + 9000, "사례금 받음")
	_eq(gs.reputation, r0 + Board.REP, "평판 오름")
	_eq(gs.inventory.size(), 1, "볼락 두 마리 빠짐")
	_eq(gs.inventory[0].id, "noraemi", "다른 생선은 그대로")
	_eq(Board.deliver(fp, gs), 0, "한 번만 들어줌")
	var pp := {"id": "t-1", "day": 10, "who": "복자네 밥집", "kind": "produce", "item": "daepa", "count": 3, "text": "", "reward": 4000}
	gs.produce = {"daepa": 3}
	_eq(Board.deliver(pp, gs), 4000, "대파 세 단 갖다줌")
	_eq(gs.produce.has("daepa"), false, "다 쓰면 목록에서 빠짐")
	gs.flags["bd_" + p0.id] = true
	_eq(Board.open_on(10, gs.flags).has(p0), false, "들어준 의뢰는 떨어짐")
	gs.free()
	# 이장 첫 만남이 회관을 연다
	var ev: Array = Story.EVENTS.filter(func(e): return e.id == "taesik_first")
	_eq(ev.size(), 1, "이장 첫 만남 사건")
	_eq("hall_open" in ev[0].set, true, "회관이 열림")
	_eq(Locations.get_loc("hall").scene, "res://scenes/village/hall.tscn", "회관 화면 연결")


## 식당 4안 물건 배치 (Shop4)
func _test_shop4() -> void:
	_eq(Shop4.SEAT_KEY.size(), 16, "자리마다 그리는 순서")
	_eq(Shop4.SEAT_STOOL.size(), 16, "자리마다 스툴 덮개 표")
	for it in Shop4.ITEMS:
		_eq(ArtSlot.has_art(Shop4.path(it[0], true, it[7])), true, "4안 그림 있음 %s" % it[0])
		_eq(ArtSlot.has_art(Shop4.path(it[0], false, it[7])), true, "4안 낮 그림 있음 %s" % it[0])
	_eq(ArtSlot.has_art(Shop4.bg_id(true)) and ArtSlot.has_art(Shop4.bg_id(false)), true, "빈 바탕 낮밤")
	var r := Shop4.rect_of(["x", 366, 598, 134, 0.0, "bc", false, false], Vector2(1748, 751))
	_eq(r.end.y, 598.0, "아래 가운데 기준이면 바닥이 y")
	_eq(r.get_center().x, 366.0, "아래 가운데 기준이면 가운데가 x")
	var sr := Shop4.stool_rect(Shop4.STOOLS[0])
	_eq([sr.end.y, sr.size.y], [724.0, 111.0], "바 스툴 높이 111, 바닥 724")
	# 뒷모습 손님 엉덩이는 스툴 방석 안에 (방석 윗면과 앞 테두리 사이)
	for i in 16:
		var si: int = Shop4.SEAT_STOOL[i]
		if si < 0:
			continue
		var st: Array = Shop4.STOOLS[si]
		var rr := Shop4.stool_rect(st)
		var y: float = DiningLogic.SEATS[i].y * DiningLogic.H
		_eq(y > rr.position.y and y < rr.position.y + float(Shop4.STOOL_FRONT[st[0]]) * rr.size.y, true, "%d번 엉덩이가 방석 위" % i)
		_eq(Shop4.SEAT_KEY[i] > float(st[3]), true, "%d번 손님은 스툴 다음에 그림" % i)
	# 위쪽 줄 테이블 손님은 테이블보다 먼저 그려 다리가 가린다
	_eq(Shop4.SEAT_KEY[6] < 794.0 and Shop4.SEAT_KEY[10] < 1046.0, true, "테이블 위쪽 줄은 테이블 뒤")
	_eq(Shop4.SEAT_KEY[4] < 1300.0, true, "창가 손님 다리는 창가 바가 덮음")
	# 첫날 정지 화면 (Shop4View): 낮 판 그림이 있고, 덮기는 영업 판과 같다
	_eq(Shop4View.has_art(false), true, "4안 낮 판 그림 있음")
	var v := Shop4View.new()
	v.size = Vector2(720, 1280)
	_eq(v.floor_rect().size.y, 1280.0, "세로 화면은 높이를 맞춰 덮음")
	_eq(v.floor_rect().position.x < 0.0, true, "넘치는 가로는 가운데 기준으로 잘림")
	v.free()


## 낚시터: 북쪽 방파제와 검은여 갯바위 (2026-11-18)
func _test_spots() -> void:
	_eq(Spots.of_location("rocks"), "rocks", "갯바위에서 오면 갯바위")
	_eq(Spots.of_location("home"), "breakwater", "모르는 곳은 방파제")
	_eq(Spots.fish_mult("breakwater", "ureok"), 1.0, "방파제는 배율 그대로")
	var ctx := {"brightness": 0.3, "depth": 0.6, "weather": "sunny"}
	var rc := ctx.duplicate()
	rc["spot"] = "rocks"
	_eq(FishDB.weight_of("ureok", rc) > FishDB.weight_of("ureok", ctx) * 2.0, true, "갯바위는 우럭이 잘 나옴")
	_eq(FishDB.weight_of("mangsang", rc) < FishDB.weight_of("mangsang", ctx), true, "갯바위엔 망상어가 드묾")
	# 감성돔 비율: 방파제보다 갯바위에서 몇 배
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var g := {"breakwater": 0, "rocks": 0}
	for sp in g:
		var c := ctx.duplicate()
		c["spot"] = sp
		for i in 4000:
			if FishDB.pick_ctx(rng, c) == "gamseongdom":
				g[sp] += 1
	_eq(g.rocks > g.breakwater * 2, true, "갯바위 감성돔이 방파제보다 두 배 넘게 (%d / %d)" % [g.rocks, g.breakwater])
	# 물때: 하루 두 번 간조, 날마다 늦어짐
	_eq(Spots.low_tides(1)[0], Spots.FIRST_LOW, "첫날 첫 간조")
	_eq(Spots.low_tides(2)[0], Spots.FIRST_LOW + Spots.TIDE_SHIFT, "다음 날 50분 늦게")
	_eq(Spots.low_tides(1).size(), 2, "하루 두 번")
	var low: int = Spots.low_tides(1)[0]
	_eq(Spots.rocks_until(1, low), low + Spots.LOW_SPAN, "간조 때 열려 있고 한 시간 반 뒤 물이 듦")
	_eq(Spots.rocks_until(1, low + Spots.LOW_SPAN + 10), -1, "물이 들면 닫힘")
	var some := 0
	for d in range(1, 31):
		var times := Spots.rocks_fishing_times(d)
		if not times.is_empty():
			some += 1
		for t in times:
			_eq(Spots.can_fish_rocks(d, int(t[0])), true, "%d일 %s 갯바위 낚시 가능" % [d, Bus.clock(int(t[0]))])
			_eq(Spots.rocks_end(d, int(t[0])) <= int(t[1]), true, "%d일 끝나는 시각은 물이 들거나 시간대가 끝날 때" % d)
	_eq(some >= 20, true, "한 달 중 3분의 2 넘는 날은 갯바위 낚시 시간이 있음 (%d일)" % some)
	_eq(Spots.times_text([[6 * 60, 7 * 60 + 30]]), "06:00~07:30", "시간 글자")
	_eq(Spots.schedule("breakwater", SeaBackdrop.FISHING_SCHEDULE), SeaBackdrop.FISHING_SCHEDULE, "방파제 배경표 그대로")
	_eq(Spots.schedule("rocks", SeaBackdrop.FISHING_SCHEDULE), SeaBackdrop.FISHING_SCHEDULE, "갯바위 그림이 없으면 방파제 배경표")
	# 만수 이야기가 갯바위를 연다
	var ev: Array = Story.EVENTS.filter(func(e): return e.id == "mansu_rocks")
	_eq(ev.size(), 1, "만수 갯바위 사건")
	_eq("learned_tide" in ev[0].set and "caught_gamseongdom" in ev[0].needs, true, "감성돔을 잡아야 열림")
	_eq(Locations.get_loc("rocks").scene, "res://scenes/fishing/fishing.tscn", "갯바위는 낚시 화면")
	_eq(Locations.get_loc("rocks").unlock, "learned_tide", "물때를 배워야 열림")
	# 낚시 규칙: 갯바위 고기는 조금 더 크다
	var a := FishingLogic.new()
	a.spot = "rocks"
	_eq(a.spot, "rocks", "낚시 규칙에 낚시터")


## 이야기 목록: 메인, 서브, 오늘 부탁과 맥락 (11-19)
func _test_quests() -> void:
	# 주문과 게시판은 만난 사람만
	_eq(Orders.of(5, {}), {}, "아무도 안 만났으면 주문 없음")
	for d in range(2, 30):
		_eq(Orders.of(d, {"met_sundeok": true}).get("customer", ""), "최순덕", "%d일: 순덕 할머니만 만났으면 순덕 할머니 주문" % d)
	_eq(Orders.of(7).is_empty(), false, "flags 없이 부르면 예전처럼 아무나")
	for d in range(9, 30):
		for p in Board.posted_on(d, false, {"met_taesik": true}):
			_eq(p.who, "정태식 이장", "%d일: 모르는 사람 자리는 이장이 붙임" % d)
	var gs = load("res://scripts/autoload/game_state.gd").new()
	gs.day = 1
	_eq(Quests.main_quest(gs).id, "main_first_guest", "첫날 메인: 첫 번째 손님")
	gs.flags["first_guest_done"] = true
	gs.flags["met_sundeok"] = true
	gs.day = 2
	var m: Dictionary = Quests.main_quest(gs)
	_eq(m.id, "main_greet", "둘째 날 메인: 마을에 인사하기")
	_eq(m.progress, "0/4", "인사 0/4")
	_eq(m.target, "breakwater", "먼저 방파제 노인")
	_eq(m.who, "순덕 할머니", "인사하라고 한 사람")
	for f in ["met_mansu", "met_yongpal", "met_kyungja", "met_bokja"]:
		gs.flags[f] = true
	_eq(Quests.main_quest(gs).id, "main_first_month", "다 만나면 첫 달 버티기")
	gs.day = 40
	_eq(Quests.main_quest(gs).id, "main_wait", "첫 달이 지나면 1막 끝")
	gs.arrears = 10000
	_eq(Quests.main_quest(gs).goal.contains("밀린 돈"), true, "밀린 돈이 있으면 갚기")
	gs.arrears = 0
	# 서브: 부탁을 들은 뒤에만
	var subs: Array = Quests.sub_quests(gs).map(func(q): return q.id)
	_eq(subs, ["sub_sundeok"], "순덕 할머니 부탁만 (만수, 해솔은 아직 부탁 전)")
	gs.flags["learned_tide_talk"] = true
	gs.flags["hw_haesol"] = true
	gs.flags["hw_lookout"] = true
	subs = Quests.sub_quests(gs).map(func(q): return q.id)
	_eq(subs, ["sub_sundeok", "sub_mansu", "sub_haesol"], "부탁을 들으면 생김")
	var hs: Dictionary = Quests.sub_quests(gs)[2]
	_eq(hs.progress, "1/3", "해솔 숙제 1/3")
	_eq(hs.target, "market", "다음 자랑거리는 시장")
	gs.flags["coop_open"] = true
	gs.flags["learned_tide"] = true
	_eq(Quests.sub_quests(gs).map(func(q): return q.id), ["sub_haesol"], "끝난 이야기는 사라짐")
	# 오늘 부탁: 모든 줄에 누가와 왜
	gs.flags["hall_open"] = true
	gs.flags["met_taesik"] = true
	gs.day = 12
	var daily: Array = Quests.daily_quests(gs)
	_eq(daily.size() >= 2, true, "주문 쪽지와 게시판 의뢰")
	for q in Quests.active(gs):
		_eq(q.who.is_empty() and q.kind != "main", false, "%s: 누가 부탁했는지 있음" % q.id)
		_eq(q.why.is_empty(), false, "%s: 왜 하는지 있음" % q.id)
	var names: Array = DayBrief.build(gs).sections.map(func(s): return s.name)
	_eq(names.has("메인 이야기") and names.has("마을 사람 이야기") and names.has("오늘 부탁"), true, "서랍에 이야기 세 칸")
	gs.free()


## 아이스박스 골라 놓아주기, 쿨러, 낚시방 도구, 통발 (11-19, 여울 참고)
func _test_kits() -> void:
	var gs = load("res://scripts/autoload/game_state.gd").new()
	gs.day = 5
	gs.icebox_size = 2
	gs.store_catch({"id": "bolak", "size": 20.0})
	gs.store_catch({"id": "bolak", "size": 15.0})
	_eq(gs.store_catch({"id": "ureok", "size": 30.0}, false), {}, "골라 놓아주기: 바로 놓아주지 않음")
	_eq(gs.is_overfull(), true, "넘친 채로 둠")
	_eq(gs.release_fish(gs.inventory[0]), true, "고른 고기 놓아주기")
	_eq(gs.is_overfull(), false, "한 마리 놓아주면 들어감")
	_eq(gs.release_fish({"id": "x", "size": 1.0}), false, "없는 고기는 못 놓아줌")
	_eq(gs.store_catch({"id": "bolak", "size": 10.0}).is_empty(), false, "기본은 예전처럼 가장 싼 것을 놓아줌")
	# 쿨러
	gs.money = 1_000_000
	gs.cooler = 0
	gs.icebox_size = 10
	_eq(gs.buy_cooler(), "", "쿨러 사기")
	_eq(gs.icebox_size, KitDB.COOLERS[1].size, "칸 수가 늘어남")
	gs.cooler = KitDB.COOLERS.size() - 1
	_eq(gs.buy_cooler().is_empty(), false, "끝 단계면 더 못 삼")
	# 도구
	_eq(KitDB.level(gs.kits, "line"), 0, "처음엔 줄 없음")
	_eq(gs.buy_kit("line"), "", "줄 사기")
	_eq(gs.buy_kit("line"), "", "다음 단계 줄")
	_eq(KitDB.level(gs.kits, "line"), 2, "줄 2단계")
	_eq(KitDB.effect_text("line", 2), "장력이 5% 덜 오른다", "효과 글")
	_eq(KitDB.effect_text("hook", 1), "줄이 느슨해도 0.15초 더 버틴다", "소수 효과 글")
	for i in 4:
		gs.buy_kit("chair")
	_eq(gs.buy_kit("chair").is_empty(), false, "4단계 넘으면 못 삼")
	var l := FishingLogic.new()
	GearDB.apply(l, "rod_1", "reel_1")
	var base_t := l.tension_mult
	l.bite_mult = 1.0
	KitDB.apply(l, {"line": 4, "net": 2, "chair": 1, "lamp": 1, "boots": 1}, false, "sunny")
	_eq(l.tension_mult < base_t, true, "줄: 장력 덜 오름")
	_eq(is_equal_approx(l.land_at, 0.07), true, "뜰채: 7%에서 떠 올림")
	_eq(is_equal_approx(l.bite_mult, 1.04), true, "낮 맑은 날은 의자만")
	l.bite_mult = 1.0
	KitDB.apply(l, {"chair": 1, "lamp": 1, "boots": 1}, true, "rain")
	_eq(is_equal_approx(l.bite_mult, 1.13), true, "밤 비 오는 날은 의자, 랜턴, 장화")
	# 태클박스: 미끼 묶음이 더 들어감
	gs.kits["tacklebox"] = 2
	var before: int = maxi(gs.bait_count("worm"), 0)
	gs.buy_bait("worm")
	_eq(gs.bait_count("worm") - before, int(BaitDB.bait("worm").amount) + 4, "태클박스 2단계: 4개 더")
	# 통발
	_eq(KitDB.trap_night({}, 0, 3), [], "통발 없으면 빈손")
	var total := 0
	for d in range(1, 40):
		var got := KitDB.trap_night({"trap": 3}, 0, d)
		_eq(got.size() <= 2, true, "%d일: 통발 3단계는 두 마리까지" % d)
		total += got.size()
		for e in got:
			_eq(KitDB.TRAP_POOL.has(e.id), true, "통발엔 바위 고기")
	_eq(total > 20, true, "통발에 꾸준히 든다 (%d)" % total)
	_eq(KitDB.trap_night({"trap": 3}, 2, 5), [], "이미 차 있으면 더 안 듦")
	gs.kits = {"trap": 4}
	gs.inventory = []
	gs.icebox_size = 10
	for i in 10:
		gs.end_day()
	_eq(gs.trap_fish.size() <= 2, true, "걷지 않으면 통발 자리만큼만 쌓임")
	var had: int = gs.trap_fish.size()
	_eq(gs.haul_traps().size(), had, "방파제에서 걷기")
	_eq(gs.inventory.size(), had, "걷은 고기는 아이스박스로")
	_eq(gs.trap_fish.size(), 0, "통발 비움")
	gs.free()
