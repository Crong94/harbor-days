class_name DayFlow
extends RefCounted
## 하루 흐름 규칙 (2026-11-10 사용자 결정)
##   새벽 낚시 05:00~07:00 → 아침 낚시 07:00~11:00 → (자유: 낚시방, 마을) → 저녁 영업 18:00~ → 밤 낚시 21:00~23:30(선택) → 잠
##   밤 낚시를 하면 늦잠을 자서 다음 날 새벽 낚시를 건너뛴다 (07:00에 일어난다)
##   식당 재료는 직접 낚은 생선만 쓴다
## 저녁 영업은 섞어서: 보통 손님은 아이스박스 생선으로 알아서 팔리고, 단골·특별 손님 한 명은 직접 요리한다
## 장면이 아닌 규칙만 담아 헤드리스로 시험한다.

const WAKE_EARLY := 5 * 60
const WAKE_LATE := 7 * 60 # 밤 낚시 다음 날 (늦잠)
const SHOP_OPEN := 18 * 60
const SHOP_CLOSE := 21 * 60
const SLEEP_AT := 23 * 60 + 30

## 낚시할 수 있는 시간대: [id, 이름, 시작, 끝]
const FISHING_SLOTS := [
	["dawn", "새벽 낚시", 5 * 60, 7 * 60],
	["morning", "아침 낚시", 7 * 60, 11 * 60],
	["night", "밤 낚시", 21 * 60, 23 * 60 + 30],
]

## 보통 손님 수 (요일마다 조금씩 다르다)
const GUESTS_MIN := 3
const GUESTS_MAX := 5
## 구이 한 접시 값 = 생선 값 × 이 배수 (밥, 반찬 포함)
const DISH_MARKUP := 1.6
const DISH_MIN := 6000
## 생선 없이 온 손님이 그냥 돌아갈 때 깎이는 평판
const REP_MISS := -2
const REP_SERVED := 1


## 지금 시각의 낚시 시간대. 낚시할 수 없는 시각이면 빈 Dictionary
static func fishing_slot(minutes: int) -> Dictionary:
	for s in FISHING_SLOTS:
		if minutes >= s[2] and minutes < s[3]:
			return {"id": s[0], "name": s[1], "start": s[2], "end": s[3]}
	return {}


static func can_fish(minutes: int) -> bool:
	return not fishing_slot(minutes).is_empty()


## 이 시각에 시작한 낚시가 끝나는 시각
static func fishing_end(minutes: int) -> int:
	var s := fishing_slot(minutes)
	return s.end if not s.is_empty() else minutes


## 가게를 열 수 있는가 (열기 전이면 18시로 건너뛴다)
static func can_open_shop(minutes: int, opened_today: bool) -> bool:
	return not opened_today and minutes < SHOP_CLOSE


## 다음 할 일 안내 (지도 위 알림)
static func next_hint(minutes: int, opened_today: bool) -> String:
	var s := fishing_slot(minutes)
	if not s.is_empty() and s.id != "night":
		return "%s 시간이에요. 방파제로 가 볼까요?" % s.name
	if not opened_today and minutes < SHOP_CLOSE:
		if minutes < SHOP_OPEN:
			return "저녁 6시에 식당 문을 열어요. 잡은 생선으로 장사해요"
		return "가게 열 시간이에요. 식당으로 가요"
	if not s.is_empty():
		return "밤 낚시를 하면 내일 새벽엔 늦잠을 자요"
	if minutes >= SHOP_CLOSE and minutes < FISHING_SLOTS[2][2]:
		return "밤 9시부터 밤 낚시를 할 수 있어요. 아니면 집에서 쉬어요"
	return "오늘은 푹 쉬어요"


## 다음 날 일어나는 시각
static func wake_time(night_fished: bool) -> int:
	return WAKE_LATE if night_fished else WAKE_EARLY


## 구이 한 접시 값
static func dish_price(fish_id: String, size_cm: float) -> int:
	var v := float(FishDB.value_of(fish_id, size_cm)) * DISH_MARKUP
	return maxi(DISH_MIN, int(roundf(v / 500.0) * 500.0))


## 오늘 보통 손님 수 (날짜로 정해진다)
static func guest_count(day: int) -> int:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("손님-%d" % day)
	return rng.randi_range(GUESTS_MIN, GUESTS_MAX)


## 보통 손님 영업: 아이스박스(inventory)에서 큰 생선부터 한 마리씩 구워 낸다.
## 특별 손님 몫으로 따로 뺀 생선은 inventory에 없다고 본다.
## 돌려주는 값: {"served": [{"guest", "fish", "size", "price"}...], "missed": 돌아간 손님 수, "sales": 합계, "used": 쓴 생선 index들}
static func serve_regulars(day: int, inventory: Array) -> Dictionary:
	var order := []
	for i in inventory.size():
		order.append(i)
	order.sort_custom(func(a, b): return FishDB.value_of(inventory[a].id, inventory[a].size) > FishDB.value_of(inventory[b].id, inventory[b].size))
	var n := guest_count(day)
	var served := []
	var used := []
	var sales := 0
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("손님얼굴-%d" % day)
	for g in n:
		var guest: String = GUESTS[rng.randi() % GUESTS.size()]
		if g >= order.size():
			continue
		var e: Dictionary = inventory[order[g]]
		var price := dish_price(e.id, e.size)
		served.append({"guest": guest, "fish": e.id, "size": e.size, "price": price})
		used.append(order[g])
		sales += price
	return {"served": served, "missed": maxi(0, n - served.size()), "sales": sales, "used": used}


## 보통 손님 (이름 없이 부르는 마을 사람, 관광객)
const GUESTS := ["동네 아저씨", "고깃배 선장", "등산객 부부", "민박 손님", "택배 기사", "장 보던 아주머니", "낚시꾼 둘"]


## 오늘의 특별 손님: 주문서를 낸 사람이 저녁에 직접 온다. 첫날(튜토리얼)은 없다
static func special_guest(day: int) -> Dictionary:
	var o := Orders.of(day)
	if o.is_empty():
		return {}
	return {"name": o.customer, "fish": o.fish}


## 특별 손님 요리값: 별 하나당 더 받는다
static func special_price(fish_id: String, size_cm: float, stars: int) -> int:
	var base := dish_price(fish_id, size_cm)
	return int(roundf(base * (0.8 + 0.3 * clampi(stars, 1, 3)) / 500.0) * 500.0)
