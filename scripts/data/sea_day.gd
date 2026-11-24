class_name SeaDay
extends RefCounted
## 〈오늘의 바다〉 카드: 날마다 바뀌는 물때와 날씨.
## 같은 날짜는 언제나 같은 결과가 나온다 (날짜로 정한 난수).
##
## 물때: 남해 기준 15일 주기. 사리(물이 많이 움직이는 때) 무렵 입질이 좋고 조금, 무시 무렵은 느리다.
## 날씨: 맑음, 흐림, 비, 바람. 어종마다 좋아하는 날씨가 다르다 (FishDB weather)

const TIDES := ["1물", "2물", "3물", "4물", "5물", "6물", "7물", "8물", "9물", "10물", "11물", "12물", "13물", "조금", "무시"]
## 물때별 입질 속도 배율 (클수록 빨리 문다)
const TIDE_BITE := [0.9, 0.95, 1.0, 1.1, 1.2, 1.3, 1.35, 1.3, 1.2, 1.1, 1.0, 0.95, 0.9, 0.8, 0.85]

const WEATHER := {
	"sunny": {"name": "맑음", "icon": "☀", "bite": 1.0},
	"cloudy": {"name": "흐림", "icon": "☁", "bite": 1.1},
	"rain": {"name": "비", "icon": "☂", "bite": 1.15},
	"windy": {"name": "바람", "icon": "≋", "bite": 0.95},
}
const WEATHER_ORDER := ["sunny", "sunny", "cloudy", "cloudy", "rain", "windy"]


## 첫날은 이야기에 맞춰 맑은 7물(사리 무렵)로 고정한다
static func of(day: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("오늘의바다-%d" % day)
	var tide_i := (day + 5) % TIDES.size() # 1일차 = 7물
	var w: String = "sunny" if day <= 1 else WEATHER_ORDER[rng.randi() % WEATHER_ORDER.size()]
	return {
		"day": day,
		"school": school(day),
		"tide": TIDES[tide_i],
		"tide_bite": TIDE_BITE[tide_i],
		"tide_good": TIDE_BITE[tide_i] >= 1.2,
		"weather": w,
		"weather_name": WEATHER[w].name,
		"weather_icon": WEATHER[w].icon,
		"bite": TIDE_BITE[tide_i] * WEATHER[w].bite,
	}


## 오늘 떼로 들어온 어종 (없으면 ""). 나흘에 하루쯤, 그 달에 나오는 고기 가운데 하나가 SCHOOL_MULT배 잘 문다
const SCHOOL_MULT := 2.5
const SCHOOL_CHANCE := 0.28


static func school(day: int) -> String:
	if day < 3:
		return ""
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("고기떼-%d" % day)
	if rng.randf() >= SCHOOL_CHANCE:
		return ""
	var month := int(Calendar.date(day).month)
	var pool := FishDB.FISH.keys().filter(func(id): return FishDB.FISH[id].rarity != "legend" and not FishDB.is_bycatch(id) and FishDB.season_mult(id, month) >= 0.5)
	return pool[rng.randi() % pool.size()] if not pool.is_empty() else ""


## 이 날씨, 이 밝기에 잘 무는 어종 (가중치 큰 순서로 n개)
static func best_fish(info: Dictionary, brightness: float, n := 2) -> Array:
	var scored: Array = []
	for id in FishDB.FISH:
		var base: float = FishDB.FISH[id].weight
		var w := FishDB.weight_of(id, {"brightness": brightness, "depth": 0.5, "weather": info.weather, "school": info.get("school", ""), "month": int(Calendar.date(int(info.get("day", 1))).month)}) / base
		scored.append([w, id])
	scored.sort_custom(func(a, b): return a[0] > b[0])
	var out: Array = []
	for i in mini(n, scored.size()):
		out.append(scored[i][1])
	return out


## 카드 한 줄 요약. 예: "7물 · 맑음 · 물때 좋음"
static func summary(info: Dictionary) -> String:
	return "%s · %s%s" % [info.tide, info.weather_name, " · 물때 좋음" if info.tide_good else ""]
