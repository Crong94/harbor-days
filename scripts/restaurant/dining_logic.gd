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
## 나중에 알바를 뽑으면 요리나 서빙을 맡긴다 (helper_serve: 완성 접시를 알아서 갖다준다).

enum GuestState { SEATED, EATING, LEFT }

const OPEN_SECONDS := 240.0 # 실제 약 4분 (사용자 결정)
const LAST_ARRIVAL := 0.8 # 영업 시간의 이 비율까지만 손님이 들어온다
const GUESTS_MIN := 6
const GUESTS_MAX := 9
const COOK_TIME := 9.0 # 한 접시 굽는 시간 (초). 큰 고기는 조금 더
const COOK_PER_CM := 0.15
const STOVES := 2 # 동시에 굽는 화로 수
const PASS_MAX := 4 # 내놓는 자리에 놓을 수 있는 접시 수
const PATIENCE := 45.0 # 주문하고 받을 때까지 참는 시간 (초)
const QUICK := 0.5 # 참는 시간의 이 비율 안에 받으면 하트
const QUICK_BONUS := 1.15 # 하트 손님 값 배수
const SLOW_CUT := 0.85 # 참을성이 바닥나기 직전(마지막 20%)에 받으면 값 배수
const EAT_TIME := 6.0
const MOVE_SPEED := 0.55 # 주인공 걷는 속도 (바닥 비율/초)
const REACH := 0.07 # 서빙 자리에 닿았다고 보는 거리

## 배치 (2026-11-11 사용자): 세로로 긴 식당. 맨 위 주방, 양옆에 위아래로 긴 바 카운터, 가운데 통로, 맨 아래 입구.
## 손님은 바 바깥(벽) 쪽 의자에 앉아 가운데를 본다. 한쪽 4석, 모두 8석. 주인공은 통로에서 바 너머로 접시를 놓는다.
const SEATS := [
	Vector2(0.13, 0.36), Vector2(0.13, 0.52), Vector2(0.13, 0.68), Vector2(0.13, 0.84),
	Vector2(0.87, 0.36), Vector2(0.87, 0.52), Vector2(0.87, 0.68), Vector2(0.87, 0.84),
]
const AISLE_EDGE := 0.36 # 통로에서 바에 붙어 설 수 있는 x (왼쪽 바. 오른쪽은 1에서 뺀 값)
## 완성 접시 내놓는 자리 (위 주방 가운데)
const PASS := Vector2(0.5, 0.16)
const START := Vector2(0.5, 0.3)
## 걸어 다닐 수 있는 범위 (가운데 통로)
const FLOOR_MIN := Vector2(0.36, 0.24)
const FLOOR_MAX := Vector2(0.64, 0.92)

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
var helper_serve := false # 알바: 완성 접시를 알아서 갖다준다 (나중에)

var served: Array = [] # {guest, fish, size, price, heart}
var missed := 0 # 생선이 없어 그냥 돌아간 손님
var angry := 0 # 너무 기다려서 그냥 간 손님
var sales := 0
var events: Array = [] # 화면 연출용 한 번짜리 알림 {type, guest} (화면이 꺼내 쓴다)


## 오늘 손님 명단. 날짜로 정해져서 같은 날은 늘 같다
func setup(day: int, inv: Array, names: Array) -> void:
	inventory = inv
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("영업-%d" % day)
	var n := rng.randi_range(GUESTS_MIN, GUESTS_MAX)
	schedule.clear()
	var last := OPEN_SECONDS * LAST_ARRIVAL
	for i in n:
		# 고르게 흩되 조금씩 흔든다. 첫 손님은 문 열자마자
		var t := 2.0 + (last - 2.0) * i / maxf(1.0, n - 1.0) + rng.randf_range(-4.0, 4.0)
		schedule.append({"t": clampf(t, 1.0, last), "name": names[rng.randi() % names.size()] if not names.is_empty() else "손님"})
	schedule.sort_custom(func(a, b): return a.t < b.t)


func is_over() -> bool:
	return time >= OPEN_SECONDS and _active_count() == 0


## 문 닫을 때까지 남은 시간 (초)
func time_left() -> float:
	return maxf(0.0, OPEN_SECONDS - time)


func update(dt: float) -> void:
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
	return Vector2(AISLE_EDGE if s.x < 0.5 else 1.0 - AISLE_EDGE, s.y)


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


func _cook(dt: float) -> void:
	while cooking.size() < STOVES and not queue.is_empty():
		var gi: int = queue.pop_front()
		cooking.append({"guest": gi, "left": cook_time(guests[gi].size), "total": cook_time(guests[gi].size)})
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
				if g.wait >= PATIENCE:
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
	if helper_serve and holding < 0 and not pass_dishes.is_empty():
		holding = pass_dishes.pop_front() # 알바가 집어 바로 갖다준다
		_serve(holding)
		return
	if holding < 0:
		return
	var g: Dictionary = guests[holding]
	if g.state == GuestState.SEATED and player.distance_to(serve_spot(g.seat)) <= REACH:
		_serve(holding)


func _serve(gi: int) -> void:
	var g: Dictionary = guests[gi]
	var price := pay(g.price, g.wait)
	var heart: bool = g.wait <= PATIENCE * QUICK
	g.state = GuestState.EATING
	g.paid = price
	sales += price
	served.append({"guest": g.name, "fish": g.fish, "size": g.size, "price": price, "heart": heart})
	events.append({"type": "served", "guest": gi, "heart": heart, "price": price})
	holding = -1
