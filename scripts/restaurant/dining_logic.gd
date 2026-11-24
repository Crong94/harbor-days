class_name DiningLogic
extends RefCounted
## 저녁 영업 (2026-11-16 다시 짬. 사용자: "한 사람은 주방에서 계속 요리하고 다른 한 사람은 서빙만").
## 장면 없이 규칙만 담아 헤드리스로 시험한다. 화면은 scenes/restaurant/dining_floor.gd.
##
## 사람은 둘 자리: 주방(화구 앞에서 굽는다)과 홀(완성 접시를 들고 테이블 사이 빈 바닥으로 날라 준다).
##   2026-11-16 사용자: "주인공은 낚시, 서빙을 담당하고 다른 등장인물이 요리 전담". 요리사는 순덕 할머니 손녀 최세라 (둘째 날부터, Story sera_arrives).
##   세라는 노릇할 때 담아 조리대 끝 내놓는 자리에 놓는다. 주인공은 접시를 눌러(take) 손님에게 갖다준다.
##   내놓는 자리가 꽉 차면 세라가 접시를 못 내려서 화구 위 생선이 탈 수 있다 (빨리 날라야 하는 까닭).
##   서빙 알바(여울)를 뽑으면 여울도 맨 앞 접시부터 알아서 나른다.
##   helper_kitchen이 false면 예전처럼 주인공이 직접 굽는다 (plate, 첫날 튜토리얼과 시험용).
## 사람은 조이스틱 없이 정해진 길(LANE)로만 걷는다: 홀 자리 → 길 → 손님 곁 서빙 자리 → 돌아옴.
##
## 손님: 아래 문으로 들어와 가운데 길로 걸어 자리에 앉고 주문한다. 아이스박스에서 생선 한 마리를 고른다.
## 생선이 떨어지면 "재료 소진"으로 문을 닫는다 (2026-11-16). 남은 손님은 오지 않고 평판도 깎이지 않는다.

enum GuestState { SEATED, EATING, LEFT, WALKING } # WALKING: 문에서 자리까지 걷는 중 (도착하면 주문)

const OPEN_SECONDS := 150.0 # 문 닫는 시각 (초). 손님을 다 받으면 그 전에 끝난다
const LAST_ARRIVAL := 0.55 # 영업 시간의 이 비율까지만 손님이 들어온다
const GUESTS_MIN := 8
const GUESTS_MAX := 11
const GROUP_MAX := 3 # 손님은 1~3명씩 몰려 들어온다
const COOK_TIME := 8.0 # 한 접시 굽는 시간 (초). 큰 고기는 조금 더
const COOK_PER_CM := 0.15
const GOLD := 2.2 # 다 익은 뒤 이 시간 안에 담으면 노릇노릇 (값 더)
const BURN := 6.0 # 다 익은 뒤 이 시간이 지나면 탄다 (값 깎임, 하트 없음)
const STOVES := 2 # 화구 하나에 불 두 개
const PASS_MAX := 3 # 내놓는 자리에 놓을 수 있는 접시 수
const PATIENCE := 32.0 # 주문하고 받을 때까지 참는 시간 (초). 11-16 서빙 판으로 바꾸며 40에서 줄임
const QUICK := 0.5 # 참는 시간의 이 비율 안에 받으면 하트
const LATE := 0.8 # 참는 시간의 이 비율을 넘겨 받으면 팁이 없다
const EAT_TIME := 6.0
const WALK_SPEED := 0.42 # 주인공, 서빙 알바 걷는 속도 (그림 비율/초)
const GUEST_SPEED := 0.4
const HELPER_AUTO := [0.3, 1.3] # 주방 알바는 다 익고 이 사이에 담는다 (거의 노릇노릇)

## 2026-11-18 식당 4안 (회사 PC 그림 세션 확정, Shop4): 빈 바탕 shop4/bg_night (982x1602)에 가구를 낱장으로 얹는다.
## 배치는 3안 그대로: 위 오른쪽 ㄱ자 카운터 앞 바 4석, 왼쪽 창가 바 2석, 가운데 테이블 둘 (4인씩), 오른쪽 아래 칸막이 2인석. 모두 16석.
## 좌표는 바탕 px를 W, H로 나눈 비율. 자리 좌표는 엉덩이 바닥 (그림 세션 4안_합친확인그림.py에서 스툴 크기로 계산한 값).
## 옆모습은 엉덩이 뒤쪽 끝 x, 나머지는 가운데 x
const W := 982.0
const H := 1602.0

## 손님 자리 (엉덩이 바닥). 0~3 카운터 앞 바, 4·5 창가, 6·7 위 테이블 위쪽 줄, 8·9 아래쪽 줄,
## 10·11 아래 테이블 위쪽 줄, 12·13 아래쪽 줄, 14·15 칸막이
const SEATS := [
	Vector2(478 / W, 645.5 / H), Vector2(593 / W, 645.5 / H), Vector2(708 / W, 645.5 / H), Vector2(823 / W, 645.5 / H),
	Vector2(224.5 / W, 618.8 / H), Vector2(224.5 / W, 918.8 / H),
	Vector2(307 / W, 802.6 / H), Vector2(394 / W, 802.6 / H), Vector2(311 / W, 942.6 / H), Vector2(396 / W, 942.6 / H),
	Vector2(307 / W, 1054.6 / H), Vector2(394 / W, 1054.6 / H), Vector2(311 / W, 1194.6 / H), Vector2(396 / W, 1194.6 / H),
	Vector2(645.5 / W, 1165.9 / H), Vector2(860.5 / W, 1165.9 / H),
]
## 앉은 그림: back 등을 보임, front 얼굴을 보임 (테이블 너머), side 옆모습 (오른쪽을 봄. SEAT_FLIP이면 왼쪽)
const SEAT_VIEW := ["back", "back", "back", "back", "side", "side", "front", "front", "back", "back",
	"front", "front", "back", "back", "side", "side"]
const SEAT_FLIP := [false, false, false, false, true, true, false, false, false, false,
	false, false, false, false, false, true]
## 서빙 자리 (주인공이 서서 내는 곳, 발끝)
const SPOTS := [
	Vector2(478 / W, 748 / H), Vector2(593 / W, 748 / H), Vector2(708 / W, 748 / H), Vector2(823 / W, 748 / H),
	Vector2(252 / W, 708 / H), Vector2(252 / W, 1005 / H),
	Vector2(307 / W, 745 / H), Vector2(394 / W, 745 / H), Vector2(470 / W, 990 / H), Vector2(470 / W, 990 / H),
	Vector2(470 / W, 1060 / H), Vector2(470 / W, 1060 / H), Vector2(470 / W, 1210 / H), Vector2(470 / W, 1210 / H),
	Vector2(612 / W, 1190 / H), Vector2(760 / W, 1238 / H),
]
## 다 먹고 간 빈 그릇 자리 (카운터, 창가 바, 테이블 위)
const PLATE_SPOTS := [
	Vector2(478 / W, 585 / H), Vector2(593 / W, 585 / H), Vector2(708 / W, 585 / H), Vector2(823 / W, 585 / H),
	Vector2(122 / W, 640 / H), Vector2(122 / W, 940 / H),
	Vector2(307 / W, 835 / H), Vector2(394 / W, 835 / H), Vector2(311 / W, 880 / H), Vector2(396 / W, 880 / H),
	Vector2(307 / W, 1087 / H), Vector2(394 / W, 1087 / H), Vector2(311 / W, 1132 / H), Vector2(396 / W, 1132 / H),
	Vector2(732 / W, 1095 / H), Vector2(778 / W, 1095 / H),
]

## 걷는 길: 바닥의 빈 곳을 잇는 한 줄
##   0 창가 아래 - 1 창가 위, 홀 자리 앞 (HOME_LANE) - 2 픽업대 아래 - 3 가운데 통로 위 - 4 가운데 - 5 문 앞 (ENTRY_LANE)
const LANE := [Vector2(240 / W, 1005 / H), Vector2(240 / W, 740 / H), Vector2(390 / W, 740 / H),
	Vector2(545 / W, 740 / H), Vector2(545 / W, 1000 / H), Vector2(545 / W, 1200 / H)]
const HOME_LANE := 1
const ENTRY_LANE := 5
## 자리마다 서빙 자리로 들어가는 길 점 (LANE 번호)
const SEAT_ACCESS := [[2, 3], [3], [3], [3], [1], [0],
	[1, 2], [2], [4], [4], [4], [4], [5], [5], [5], [5]]

## 주방: 요리사는 오른쪽 벽 옆모습 화구 둘 앞에 선다
const COOK_SPOT := Vector2(752 / W, 520 / H) # 요리사 발끝 (화구 앞)
const BURNERS := [Vector2(838 / W, 398 / H), Vector2(838 / W, 474 / H)] # 화구 위 냄비 자리
## 완성 접시 내놓는 자리 (카운터 꺾이는 모서리 픽업대 위)
const PASS_SPOTS := [Vector2(328 / W, 575 / H), Vector2(366 / W, 575 / H), Vector2(404 / W, 575 / H)]
const KITCHEN_EXIT := Vector2(330 / W, 390 / H) # 카운터 세로 팔 위 직원 통로
const HALL_HOME := Vector2(238 / W, 512 / H) # 홀 담당(주인공)이 접시를 기다리는 자리. 왼쪽 위 빈 구석, 카운터 옆 (11-24 사용자: 손님 바로 옆이라 부담스럽다)
const START := COOK_SPOT

## 손님 입구 (아래 가운데 문)
const ENTRANCE := Vector2(491 / W, 1240 / H)

var time := 0.0
var inventory: Array = []
var schedule: Array = [] # [{t, name}]
var guests: Array = [] # {name, seat, fish, size, price, state, wait, eat, cooked, quality, pos, path, dir}
var queue: Array = [] # 화구가 비길 기다리는 주문 (guest index)
var cooking: Array = [] # 화구 위 {guest, t, total, burner}
var pass_dishes: Array = [] # 완성 접시 (guest index)
var helper_serve := false # 서빙 알바 (여울)
var helper_kitchen := true # 요리사 세라가 굽는다 (false면 주인공이 굽는다)
var seat_bonus: Array = []

## 주인공: 요리사(주방 알바가 없으면)이자 혼자일 때는 서빙도 한다
var player := START
var player_path: Array = [] # 걷는 길 (지나갈 점)
var player_dir := Vector2.DOWN
var holding := -1 # 주인공이 든 접시 (guest index)
## 서빙 알바
var helper := HALL_HOME
var helper_path: Array = []
var helper_dir := Vector2.DOWN
var helper_dish := -1

var served: Array = [] # {guest, fish, size, price, heart, side, quality}
var missed := 0 # 예전 저장과 맞추려고 남김 (재료 소진 뒤로는 없다)
var sold_out := false
var turned_away := 0
var angry := 0
var sales := 0 # 음식값 + 팁
var tips := 0 # 그중 팁
var burnt := 0
var perfect := 0
var pantry := {} # 채소 (GameState.produce). 요리 재료로 쓴다
var reserve := {} # 남겨 둘 채소 (Pantry.reserve_for)
## 하트 잇기: 하트를 이어 받을 때마다 팁이 늘어난다 (ServicePlan.COMBO_TIP). 하트 없는 접시나 화난 손님이 나오면 끊긴다
var combo := 0
var best_combo := 0
## 비싼 회를 시킬 손님이 몇 명 남았나 (DayFlow.raw_guests)
var raw_left := 0
## 주방 장비 (KitchenDB.apply)
var cook_mult := 1.0
var plate_bonus := 1.0
var auto_clean := 0.0
var _rng := RandomNumberGenerator.new()
## 생선튀김 (2026-11-18). 복자 할머니 비법(recipe_fish_fry)을 배우면 손님 일부가 구이 대신 튀김을 시킨다.
## 튀김은 값을 더 받는다. 굽는 규칙(화구, 노릇노릇, 탐)은 구이와 같다
const FRY_SHARE := 0.35
const FRY_PRICE := 1.25
const FRY_ART := "bungjangeo-twigim"
var fry := false
var _fry_rng := RandomNumberGenerator.new()
## 새 메뉴 (Menu, 11-19): 메뉴판에 오른 요리 id들. 손님이 고르면 그 재료를 seafood와 pantry(채소)에서 쓴다
var menu: Array = []
var seafood := {}
var today := 0
## 영업 개편 (ServicePlan, 11-19): setup 전에 넣는다. plan이 비면 예전 규칙(손님이 메뉴를 고른다)
var plan := {}
var flags := {}
var patience_mult := 1.0
var regular_names: Array = []
var angry_list: Array = [] # 화나서 간 손님 {"guest", "kind", "reason"}
var events: Array = [] # 화면 연출용 한 번짜리 알림 {type, ...}


## 오늘 손님 명단. 날짜로 정해져서 같은 날은 늘 같다.
## visitors: 저녁 버스로 오는 외지 손님 수 (Bus.visitors). 마지막 무리로 늦게 온다
func setup(day: int, inv: Array, names: Array, visitors := 0) -> void:
	inventory = inv
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("영업-%d" % day)
	_rng.seed = hash("자리-%d" % day)
	_fry_rng.seed = hash("튀김-%d" % day)
	raw_left = DayFlow.raw_guests(day)
	var locals := maxi(1, rng.randi_range(GUESTS_MIN, GUESTS_MAX))
	var n := locals + maxi(0, visitors)
	schedule.clear()
	var last := OPEN_SECONDS * LAST_ARRIVAL
	var groups: Array = []
	var left := n
	while left > 0:
		var g := mini(left, rng.randi_range(1, GROUP_MAX))
		groups.append(g)
		left -= g
	var who := 0 # 몇 번째 손님인지. locals 뒤는 버스 손님
	for gi in groups.size():
		var t0 := 2.0 + (last - 6.0) * gi / maxf(1.0, groups.size() - 1.0) + rng.randf_range(-4.0, 4.0)
		for k in int(groups[gi]):
			var t := t0 + k * rng.randf_range(0.8, 1.6)
			var name: String = names[rng.randi() % names.size()] if not names.is_empty() else "손님"
			if who >= locals:
				name = Bus.VISITOR_NAMES[who % Bus.VISITOR_NAMES.size()]
			schedule.append({"t": clampf(t, 1.0, last), "name": name})
			who += 1
	schedule.sort_custom(func(a, b): return a.t < b.t)
	ServicePlan.assign_kinds(schedule, regular_names, day)
	player = HALL_HOME if helper_kitchen else COOK_SPOT


## 알바가 정해진 뒤 자리 다시 잡기 (setup 뒤에 helper_*를 바꿨을 때)
func place_staff() -> void:
	player = HALL_HOME if helper_kitchen else COOK_SPOT
	helper = HELPER_HOME


func is_over() -> bool:
	return (time >= OPEN_SECONDS or schedule.is_empty()) and _active_count() == 0


func time_left() -> float:
	return maxf(0.0, OPEN_SECONDS - time)


func update(dt: float) -> void:
	time += dt
	_arrive()
	_walk_guests(dt)
	_cook(dt)
	_wait(dt)
	_walk_player(dt)
	_helper_step(dt)


# ─── 주방 ───────────────────────────────────────────

static func cook_time(size_cm: float) -> float:
	return COOK_TIME + maxf(0.0, size_cm - 15.0) * COOK_PER_CM


## 주인공이 조리대 뒤에 서 있는가 (주방 알바가 없을 때 화구를 만질 수 있다)
func at_stove() -> bool:
	return not helper_kitchen and player_path.is_empty() and holding < 0 and player.distance_to(COOK_SPOT) < 0.01


## 화구 위 접시의 익은 정도: 0~1 굽는 중, 1부터 다 익음. 노릇노릇 구간은 1 ~ 1 + GOLD/total
static func doneness(c: Dictionary) -> float:
	return float(c.t) / maxf(float(c.total), 0.01)


## 지금 담으면 어떤 접시가 되나: "" (아직), perfect, good
static func quality_at(c: Dictionary) -> String:
	var over := float(c.t) - float(c.total)
	if over < 0.0:
		return ""
	return "perfect" if over <= GOLD else "good"


func _cook(dt: float) -> void:
	while cooking.size() < STOVES and not queue.is_empty():
		var gi: int = queue.pop_front()
		var used := cooking.map(func(c): return c.burner)
		var b := 0 if not used.has(0) else 1
		cooking.append({"guest": gi, "t": 0.0, "total": cook_time(guests[gi].size) * cook_mult, "burner": b,
			"auto": _rng.randf_range(HELPER_AUTO[0], HELPER_AUTO[1])})
		events.append({"type": "cook", "guest": gi, "burner": b})
	for c in cooking:
		var was := float(c.t)
		c.t = float(c.t) + dt
		if was < c.total and c.t >= c.total:
			events.append({"type": "ready", "guest": c.guest, "burner": c.burner})
	# 주방 알바는 노릇할 때 담는다. 내놓는 자리가 꽉 차면 기다린다
	if helper_kitchen:
		for c in cooking.duplicate():
			if float(c.t) - float(c.total) >= float(c.auto) and pass_dishes.size() < PASS_MAX:
				_to_pass(c, quality_at(c))
	# 너무 오래 두면 탄다: 타면 저절로 내린다 (자리가 없으면 화구 위에서 기다린다)
	for c in cooking.duplicate():
		if float(c.t) - float(c.total) >= BURN and pass_dishes.size() < PASS_MAX:
			_to_pass(c, "burnt")


## 주인공이 화구 하나를 눌러 담는다. 돌려주는 값: "perfect", "good", "early"(아직 덜 익음), "full"(내놓는 자리 꽉 참), "away"(주방에 없음), ""(빈 화구)
func plate(burner: int) -> String:
	var c := _on_burner(burner)
	if c.is_empty():
		return ""
	if not at_stove():
		return "away"
	var q := quality_at(c)
	if q == "":
		events.append({"type": "early", "burner": burner})
		return "early"
	if pass_dishes.size() >= PASS_MAX:
		return "full"
	_to_pass(c, q)
	return q


func _on_burner(burner: int) -> Dictionary:
	for c in cooking:
		if int(c.burner) == burner:
			return c
	return {}


func _to_pass(c: Dictionary, q: String) -> void:
	cooking.erase(c)
	var gi: int = c.guest
	guests[gi].cooked = true
	guests[gi].quality = q
	if q == "burnt":
		burnt += 1
	elif q == "perfect":
		perfect += 1
	pass_dishes.append(gi)
	events.append({"type": "plated", "guest": gi, "quality": q, "burner": c.burner})


# ─── 홀 ─────────────────────────────────────────────
# 주인공(홀 담당)의 일: 완성 접시를 골라(select) 그 요리를 시킨 손님에게(deliver_to), 다 먹고 간 자리 치우기(clear_seat).
# 누른 일은 줄을 서고(MAX_TASKS) 하나씩 한다. 일마다 홀 자리(HALL_HOME)에서 나가 끝나면 돌아온다.
# 같은 생선을 시킨 손님이면 누구에게 줘도 된다 (두 손님의 주문을 맞바꾼다). 다른 요리를 시킨 손님은 안 받는다.

const MAX_TASKS := 3
const HELPER_HOME := Vector2(140 / W, 496 / H) # 서빙 알바가 기다리는 자리 (주인공 왼쪽)

var selected := -1 # 고른 접시 (주문한 guest index). 아직 내놓는 자리에 있다
var tasks: Array = [] # 줄 선 일 [{type: "serve", dish} / {type: "clear", seat}]
var task := {} # 지금 하는 일
var dirty := {} # 다 먹고 간 자리 {seat: true}. 치우기 전엔 손님이 못 앉는다
var carrying_dirty := false # 치운 그릇을 들고 돌아가는 중
var helper_task := {}
var helper_dirty := false


## 내놓는 자리 i번 접시를 고른다 (다시 누르면 내려놓는다)
func select(pass_index: int) -> bool:
	if pass_index < 0 or pass_index >= pass_dishes.size():
		return false
	var gi: int = pass_dishes[pass_index]
	if _dish_reserved(gi):
		return false
	selected = -1 if selected == gi else gi
	events.append({"type": "select", "guest": selected})
	return true


## 고른 접시를 그 손님에게 낸다. "ok", "wrong"(다른 요리를 시킴), "full"(할 일이 꽉 참), "none"(고른 접시 없음)
func deliver_to(gi: int) -> String:
	if selected < 0:
		return "none"
	if gi < 0 or gi >= guests.size() or guests[gi].state != GuestState.SEATED or _dish_reserved(gi) \
			or not same_order(gi, selected) or not _waiting_dish(gi):
		events.append({"type": "wrong", "guest": gi})
		return "wrong"
	if _task_count() >= MAX_TASKS:
		return "full"
	if gi != selected:
		_swap(selected, gi)
	tasks.append({"type": "serve", "dish": gi})
	selected = -1
	events.append({"type": "queued", "guest": gi})
	return "ok"


## 지저분한 자리를 치우러 간다
func clear_seat(seat: int) -> bool:
	if not dirty.has(seat) or _seat_reserved(seat) or _task_count() >= MAX_TASKS:
		return false
	tasks.append({"type": "clear", "seat": seat})
	events.append({"type": "queued_clear", "seat": seat})
	return true


## 자동 플레이와 시험용: 그 접시를 골라 주인 손님에게 바로
func take(pass_index: int) -> bool:
	if not select(pass_index) or selected < 0:
		return false
	return deliver_to(selected) == "ok"


## 그 손님의 주문이 아직 안 나갔는가 (줄, 화구, 내놓는 자리 어딘가에 있다)
func _waiting_dish(gi: int) -> bool:
	return queue.has(gi) or pass_dishes.has(gi) or cooking.any(func(c): return c.guest == gi)


func _task_count() -> int:
	return tasks.size() + (0 if task.is_empty() else 1)


func _dish_reserved(gi: int) -> bool:
	if holding == gi or helper_dish == gi:
		return true
	return tasks.any(func(t): return t.type == "serve" and t.dish == gi) \
		or (helper_task.get("type", "") == "serve" and helper_task.dish == gi)


func _seat_reserved(seat: int) -> bool:
	for t in tasks + [task, helper_task]:
		if t.get("type", "") == "clear" and t.seat == seat:
			return true
	return false


## 같은 생선을 시킨 두 손님의 주문을 맞바꾼다 (줄, 화구, 내놓는 자리, 익은 정도)
func _swap(a: int, b: int) -> void:
	var f := func(x): return b if x == a else (a if x == b else x)
	queue = queue.map(f)
	pass_dishes = pass_dishes.map(f)
	for c in cooking:
		c.guest = f.call(c.guest)
	for k in ["cooked", "quality"]:
		var t = guests[a].get(k)
		guests[a][k] = guests[b].get(k)
		guests[b][k] = t


## 서빙 자리: 그 손님 곁 빈 바닥
static func serve_spot(seat: int) -> Vector2:
	return SPOTS[seat]


## LANE i번에서 j번까지 지나는 점들 (둘 다 넣는다)
static func _lane(i: int, j: int) -> Array:
	var out := []
	var step := 1 if j >= i else -1
	var k := i
	while true:
		out.append(LANE[k])
		if k == j:
			break
		k += step
	return out


## from(들어가는 길 점 from_access 중 하나로 LANE에 올라탐)에서 to까지 가장 짧은 길. to는 넣고 from은 넣지 않는다
static func _route(from: Vector2, from_access: Array, to: Vector2, to_access: Array) -> Array:
	var best := []
	var best_len := INF
	for i in from_access:
		for j in to_access:
			var pts := _lane(i, j)
			var length := from.distance_to(pts[0]) + to.distance_to(pts[pts.size() - 1])
			for k in range(1, pts.size()):
				length += pts[k - 1].distance_to(pts[k])
			if length < best_len:
				best_len = length
				best = pts
	return best + [to]


## 홀 자리, 알바 자리, 주방에서 LANE에 올라타는 점
static func _home_access(from: Vector2) -> Array:
	return [ENTRY_LANE] if from.distance_to(ENTRANCE) < 0.02 else [HOME_LANE]


## from에서 그 자리 서빙 자리까지 가는 길 (주방 안이면 주방 출구로 먼저 나온다)
static func _path_to_guest(from: Vector2, seat: int) -> Array:
	var path := []
	if from.distance_to(COOK_SPOT) < 0.01:
		path.append(KITCHEN_EXIT)
		from = KITCHEN_EXIT
	return path + _route(from, _home_access(from), SPOTS[seat], SEAT_ACCESS[seat])


## 그 자리 서빙 자리에서 홀 자리(또는 주방)로 돌아가는 길
static func _path_home(seat: int, home: Vector2) -> Array:
	var to := KITCHEN_EXIT if home.distance_to(COOK_SPOT) < 0.01 else home
	var path := _route(SPOTS[seat], SEAT_ACCESS[seat], to, [HOME_LANE])
	if to != home:
		path.append(home)
	return path


## 그 일의 자리 (접시를 낼 손님 자리, 또는 치울 자리)
func _task_seat(t: Dictionary) -> int:
	return int(t.seat) if t.type == "clear" else int(guests[t.dish].seat)


## 주인공이 돌아갈 자리
func player_home() -> Vector2:
	return HALL_HOME if helper_kitchen else COOK_SPOT


func _walk_player(dt: float) -> void:
	# 홀 자리에 있고 할 일이 남았으면 다음 일을 시작한다
	if task.is_empty() and player_path.is_empty() and not tasks.is_empty():
		task = tasks.pop_front()
		_start_task(task, true)
	var r := _step(player, player_path, WALK_SPEED * dt)
	player = r[0]
	if r[1] != Vector2.ZERO:
		player_dir = r[1]
	if not task.is_empty() and player_path.is_empty():
		if task.get("back", false):
			carrying_dirty = false
			task = {}
		else:
			_finish_task(task, true)
			player_path = _path_home(_task_seat(task), player_home())
			task["back"] = true


## 일 시작. 접시가 아직 안 나왔으면 줄 맨 앞으로 돌려 두고 기다린다
func _start_task(t: Dictionary, by_player: bool) -> void:
	var from := player if by_player else helper
	if t.type == "serve":
		var gi: int = t.dish
		if guests[gi].state != GuestState.SEATED:
			t["back"] = true
			return
		if not pass_dishes.has(gi):
			if by_player:
				tasks.push_front(t)
				task = {}
			else:
				t["back"] = true
			return
		pass_dishes.erase(gi)
		if by_player:
			holding = gi
			player_path = _path_to_guest(from, guests[gi].seat)
		else:
			helper_dish = gi
			helper_path = _path_to_guest(from, guests[gi].seat)
		events.append({"type": "take" if by_player else "helper_take", "guest": gi})
	else:
		if by_player:
			player_path = _path_to_guest(from, t.seat)
		else:
			helper_path = _path_to_guest(from, t.seat)


func _finish_task(t: Dictionary, by_player: bool) -> void:
	if t.type == "serve":
		var gi: int = holding if by_player else helper_dish
		if gi >= 0 and guests[gi].state == GuestState.SEATED:
			_serve(gi, by_player)
		if by_player:
			holding = -1
		else:
			helper_dish = -1
	else:
		dirty.erase(t.seat)
		if by_player:
			carrying_dirty = true
		else:
			helper_dirty = true
		events.append({"type": "cleared", "seat": t.seat, "helper": not by_player})


## 서빙 알바: 손이 비면 맨 앞 접시(주인공이 맡지 않은 것)를 나르고, 없으면 지저분한 자리를 치운다
func _helper_step(dt: float) -> void:
	if not helper_serve:
		return
	if helper_task.is_empty() and helper_path.is_empty():
		for gi in pass_dishes:
			if not _dish_reserved(gi) and gi != selected and guests[gi].state == GuestState.SEATED:
				helper_task = {"type": "serve", "dish": gi}
				break
		if helper_task.is_empty():
			for seat in dirty:
				if not _seat_reserved(seat):
					helper_task = {"type": "clear", "seat": seat}
					break
		if not helper_task.is_empty():
			_start_task(helper_task, false)
			if helper_task.get("back", false):
				helper_task = {}
	var r := _step(helper, helper_path, WALK_SPEED * dt)
	helper = r[0]
	if r[1] != Vector2.ZERO:
		helper_dir = r[1]
	if not helper_task.is_empty() and helper_path.is_empty():
		if helper_task.get("back", false):
			helper_dirty = false
			helper_task = {}
		else:
			_finish_task(helper_task, false)
			helper_path = _path_home(_task_seat(helper_task), HELPER_HOME)
			helper_task["back"] = true


## 길을 따라 한 걸음. [새 자리, 걷는 방향(멈췄으면 ZERO)]
static func _step(pos: Vector2, path: Array, step: float) -> Array:
	var dir := Vector2.ZERO
	while step > 0.0 and not path.is_empty():
		var to: Vector2 = path[0]
		var d := to - pos
		if d.length() <= step:
			pos = to
			step -= d.length()
			path.pop_front()
		else:
			dir = d.normalized()
			pos += dir * step
			step = 0.0
	return [pos, dir]


func patience_of(seat: int) -> float:
	return PATIENCE + (float(seat_bonus[seat]) if seat < seat_bonus.size() else 0.0)


## 한 접시 값: 구이는 DayFlow.dish_price, 튀김은 그보다 FRY_PRICE배
static func dish_price_of(fish_id: String, size_cm: float, dish: String) -> int:
	var base := DayFlow.dish_price(fish_id, size_cm)
	if Menu.RECIPES.has(dish):
		return Menu.price(dish, base)
	base = mini(base, DayFlow.REGULAR_MAX)
	if dish != "fry":
		return base
	return int(roundf(base * FRY_PRICE / 500.0) * 500.0)


## 두 손님이 같은 요리를 시켰나 (같은 생선, 같은 조리법). 접시를 바꿔 내도 되는지 볼 때 쓴다
func same_order(a: int, b: int) -> bool:
	return guests[a].fish == guests[b].fish and guests[a].get("dish", "grill") == guests[b].get("dish", "grill")


## 요리 그림 id (dish/<id>.png)
static func dish_art_id(fish_id: String, dish: String) -> String:
	if dish == "fry":
		return FRY_ART
	if Menu.RECIPES.has(dish):
		return Menu.art(dish, fish_id)
	return FishDB.get_fish(fish_id).get("grill", "bollak-gui")


func _serve(gi: int, by_player: bool) -> void:
	var g: Dictionary = guests[gi]
	var q: String = g.get("quality", "good")
	var pat := float(g.get("patience", PATIENCE))
	var quick: bool = g.wait <= pat * QUICK
	var late: bool = g.wait >= pat * LATE
	var kind: String = g.get("kind", "normal")
	combo = combo + 1 if ServicePlan.gives_heart(kind, q, quick) else 0
	best_combo = maxi(best_combo, combo)
	var st := ServicePlan.settle(kind, int(g.price), q, quick, late, combo)
	var paid := int(st.price) + int(st.tip)
	g.state = GuestState.EATING
	g.paid = paid
	sales += paid
	tips += int(st.tip)
	served.append({"guest": g.name, "fish": g.fish, "size": g.size, "price": int(st.price), "tip": int(st.tip), "level": int(st.level), "heart": st.heart, "quality": q,
		"dish": g.get("dish", "grill"), "kind": kind})
	events.append({"type": "served", "guest": gi, "heart": st.heart, "price": int(st.price), "tip": int(st.tip), "combo": combo, "quality": q, "helper": not by_player})


# ─── 손님 ───────────────────────────────────────────

func free_seats() -> Array:
	var used := dirty.duplicate()
	for g in guests:
		if g.state != GuestState.LEFT:
			used[g.seat] = true
	var out := []
	for i in SEATS.size():
		if not used.has(i):
			out.append(i)
	return out


## 이 생선을 비싼 회로 낼 수 있나 (구이 값 끝보다 비싸고, 회가 되는 싱싱한 것)
func _is_raw(e: Dictionary) -> bool:
	return DayFlow.too_pricey(e.id, e.size) and Menu.fits("hoe", e, today if today > 0 else int(e.get("day", 0))) \
		and (plan.is_empty() or ServicePlan.dish_for(plan, e.id, flags) == "hoe")


## 다음 손님에게 낼 생선: 가장 값진 것. 없으면 -1.
## 회 손님을 다 받았으면 싱싱한 비싼 생선은 아껴 둔다 (내일 수조나 시장으로)
func pick_fish() -> int:
	var best := -1
	for i in inventory.size():
		var e: Dictionary = inventory[i]
		if raw_left <= 0 and _is_raw(e):
			continue
		if best < 0 or FishDB.value_of(e.id, e.size) > FishDB.value_of(inventory[best].id, inventory[best].size):
			best = i
	return best


## 그 생선으로 낼 요리. 비싼 회면 회 손님 한 명을 쓴다
func _dish_of(e: Dictionary) -> String:
	if raw_left > 0 and _is_raw(e):
		raw_left -= 1
		return "hoe"
	var dish := ""
	if not plan.is_empty():
		# 메뉴판에 적은 대로. 재료가 떨어졌거나 싱싱하지 않으면 구이로
		dish = ServicePlan.dish_for(plan, e.id, flags)
		if Menu.RECIPES.has(dish):
			if not Menu.fits(dish, e, today) or not Menu.can_make(dish, pantry, seafood, reserve):
				dish = "grill"
	else:
		dish = Menu.pick(menu, e, today, pantry, seafood, _fry_rng)
		if dish.is_empty():
			dish = "fry" if fry and _fry_rng.randf() < FRY_SHARE else "grill"
	if Menu.RECIPES.has(dish):
		Menu.take(dish, pantry, seafood)
	return dish


func _active_count() -> int:
	var n := 0
	for g in guests:
		if g.state != GuestState.LEFT:
			n += 1
	return n


func _arrive() -> void:
	while not schedule.is_empty() and schedule[0].t <= time:
		var s: Dictionary = schedule.pop_front()
		var seats := free_seats()
		if seats.is_empty():
			s.t = time + 2.0
			if s.t < OPEN_SECONDS:
				schedule.push_front(s)
				schedule.sort_custom(func(a, b): return a.t < b.t)
			return
		var fi := pick_fish()
		if fi < 0:
			sold_out = true
			turned_away += 1 + schedule.size()
			schedule.clear()
			events.append({"type": "sold_out", "count": turned_away})
			return
		var e: Dictionary = inventory[fi]
		inventory.remove_at(fi)
		var seat: int = seats[_rng.randi() % seats.size()]
		var dish := _dish_of(e)
		var kind: String = s.get("kind", "normal")
		var g := {
			"name": s.name, "seat": seat, "fish": e.id, "size": e.size, "entry": e, "dish": dish,
			"price": int(roundf(dish_price_of(e.id, e.size, dish) * plate_bonus / 500.0) * 500.0), "state": GuestState.WALKING,
			"kind": kind, "patience": patience_of(seat) * patience_mult * float(ServicePlan.KINDS[kind].patience),
			"wait": 0.0, "eat": 0.0, "cooked": false, "quality": "",
			"pos": ENTRANCE, "path": entry_path(seat), "dir": Vector2.UP,
		}
		guests.append(g)
		events.append({"type": "arrive", "guest": guests.size() - 1})


## 문에서 그 자리까지 걷는 길: 문 앞에서 가운데 길을 따라 서빙 자리까지 와서 자리에 앉는다
static func entry_path(seat: int) -> Array:
	return _route(ENTRANCE, [ENTRY_LANE], SPOTS[seat], SEAT_ACCESS[seat]) + [SEATS[seat]]


func _walk_guests(dt: float) -> void:
	for gi in guests.size():
		var g: Dictionary = guests[gi]
		if g.state != GuestState.WALKING:
			continue
		var r := _step(g.pos, g.path, GUEST_SPEED * dt)
		g.pos = r[0]
		if r[1] != Vector2.ZERO:
			g.dir = r[1]
		if g.path.is_empty():
			g.state = GuestState.SEATED
			queue.append(gi)
			events.append({"type": "order", "guest": gi})


func _wait(dt: float) -> void:
	for gi in guests.size():
		var g: Dictionary = guests[gi]
		match g.state:
			GuestState.SEATED:
				g.wait += dt
				if g.wait >= float(g.get("patience", patience_of(g.seat))):
					_leave_angry(gi)
			GuestState.EATING:
				g.eat += dt
				if g.eat >= EAT_TIME:
					g.state = GuestState.LEFT
					if auto_clean <= 0.0 or _rng.randf() >= auto_clean: # 좋은 싱크대면 가끔 저절로 치워진다
						dirty[g.seat] = true # 빈 그릇이 남는다. 치워야 다음 손님이 앉는다
					events.append({"type": "left", "guest": gi})


## 너무 기다려서 간다. 아직 굽지 않은 생선은 아이스박스로 돌아가고, 굽던 것과 구운 접시는 버린다
func _leave_angry(gi: int) -> void:
	var g: Dictionary = guests[gi]
	g.state = GuestState.LEFT
	angry += 1
	combo = 0
	# 왜 화났는지: 접시가 나와 있었는데 안 날랐나(pass), 아직 굽는 중이었나(kitchen)
	var reason := "pass" if pass_dishes.has(gi) or holding == gi else "kitchen"
	angry_list.append({"guest": g.name, "kind": g.get("kind", "normal"), "reason": reason})
	events.append({"type": "angry", "guest": gi, "reason": reason})
	if queue.has(gi):
		queue.erase(gi)
		inventory.append(g.entry)
	cooking = cooking.filter(func(c): return c.guest != gi)
	pass_dishes.erase(gi)
	if selected == gi:
		selected = -1
	tasks = tasks.filter(func(t): return not (t.type == "serve" and t.dish == gi))
	# 들고 가던 접시는 손님 앞에 닿으면 아무 일 없이 돌아온다
