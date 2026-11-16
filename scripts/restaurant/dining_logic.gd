class_name DiningLogic
extends RefCounted
## 저녁 영업 (2026-11-16 다시 짬. 사용자: "한 사람은 주방에서 계속 요리하고 다른 한 사람은 서빙만").
## 장면 없이 규칙만 담아 헤드리스로 시험한다. 화면은 scenes/restaurant/dining_floor.gd.
##
## 사람은 둘 자리: 주방(조리대 뒤에 서서 굽는다)과 홀(완성 접시를 들고 U자 바 안쪽 통로로 날라 준다).
##   2026-11-16 사용자: "주인공은 낚시, 서빙을 담당하고 다른 등장인물이 요리 전담". 요리사는 순덕 할머니 손녀 최세라 (둘째 날부터, Story sera_arrives).
##   세라는 노릇할 때 담아 조리대 끝 내놓는 자리에 놓는다. 주인공은 접시를 눌러(take) 손님에게 갖다준다.
##   내놓는 자리가 꽉 차면 세라가 접시를 못 내려서 화구 위 생선이 탈 수 있다 (빨리 날라야 하는 까닭).
##   서빙 알바(여울)를 뽑으면 여울도 맨 앞 접시부터 알아서 나른다.
##   helper_kitchen이 false면 예전처럼 주인공이 직접 굽는다 (plate, 첫날 튜토리얼과 시험용).
## 사람은 조이스틱 없이 정해진 길로만 걷는다: 주방 → 조리대 옆 출구 → 바 안쪽 통로 → 손님 앞 → 돌아옴.
##
## 손님: 문으로 들어와 벽 쪽 길로 걸어 바 바깥 의자에 앉고 주문한다. 아이스박스에서 생선 한 마리를 고른다.
## 생선이 떨어지면 "재료 소진"으로 문을 닫는다 (2026-11-16). 남은 손님은 오지 않고 평판도 깎이지 않는다.
## 좌표는 식당 배경 그림(bg_shop_openkitchen_*, 941x1671) 전체 비율, 발끝 기준. 그림 세션 슬롯 설계 7·8차 값.

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
const QUALITY_PRICE := {"perfect": 1.1, "good": 1.0, "burnt": 0.6}
const STOVES := 2 # 화구 하나에 불 두 개
const PASS_MAX := 3 # 내놓는 자리에 놓을 수 있는 접시 수
const PATIENCE := 32.0 # 주문하고 받을 때까지 참는 시간 (초). 11-16 서빙 판으로 바꾸며 40에서 줄임
const QUICK := 0.5 # 참는 시간의 이 비율 안에 받으면 하트
const QUICK_BONUS := 1.15
const SLOW_CUT := 0.85
const EAT_TIME := 6.0
const WALK_SPEED := 0.42 # 주인공, 서빙 알바 걷는 속도 (그림 비율/초)
const GUEST_SPEED := 0.4
const HELPER_AUTO := [0.3, 1.3] # 주방 알바는 다 익고 이 사이에 담는다 (거의 노릇노릇)

## 손님 자리 (의자 기준점, 슬롯 설계 7차 chair_0~9). 바 바깥: 왼쪽 4, 오른쪽 4, 앞 바 아래 2
## 11-16 영상 확인: 옆모습 손님은 몸이 그림 칸 가운데보다 바 쪽으로 나와서 양옆 자리를 바깥으로 조금 옮겼다 (왼쪽 0.012, 오른쪽 0.035)
const SEATS := [
	Vector2(0.233, 0.598), Vector2(0.204, 0.683), Vector2(0.174, 0.768), Vector2(0.145, 0.853),
	Vector2(0.787, 0.598), Vector2(0.817, 0.683), Vector2(0.847, 0.768), Vector2(0.876, 0.853),
	Vector2(0.389, 0.917), Vector2(0.610, 0.917),
]
const FRONT_Y := 0.88 # 이보다 아래 자리는 앞 바 손님 (등을 보인다)
## U자 바 안쪽 가장자리 (위 끝과 아래 끝). 원근 때문에 아래로 갈수록 벌어진다
const INNER_TOP := Vector2(0.386, 0.512) # 왼쪽 안쪽 위 끝 (오른쪽은 좌우 대칭)
const INNER_BOTTOM := Vector2(0.328, 0.793)
const SERVE_INSET := 0.045 # 바 안쪽 가장자리에서 이만큼 통로 쪽에 서서 낸다
const AISLE_BOTTOM := 0.775 # 통로 맨 아래 (앞 바 손님은 여기서 받는다)

## 주방과 출구
const COOK_SPOT := Vector2(0.266, 0.455) # 요리사 발끝 (조리대 뒤)
const BURNERS := [Vector2(0.232, 0.428), Vector2(0.300, 0.428)] # 화구 불 두 개 (조리대 윗면)
const PASS := Vector2(0.405, 0.432) # 완성 접시 내놓는 자리 (조리대 오른쪽 끝)
const PASS_STEP := 0.05 # 접시가 여럿이면 오른쪽으로 이어 놓는다
const KITCHEN_EXIT := Vector2(0.475, 0.462) # 조리대 옆 트인 곳
const AISLE_TOP := Vector2(0.5, 0.53)
const HALL_HOME := Vector2(0.515, 0.468) # 홀 담당(주인공)이 접시를 기다리는 자리 (조리대 끝 바로 옆)
const START := COOK_SPOT

## 손님 입구 (오른쪽 벽 문) 와 벽 쪽 길
const ENTRANCE := Vector2(0.95, 0.475)
const LANE_RIGHT := 0.925
const LANE_LEFT := 0.07
const LANE_BOTTOM := 0.97

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
var sales := 0
var burnt := 0
var perfect := 0
var pantry := {}
var reserve := {}
var side_sales := 0
var _rng := RandomNumberGenerator.new()
var events: Array = [] # 화면 연출용 한 번짜리 알림 {type, ...}


## 오늘 손님 명단. 날짜로 정해져서 같은 날은 늘 같다
func setup(day: int, inv: Array, names: Array) -> void:
	inventory = inv
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("영업-%d" % day)
	_rng.seed = hash("자리-%d" % day)
	var n := rng.randi_range(GUESTS_MIN, GUESTS_MAX)
	schedule.clear()
	var last := OPEN_SECONDS * LAST_ARRIVAL
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
		cooking.append({"guest": gi, "t": 0.0, "total": cook_time(guests[gi].size), "burner": b,
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
const HELPER_HOME := Vector2(0.66, 0.478) # 서빙 알바가 기다리는 자리 (주인공 오른쪽)

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
			or guests[gi].fish != guests[selected].fish or not _waiting_dish(gi):
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


## 서빙 자리: 손님 앞 바 안쪽 가장자리에서 통로 쪽으로 조금
static func serve_spot(seat: int) -> Vector2:
	var s: Vector2 = SEATS[seat]
	if s.y > FRONT_Y:
		return Vector2(clampf(s.x, 0.42, 0.58), AISLE_BOTTOM)
	var y := clampf(s.y, AISLE_TOP.y + 0.02, AISLE_BOTTOM)
	var x := inner_x(y, s.x < 0.5)
	return Vector2(x + (SERVE_INSET if s.x < 0.5 else -SERVE_INSET), y)


## 바 안쪽 가장자리 x (그 높이에서)
static func inner_x(y: float, left: bool) -> float:
	var k := clampf((y - INNER_TOP.y) / (INNER_BOTTOM.y - INNER_TOP.y), 0.0, 1.0)
	var x := lerpf(INNER_TOP.x, INNER_BOTTOM.x, k)
	return x if left else 1.0 - x


## from에서 그 자리 앞까지 가는 길 (주방 안이면 출구로 먼저 나온다)
static func _path_to_guest(from: Vector2, seat: int) -> Array:
	var spot := serve_spot(seat)
	var path := []
	if from.x < KITCHEN_EXIT.x - 0.01 and from.y < AISLE_TOP.y:
		path.append(KITCHEN_EXIT)
	path.append(AISLE_TOP)
	path.append(Vector2(AISLE_TOP.x, spot.y))
	path.append(spot)
	return path


## 자리 앞에서 돌아가는 길
static func _path_home(from: Vector2, home: Vector2) -> Array:
	var path := [Vector2(AISLE_TOP.x, from.y), AISLE_TOP]
	if home.x < KITCHEN_EXIT.x:
		path.append(KITCHEN_EXIT)
	path.append(home)
	return path


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
			player_path = _path_home(player, player_home())
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
			helper_path = _path_home(helper, HELPER_HOME)
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


## 받는 시점의 값. 빨리 받으면 하트 값, 아슬아슬하면 깎인 값
static func pay(price: int, waited: float) -> int:
	var k := 1.0
	if waited <= PATIENCE * QUICK:
		k = QUICK_BONUS
	elif waited >= PATIENCE * 0.8:
		k = SLOW_CUT
	return int(roundf(price * k / 500.0) * 500.0)


func _serve(gi: int, by_player: bool) -> void:
	var g: Dictionary = guests[gi]
	var q: String = g.get("quality", "good")
	var price := pay(int(roundf(g.price * float(QUALITY_PRICE.get(q, 1.0)) / 500.0) * 500.0), g.wait)
	var heart: bool = g.wait <= PATIENCE * QUICK and q != "burnt"
	var side := Sides.take(pantry, reserve)
	var extra := Sides.bonus(side)
	price += extra
	side_sales += extra
	g.state = GuestState.EATING
	g.paid = price
	sales += price
	served.append({"guest": g.name, "fish": g.fish, "size": g.size, "price": price, "heart": heart, "side": side, "quality": q})
	events.append({"type": "served", "guest": gi, "heart": heart, "price": price, "side": side, "quality": q, "helper": not by_player})


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
		var g := {
			"name": s.name, "seat": seat, "fish": e.id, "size": e.size, "entry": e,
			"price": DayFlow.dish_price(e.id, e.size), "state": GuestState.WALKING,
			"wait": 0.0, "eat": 0.0, "cooked": false, "quality": "",
			"pos": ENTRANCE, "path": entry_path(seat), "dir": Vector2.LEFT,
		}
		guests.append(g)
		events.append({"type": "arrive", "guest": guests.size() - 1})


## 문에서 그 자리까지 걷는 길. 오른쪽 손님은 오른쪽 벽 길로, 앞 바와 왼쪽 손님은 맨 아래 길을 지나 간다
static func entry_path(seat: int) -> Array:
	var s: Vector2 = SEATS[seat]
	var path := [Vector2(LANE_RIGHT, ENTRANCE.y)]
	if s.y > FRONT_Y:
		path.append(Vector2(LANE_RIGHT, LANE_BOTTOM))
		path.append(Vector2(s.x, LANE_BOTTOM))
	elif s.x > 0.5:
		path.append(Vector2(LANE_RIGHT, s.y))
	else:
		path.append(Vector2(LANE_RIGHT, LANE_BOTTOM))
		path.append(Vector2(LANE_LEFT, LANE_BOTTOM))
		path.append(Vector2(LANE_LEFT, s.y))
	path.append(s)
	return path


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
				if g.wait >= patience_of(g.seat):
					_leave_angry(gi)
			GuestState.EATING:
				g.eat += dt
				if g.eat >= EAT_TIME:
					g.state = GuestState.LEFT
					dirty[g.seat] = true # 빈 그릇이 남는다. 치워야 다음 손님이 앉는다
					events.append({"type": "left", "guest": gi})


## 너무 기다려서 간다. 아직 굽지 않은 생선은 아이스박스로 돌아가고, 굽던 것과 구운 접시는 버린다
func _leave_angry(gi: int) -> void:
	var g: Dictionary = guests[gi]
	g.state = GuestState.LEFT
	angry += 1
	events.append({"type": "angry", "guest": gi})
	if queue.has(gi):
		queue.erase(gi)
		inventory.append(g.entry)
	cooking = cooking.filter(func(c): return c.guest != gi)
	pass_dishes.erase(gi)
	if selected == gi:
		selected = -1
	tasks = tasks.filter(func(t): return not (t.type == "serve" and t.dish == gi))
	# 들고 가던 접시는 손님 앞에 닿으면 아무 일 없이 돌아온다
