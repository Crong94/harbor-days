class_name Tide
extends RefCounted
## 물때에 따른 입질 (2026-11-19). 사용자의 낚시 계획 앱 "끌어올려"(FishingPlan 레포 core/plan/Skeleton.kt)의 규칙을 옮겼다.
## - 정조(만조, 간조 앞뒤 30분): 물이 멈춰서 입질이 뜸하다
## - 집중: 물이 움직이고 해뜰녘(일출 60분 전 ~ 90분 뒤)이나 해질녘(일몰 90분 전 ~ 60분 뒤)이 겹치는 때
## - 보조: 그 밖에 물이 움직이는 때
## 간조 시각은 Spots.low_tides(검은여 갯바위와 같은 물때), 만조는 간조 사이 가운데. 해 시각은 봄 남해 기준으로 고정한다.
## 장면이 아닌 규칙만 담아 헤드리스로 시험한다.

const SLACK := 30
const SUNRISE := 6 * 60 + 20
const SUNSET := 18 * 60 + 40
const DAWN_BEFORE := 60
const DAWN_AFTER := 90
const DUSK_BEFORE := 90
const DUSK_AFTER := 60
## 입질 배율
const BITE := {"rest": 0.75, "peak": 1.25, "support": 1.0}


## 그날 물이 멈추는 때(간조와 만조) [분...]. 하루 앞뒤로 조금 넘친 것도 넣는다
static func extremes(day: int) -> Array:
	var out := []
	for d in [day - 1, day, day + 1]:
		for low in Spots.low_tides(d):
			var t: int = int(low) + (d - day) * 24 * 60
			out.append(t)
			out.append(t + Spots.TIDE_CYCLE / 2)
	out.sort()
	return out


## 그 시각의 물 상태: "rest"(정조), "peak"(집중), "support"(보조)
static func phase(day: int, minutes: int) -> String:
	for e in extremes(day):
		if absi(int(e) - minutes) < SLACK:
			return "rest"
	var dawn := minutes >= SUNRISE - DAWN_BEFORE and minutes < SUNRISE + DAWN_AFTER
	var dusk := minutes >= SUNSET - DUSK_BEFORE and minutes < SUNSET + DUSK_AFTER
	return "peak" if dawn or dusk else "support"


static func bite(day: int, minutes: int) -> float:
	return float(BITE[phase(day, minutes)])


## from~to 사이 집중 시간 [[시작, 끝]...] (10분 단위로 훑는다)
static func peak_times(day: int, from: int, to: int) -> Array:
	var out := []
	var start := -1
	var m := from
	while m <= to:
		var p := m < to and phase(day, m) == "peak"
		if p and start < 0:
			start = m
		elif not p and start >= 0:
			out.append([start, m])
			start = -1
		m += 10
	return out


## 낚시 시간대 안의 집중 시간 (조황 앱을 만든 뒤 하루 서랍에 보인다)
static func fishing_peaks(day: int) -> Array:
	var out := []
	for s in DayFlow.FISHING_SLOTS:
		out.append_array(peak_times(day, int(s[2]), int(s[3])))
	return out
