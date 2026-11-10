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
	_eq(l.cast_power > 0.4 and l.cast_power < 0.7, true, "0.5초 힘 (%.2f)" % l.cast_power)
	_run_until(l, [S.WAITING], never, 2.0)
	_eq(l.state, S.WAITING, "던진 뒤 기다리기")

	l.press()
	_eq(l.state, S.FAILED, "기다리는 중 누르면 실패")
	_eq(l.fail_reason in ["early", "nibble"], true, "일찍 챈 이유")
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
	_eq(HudText.date_text(3), "3일차", "날짜")
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
	gs.free()
	_eq(Locations.is_unlocked("garden", {}), true, "텃밭은 처음부터 열림")
	_eq(Locations.is_unlocked("coop", {}), false, "닭장은 처음엔 잠김")
	_eq(Locations.is_unlocked("coop", {"coop_open": true}), true, "이야기가 진행되면 닭장 열림")

