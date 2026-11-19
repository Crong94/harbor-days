class_name Menu
extends RefCounted
## 새 메뉴 개발 (2026-11-19). 기획서 챕터 4 "레시피 해금".
##
## 흐름: 마을 사람과 친해지면 요리법을 알려 준다(Friends teach → flags learn_<id>)
##   → 낮에 식당에서 시험 조리(간 맞추기 세 번 중 두 번)를 하면 메뉴판에 오른다(flags menu_<id>)
##   → 저녁 영업에서 손님 일부(share)가 그 요리를 시킨다. 재료(채소, 갯벌 것)가 있으면 그 요리로, 없으면 구이로 낸다
## 주재료는 언제나 낚은 생선이다 (하루 흐름 결정: 식당 재료는 직접 낚은 생선만). 채소와 갯벌 것은 곁들임처럼 더해지는 재료
## 장면이 아닌 규칙만 담아 헤드리스로 시험한다.

## fish: 쓸 수 있는 어종(빈 배열이면 아무 생선). needs: {"produce:<id>" 또는 "sea:<id>": 개수}
## mult: 구이 값에 곱하는 배수. share: 그 메뉴를 고르는 손님 비율. art: dish/<id> (어종별이면 {어종: 그림})
const RECIPES := {
	"jorim": {"name": "생선조림", "who": "최순덕", "fish": [], "needs": {"produce:mu": 1}, "mult": 1.3, "share": 0.3,
		"art": "godeungeo-jorim", "tip": "무를 깔고 자작하게 졸여야 해. 간장은 나중에."},
	"maeuntang": {"name": "매운탕", "who": "박만수", "fish": ["ureok", "noraemi", "ssombaengi"], "needs": {"produce:gochu": 1}, "mult": 1.45, "share": 0.35,
		"art": {"ureok": "ureok-maeun", "noraemi": "noraemi-maeun", "": "ureok-maeun"}, "tip": "뼈째 넣고 푹. 고춧가루는 아끼지 마라."},
	"hoe": {"name": "회", "who": "이준호", "fish": ["gamseongdom", "ureok", "noraemi"], "needs": {}, "mult": 1.5, "share": 0.25, "fresh": true,
		"art": {"gamseongdom": "gamseongdom-hoe", "": "sungeo-hoe"}, "tip": "형, 회는 그날 잡은 걸로만 내야 돼요."},
	"jiri": {"name": "생선 맑은탕", "who": "김복자", "fish": [], "needs": {"sea:bajirak": 2}, "mult": 1.35, "share": 0.3,
		"art": "dodari-ssukguk", "tip": "바지락으로 국물을 내믄 생선 맛이 산다."},
	"haemultang": {"name": "해물탕", "who": "김복자", "fish": [], "needs": {"sea:nakji": 1, "sea:bajirak": 2}, "mult": 1.9, "share": 0.25,
		"art": "galchi-ttukbaegi", "tip": "낙지는 마지막에 넣어야 질기지 않다."},
}
## 시험 조리: 간 맞추기 TRIES번 중 PASS번을 바늘이 초록 칸에 멈추면 성공
const TRIES := 3
const PASS := 2
const ZONE := 0.18 # 초록 칸 너비 (0~1 막대 위)
const LAB_MINUTES := 60


static func recipe(id: String) -> Dictionary:
	return RECIPES.get(id, {})


static func learned(flags: Dictionary, id: String) -> bool:
	return flags.get("learn_" + id, false)


static func on_menu(flags: Dictionary, id: String) -> bool:
	return flags.get("menu_" + id, false)


## 메뉴판에 오른 메뉴들
static func menu_list(flags: Dictionary) -> Array:
	return RECIPES.keys().filter(func(id): return on_menu(flags, id))


## 배웠지만 아직 시험하지 않은 메뉴들
static func to_test(flags: Dictionary) -> Array:
	return RECIPES.keys().filter(func(id): return learned(flags, id) and not on_menu(flags, id))


static func fits_fish(id: String, fish_id: String) -> bool:
	var f: Array = recipe(id).get("fish", [])
	return f.is_empty() or fish_id in f


static func _count(key: String, produce: Dictionary, seafood: Dictionary) -> int:
	var p := key.split(":")
	return int((produce if p[0] == "produce" else seafood).get(p[1], 0))


## 재료가 있나 (생선 빼고)
static func can_make(id: String, produce: Dictionary, seafood: Dictionary) -> bool:
	var needs: Dictionary = recipe(id).get("needs", {})
	for k in needs:
		if _count(k, produce, seafood) < int(needs[k]):
			return false
	return true


## 재료를 쓴다
static func take(id: String, produce: Dictionary, seafood: Dictionary) -> void:
	var needs: Dictionary = recipe(id).get("needs", {})
	for k in needs:
		var p: PackedStringArray = str(k).split(":")
		var d: Dictionary = produce if p[0] == "produce" else seafood
		d[p[1]] = int(d.get(p[1], 0)) - int(needs[k])
		if int(d[p[1]]) <= 0:
			d.erase(p[1])


## "무 하나", "바지락 두 개, 낙지 하나"
static func needs_text(id: String) -> String:
	var parts := PackedStringArray()
	var needs: Dictionary = recipe(id).get("needs", {})
	for k in needs:
		var p: PackedStringArray = str(k).split(":")
		var n := Sides.name_of(p[1]) if p[0] == "produce" else Flat.name_of(p[1])
		parts.append("%s %d" % [n, int(needs[k])])
	if parts.is_empty():
		return "그날 잡은 생선"
	return ", ".join(parts)


static func art(id: String, fish_id: String) -> String:
	var a = recipe(id).get("art", "")
	if a is Dictionary:
		return str(a.get(fish_id, a.get("", "")))
	return str(a)


static func price(id: String, base: int) -> int:
	return int(roundf(base * float(recipe(id).get("mult", 1.0)) / 500.0) * 500.0)


## 손님 한 명이 고르는 요리. 메뉴판에 있고, 그 생선으로 되고, 재료가 있으면 그 요리. 아니면 ""(구이)
## fresh 메뉴(회)는 오늘 잡은 생선(entry.day == today)만
static func pick(menu: Array, entry: Dictionary, today: int, produce: Dictionary, seafood: Dictionary, rng: RandomNumberGenerator) -> String:
	for id in menu:
		var r := recipe(id)
		var roll := rng.randf()
		if roll >= float(r.share):
			continue
		if not fits_fish(id, entry.id) or not can_make(id, produce, seafood):
			continue
		if r.get("fresh", false) and int(entry.get("day", today)) != today:
			continue
		return id
	return ""


## 간 맞추기 한 번: 바늘 위치(0~1)가 초록 칸(target 가운데 ZONE 폭) 안인가
static func hit(needle: float, target: float) -> bool:
	return absf(needle - target) <= ZONE / 2.0


## 그날 시험 조리의 초록 칸 자리들 (TRIES개)
static func targets(day: int, id: String) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("시험-%d-%s" % [day, id])
	var out := []
	for i in TRIES:
		out.append(rng.randf_range(0.2, 0.8))
	return out
