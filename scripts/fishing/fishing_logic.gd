class_name FishingLogic
extends RefCounted
## 찌낚시 규칙만 담당한다. 화면 그리기와 분리해서 헤드리스로 테스트할 수 있다.
##
## 흐름: READY → (누르기) CHARGING → (떼기) CASTING → WAITING → BITE → (누르기) REELING → CAUGHT
## 실패하면 FAILED 상태로 잠깐 머문 뒤 READY로 돌아간다.

enum State { READY, CHARGING, CASTING, WAITING, BITE, REELING, CAUGHT, FAILED }

const POWER_SPEED := 1.1 # 힘 게이지가 차오르는 속도 (초당)
const CAST_TIME := 0.8
const WAIT_MIN := 2.5
const WAIT_MAX := 6.0
const NIBBLE_CHANCE := 0.45 # 대기 중 초당 '톡톡' 확률
const NIBBLE_TIME := 0.3
const BITE_WINDOW := 0.75
const BITE_WINDOW_FORGIVING := 1.3
const TENSION_DOWN := 0.85
const REEL_SPEED := 0.2
const BREAK_HOLD := 0.35 # 장력이 최대인 채로 버티면 줄이 끊기는 시간
const SLACK_LIMIT := 2.2
const SLACK_LIMIT_FORGIVING := 3.5
const FAIL_SHOW_TIME := 2.0

var state := State.READY
var power := 0.0
var cast_power := 0.0
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

var rng := RandomNumberGenerator.new()

var _power_dir := 1.0
var _timer := 0.0
var _nibble_timer := 0.0
var _over_time := 0.0
var _slack_time := 0.0
var _t := 0.0
var _burst := 0.0
var _burst_cooldown := 1.5


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


func release() -> void:
	if state == State.CHARGING:
		cast_power = maxf(power, 0.08)
		progress = 0.0
		state = State.CASTING


## 잡은 물고기 카드를 닫는다.
func acknowledge() -> void:
	if state == State.CAUGHT:
		state = State.READY


func update(dt: float, held: bool) -> void:
	_t += dt
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
			_timer -= dt
			if _nibble_timer > 0.0:
				_nibble_timer -= dt
				nibble = sin(clampf(1.0 - _nibble_timer / NIBBLE_TIME, 0.0, 1.0) * PI)
			else:
				nibble = 0.0
				if _timer > 0.8 and rng.randf() < NIBBLE_CHANCE * dt:
					_nibble_timer = NIBBLE_TIME
			if _timer <= 0.0:
				nibble = 0.0
				state = State.BITE
				_timer = BITE_WINDOW_FORGIVING if forgiving else BITE_WINDOW
		State.BITE:
			_timer -= dt
			if _timer <= 0.0:
				_fail("missed")
		State.REELING:
			_update_reel(dt, held)
		State.FAILED:
			_timer -= dt
			if _timer <= 0.0:
				state = State.READY


func _start_waiting() -> void:
	state = State.WAITING
	nibble = 0.0
	_nibble_timer = 0.0
	# 밝아질수록 입질이 늦어진다
	var slow := 1.0 + brightness * 1.2
	_timer = rng.randf_range(WAIT_MIN, WAIT_MAX) * slow
	if forgiving:
		_timer = minf(_timer, 4.0)


func _hook() -> void:
	if catch_count == 0 and not force_first_fish.is_empty():
		fish_id = force_first_fish
	else:
		fish_id = FishDB.pick(rng, brightness)
	fish_size = FishDB.roll_size(rng, fish_id)
	tension = 0.35
	distance = 1.0
	_over_time = 0.0
	_slack_time = 0.0
	_burst = 0.0
	_burst_cooldown = rng.randf_range(1.0, 2.0)
	state = State.REELING


## 지금 물고기가 당기는 힘. 화면에서 낚싯대 휨에도 쓴다.
func fish_pull() -> float:
	var strength: float = FishDB.get_fish(fish_id).get("strength", 0.5)
	var bigness := clampf((fish_size - 12.0) / 18.0, 0.0, 1.0) * 0.25
	var wave := 0.6 + 0.4 * sin(_t * 3.1)
	return clampf((strength + bigness) * wave + _burst, 0.0, 1.6)


func _update_reel(dt: float, held: bool) -> void:
	_burst_cooldown -= dt
	if _burst_cooldown <= 0.0:
		_burst = 0.7
		_burst_cooldown = rng.randf_range(1.5, 3.0)
	_burst = maxf(0.0, _burst - dt * 1.4)

	var pull := fish_pull()
	if held:
		tension += (0.35 + pull * 0.75) * dt
		distance -= REEL_SPEED * dt * (1.0 - pull * 0.35)
	else:
		tension -= TENSION_DOWN * dt
		distance += 0.06 * pull * dt
	tension = clampf(tension, 0.0, 1.0)
	distance = clampf(distance, 0.0, 1.0)

	_over_time = _over_time + dt if tension >= 1.0 else 0.0
	_slack_time = _slack_time + dt if tension <= 0.08 else 0.0

	if _over_time >= BREAK_HOLD:
		_fail("broke")
	elif _slack_time >= (SLACK_LIMIT_FORGIVING if forgiving else SLACK_LIMIT):
		_fail("slack")
	elif distance <= 0.0:
		catch_count += 1
		forgiving = false
		state = State.CAUGHT


func _fail(reason: String) -> void:
	fail_reason = reason
	nibble = 0.0
	_timer = FAIL_SHOW_TIME
	state = State.FAILED


static func fail_message(reason: String) -> String:
	match reason:
		"nibble":
			return "톡톡 건드리는 건 아직 입질이 아니다. 찌가 쑥 잠길 때까지 기다리자."
		"early":
			return "너무 일찍 챘다. 미끼만 날아갔다."
		"missed":
			return "찌가 들어갔다 올라왔다. 미끼만 뺏겼다."
		"broke":
			return "팽팽하게 버티던 줄이 끊어졌다. 줄이 빨개지면 잠깐 손을 떼자."
		"slack":
			return "줄이 느슨해진 사이 바늘이 빠졌다."
	return ""
