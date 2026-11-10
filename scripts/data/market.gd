class_name Market
extends RefCounted
## 물빛 수산시장 규칙. 잡은 생선을 오용팔 경매사에게 넘긴다.
## - 여는 시간: 새벽 5시 ~ 오후 5시 (저녁 장사 전에 팔고 남길 걸 고른다)
## - 값: 생선 값(FishDB.value_of)의 RATE배. 흔한 고기는 식당에서 굽는 게 낫고,
##   보통 손님에게 내기엔 비싼 고기(감성돔 같은)는 시장에 파는 게 낫다

const OPEN := 5 * 60
const CLOSE := 17 * 60
const RATE := 0.7


static func is_open(minutes: int) -> bool:
	var m := minutes % (24 * 60)
	return m >= OPEN and m < CLOSE


## 시장에 넘길 때 받는 돈
static func price(fish_id: String, size_cm: float) -> int:
	return int(roundf(FishDB.value_of(fish_id, size_cm) * RATE / 100.0) * 100.0)


## 식당에서 굽기보다 시장에 파는 게 나은 생선인지 (목록에 "시장이 나아요" 표시)
static func better_here(fish_id: String, size_cm: float) -> bool:
	return DayFlow.too_pricey(fish_id, size_cm)
