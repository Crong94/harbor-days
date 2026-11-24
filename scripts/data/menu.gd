class_name Menu
extends RefCounted
## 식당 요리 (2026-11-24 다시 짬. 사용자: 곁들임을 없애고 채소는 요리에 쓰게, 레시피 얻기를 더 쉽게, 비싼 생선은 회 중심으로).
##
## 얻는 길 둘. 둘 다 얻는 즉시 메뉴판에 오른다
##   1. 마을 사람과 친해지면 알려 준다 (Friends teach → flags learn_<id>). 대부분 하트 하나
##   2. 세라와 연구: 낮에 식당에서 생선 한 마리와 재료를 주면 세라가 요리를 알아낸다 (하루 한 번, 언제나 성공)
##   basic 요리(회)는 세라가 처음부터 할 줄 안다
## 영업: 메뉴판(ServicePlan)에서 생선마다 요리를 고른다. 재료가 떨어지면 구이로 낸다
## 주재료는 언제나 낚은 생선이다. 채소는 텃밭이나 경자상회, 조개는 갯벌에서
## 장면이 아닌 규칙만 담아 헤드리스로 시험한다.

## fish: 쓸 수 있는 어종(빈 배열이면 아무 생선). needs: {"produce:<id>" 또는 "sea:<id>": 개수}
## mult: 구이 값에 곱하는 배수. share: 메뉴판 없이 손님이 고를 때 비율. fresh: 오늘 잡았거나 수조에서 꺼낸 생선만
## art: dish/<id> (어종별이면 {어종: 그림, "": 그 밖}). art_new: 그림이 들어오면 먼저 쓴다
const RECIPES := {
	"hoe": {"name": "회", "who": "최세라", "basic": true, "fish": ["gamseongdom", "nongeo", "ureok", "noraemi"], "needs": {}, "mult": 1.4, "share": 0.25, "fresh": true,
		"art": {"gamseongdom": "gamseongdom-hoe", "": "sungeo-hoe"}, "art_new": {"nongeo": "nongeo-hoe", "ureok": "ureok-hoe"}, "tip": "비싼 고기는 그날 회로 내야 제값을 받아요."},
	"jorim": {"name": "생선조림", "who": "최순덕", "fish": [], "needs": {"produce:mu": 1}, "mult": 1.4, "share": 0.3,
		"art": "godeungeo-jorim", "tip": "무를 깔고 자작하게 졸여야 해. 간장은 나중에."},
	"pajjim": {"name": "대파 생선찜", "who": "정태식", "fish": [], "needs": {"produce:daepa": 1}, "mult": 1.3, "share": 0.25,
		"art": "godeungeo-jorim", "art_new": "pa-jjim", "tip": "대파를 듬뿍 얹어 김을 올리면 비린내가 싹 가셔요."},
	"maneul": {"name": "마늘양념구이", "who": "문경자", "fish": [], "needs": {"produce:maneul": 1}, "mult": 1.4, "share": 0.25,
		"art": "ureok-gui", "art_new": "maneul-gui", "tip": "마늘은 태우지 말고 노릇할 때 얹어."},
	"maeuntang": {"name": "매운탕", "who": "박만수", "fish": ["ureok", "noraemi", "ssombaengi"], "needs": {"produce:gochu": 1}, "mult": 1.5, "share": 0.35,
		"art": {"ureok": "ureok-maeun", "noraemi": "noraemi-maeun", "": "ureok-maeun"}, "tip": "뼈째 넣고 푹. 고춧가루는 아끼지 마라."},
	"baechuguk": {"name": "배추 생선국", "who": "최순덕", "fish": [], "needs": {"produce:baechu": 1}, "mult": 1.5, "share": 0.25,
		"art": "dodari-ssukguk", "art_new": "baechu-guk", "tip": "된장 풀고 배추 넣으면 속이 확 풀린다."},
	"muchim": {"name": "회무침", "who": "이준호", "fish": ["hakgongchi", "noraemi", "bolak"], "needs": {"produce:kkaennip": 1}, "mult": 1.5, "share": 0.25, "fresh": true,
		"art": "hakgongchi-muchim", "tip": "형, 깻잎 잔뜩 넣고 새콤하게 무쳐 봐요."},
	"kkaennip": {"name": "깻잎말이 튀김", "who": "문경자", "fish": ["bolak", "mangsang", "hakgongchi", "noraemi"], "needs": {"produce:kkaennip": 1}, "mult": 1.45, "share": 0.25,
		"art": "mangdung-twigim", "art_new": "kkaennip-twigim", "tip": "깻잎에 돌돌 말아 튀기면 애들도 잘 먹어."},
	"jeon": {"name": "생선전", "who": "김해솔", "fish": [], "needs": {"produce:egg": 1}, "mult": 1.35, "share": 0.25,
		"art": "bungjangeo-twigim", "art_new": "fish-jeon", "tip": "할머니가 달걀물 입혀서 부쳐 주는 거예요!"},
	"jiri": {"name": "생선 맑은탕", "who": "김복자", "fish": [], "needs": {"sea:bajirak": 2}, "mult": 1.5, "share": 0.3,
		"art": "dodari-ssukguk", "tip": "바지락으로 국물을 내믄 생선 맛이 산다."},
	"chobap": {"name": "생선초밥", "who": "이준호", "fish": ["hakgongchi", "bolak", "nongeo", "ureok"], "needs": {"produce:maneul": 1}, "mult": 1.6, "share": 0.25, "fresh": true,
		"art": "jeongaengi-chobap", "tip": "형, 구운 마늘 한 쪽 올리면 도시 초밥집 안 부러워요."},
	"haemultang": {"name": "해물탕", "who": "김복자", "fish": [], "needs": {"sea:nakji": 1, "sea:bajirak": 2}, "mult": 2.0, "share": 0.25,
		"art": "galchi-ttukbaegi", "art_new": "haemultang", "tip": "낙지는 마지막에 넣어야 질기지 않다."},
}
## 세라와 연구 한 번에 드는 시간
const LAB_MINUTES := 30


static func recipe(id: String) -> Dictionary:
	return RECIPES.get(id, {})


## 배운 요리는 곧 메뉴판에 오른 요리 (예전 저장의 learn_, menu_ 표시를 모두 받는다)
static func on_menu(flags: Dictionary, id: String) -> bool:
	return recipe(id).get("basic", false) or flags.get("learn_" + id, false) or flags.get("menu_" + id, false)


static func menu_list(flags: Dictionary) -> Array:
	return RECIPES.keys().filter(func(id): return on_menu(flags, id))


## 아직 모르는 요리
static func unknown(flags: Dictionary) -> Array:
	return RECIPES.keys().filter(func(id): return not on_menu(flags, id))


static func fits_fish(id: String, fish_id: String) -> bool:
	var f: Array = recipe(id).get("fish", [])
	return f.is_empty() or fish_id in f


## 오늘 잡은 생선이어야 하는 요리면 그것도 본다
static func fits(id: String, entry: Dictionary, today: int) -> bool:
	if not fits_fish(id, entry.id):
		return false
	return not recipe(id).get("fresh", false) or int(entry.get("day", today)) == today


static func _count(key: String, produce: Dictionary, seafood: Dictionary, reserve: Dictionary) -> int:
	var p := key.split(":")
	if p[0] == "produce":
		return int(produce.get(p[1], 0)) - int(reserve.get(p[1], 0))
	return int(seafood.get(p[1], 0))


## 재료가 있나 (생선 빼고). reserve: 남겨 둘 채소
static func can_make(id: String, produce: Dictionary, seafood: Dictionary, reserve := {}) -> bool:
	var needs: Dictionary = recipe(id).get("needs", {})
	for k in needs:
		if _count(k, produce, seafood, reserve) < int(needs[k]):
			return false
	return true


## 지금 재료로 몇 접시까지 되나 (재료가 안 드는 요리는 99)
static func plates(id: String, produce: Dictionary, seafood: Dictionary, reserve := {}) -> int:
	var n := 99
	var needs: Dictionary = recipe(id).get("needs", {})
	for k in needs:
		n = mini(n, maxi(0, _count(k, produce, seafood, reserve)) / int(needs[k]))
	return n


## 재료를 쓴다 (n접시)
static func take(id: String, produce: Dictionary, seafood: Dictionary, n := 1) -> void:
	var needs: Dictionary = recipe(id).get("needs", {})
	for k in needs:
		var p: PackedStringArray = str(k).split(":")
		var d: Dictionary = produce if p[0] == "produce" else seafood
		d[p[1]] = int(d.get(p[1], 0)) - int(needs[k]) * n
		if int(d[p[1]]) <= 0:
			d.erase(p[1])


## "무 1", "낙지 1, 바지락 2"
static func needs_text(id: String) -> String:
	var parts := PackedStringArray()
	var needs: Dictionary = recipe(id).get("needs", {})
	for k in needs:
		var p: PackedStringArray = str(k).split(":")
		var n := Pantry.name_of(p[1]) if p[0] == "produce" else Flat.name_of(p[1])
		parts.append("%s %d" % [n, int(needs[k])])
	if parts.is_empty():
		return "그날 잡은 생선"
	return ", ".join(parts)


static func _pick_art(a, fish_id: String) -> String:
	return str(a.get(fish_id, a.get("", ""))) if a is Dictionary else str(a)


static func art(id: String, fish_id: String) -> String:
	var fresh := _pick_art(recipe(id).get("art_new", ""), fish_id)
	if not fresh.is_empty() and ArtSlot.has_art("dish/" + fresh):
		return fresh
	return _pick_art(recipe(id).get("art", ""), fish_id)


## 요리 값. base는 DayFlow.dish_price. 비싼 생선은 회로 낼 때만 제값(그대로), 다른 요리는 구이 값 끝(REGULAR_MAX)에 배수를 곱한다
static func price(id: String, base: int) -> int:
	if id == "hoe" and base > DayFlow.REGULAR_MAX:
		return base
	var v := mini(base, DayFlow.REGULAR_MAX) * float(recipe(id).get("mult", 1.0))
	return int(roundf(v / 500.0) * 500.0)


## 메뉴판을 정하지 않았을 때 손님 한 명이 고르는 요리. 아니면 ""(구이)
static func pick(menu: Array, entry: Dictionary, today: int, produce: Dictionary, seafood: Dictionary, rng: RandomNumberGenerator) -> String:
	for id in menu:
		var roll := rng.randf()
		if roll < float(recipe(id).share) and fits(id, entry, today) and can_make(id, produce, seafood):
			return id
	return ""


# ─── 세라와 연구 ─────────────────────────────────────

## 이 요리를 연구할 때 쓸 생선 (맞는 것 중 가장 싼 것). 없으면 빈 Dictionary
static func research_fish(id: String, inventory: Array, today: int) -> Dictionary:
	var best := {}
	for e in inventory:
		if not fits(id, e, today):
			continue
		if best.is_empty() or FishDB.value_of(e.id, e.size) < FishDB.value_of(best.id, best.size):
			best = e
	return best


## 지금 연구할 수 있나 (하루 한 번)
static func can_research(gs: Object, id: String) -> bool:
	return not on_menu(gs.flags, id) and int(gs.research_day) != int(gs.day) \
		and not research_fish(id, gs.inventory, gs.day).is_empty() and can_make(id, gs.produce, gs.seafood)


## 연구한다: 생선 한 마리와 재료를 쓰고 요리를 배운다
static func research(gs: Object, id: String) -> bool:
	if not can_research(gs, id):
		return false
	gs.inventory.erase(research_fish(id, gs.inventory, gs.day))
	take(id, gs.produce, gs.seafood)
	gs.flags["learn_" + id] = true
	gs.research_day = int(gs.day)
	return true
