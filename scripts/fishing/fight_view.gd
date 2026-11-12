class_name FightView
extends RefCounted
## 줄다리기 화면이 장력을 보여 주는 규칙.
## 장력은 오른쪽 세로 게이지로 읽고, 낚싯대 휨새와 줄 처짐은 실제처럼 따라 움직인다.
## 2026-11-12 사용자: 게이지는 있어야 하고 대 끝 색과 줄 떨림은 뺀다 (docs/찌낚시_동작_조사.md 4장).
## 낚시 규칙(FishingLogic)의 숫자는 건드리지 않고 보여 주는 값만 만든다.

const SAG_MAX := 46.0 # 줄이 가장 느슨할 때 처지는 정도 (px)
const LINE_M := 30.0 # 가장 멀리 던졌을 때 줄 길이 (m)


## 낚싯대 휨 0~1. 느슨하면 거의 곧고, 알맞으면 활처럼, 위험하면 크게 꺾인다
static func rod_bend(tension: float) -> float:
	var t := clampf(tension, 0.0, 1.0)
	var slack := FishingLogic.TENSION_SLACK
	var danger := FishingLogic.TENSION_DANGER
	if t < slack:
		return lerpf(0.03, 0.2, t / slack)
	if t < danger:
		return lerpf(0.2, 0.68, (t - slack) / (danger - slack))
	return lerpf(0.68, 1.0, (t - danger) / (1.0 - danger))


## 줄 처짐 (px). 느슨할 때만 처지고 알맞음부터는 팽팽하게 곧다
static func line_sag(tension: float) -> float:
	var slack := FishingLogic.TENSION_SLACK
	return SAG_MAX * clampf(1.0 - tension / slack, 0.0, 1.0)


## 남은 줄 (m)
static func line_meters(distance: float, cast_power: float) -> int:
	return int(ceil(clampf(distance, 0.0, 1.0) * cast_power * LINE_M))


## 누른 채 끈 거리(px)를 버티기 값 -1~1로
static func steer_from_drag(dx: float, steer_range: float) -> float:
	return clampf(dx / maxf(steer_range, 1.0), -1.0, 1.0)


## 장력 게이지 구간 (아래부터): [끝 값, 색 이름]. 느슨 → 알맞음 → 드랙(줄이 풀리기 시작) → 위험
static func gauge_zones() -> Array:
	return [
		[FishingLogic.TENSION_SLACK, "slack"],
		[FishingLogic.TENSION_WARN, "good"],
		[FishingLogic.TENSION_DANGER, "drag"],
		[1.0, "danger"],
	]


## 장력 값이 어느 구간인지
static func gauge_zone(tension: float) -> String:
	for z in gauge_zones():
		if tension < float(z[0]):
			return z[1]
	return "danger"
