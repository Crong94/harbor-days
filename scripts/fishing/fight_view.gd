class_name FightView
extends RefCounted
## 줄다리기 화면(T2)이 장력을 낚싯대와 줄 모양으로 바꾸는 규칙.
## 게이지와 글자 없이 휨새, 대 끝 빛, 줄 처짐과 떨림만으로 읽게 한다 (docs/줄다리기_UI_설계와_그림정리_2026-11-11.md).
## 낚시 규칙(FishingLogic)의 숫자는 건드리지 않고 보여 주는 값만 만든다.

const TEAL := Color("3fd6c4") # 알맞음: 대 끝 청록빛
const RED := Color("ff4b4b") # 위험: 대 끝 빨강
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


## 낚싯대 끝 빛. 느슨하면 없고(알파 0), 알맞으면 은은한 청록, 위험하면 빨강
static func tip_glow(tension: float) -> Color:
	var t := clampf(tension, 0.0, 1.0)
	var slack := FishingLogic.TENSION_SLACK
	var danger := FishingLogic.TENSION_DANGER
	if t < slack:
		return Color(TEAL, 0.0)
	if t >= danger:
		return Color(RED, 1.0)
	# 알맞은 구간 들머리에서 서서히 켜지고, 위험 바로 앞에서 붉은 기가 돈다
	var a := clampf((t - slack) / 0.12, 0.0, 1.0) * 0.6
	var warn := clampf((t - (danger - 0.12)) / 0.12, 0.0, 1.0)
	return Color(TEAL.lerp(RED, warn), lerpf(a, 0.85, warn))


## 줄 처짐 (px). 느슨할 때만 처지고 알맞음부터는 팽팽하게 곧다
static func line_sag(tension: float) -> float:
	var slack := FishingLogic.TENSION_SLACK
	return SAG_MAX * clampf(1.0 - tension / slack, 0.0, 1.0)


## 줄이 붉어지는 정도 0~1
static func line_red(tension: float) -> float:
	return clampf((tension - 0.62) / (FishingLogic.TENSION_DANGER - 0.62), 0.0, 1.0)


## 남은 줄 (m)
static func line_meters(distance: float, cast_power: float) -> int:
	return int(ceil(clampf(distance, 0.0, 1.0) * cast_power * LINE_M))


## 누른 채 끈 거리(px)를 버티기 값 -1~1로
static func steer_from_drag(dx: float, steer_range: float) -> float:
	return clampf(dx / maxf(steer_range, 1.0), -1.0, 1.0)
