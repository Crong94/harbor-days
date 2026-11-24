class_name Bus
extends RefCounted
## 읍내 가는 버스와 옆마을 손님 (2026-11-18, 사용자: 장터 다녀오기와 외지 손님 둘 다)
##
## - 마을 정류장에서 하루 네 번 읍내로 간다. 읍내에서도 하루 네 번 돌아온다. 한 번 타는 데 RIDE분, 편도 FARE원
## - 읍내 장터: 생선을 수산시장보다 조금 비싸게 넘기고(SELL_RATE), 미끼를 도매값(BAIT_RATE)으로 산다
## - 옆마을 손님: 평판이 오르면 저녁 버스로 외지 손님이 더 온다(visitors). 영업 판에서는 늦게 오는 무리가 된다
## 장면이 아닌 규칙만 담아 헤드리스로 시험한다.

const FARE := 2000
const RIDE := 40
## 마을 정류장에서 읍내로 떠나는 시각
const TO_TOWN := [8 * 60, 11 * 60, 14 * 60, 17 * 60]
## 읍내에서 마을로 떠나는 시각 (마지막 버스를 타도 가게 닫기 전에 온다)
const TO_VILLAGE := [10 * 60, 13 * 60, 16 * 60, 19 * 60]

## 읍내 도매상이 생선을 받는 값 (생선 값의 배수. 수산시장 Market.RATE는 0.4)
const SELL_RATE := 0.5
## 읍내 미끼 도매값 (낚시방 값의 배수)
const BAIT_RATE := 0.7

## 옆마을 손님: 평판 VISIT_STEP마다 한 명, 많아야 VISIT_MAX명
const VISIT_STEP := 30
const VISIT_MAX := 3
const VISITOR_NAMES := ["읍내 손님", "옆마을 손님"]


## minutes 뒤로 가장 먼저 떠나는 버스 시각. 오늘 버스가 끝났으면 -1
static func next_departure(minutes: int, table: Array = TO_TOWN) -> int:
	for t in table:
		if int(t) >= minutes:
			return int(t)
	return -1


## 지금(minutes) 읍내에서 탈 수 있는 돌아가는 버스 시각들
static func returns_after(minutes: int) -> Array:
	var out := []
	for t in TO_VILLAGE:
		if int(t) >= minutes:
			out.append(int(t))
	return out


## 읍내 도매상이 주는 값
static func fish_price(fish_id: String, size_cm: float) -> int:
	return int(roundf(FishDB.value_of(fish_id, size_cm) * SELL_RATE / 100.0) * 100.0)


## 읍내에서 사는 미끼 한 묶음 값
static func bait_price(bait_id: String) -> int:
	return int(roundf(int(BaitDB.bait(bait_id).price) * BAIT_RATE / 100.0) * 100.0)


## 오늘 저녁 버스로 오는 외지 손님 수. 평판과 날짜로 정해진다
## flags를 주면 민박 손님(Places.inn_guests)도 더한다
static func visitors(reputation: int, day: int, flags := {}) -> int:
	var base := clampi(reputation / VISIT_STEP, 0, VISIT_MAX)
	var inn := Places.inn_guests(flags, day)
	if base == 0:
		return inn
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("버스손님-%d" % day)
	return clampi(base - rng.randi_range(0, 1), 0, VISIT_MAX) + inn


## "08:00" 꼴
static func clock(minutes: int) -> String:
	var m := minutes % (24 * 60)
	return "%02d:%02d" % [m / 60, m % 60]
