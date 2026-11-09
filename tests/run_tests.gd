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


func _test_fishing() -> void:
	var S := FishingLogic.State
	var never := func(_x): return false
	var always := func(_x): return true
	var smart := func(x): return x.tension < 0.8

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
