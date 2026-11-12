class_name DiningLogic
extends RefCounted
## 저녁 영업 (2026-11-11 사용자 요청: 손님이 앉아 주문하고, 요리는 시간이 지나면 완성되고, 주인공이 들고 가서 서빙한다).
## 장면 없이 규칙만 담아 헤드리스로 시험한다. 화면은 scenes/restaurant/service.gd의 영업 판.
##
## 흐름
##   손님이 정해진 때에 들어와 빈자리에 앉는다 → 아이스박스에서 생선 한 마리를 골라 주문한다(머리 위 아이콘)
##   → 주문은 바로 화로에 올라가 COOK_TIME초 뒤 완성되어 내놓는 자리(pass)에 놓인다
##   → 주인공이 완성 접시를 집어(take) 방향 버튼으로 걸어가 그 손님 곁에 닿으면 내려놓는다
##   → 손님은 EAT_TIME초 먹고 값을 내고 나간다. 빨리 받으면 하트(값 더), 너무 오래 기다리면 화나서 그냥 간다
## 생선이 떨어지면 들어온 손님은 그냥 돌아간다 (평판 깎임). 재료는 낚시로 잡은 생선뿐이다.
## 좌표는 바닥 비율 (x 0 왼쪽 ~ 1 오른쪽, y 0 위 ~ 1 아래). 배경 그림이 오면 SEATS, PASS만 맞춘다.
## 요리 (2026-11-11 사용자): 주방 알바가 없으면 주인공이 주방 앞(통로 맨 위)에 서 있는 동안만 화로가 익는다.
## 알바 (한 번 뽑으면 계속, StaffDB): 주방 알바는 혼자 굽고(helper_kitchen), 서빙 알바는 완성 접시를 알아서 나른다(helper_serve).

enum GuestState { SEATED, EATING, LEFT }

const OPEN_SECONDS := 240.0 # 실제 약 4분 (사용자 결정)
const LAST_ARRIVAL := 0.8 # 영업 시간의 이 비율까지만 손님이 들어온다
const GUESTS_MIN := 11 # 2026-11-12 사용자: 6~9명은 너무 한가함
const GUESTS_MAX := 15
const GROUP_MAX := 3 # 손님은 1~3명씩 몰려 들어온다 (저녁 붐빔)
const COOK_TIME := 8.0 # 한 접시 굽는 시간 (초). 큰 고기는 조금 더
const COOK_PER_CM := 0.15
const STOVES := 2 # 동시에 굽는 화로 수
const PASS_MAX := 4 # 내놓는 자리에 놓을 수 있는 접시 수
const PATIENCE := 40.0 # 주문하고 받을 때까지 참는 시간 (초)
const QUICK := 0.5 # 참는 시간의 이 비율 안에 받으면 하트
const QUICK_BONUS := 1.15 # 하트 손님 값 배수
const SLOW_CUT := 0.85 # 참을성이 바닥나기 직전(마지막 20%)에 받으면 값 배수
const EAT_TIME := 6.0
const MOVE_SPEED := 0.55 # 주인공 걷는 속도 (바닥 비율/초)
const REACH := 0.07 # 서빙 자리에 닿았다고 보는 거리
const HELPER_TRIP := 3.5 # 서빙 알바가 한 접시 갖다주는 데 걸리는 시간 (초)
const KITCHEN_DEPTH := 0.03 # 통로 맨 위에서 이만큼 안은 주방 앞 (요리가 익는 곳)

## 배치 (2026-11-11 사용자 확정): 바가 왼쪽, 앞, 오른쪽으로 이어진 U자. 위쪽은 주방으로 열린다.
## 시점은 정면에서 약 25도 내려다본 거의 직교 투영 (배경 bg_shop_inside_night/day, 941x1671).
## 안쪽 통로는 SD 하나 폭. 손님은 바 바깥에 왼쪽 4, 오른쪽 4, 앞 바 앞 양끝 2 (10석). 앞 바 손님은 등이, 양옆 손님은 옆모습이 보인다.
## 좌표는 배경 그림 전체에 대한 비율, 발끝 기준 (그림 세션이 잰 값). 양옆 바는 뒤로 갈수록 안쪽으로 들어가서 줄마다 x가 다르다.
const SEATS := [
	Vector2(0.20, 0.48), Vector2(0.17, 0.57), Vector2(0.14, 0.66), Vector2(0.11, 0.75),
	Vector2(0.80, 0.48), Vector2(0.83, 0.57), Vector2(0.86, 0.66), Vector2(0.89, 0.75),
	Vector2(0.30, 0.84), Vector2(0.70, 0.84),
]
const AISLE := Vector2(0.39, 0.61) # 안쪽 통로 x 범위 (양옆 바 안쪽 가장자리)
const FRONT_Y := 0.8 # 이보다 아래 자리는 앞 바 손님 (등을 보인다)
const AISLE_BOTTOM := 0.69 # 안쪽 통로 아래 끝 (그 밑은 앞 바)
## 완성 접시 내놓는 자리 (주방 카운터 윗면, 가운데 트인 출구)
const PASS := Vector2(0.51, 0.37)
const START := Vector2(0.5, 0.46)
## 걸어 다닐 수 있는 범위 (U자 안쪽 통로, 주방 출구부터 앞 바 안쪽까지)
const FLOOR_MIN := Vector2(AISLE.x, 0.40)
const FLOOR_MAX := Vector2(AISLE.y, AISLE_BOTTOM)

var time := 0.0
var inventory: Array = [] # 아이스박스 생선 {id, size, ...}. 주문할 때 여기서 뺀다
var schedule: Array = [] # [{t, name}] 들어올 손님
var guests: Array = [] # {name, seat, fish, size, price, state, wait, eat, cook_done}
var cooking: Array = [] # {guest(index), left}
var queue: Array = [] # 화로가 비길 기다리는 주문 (guest index)
var pass_dishes: Array = [] # 완성 접시 (guest index)
var holding := -1 # 주인공 손에 든 접시 (guest index, -1이면 빈손)
var player := START
var move := Vector2.ZERO # 방향 버튼 (-1~1)
var helper_serve := false # 서빙 알바: 완성 접시를 알아서 갖다준다 (한 접시에 HELPER_TRIP초)
var helper_kitchen := false # 주방 알바: 주인공이 없어도 화로가 익는다
var helper_dish := -1 # 서빙 알바가 들고 가는 접시 (guest index)
var helper_left := 0.0
var seat_bonus: Array = [] # 자리마다 더 참아 주는 시간 (초). 편한 의자 (ShopDecor.seat_comfort)

var served: Array = [] # {guest, fish, size, price, heart}
var missed := 0 # 생선이 없어 그냥 돌아간 손님
var angry := 0 # 너무 기다려서 그냥 간 손님
var sales := 0
var pantry := {} # 곁들임 보관 (GameState.produce). 접시 낼 때 하나씩 붙는다 (Sides)
var reserve := {} # 곁들이지 말고 남겨 둘 것 (순덕 할머니 부탁)
var side_sales := 0 # 곁들임으로 더 받은 돈 (sales에 포함)
var events: Array = [] # 화면 연출용 한 번짜리 알림 {type, guest} (화면이 꺼내 쓴다)


## 오늘 손님 명단. 날짜로 정해져서 같은 날은 늘 같다
func setup(day: int, inv: Array, names: Array) -> void:
	inventory = inv
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("영업-%d" % day)
	var n := rng.randi_range(GUESTS_MIN, GUESTS_MAX)
	schedule.clear()
	var last := OPEN_SECONDS * LAST_ARRIVAL
	# 1~3명씩 무리 지어 온다. 무리는 고르게 흩되 조금씩 흔들고, 한 무리는 1초 남짓 간격으로 들어온다
	var groups: Array = []
	var left := n
	while left > 0:
		var g := mini(left, rng.randi_range(1, GROUP_MAX))
		groups.append(g)
		left -= g
	for gi in groups.size():
		var t0 := 2.0 + (last - 6.0) * gi / maxf(1.0, groups.size() - 1.0) + rng.randf_range(-4.0, 4.0)
		for k in int(groups[gi]):
			var t := t0 + k * rng.randf_range(0.8, 1.6)
			schedule.append({"t": clampf(t, 1.0, last), "name": names[rng.randi() % names.size()] if not names.is_empty() else "손님"})
	schedule.sort_custom(func(a, b): return a.t < b.t)


func is_over() -> bool:
	return time >= OPEN_SECONDS and _active_count() == 0


## 문 닫을 때까지 남은 시간 (초)
func time_left() -> float:
	return maxf(0.0, OPEN_SECONDS - time)


var _last_dt := 0.0


func update(dt: float) -> void:
	_last_dt = dt
	time += dt
	_arrive()
	_cook(dt)
	_wait(dt)
	_walk(dt)
	_try_serve()


## 완성 접시를 집는다. 이미 들고 있으면 바꿔 든다 (든 건 내놓는 자리로)
func take(pass_index: int) -> bool:
	if pass_index < 0 or pass_index >= pass_dishes.size():
		return false
	var g: int = pass_dishes[pass_index]
	pass_dishes.remove_at(pass_index)
	if holding >= 0:
		pass_dishes.append(holding)
	holding = g
	events.append({"type": "take", "guest": g})
	return true


## 그 자리 손님에게 접시를 놓을 때 주인공이 서는 곳 (손님 앞 통로, 바에 붙어서)
static func serve_spot(seat: int) -> Vector2:
	var s: Vector2 = SEATS[seat]
	var x := AISLE.x if s.x < 0.5 else AISLE.y
	if s.y > AISLE_BOTTOM:
		return Vector2(x, AISLE_BOTTOM) # 아래 바 밑 손님은 통로 아래 모서리에서
	return Vector2(x, s.y)


func free_seats() -> Array:
	var used := {}
	for g in guests:
		if g.state != GuestState.LEFT:
			used[g.seat] = true
	var out := []
	for i in SEATS.size():
		if not used.has(i):
			out.append(i)
	return out


## 보통 손님에게 낼 수 있는 생선 중 가장 값진 것의 index. 없으면 -1
func pick_fish() -> int:
	var best := -1
	for i in inventory.size():
		var e: Dictionary = inventory[i]
		if DayFlow.dish_price(e.id, e.size) > DayFlow.REGULAR_MAX:
			continue
		if best < 0 or FishDB.value_of(e.id, e.size) > FishDB.value_of(inventory[best].id, inventory[best].size):
			best = i
	return best


static func cook_time(size_cm: float) -> float:
	return COOK_TIME + maxf(0.0, size_cm - 15.0) * COOK_PER_CM


## 그 자리 손님이 참는 시간 (의자가 편하면 더 길다)
func patience_of(seat: int) -> float:
	return PATIENCE + (float(seat_bonus[seat]) if seat < seat_bonus.size() else 0.0)


## 받는 시점의 값. 빨리 받으면 하트 값, 아슬아슬하면 깎인 값
static func pay(price: int, waited: float) -> int:
	var k := 1.0
	if waited <= PATIENCE * QUICK:
		k = QUICK_BONUS
	elif waited >= PATIENCE * 0.8:
		k = SLOW_CUT
	return int(roundf(price * k / 500.0) * 500.0)


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
			# 자리가 없으면 잠깐 밖에서 기다린다 (2초 뒤 다시)
			s.t = time + 2.0
			if s.t < OPEN_SECONDS:
				schedule.push_front(s)
				schedule.sort_custom(func(a, b): return a.t < b.t)
			return
		var fi := pick_fish()
		if fi < 0:
			missed += 1
			events.append({"type": "missed", "name": s.name})
			continue
		var e: Dictionary = inventory[fi]
		inventory.remove_at(fi)
		var g := {
			"name": s.name, "seat": seats[0], "fish": e.id, "size": e.size, "entry": e,
			"price": DayFlow.dish_price(e.id, e.size), "state": GuestState.SEATED,
			"wait": 0.0, "eat": 0.0, "cooked": false,
		}
		guests.append(g)
		var gi := guests.size() - 1
		queue.append(gi)
		events.append({"type": "order", "guest": gi})


## 주인공이 주방 앞에 서 있는가
func in_kitchen() -> bool:
	return player.y <= FLOOR_MIN.y + KITCHEN_DEPTH


## 지금 화로가 익고 있는가 (주방 알바가 있거나 주인공이 주방 앞에)
func cooking_now() -> bool:
	return helper_kitchen or in_kitchen()


func _cook(dt: float) -> void:
	while cooking.size() < STOVES and not queue.is_empty():
		var gi: int = queue.pop_front()
		cooking.append({"guest": gi, "left": cook_time(guests[gi].size), "total": cook_time(guests[gi].size)})
	if cooking_now():
		for c in cooking:
			# 내놓는 자리가 꽉 차면 다 구운 접시는 화로에서 기다린다
			c.left = maxf(0.0, c.left - dt)
	var still := []
	for c in cooking:
		if c.left <= 0.0 and pass_dishes.size() < PASS_MAX:
			pass_dishes.append(c.guest)
			guests[c.guest].cooked = true
			events.append({"type": "ready", "guest": c.guest})
		else:
			still.append(c)
	cooking = still


func _wait(dt: float) -> void:
	for gi in guests.size():
		var g: Dictionary = guests[gi]
		match g.state:
			GuestState.SEATED:
				g.wait += dt
				if g.wait >= patience_of(g.seat):
					_leave_angry(gi)
			GuestState.EATING:
				g.eat += dt
				if g.eat >= EAT_TIME:
					g.state = GuestState.LEFT
					events.append({"type": "left", "guest": gi})


## 너무 기다려서 간다. 아직 굽지 않은 생선은 아이스박스로 돌아가고, 구운 접시는 버린다
func _leave_angry(gi: int) -> void:
	var g: Dictionary = guests[gi]
	g.state = GuestState.LEFT
	angry += 1
	events.append({"type": "angry", "guest": gi})
	if queue.has(gi):
		queue.erase(gi)
		inventory.append(g.entry)
	for c in cooking:
		if c.guest == gi and c.left >= c.total:
			inventory.append(g.entry) # 화로에 올렸지만 아직 안 익었으면 생선은 돌아온다
	if helper_dish == gi:
		helper_dish = -1
	pass_dishes.erase(gi)
	if holding == gi:
		holding = -1
	for c in cooking:
		if c.guest == gi:
			c.left = INF # 화로에서 내려 버린다
	cooking = cooking.filter(func(c): return c.guest != gi)


func _walk(dt: float) -> void:
	if move == Vector2.ZERO:
		return
	player = (player + move.limit_length(1.0) * MOVE_SPEED * dt).clamp(FLOOR_MIN, FLOOR_MAX)


func _try_serve() -> void:
	if helper_serve:
		_helper_step()
	if holding < 0:
		return
	var g: Dictionary = guests[holding]
	if g.state == GuestState.SEATED and player.distance_to(serve_spot(g.seat)) <= REACH:
		_serve(holding)


## 서빙 알바: 완성 접시를 하나 집어 HELPER_TRIP초 뒤 그 손님에게 낸다
func _helper_step() -> void:
	if helper_dish < 0:
		if pass_dishes.is_empty():
			return
		helper_dish = pass_dishes.pop_front()
		helper_left = HELPER_TRIP
		return
	helper_left -= _last_dt
	if helper_left <= 0.0:
		var gi := helper_dish
		helper_dish = -1
		if guests[gi].state == GuestState.SEATED:
			_serve(gi, false)


func _serve(gi: int, by_player := true) -> void:
	var g: Dictionary = guests[gi]
	var price := pay(g.price, g.wait)
	var heart: bool = g.wait <= PATIENCE * QUICK
	var side := Sides.take(pantry, reserve)
	var extra := Sides.bonus(side)
	price += extra
	side_sales += extra
	g.state = GuestState.EATING
	g.paid = price
	sales += price
	served.append({"guest": g.name, "fish": g.fish, "size": g.size, "price": price, "heart": heart, "side": side})
	events.append({"type": "served", "guest": gi, "heart": heart, "price": price, "side": side, "helper": not by_player})
	if by_player:
		holding = -1
