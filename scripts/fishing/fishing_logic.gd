class_name FishingLogic
extends RefCounted
## 찌낚시 규칙만 담당한다. 화면 그리기와 분리해서 헤드리스로 테스트할 수 있다.
##
## 흐름: READY → (누르기) CHARGING → (떼기) CASTING → WAITING → BITE → (누르기) REELING → CAUGHT
## 실패하면 FAILED 상태로 잠깐 머문 뒤 READY로 돌아간다.
##
## 재미 요소
## - 캐스팅 포인트: 바다에 물고기가 모인 자리(point_depth)가 보인다. 거기 맞춰 던지면 NICE CAST, 입질이 빠르고 큰 고기가 잘 나온다
## - 챔질 판정: 찌가 잠기는 한가운데(PERFECT 구간)에 채면 PERFECT. 물고기 체력이 깎인 채로 시작한다
## - 연속 PERFECT: 3번 이상 이어지면 "물 오름" 상태가 되어 희귀 어종이 잘 나온다
## - 줄다리기: 물고기가 왼쪽이나 오른쪽으로 차고 나가면(run_dir) 누른 채 반대로 끌어야(steer) 버틴다.
##   잘 버티면 물고기 체력(fish_hp)이 크게 깎인다. 체력이 0이 되면 지쳐서(exhausted) 빨리 끌려온다
##   반대로 끌지 않고 두면 escape가 차올라 물고기가 바위틈으로 파고든다 (실패 "escaped")
##
## 실제 찌낚시 기준 (docs/찌낚시_동작_조사.md)
## - 순간적인 찌 떨림(톡톡)에 채면 헛챔질. 찌가 계속 잠길 때 챈다
## - 기다리는 동안 찌는 조류에 흘러간다. 뒷줄을 잡아 견제하면 흐름이 멈추고 입질이 빨라진다
## - 챔질 뒤에는 곧바로 감기 시작해야 한다. 줄이 느슨하면 바늘이 빠진다

enum State { READY, CHARGING, CASTING, WAITING, BITE, REELING, CAUGHT, FAILED }

const POWER_SPEED := 0.95 # 힘 게이지가 차오르는 속도 (초당)
const CAST_TIME := 0.8
const WAIT_MIN := 2.5
const WAIT_MAX := 6.0
const NIBBLE_CHANCE := 0.45 # 대기 중 초당 '톡톡' 확률
const NIBBLE_TIME := 0.3
const BITE_WINDOW := 1.1 # 찌가 잠기기 시작해서 다시 떠오를 때까지
const BITE_WINDOW_FORGIVING := 1.7
const PERFECT_FROM := 0.36 # BITE 진행도(bite_depth) 중 PERFECT 구간
const PERFECT_TO := 0.64
const MEND_SPEEDUP := 0.6 # 견제 중에는 입질까지 남은 시간이 이만큼 더 빨리 줄어든다
const MEND_NIBBLE := 1.6 # 견제 중 톡톡 입질 배율
const DRIFT_SPEED := 0.018 # 견제하지 않으면 찌가 옆으로 흘러가는 속도
const DRIFT_MAX := 0.22

## 캐스팅 포인트 판정 (던진 거리와 포인트 거리 차이)
const CAST_NICE := 0.05
const CAST_GOOD := 0.12

## 줄다리기
const TENSION_DOWN := 0.95
const REEL_SPEED := 0.17
const HP_DRAIN := 0.15 # 누르고 감을 때 물고기 체력이 깎이는 속도 (힘 0.5 기준 근처)
const HP_COUNTER := 0.24 # 반대로 버틸 때 더 깎이는 양
const COUNTER_STEER := 0.35 # 이만큼 이상 반대로 끌어야 버티기로 친다
const EXHAUSTED_REEL := 2.4 # 지친 물고기를 감는 속도 배율
const BREAK_HOLD := 0.35 # 장력이 최대인 채로 버티면 줄이 끊기는 시간
const SLACK_LIMIT := 2.2
const SLACK_LIMIT_FORGIVING := 3.5
const FAIL_SHOW_TIME := 2.0
const FAIL_SKIP_AFTER := 0.45 # 실패 안내가 뜬 뒤 이만큼 지나면 눌러서 바로 다음 캐스팅을 시작할 수 있다
## 장력 단계 (화면 색, 깜빡임, 진동에 쓴다)
const TENSION_WARN := 0.62
const TENSION_DANGER := 0.85
const STREAK_HOT := 3 # 연속 PERFECT 몇 번부터 물 오름

var state := State.READY
var power := 0.0
var cast_power := 0.0 # 실제로 날아간 거리 0~1
var progress := 0.0 # 캐스팅 진행도 0~1
var nibble := 0.0 # 찌가 톡 잠기는 정도 0~1
var tension := 0.0
var distance := 0.0 # 물고기와의 거리 0(발밑)~1(찌 위치)
var fish_id := ""
var fish_size := 0.0
var fail_reason := ""
var brightness := 0.0
var forgiving := true # 첫 물고기를 잡기 전까지 판정을 너그럽게
var force_first_fish := "bolak" # 첫 물고기 고정
var catch_count := 0
var drift := 0.0 # 찌가 조류에 흘러간 정도 (화면 가로 비율)
var mending := false # 지금 뒷줄 견제 중인지
var bite_depth := 0.0 # 입질 때 찌가 잠긴 진행도 0~1

## 캐스팅 포인트
var point_depth := 0.5 # 처음 값. 화면에서 장비를 넣은 뒤 new_point()로 정한다
var cast_grade := "" # "nice", "good", "" (빗나감)
## 챔질 판정
var hook_grade := "" # "perfect", "good"
var perfect_streak := 0

## 줄다리기
var steer := 0.0 # 입력: 누른 채 좌우로 끈 정도 -1~1 (화면에서 넣는다)
var fish_hp := 1.0
var run_dir := 0 # 물고기가 차고 나가는 방향 -1 왼쪽, 1 오른쪽, 0 쉬는 중
var fish_x := 0.0 # 물고기가 옆으로 끌고 간 정도 -1~1 (화면에서 줄 각도)
var exhausted := false
var countering := false # 지금 반대로 잘 버티는 중인지
var escape := 0.0 # 차고 나가는 걸 그냥 두면 차오른다. 1이 되면 바위틈으로 파고들어 놓친다

## 오늘의 바다와 미끼 (화면에서 넣는다)
var bait := "krill"
var weather := "sunny"
var bite_mult := 1.0 # 물때, 날씨에 따른 입질 속도 (클수록 빨리)

## 장비 능력치 (GearDB.apply로 넣는다)
var cast_mult := 1.0 # 최대 던지기 거리
var reel_mult := 1.0 # 감는 속도
var tension_mult := 1.0 # 장력이 오르는 정도 (작을수록 버티기 쉬움)
var hook_bonus := 0.0 # 챔질 여유 (초)
var slack_bonus := 0.0 # 느슨함을 버티는 추가 시간 (초)

var rng := RandomNumberGenerator.new()

var _power_dir := 1.0
var _timer := 0.0
var _nibble_timer := 0.0
var _over_time := 0.0
var _slack_time := 0.0
var _t := 0.0
var _run_time := 0.0
var _rest_time := 0.0
var _run_power := 0.0
var _size_bonus := 0.0


## 다음 캐스팅 포인트를 정한다. 던질 수 있는 거리 안에서 고른다.
func new_point() -> void:
	point_depth = rng.randf_range(0.28, maxf(0.35, cast_mult - 0.06))


## 물 오름: 연속 PERFECT로 희귀 어종이 잘 나오는 상태
func is_hot() -> bool:
	return perfect_streak >= STREAK_HOT


func press() -> void:
	match state:
		State.READY:
			state = State.CHARGING
			power = 0.0
			_power_dir = 1.0
		State.WAITING:
			_fail("nibble" if nibble > 0.0 else "early")
		State.BITE:
			_hook()
		State.FAILED:
			# 실패 안내를 잠깐 보여 준 뒤에는 다시 누르면 기다리지 않고 바로 힘 모으기를 시작한다
			if can_skip_fail():
				state = State.CHARGING
				power = 0.0
				_power_dir = 1.0


func release() -> void:
	if state == State.CHARGING:
		cast_power = maxf(power, 0.08) * cast_mult
		var miss := absf(cast_power - point_depth)
		cast_grade = "nice" if miss <= CAST_NICE else ("good" if miss <= CAST_GOOD else "")
		progress = 0.0
		state = State.CASTING


## 잡은 물고기 카드를 닫는다.
func acknowledge() -> void:
	if state == State.CAUGHT:
		state = State.READY


## held: 주 버튼을 누르고 있는지, mend: 견제 버튼을 누르고 있는지
func update(dt: float, held: bool, mend := false) -> void:
	_t += dt
	mending = mend and state == State.WAITING
	match state:
		State.CHARGING:
			power += _power_dir * POWER_SPEED * dt
			if power >= 1.0:
				power = 1.0
				_power_dir = -1.0
			elif power <= 0.0:
				power = 0.0
				_power_dir = 1.0
		State.CASTING:
			progress += dt / CAST_TIME
			if progress >= 1.0:
				progress = 1.0
				_start_waiting()
		State.WAITING:
			_timer -= dt * (1.0 + (MEND_SPEEDUP if mending else 0.0))
			if not mending:
				drift = minf(drift + DRIFT_SPEED * dt, DRIFT_MAX)
			if _nibble_timer > 0.0:
				_nibble_timer -= dt
				nibble = sin(clampf(1.0 - _nibble_timer / NIBBLE_TIME, 0.0, 1.0) * PI)
			else:
				nibble = 0.0
				if _timer > 0.8 and rng.randf() < NIBBLE_CHANCE * (MEND_NIBBLE if mending else 1.0) * dt:
					_nibble_timer = NIBBLE_TIME
			if _timer <= 0.0:
				nibble = 0.0
				state = State.BITE
				bite_depth = 0.0
				_timer = bite_window()
		State.BITE:
			_timer -= dt
			bite_depth = clampf(1.0 - _timer / bite_window(), 0.0, 1.0)
			if _timer <= 0.0:
				_fail("missed")
		State.REELING:
			_update_reel(dt, held)
		State.FAILED:
			_timer -= dt
			if _timer <= 0.0:
				state = State.READY


func bite_window() -> float:
	return (BITE_WINDOW_FORGIVING if forgiving else BITE_WINDOW) + hook_bonus


## PERFECT 구간 (BITE 진행도 0~1). 챔질 여유가 좋은 낚싯대와 튜토리얼은 넓다
func perfect_zone() -> Vector2:
	var widen := hook_bonus * 0.35 + (0.08 if forgiving else 0.0)
	return Vector2(PERFECT_FROM - widen, PERFECT_TO + widen)


func _start_waiting() -> void:
	state = State.WAITING
	drift = 0.0
	nibble = 0.0
	_nibble_timer = 0.0
	# 밝아질수록 입질이 늦어진다
	var slow := 1.0 + brightness * 0.6
	var cast_k: float = {"nice": 0.45, "good": 0.7}.get(cast_grade, 1.0)
	_timer = rng.randf_range(WAIT_MIN, WAIT_MAX) * slow * cast_k * BaitDB.bait(bait).wait / maxf(bite_mult, 0.3)
	if forgiving:
		_timer = minf(_timer, 4.0)


func _hook() -> void:
	var z := perfect_zone()
	hook_grade = "perfect" if bite_depth >= z.x and bite_depth <= z.y else "good"
	if hook_grade == "perfect":
		perfect_streak += 1
	else:
		perfect_streak = 0
	_size_bonus = {"nice": 0.6, "good": 0.25}.get(cast_grade, 0.0) + (0.2 if hook_grade == "perfect" else 0.0)
	if catch_count == 0 and not force_first_fish.is_empty():
		fish_id = force_first_fish
	else:
		var boost := 1.0
		if cast_grade == "nice":
			boost *= 1.5
		if is_hot():
			boost *= 2.0
		fish_id = FishDB.pick_ctx(rng, {
			"brightness": brightness, "depth": cast_power, "bait": bait,
			"weather": weather, "rare_boost": boost,
		})
	fish_size = FishDB.roll_size(rng, fish_id, _size_bonus)
	tension = 0.3
	distance = 1.0
	fish_hp = 0.75 if hook_grade == "perfect" else 1.0
	exhausted = false
	run_dir = 0
	fish_x = 0.0
	countering = false
	escape = 0.0
	_rest_time = rng.randf_range(0.6, 1.2)
	_over_time = 0.0
	_slack_time = 0.0
	state = State.REELING


## 실패 안내를 건너뛰고 다시 던질 수 있는지
func can_skip_fail() -> bool:
	return state == State.FAILED and _timer <= FAIL_SHOW_TIME - FAIL_SKIP_AFTER


## 장력 단계: 0 안전, 1 주의(노랑), 2 위험(빨강, 줄 끊김 직전)
static func tension_level(t: float) -> int:
	if t >= TENSION_DANGER:
		return 2
	if t >= TENSION_WARN:
		return 1
	return 0


## 줄이 끊어지기까지 얼마나 버텼는지 0~1 (장력이 끝까지 찬 채로 있는 시간). 1이면 끊어진다
func break_progress() -> float:
	return clampf(_over_time / BREAK_HOLD, 0.0, 1.0) if state == State.REELING else 0.0


## 물고기의 힘 (어종 힘 + 크기). 0~1.2
func fish_strength() -> float:
	var f := FishDB.get_fish(fish_id)
	var k := inverse_lerp(f.get("min_cm", 10.0), f.get("max_cm", 30.0), fish_size)
	return clampf(f.get("strength", 0.5) + k * 0.25, 0.0, 1.2)


## 지금 물고기가 당기는 힘. 화면에서 낚싯대 휨에도 쓴다.
func fish_pull() -> float:
	if exhausted:
		return 0.15
	var wave := 0.6 + 0.4 * sin(_t * 3.1)
	var run := _run_power if run_dir != 0 else 0.0
	return clampf(fish_strength() * wave + run * 0.6, 0.0, 1.6)


func _update_reel(dt: float, held: bool) -> void:
	var s := fish_strength()
	var easy := 0.7 if forgiving else 1.0
	var tm := tension_mult * easy

	# 물고기 움직임: 쉬다가 왼쪽이나 오른쪽으로 차고 나간다
	if not exhausted:
		if run_dir == 0:
			_rest_time -= dt
			if _rest_time <= 0.0:
				run_dir = -1 if rng.randf() < 0.5 else 1
				_run_time = rng.randf_range(0.7, 1.4) * (0.7 + s * 0.6)
				_run_power = (0.5 + s * 0.6) * easy
		else:
			_run_time -= dt
			if _run_time <= 0.0:
				run_dir = 0
				_rest_time = rng.randf_range(0.9, 2.0) * (1.3 - s * 0.5) / easy

	countering = run_dir != 0 and held and steer * run_dir <= -COUNTER_STEER
	if run_dir != 0 and not countering:
		fish_x = clampf(fish_x + run_dir * 0.9 * dt, -1.0, 1.0)
		escape += (0.25 + s * 0.4) * easy * dt
	else:
		fish_x = move_toward(fish_x, 0.0, (0.9 if countering else 0.35) * dt)
		escape = maxf(0.0, escape - (0.45 if countering else 0.2) * dt)

	# 반대로 끌어 버티면 낚싯대가 힘을 받아 줘서 장력이 조금만 오른다 (안전한 선택).
	# 다만 힘센 고기는 버티는 동안에도 장력이 오르니, 쉬는 틈에 손을 떼서 식혀야 한다. 좋은 장비일수록 덜 오른다
	var pull := fish_pull()
	if held and countering:
		tension += (0.06 + maxf(0.0, s - 0.55) * 0.9 * tm) * dt
	elif held:
		tension += (0.26 + pull * 0.45) * dt * tm
	else:
		tension -= TENSION_DOWN * dt
	if run_dir != 0 and not countering:
		if held:
			tension += _run_power * 0.95 * dt * tm # 차고 나가는데 그대로 감으면 줄이 위험하다
		else:
			tension += _run_power * 0.3 * dt * tm
			distance += 0.07 * dt # 손을 떼면 줄이 풀려 나간다
	if exhausted:
		tension = minf(tension, 0.7)
	tension = clampf(tension, 0.0, 1.0)

	# 물고기 체력
	var drain := 0.0
	if held and tension > 0.1:
		drain += HP_DRAIN / (0.5 + s)
	if countering:
		drain += HP_COUNTER / (0.5 + s)
	if not held and run_dir == 0:
		drain -= 0.02
	fish_hp = clampf(fish_hp - drain * dt, 0.0, 1.0)
	if fish_hp <= 0.0 and not exhausted:
		exhausted = true
		run_dir = 0

	# 거리: 물고기가 지칠수록 잘 끌려온다
	if held:
		var k := 0.35 + 0.65 * (1.0 - fish_hp)
		if run_dir != 0 and not countering:
			k *= 0.4
		if exhausted:
			k = EXHAUSTED_REEL
		distance -= REEL_SPEED * k * reel_mult * dt
	distance = clampf(distance, 0.0, 1.0)

	_over_time = _over_time + dt if tension >= 1.0 else 0.0
	_slack_time = _slack_time + dt if tension <= 0.06 and not exhausted else 0.0

	if _over_time >= BREAK_HOLD:
		_fail("broke")
	elif escape >= 1.0:
		_fail("escaped")
	elif _slack_time >= (SLACK_LIMIT_FORGIVING if forgiving else SLACK_LIMIT) + slack_bonus:
		_fail("slack")
	elif distance <= 0.0:
		catch_count += 1
		forgiving = false
		run_dir = 0
		state = State.CAUGHT
		new_point()


func _fail(reason: String) -> void:
	fail_reason = reason
	nibble = 0.0
	run_dir = 0
	_timer = FAIL_SHOW_TIME
	if reason in ["nibble", "early", "missed", "broke", "slack", "escaped"]:
		perfect_streak = 0
	state = State.FAILED
	new_point()


## 하루 중 시각(자정부터 분)에 따른 바다 밝기 0~1. 05:00~07:00에 밝아지고 17:30~19:30에 어두워진다.
## 볼락 입질(FishDB.pick)과 배경 밝기에 쓴다.
static func brightness_at(minutes: float) -> float:
	var m := fposmod(minutes, 24.0 * 60.0)
	if m < 5 * 60:
		return 0.0
	if m < 7 * 60:
		return (m - 5 * 60) / 120.0
	if m < 17.5 * 60:
		return 1.0
	if m < 19.5 * 60:
		return 1.0 - (m - 17.5 * 60) / 120.0
	return 0.0


static func fail_message(reason: String) -> String:
	match reason:
		"nibble":
			return "찌가 살짝 떨린 순간에 챘어요. 찌가 쭉 잠겨 들어갈 때 채요"
		"early":
			return "너무 일찍 챘어요. 미끼만 날아갔어요"
		"missed":
			return "찌가 잠겼다가 다시 떠올랐어요. 미끼만 뺏겼어요"
		"broke":
			return "줄이 끊어졌어요. 장력 게이지가 빨개지면 잠깐 손을 떼요"
		"slack":
			return "줄이 느슨해진 사이 바늘이 빠졌어요. 손을 너무 오래 뗐어요"
		"escaped":
			return "물고기가 바위틈으로 파고들었어요. 옆으로 차고 나가면 반대로 끌어요"
	return ""


## 실패 순간 찌 위에 튀어 오르는 짧은 글자
static func fail_short(reason: String) -> String:
	match reason:
		"nibble":
			return "헛챔질!"
		"early":
			return "너무 일찍!"
		"missed":
			return "놓쳤어요"
		"broke":
			return "툭! 줄이 끊어졌어요"
		"slack":
			return "바늘이 빠졌어요"
		"escaped":
			return "도망갔어요"
	return ""
