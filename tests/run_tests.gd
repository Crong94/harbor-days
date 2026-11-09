extends SceneTree
## 헤드리스 테스트. 실행: godot --headless --path . --script res://tests/run_tests.gd

var _fail := 0
var _pass := 0


func _init() -> void:
	_test_josa()
	_test_format()
	_test_validation()
	_test_won()
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
