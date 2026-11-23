class_name DayFlow
extends RefCounted
## 하루 흐름 규칙 (2026-11-10 사용자 결정, 2026-11-19 두 번 고침)
##   06:00 기상 → 낮 낚시 한 번(06:00~17:00 사이 아무 때나, DAY_SESSION분) + 마을 일 → 저녁 영업 18:00~ → 밤 낚시 21:00~23:30(선택) → 잠
##   11-19 아침: 새벽, 아침, 낮, 밤 네 번이 너무 많다 → 아침 05~09 한 번과 밤으로 줄임
##   11-19 저녁: 그러자 09~21시가 텅 빈다(사용자: "시간이 너무 뜬다, 꼭 새벽 5시부터 안 해도 된다")
##   → 낮 낚시는 하루 한 번만, 언제 갈지는 고른다. 새벽 볼락, 물때 집중 시간(Tide), 갯바위 간조에 맞춰 가는 재미
##   밤 낚시를 하면 늦잠을 자서 다음 날 08:00에 일어난다
##   식당 재료는 직접 낚은 생선만 쓴다
## 저녁 영업은 섞어서: 보통 손님은 아이스박스 생선으로 알아서 팔리고, 단골·특별 손님 한 명은 직접 요리한다
## 장면이 아닌 규칙만 담아 헤드리스로 시험한다.

const WAKE_EARLY := 6 * 60
const WAKE_LATE := 8 * 60 # 밤 낚시 다음 날 (늦잠)
## 낮 낚시 한 번의 길이 (분)
const DAY_SESSION := 180
const SHOP_OPEN := 18 * 60
const SHOP_CLOSE := 21 * 60
const SLEEP_AT := 23 * 60 + 30

## 낚시할 수 있는 시간대: [id, 이름, 시작, 끝]
const FISHING_SLOTS := [
	["day", "낮 낚시", 6 * 60, 17 * 60],
	["night", "밤 낚시", 21 * 60, 23 * 60 + 30],
]
const DAY := 0
const NIGHT := 1

## 보통 손님 수 (요일마다 조금씩 다르다)
const GUESTS_MIN := 3
const GUESTS_MAX := 5
## 돈 균형 (2026-11-16, tools/money_balance.gd로 두 달을 돌려 정함. 사용자: E안으로 해 보고 손님 수는 그대로)
##   예전 값(배수 1.6, 특별 4.5만, 재료비 없음)은 첫 달에 300만~450만 원이 남아 기획서 "초반 3개월은 빠듯하게"와 멀었다.
##   그때 값은 고정비 80만 원을 내고 새벽만 낚시하면 50만 원쯤, 새벽과 아침 모두 하면 140만 원쯤 남았다 (11-19 아침 한 번으로 바뀐 뒤 tools/money_balance.gd로 다시 잰다).
## 구이 한 접시 값 = 생선 값 × 이 배수 (밥, 반찬 포함)
const DISH_MARKUP := 1.0
const DISH_MIN := 5000
## 접시마다 드는 재료비 (밥, 반찬, 가스). 영업이 끝나면 낸 접시 수만큼 나간다
const DISH_COST := 2500
## 보통 손님이 한 끼에 내는 돈의 끝. 이보다 비싼 생선(감성돔 같은)은 보통 손님에게 내지 않는다.
## 그런 고기는 특별 손님에게 내거나 수산시장에 판다
const REGULAR_MAX := 12500
## 특별 손님 한 접시 값의 끝
const SPECIAL_MAX := 20000
## 생선 없이 온 손님이 그냥 돌아갈 때 깎이는 평판
const REP_MISS := -2
const REP_SERVED := 1


## 지금 시각의 낚시 시간대. 낚시할 수 없는 시각이면 빈 Dictionary
static func fishing_slot(minutes: int) -> Dictionary:
	for s in FISHING_SLOTS:
		if minutes >= s[2] and minutes < s[3]:
			return {"id": s[0], "name": s[1], "start": s[2], "end": s[3]}
	return {}


## day_fished: 오늘 낮 낚시를 이미 했나 (낮 낚시는 하루 한 번)
static func can_fish(minutes: int, day_fished := false) -> bool:
	var s := fishing_slot(minutes)
	if s.is_empty():
		return false
	return not (s.id == "day" and day_fished)


## 이 시각에 시작한 낚시가 끝나는 시각 (낮은 DAY_SESSION분 뒤, 늦어도 17시)
static func fishing_end(minutes: int) -> int:
	var s := fishing_slot(minutes)
	if s.is_empty():
		return minutes
	if s.id == "day":
		return mini(minutes + DAY_SESSION, int(s.end))
	return s.end


## 가게를 열 수 있는가 (열기 전이면 18시로 건너뛴다)
static func can_open_shop(minutes: int, opened_today: bool) -> bool:
	return not opened_today and minutes < SHOP_CLOSE


## 다음 할 일 안내 (지도 위 알림)
static func next_hint(minutes: int, opened_today: bool, day_fished := false) -> String:
	var s := fishing_slot(minutes)
	if not s.is_empty() and s.id == "day" and not day_fished:
		return "낮 낚시는 하루 한 번, 세 시간이에요. 언제 갈지 골라요"
	if not opened_today and minutes < SHOP_CLOSE:
		if minutes < SHOP_OPEN:
			return "낮에는 마을을 돌아봐요. 저녁 6시에 식당 문을 열어요"
		return "가게 열 시간이에요. 식당으로 가요"
	if not s.is_empty():
		return "밤 낚시를 하면 내일은 늦잠을 자요"
	if minutes < FISHING_SLOTS[DAY][2]:
		return "아침 6시부터 방파제에서 낚시할 수 있어요"
	if minutes >= SHOP_CLOSE and minutes < FISHING_SLOTS[NIGHT][2]:
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
		if dish_price(inventory[i].id, inventory[i].size) <= REGULAR_MAX:
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
## 보통 손님 이름. 그림은 이름 없는 손님 SD 다섯 종 (DiningFloor.GUEST_FACES가 이름 → 그림)
const GUESTS := ["퇴근한 회사원", "고깃배 선장", "등산객", "민박 손님", "물질 마친 해녀", "학교 마친 학생", "낚시꾼"]


## 오늘의 특별 손님: 주문서를 낸 사람이 저녁에 직접 온다. 첫날(튜토리얼)은 없다
static func special_guest(day: int, flags = null) -> Dictionary:
	var o := Orders.of(day, flags)
	if o.is_empty():
		return {}
	return {"name": o.customer, "fish": o.fish}


## 특별 손님 요리값: 별 하나당 더 받는다
static func special_price(fish_id: String, size_cm: float, stars: int) -> int:
	var base := dish_price(fish_id, size_cm)
	return mini(SPECIAL_MAX, int(roundf(base * (0.8 + 0.3 * clampi(stars, 1, 3)) / 500.0) * 500.0))


## 보통 손님에게 내기엔 너무 비싼 생선인지 (시장에 파는 게 낫다)
static func too_pricey(fish_id: String, size_cm: float) -> bool:
	return dish_price(fish_id, size_cm) > REGULAR_MAX
