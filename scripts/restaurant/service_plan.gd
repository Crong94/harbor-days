class_name ServicePlan
extends RefCounted
## 저녁 영업 개편 (2026-11-19 사용자: 단조롭다, 흐름이 헷갈린다, 영업 전후가 약하다, 손님이 다 똑같다).
## 영업 전 "오늘 메뉴판"과 손님 종류, 영업 중 할 일 안내, 영업 뒤 정산 줄을 정하는 규칙. 그림은 바꾸지 않는다.
##
## 영업 전: 값 수준(싸게, 보통, 비싸게)과 생선마다 낼 요리(구이, 튀김, 배운 새 메뉴)를 고른다. 손님 예상도 보여 준다.
##   싸게: 손님이 더 오고 잘 참는다. 비싸게: 손님이 덜 오고 금방 짜증 내지만 한 접시 값이 크다
## 손님 종류: 보통, 급한 손님(빨리 받으면 웃돈), 미식가(노릇노릇한 접시만 하트, 그러면 웃돈), 단골(친해진 마을 사람. 잘 참고, 대접하면 더 친해진다)
## 보관: GameState.service_plan {"price": "mid", "dishes": {어종: 요리}}
## 장면이 아닌 규칙만 담아 헤드리스로 시험한다.

const PRICES := {
	"low": {"name": "싸게", "mult": 0.85, "guests": 2, "patience": 1.15, "desc": "손님이 더 오고 잘 기다려요"},
	"mid": {"name": "보통", "mult": 1.0, "guests": 0, "patience": 1.0, "desc": "늘 받던 값"},
	"high": {"name": "비싸게", "mult": 1.2, "guests": -2, "patience": 0.85, "desc": "손님이 덜 오고 금방 짜증 내요. 대신 한 접시가 비싸요"},
}
const PRICE_ORDER := ["low", "mid", "high"]

## 손님 종류: 비율, 참는 시간 배수, 이름표
const KINDS := {
	"normal": {"tag": "", "patience": 1.0},
	"hurry": {"tag": "급해요", "patience": 0.6, "share": 0.18, "tip": 1.25},
	"gourmet": {"tag": "미식가", "patience": 1.0, "share": 0.14, "tip": 1.3, "miss": 0.8},
	"regular": {"tag": "단골", "patience": 1.35, "friend": 2},
}
const MAX_REGULARS := 2 # 하룻저녁 단골 수


static func plan_of(gs: Object) -> Dictionary:
	var p: Dictionary = gs.service_plan
	if not p.has("price"):
		p["price"] = "mid"
	if not p.has("dishes"):
		p["dishes"] = {}
	return p


static func price(level: String) -> Dictionary:
	return PRICES.get(level, PRICES.mid)


## 그 어종으로 낼 수 있는 요리들 ["grill", ...]
static func dish_options(fish_id: String, flags: Dictionary) -> Array:
	var out := ["grill"]
	if flags.get("recipe_fish_fry", false):
		out.append("fry")
	for id in Menu.menu_list(flags):
		if Menu.fits_fish(id, fish_id):
			out.append(id)
	return out


static func dish_name(dish: String) -> String:
	match dish:
		"grill":
			return "구이"
		"fry":
			return "튀김"
	return str(Menu.recipe(dish).get("name", dish))


## 메뉴판에서 그 어종의 요리 (고른 게 없거나 지금은 못 내면 구이)
static func dish_for(plan: Dictionary, fish_id: String, flags: Dictionary) -> String:
	var d: String = plan.get("dishes", {}).get(fish_id, "grill")
	return d if d in dish_options(fish_id, flags) else "grill"


## 다음 요리로 바꾼다 (메뉴판 칸을 누를 때)
static func next_dish(plan: Dictionary, fish_id: String, flags: Dictionary) -> String:
	var opts := dish_options(fish_id, flags)
	var cur := dish_for(plan, fish_id, flags)
	var nx: String = opts[(opts.find(cur) + 1) % opts.size()]
	plan.dishes[fish_id] = nx
	return nx


## 오늘 단골로 올 사람들 (친밀도 하트 하나 이상, 날짜로 정해진다)
static func regulars(gs: Object) -> Array:
	var cands: Array = Friends.PEOPLE.keys().filter(func(n): return Friends.hearts(Friends.points(gs, n)) >= 1)
	if cands.is_empty():
		return []
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("단골-%d" % int(gs.day))
	var out := []
	for i in mini(MAX_REGULARS, cands.size()):
		var n: String = cands[rng.randi() % cands.size()]
		if not n in out and rng.randf() < 0.75:
			out.append(n)
	return out


## 손님 예상: {"guests": [최소, 최대], "fish": 아이스박스 생선 수, "note": 한 줄}
static func forecast(gs: Object) -> Dictionary:
	var p := plan_of(gs)
	var d := int(price(p.price).guests)
	var vis := Bus.visitors(gs.reputation, gs.day)
	var lo := DiningLogic.GUESTS_MIN + d + vis
	var hi := DiningLogic.GUESTS_MAX + d + vis
	var fish: int = gs.inventory.filter(func(e): return DayFlow.dish_price(e.id, e.size) <= DayFlow.REGULAR_MAX).size()
	var note := "생선이 넉넉해요"
	if fish < lo:
		note = "생선이 모자라요. 손님 몇 명은 못 받아요"
	elif fish < hi:
		note = "생선이 빠듯해요"
	return {"guests": [lo, hi], "fish": fish, "note": note}


## 손님 종류를 정한다 (명단 순서대로, 날짜로 정해짐). 단골 이름은 앞쪽 무리에 넣는다
static func assign_kinds(schedule: Array, regular_names: Array, day: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("손님종류-%d" % day)
	var placed := 0
	for i in schedule.size():
		var s: Dictionary = schedule[i]
		var kind := "normal"
		if placed < regular_names.size() and i % 3 == 1:
			kind = "regular"
			s.name = regular_names[placed]
			placed += 1
		else:
			var r := rng.randf()
			if r < float(KINDS.hurry.share):
				kind = "hurry"
			elif r < float(KINDS.hurry.share) + float(KINDS.gourmet.share):
				kind = "gourmet"
		s["kind"] = kind


## 받은 값과 하트: 종류와 접시 질, 기다린 시간에 따라. {"price", "heart"}
static func settle(kind: String, base_price: int, quality: String, quick: bool) -> Dictionary:
	var k: Dictionary = KINDS.get(kind, KINDS.normal)
	var price := float(base_price)
	var heart := quick and quality != "burnt"
	match kind:
		"hurry":
			if quick:
				price *= float(k.tip)
		"gourmet":
			heart = quality == "perfect"
			price *= float(k.tip) if heart else float(k.miss)
	return {"price": int(roundf(price / 500.0) * 500.0), "heart": heart}


## 단골이 앉을 때와 먹고 갈 때 하는 말
static func regular_line(name: String, served: bool) -> String:
	var call: String = Friends.person(name).get("call", name)
	if served:
		return "%s: 역시 여기가 제일이네." % call
	return "%s: 오늘은 좀 바쁘네." % call


## 영업 중 할 일 안내 (화면 위 한 줄). logic은 DiningLogic
static func hint(logic) -> String:
	if logic.holding >= 0:
		return "그 요리를 시킨 손님을 눌러요"
	if not logic.pass_dishes.is_empty():
		return "나온 접시를 눌러 들어요"
	if not logic.dirty.is_empty() and not logic.schedule.is_empty():
		return "빈 그릇을 눌러 치워야 손님이 앉아요"
	for g in logic.guests:
		if g.state == DiningLogic.GuestState.SEATED:
			return "세라가 굽는 중이에요. 다 되면 내놓아요"
	return "손님을 기다려요"


## 정산에 덧붙일 줄: 하트와 화남(이유별), 인기 요리, 손님 종류, 단골 한마디
static func ledger_lines(result: Dictionary) -> Array:
	var out := []
	var served: Array = result.get("served", [])
	var hearts := served.filter(func(x): return x.heart).size()
	var angry: Array = result.get("angry_list", [])
	var line := "하트 %d" % hearts
	if not angry.is_empty():
		var p := angry.filter(func(a): return a.reason == "pass").size()
		line += " · 화나서 간 손님 %d (접시를 안 날라서 %d, 굽기가 늦어서 %d)" % [angry.size(), p, angry.size() - p]
	out.append(line)
	var count := {}
	for x in served:
		var d: String = x.get("dish", "grill")
		count[d] = int(count.get(d, 0)) + 1
	var best := ""
	for d in count:
		if best.is_empty() or int(count[d]) > int(count[best]):
			best = d
	if not best.is_empty():
		out.append("오늘 가장 많이 나간 요리: %s %d접시" % [dish_name(best), count[best]])
	var hurry := served.filter(func(x): return x.get("kind", "") == "hurry")
	var gourmet := served.filter(func(x): return x.get("kind", "") == "gourmet")
	if not hurry.is_empty() or not gourmet.is_empty():
		out.append("급한 손님 %d명 중 웃돈 %d · 미식가 %d명 중 만족 %d" % [hurry.size(), hurry.filter(func(x): return x.heart).size(), gourmet.size(), gourmet.filter(func(x): return x.heart).size()])
	for x in served:
		if x.get("kind", "") == "regular":
			out.append(regular_line(x.guest, true))
	for a in angry:
		if a.kind == "regular":
			out.append(regular_line(a.guest, false))
	return out
