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
	_eq(Locations.is_visible("rocks", {}), true, "잠긴 보통 장소는 점으로 보임")
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
	# 시간대: 새벽 05~07, 아침 07~11, 밤 21~23:30
	_eq(DayFlow.fishing_slot(5 * 60).get("id", ""), "dawn", "05:00 새벽 낚시")
	_eq(DayFlow.fishing_slot(7 * 60).get("id", ""), "morning", "07:00 아침 낚시")
	_eq(DayFlow.can_fish(12 * 60), false, "한낮엔 낚시 못 함")
	_eq(DayFlow.can_fish(19 * 60), false, "영업 시간엔 낚시 못 함")
	_eq(DayFlow.fishing_slot(22 * 60).get("id", ""), "night", "22:00 밤 낚시")
	_eq(DayFlow.fishing_end(6 * 60), 7 * 60, "새벽 낚시는 7시에 끝")
	_eq(DayFlow.fishing_end(9 * 60), 11 * 60, "아침 낚시는 11시에 끝")
	# 밤 낚시하면 늦잠
	_eq(DayFlow.wake_time(false), 5 * 60, "보통은 새벽 5시 기상")
	_eq(DayFlow.wake_time(true), 7 * 60, "밤 낚시 뒤엔 7시 기상 (새벽 건너뜀)")
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
	_eq(DayFlow.next_hint(5 * 60, false).contains("새벽 낚시"), true, "새벽 안내")
	_eq(DayFlow.next_hint(13 * 60, false).contains("저녁 6시"), true, "낮 안내: 가게 여는 시각")
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
	_eq(Orders.call_name("최순덕"), "순덕 할머니", "부르는 이름")
	for c in Orders.CUSTOMERS:
		_eq(c.react.size(), 3, "%s 반응 세 가지" % c.name)


func _test_market() -> void:
	_eq(Market.is_open(5 * 60), true, "새벽 5시 엶")
	_eq(Market.is_open(16 * 60 + 59), true, "오후 5시 전까지")
	_eq(Market.is_open(17 * 60), false, "오후 5시 닫음")
	_eq(Market.is_open(22 * 60), false, "밤엔 닫음")
	_eq(Market.price("bolak", 20.0) < DayFlow.dish_price("bolak", 20.0), true, "흔한 고기는 식당이 더 남음")
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
	_eq(names, ["지금 할 일", "오늘 주문", "오늘의 바다", "아침 소식"], "서랍 분류")
	var todo: Array = b.sections[0].rows
	_eq(todo[0].target, "breakwater", "새벽 6시엔 먼저 낚시")
	_eq(todo[0].state, "~7:00", "낚시 끝 시각")
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
	for id in ["noraemi", "ureok", "hakgongchi", "gamseongdom"]:
		_eq(FishDB.habit_text(id).is_empty(), false, "%s 버릇 설명" % id)
	_eq(FishDB.habit_text("bolak"), "", "볼락은 버릇 없음")
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
	var o := Orders.of(gs.day)
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
	# 대 끝 빛: 느슨하면 없음, 알맞으면 청록, 위험하면 빨강
	_eq(FightView.tip_glow(slack * 0.5).a, 0.0, "느슨하면 대 끝 빛 없음")
	var mid := FightView.tip_glow(0.5)
	_eq(mid.a > 0.3 and mid.g > mid.r, true, "알맞으면 청록빛")
	var hot := FightView.tip_glow(danger + 0.05)
	_eq(hot.a == 1.0 and hot.r > hot.g, true, "위험하면 빨갛게")
	# 줄: 느슨할 때만 처지고, 위험 앞에서 붉어진다
	_eq(FightView.line_sag(0.0), FightView.SAG_MAX, "장력 없으면 줄이 가장 처짐")
	_eq(FightView.line_sag(slack), 0.0, "알맞음부터 줄이 곧음")
	_eq(FightView.line_sag(0.9), 0.0, "위험해도 줄은 곧음")
	_eq(FightView.line_red(0.5), 0.0, "알맞을 때 줄은 흰색")
	_eq(FightView.line_red(danger), 1.0, "위험하면 줄이 다 붉음")
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
