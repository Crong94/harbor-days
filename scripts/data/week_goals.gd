class_name WeekGoals
extends RefCounted
## 이번 주 도전 (2026-11-24). 월요일마다 세 가지. 일요일 밤까지 이루면 상금과 평판을 받는다.
## 보관: GameState.week {셈 이름: 이번 주 합, "done": [이룬 목표 id]}. 일요일이 끝나면 비운다
## 오늘 잡은 고기와 오늘 매출은 하루가 끝날 때(close_day) 더한다. 보여 줄 때는 오늘 몫을 같이 센다
## 장면이 아닌 규칙만 담아 헤드리스로 시험한다.

const REWARD := 12000
const ALL_REWARD := 30000
const REP := 2
## [id, 글, 첫 주 목표, 주마다 늘어나는 수, 끝]
const POOL := [
	["caught", "고기 %d마리 잡기", 15, 3, 45],
	["trophy", "대물 %d마리 잡기 (그 어종 최대에 가까운 것)", 1, 0, 1],
	["rare", "희귀나 전설 고기 %d마리 잡기", 1, 1, 6],
	["hearts", "손님 하트 %d개 받기", 15, 3, 45],
	["sales", "매출 %d원 올리기", 250000, 30000, 600000],
	["kinds", "요리 %d가지 내기", 2, 1, 7],
	["gifts", "마을 사람에게 선물 %d번 하기", 3, 0, 3],
	["combo", "하트를 %d번 이어 받기", 4, 1, 9],
]


static func week_no(day: int) -> int:
	return (day - 1) / 7


## 그 주의 도전 세 가지 [{"id", "text", "goal"}]
static func goals(day: int) -> Array:
	var w := week_no(day)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("주간도전-%d" % w)
	var pool := range(POOL.size())
	var out := []
	for i in 3:
		var k: int = pool[rng.randi() % pool.size()]
		pool.erase(k)
		var g: Array = POOL[k]
		var n := mini(int(g[2]) + int(g[3]) * w, int(g[4]))
		out.append({"id": g[0], "goal": n, "text": str(g[1]) % n})
	return out


static func add(gs: Object, id: String, n := 1) -> void:
	gs.week[id] = int(gs.week.get(id, 0)) + n


## 이번 주 가장 큰 값만 남긴다 (하트 잇기)
static func best(gs: Object, id: String, n: int) -> void:
	gs.week[id] = maxi(int(gs.week.get(id, 0)), n)


## 나간 요리 종류
static func add_dish(gs: Object, dish: String) -> void:
	var d: Dictionary = gs.week.get("dishes", {})
	d[dish] = true
	gs.week["dishes"] = d
	gs.week["kinds"] = d.size()


static func _today(gs: Object, id: String) -> int:
	var kept: Array = gs.caught_today.filter(func(e): return not e.get("released", false))
	match id:
		"caught":
			return kept.size()
		"trophy":
			return kept.filter(func(e): return FishDB.is_trophy(e.id, e.size)).size()
		"rare":
			return kept.filter(func(e): return FishDB.get_fish(e.id).rarity != "common").size()
		"sales":
			return int(gs.sales_today)
	return 0


static func progress(gs: Object, g: Dictionary) -> int:
	return mini(int(g.goal), int(gs.week.get(g.id, 0)) + _today(gs, g.id))


static func is_done(gs: Object, g: Dictionary) -> bool:
	return g.id in gs.week.get("done", []) or progress(gs, g) >= int(g.goal)


## 하루를 마칠 때 (day를 올리기 전): 오늘 몫을 더하고, 새로 이룬 도전의 상금을 준다. 소식 글 목록을 돌려준다
static func close_day(gs: Object) -> Array:
	for id in ["caught", "trophy", "rare", "sales"]:
		add(gs, id, _today(gs, id))
	var done: Array = gs.week.get("done", [])
	var out := []
	var list := goals(gs.day)
	for g in list:
		if g.id in done or int(gs.week.get(g.id, 0)) < int(g.goal):
			continue
		done.append(g.id)
		gs.money += REWARD
		gs.reputation += REP
		out.append("이번 주 도전 성공! %s. 상금 %d원" % [g.text, REWARD])
		if done.size() == list.size():
			gs.money += ALL_REWARD
			out.append("이번 주 도전 세 가지를 다 이뤘어요! 덤으로 %d원" % ALL_REWARD)
	gs.week["done"] = done
	if int(gs.day) % 7 == 0:
		gs.week = {}
	return out
