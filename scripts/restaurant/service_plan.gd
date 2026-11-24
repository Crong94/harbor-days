class_name ServicePlan
extends RefCounted
## 저녁 영업 개편 (2026-11-19 사용자: 단조롭다, 흐름이 헷갈린다, 영업 전후가 약하다, 손님이 다 똑같다).
## 영업 전 "오늘 메뉴판"과 손님 종류, 영업 중 할 일 안내, 영업 뒤 정산 줄을 정하는 규칙. 그림은 바꾸지 않는다.
##
## 영업 전: 생선마다 낼 요리(구이, 튀김, 배운 요리)를 고른다. 손님 예상도 보여 준다.
## 손님 종류: 보통, 급한 손님(빨리 받으면 팁을 더), 미식가(노릇노릇한 접시만 하트, 그러면 팁을 더), 단골(친해진 마을 사람. 잘 참고, 대접하면 더 친해진다)
## 보관: GameState.service_plan {"dishes": {어종: 요리}}
## 장면이 아닌 규칙만 담아 헤드리스로 시험한다.

## 손님 종류: 비율, 참는 시간 배수, 이름표
const KINDS := {
	"normal": {"tag": "", "patience": 1.0},
	"hurry": {"tag": "급해요", "patience": 0.6, "share": 0.18},
	"gourmet": {"tag": "미식가", "patience": 1.0, "share": 0.14},
	"regular": {"tag": "단골", "patience": 1.35, "friend": 2},
}
const MAX_REGULARS := 2 # 하룻저녁 단골 수


static func plan_of(gs: Object) -> Dictionary:
	var p: Dictionary = gs.service_plan
	if not p.has("dishes"):
		p["dishes"] = {}
	return p


## 그 어종으로 낼 수 있는 요리들 ["grill", ...]
static func dish_options(fish_id: String, flags: Dictionary) -> Array:
	var out := ["grill"]
	if flags.get("recipe_fish_fry", false):
		out.append("fry")
	for id in Menu.menu_list(flags):
		if Menu.fits_fish(id, fish_id):
			out.append(id)
	return out


## 아무것도 고르지 않았을 때의 요리: 비싼 생선(감성돔, 농어, 우럭)은 회, 나머지는 구이
const RAW_FISH := ["gamseongdom", "nongeo", "ureok"]


static func default_dish(fish_id: String) -> String:
	return "hoe" if fish_id in RAW_FISH else "grill"


static func dish_name(dish: String) -> String:
	match dish:
		"grill":
			return "구이"
		"fry":
			return "튀김"
	return str(Menu.recipe(dish).get("name", dish))


## 메뉴판에서 그 어종의 요리 (고른 게 없으면 default_dish, 지금은 못 내면 구이)
static func dish_for(plan: Dictionary, fish_id: String, flags: Dictionary) -> String:
	var d: String = plan.get("dishes", {}).get(fish_id, default_dish(fish_id))
	return d if d in dish_options(fish_id, flags) else "grill"


## 다음 요리로 바꾼다 (메뉴판 칸을 누를 때)
static func next_dish(plan: Dictionary, fish_id: String, flags: Dictionary) -> String:
	var opts := dish_options(fish_id, flags)
	var cur := dish_for(plan, fish_id, flags)
	var nx: String = opts[(opts.find(cur) + 1) % opts.size()]
	plan.dishes[fish_id] = nx
	return nx


## 지금 아이스박스와 재료로 가장 값이 나가게 요리를 고른다 (메뉴판 "알아서 고르기")
static func auto_plan(gs: Object, plan: Dictionary) -> void:
	var produce: Dictionary = gs.produce.duplicate()
	var seafood: Dictionary = gs.seafood.duplicate()
	var reserve := Pantry.reserve_for(gs)
	var groups := {}
	for e in gs.inventory:
		if not groups.has(e.id):
			groups[e.id] = []
		groups[e.id].append(e)
	for fid in groups:
		var list: Array = groups[fid]
		var best := "grill"
		var best_v := -1
		for d in dish_options(fid, gs.flags):
			var left := Menu.plates(d, produce, seafood, reserve) if Menu.RECIPES.has(d) else 99
			var v := 0
			for e in list:
				var ok: bool = left > 0 and (not Menu.RECIPES.has(d) or Menu.fits(d, e, int(gs.day)))
				v += DiningLogic.dish_price_of(e.id, e.size, d if ok else "grill")
				if ok:
					left -= 1
			if v > best_v:
				best_v = v
				best = d
		plan.dishes[fid] = best
		if Menu.RECIPES.has(best):
			var n := list.filter(func(e): return Menu.fits(best, e, int(gs.day))).size()
			Menu.take(best, produce, seafood, mini(n, Menu.plates(best, produce, seafood, reserve)))


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
	var vis := Bus.visitors(gs.reputation, gs.day)
	var lo := DiningLogic.GUESTS_MIN + vis
	var hi := DiningLogic.GUESTS_MAX + vis
	var fish: int = gs.inventory.size()
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


## 손님 만족도와 팁 (2026-11-24 사용자: 싸게·비싸게를 없애고 만족도가 높으면 팁으로).
## 음식값은 메뉴판 값 그대로 받는다 (탄 접시만 BURNT_PRICE). 만족도 0~3이 팁 비율을 정한다
##   노릇노릇 +1, 빨리 받음 +1. 급한 손님은 빨리 받으면, 미식가는 노릇노릇하면 하나 더. 탄 접시나 너무 늦은 접시는 0
##   하트를 이어 받으면(combo) 팁이 COMBO_TIP씩 더 붙는다
const TIP_RATE := [0.0, 0.08, 0.25, 0.4]
const LEVEL_NAMES := ["아쉬움", "보통", "만족", "아주 만족"]
const BURNT_PRICE := 0.6
const COMBO_TIP := 0.03
const COMBO_MAX := 5


static func satisfaction(kind: String, quality: String, quick: bool, late: bool) -> int:
	if quality == "burnt" or late:
		return 0
	var n := int(quality == "perfect") + int(quick)
	if (kind == "hurry" and quick) or (kind == "gourmet" and quality == "perfect"):
		n += 1
	if kind == "gourmet" and quality != "perfect":
		n = 0
	return clampi(n, 0, 3)


## 손님이 하트를 주나: 빨리 받고 안 탔으면. 미식가는 노릇노릇해야
static func gives_heart(kind: String, quality: String, quick: bool) -> bool:
	return quality == "perfect" if kind == "gourmet" else quick and quality != "burnt"


## 계산: {"price": 음식값, "tip": 팁, "heart", "level": 만족도}. combo: 이번 접시까지 이어진 하트 수
static func settle(kind: String, base_price: int, quality: String, quick: bool, late := false, combo := 0) -> Dictionary:
	var price := base_price
	if quality == "burnt":
		price = int(roundf(base_price * BURNT_PRICE / 500.0) * 500.0)
	var heart := gives_heart(kind, quality, quick)
	var lv := satisfaction(kind, quality, quick, late)
	var rate: float = TIP_RATE[lv]
	if lv > 0 and heart:
		rate += COMBO_TIP * clampi(combo - 1, 0, COMBO_MAX)
	return {"price": price, "tip": int(roundf(price * rate / 100.0) * 100.0), "heart": heart, "level": lv}


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
		out.append("급한 손님 %d명 중 만족 %d · 미식가 %d명 중 만족 %d" % [hurry.size(), hurry.filter(func(x): return x.heart).size(), gourmet.size(), gourmet.filter(func(x): return x.heart).size()])
	for x in served:
		if x.get("kind", "") == "regular":
			out.append(regular_line(x.guest, true))
	for a in angry:
		if a.kind == "regular":
			out.append(regular_line(a.guest, false))
	return out
