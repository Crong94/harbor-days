class_name FishDB
extends RefCounted
## 북쪽 방파제 어종. 그림은 assets/art/fish_<id>.png (docs/물고기_그림_목록.md)
##
## rarity: common 일반, rare 희귀, legend 전설
## strength: 당기는 힘 0~1 (파이팅 체력과 줄다리기 세기)
## weight: 기본 출현 가중치
## night: 어두운 걸 좋아하는 정도 -1~1 (볼락은 밝아지면 숨고, 학공치는 낮에 수면 가까이 올라온다)
## zone: 던진 거리별 출현 배율 [발밑, 중간, 먼 물] (바다 한 접시 species.json zone)
## weather: 날씨별 배율 (SeaDay.WEATHER id)
## catalog: Catalog(바다 한 접시 데이터) 어종 id, grill: 생선구이 레시피 id
## habit: 줄다리기 버릇 (FishingLogic). dive 처음에 바위로 세게 파고듦, shake 짧고 잦게 처박음, long 길게 차고 나감, jump 바늘털이

const RARITY := {
	"common": {"name": "일반", "color": Color("7fb59a"), "price": 1.0},
	"rare": {"name": "희귀", "color": Color("6e9cf0"), "price": 1.6},
	"legend": {"name": "전설", "color": Color("f2a93b"), "price": 2.5},
}

const FISH := {
	"bolak": {
		"name": "볼락", "rarity": "common",
		"min_cm": 12.0, "max_cm": 26.0, "strength": 0.45, "price": 4000,
		"weight": 6.0, "night": 0.8, "zone": [1.6, 1.0, 0.4],
		"weather": {"cloudy": 1.3, "rain": 1.2},
		"catalog": "bollak", "grill": "bollak-gui",
		"desc": "눈이 크고 어두운 바다를 좋아하는 물고기. 새벽과 밤에 잘 물고 해가 뜨면 바위틈에 숨는다.",
	},
	"mangsang": {
		"name": "망상어", "rarity": "common",
		"min_cm": 12.0, "max_cm": 25.0, "strength": 0.35, "price": 2500,
		"weight": 4.0, "night": 0.0, "zone": [1.6, 1.0, 0.5],
		"weather": {},
		"catalog": "mangsangeo", "grill": "mangsangeo-gui",
		"desc": "몸이 납작하고 은빛이 도는 방파제 단골. 알 대신 새끼를 낳는 물고기다.",
	},
	"noraemi": {
		"name": "노래미", "rarity": "common",
		"min_cm": 15.0, "max_cm": 32.0, "strength": 0.55, "price": 5000,
		"weight": 3.0, "night": 0.1, "zone": [1.4, 1.0, 0.6],
		"weather": {"windy": 1.2},
		"habit": "shake", "catalog": "noraemi", "grill": "noraemi-gui",
		"desc": "바위틈에 숨어 사는 얼룩무늬 물고기. 작아도 끌어올릴 때 힘이 좋다.",
	},
	"ssombaengi": {
		"name": "쏨뱅이", "rarity": "common",
		"min_cm": 12.0, "max_cm": 28.0, "strength": 0.5, "price": 6000,
		"weight": 2.4, "night": 0.5, "zone": [1.3, 1.0, 0.6],
		"weather": {"cloudy": 1.2},
		"catalog": "ssombaengi", "grill": "ssombaengi-gui",
		"desc": "붉고 울퉁불퉁한 바위 물고기. 등가시가 따가우니 잡을 때 조심한다.",
	},
	"ureok": {
		"name": "우럭", "rarity": "rare",
		"min_cm": 18.0, "max_cm": 45.0, "strength": 0.7, "price": 9000,
		"weight": 1.3, "night": 0.6, "zone": [1.0, 1.2, 0.8],
		"weather": {"cloudy": 1.3, "rain": 1.4},
		"habit": "dive", "catalog": "ureok", "grill": "ureok-gui",
		"desc": "바위틈의 듬직한 대장. 한번 물면 바위로 파고들어서 처음 힘싸움이 세다.",
	},
	"hakgongchi": {
		"name": "학공치", "rarity": "rare",
		"min_cm": 25.0, "max_cm": 40.0, "strength": 0.3, "price": 7000,
		"weight": 1.2, "night": -0.7, "zone": [0.2, 0.9, 1.8],
		"weather": {"sunny": 1.4},
		"habit": "jump", "catalog": "hakgongchi", "grill": "hakgongchi-gui",
		"desc": "바늘처럼 뾰족한 아래턱을 가진 은빛 물고기. 맑은 낮에 먼 물 수면에서 떼 지어 다닌다.",
	},
	"gamseongdom": {
		"name": "감성돔", "rarity": "legend",
		"min_cm": 25.0, "max_cm": 52.0, "strength": 0.95, "price": 28000,
		"weight": 0.22, "night": 0.3, "zone": [0.2, 0.8, 1.8],
		"weather": {"cloudy": 1.4, "windy": 1.5},
		"habit": "long", "catalog": "gamseongdom", "grill": "gamseongdom-gui",
		"desc": "방파제 꾼들의 꿈. 먼 물에서 드물게 모습을 보인다. 힘이 엄청나서 장비가 약하면 버티기 어렵다.",
	},
}


static func get_fish(id: String) -> Dictionary:
	return FISH.get(id, {})


static func rarity(id: String) -> Dictionary:
	return RARITY.get(get_fish(id).get("rarity", "common"), RARITY.common)


## 지금 상황에서 한 종이 나올 가중치.
## ctx: brightness(0~1), depth(던진 거리 0~1), bait(미끼 id), weather(SeaDay id), rare_boost(희귀 이상 배율)
static func weight_of(id: String, ctx: Dictionary) -> float:
	var f := get_fish(id)
	if f.is_empty():
		return 0.0
	var b: float = clampf(ctx.get("brightness", 0.0), 0.0, 1.0)
	var w: float = f.weight
	# 밝기: night가 크면 어두울수록, 작으면 밝을수록 잘 문다
	w *= maxf(0.15, 1.0 + f.night * (0.5 - b) * 1.4)
	# 거리: 발밑(0) 중간(0.5) 먼 물(1) 사이를 이어서 본다
	var d: float = clampf(ctx.get("depth", 0.5), 0.0, 1.0)
	var z: Array = f.zone
	w *= lerpf(z[0], z[1], d * 2.0) if d < 0.5 else lerpf(z[1], z[2], (d - 0.5) * 2.0)
	# 미끼
	var bait: String = ctx.get("bait", "")
	if not bait.is_empty():
		w *= BaitDB.like_mult(bait, id)
	# 날씨
	w *= f.weather.get(ctx.get("weather", ""), 1.0)
	# 연속 PERFECT 같은 버프
	if f.rarity != "common":
		w *= ctx.get("rare_boost", 1.0)
	return w


## 가중치대로 한 종을 고른다.
static func pick_ctx(rng: RandomNumberGenerator, ctx: Dictionary) -> String:
	var total := 0.0
	var weights := {}
	for id in FISH:
		var w := weight_of(id, ctx)
		weights[id] = w
		total += w
	var r := rng.randf() * total
	for id in weights:
		r -= weights[id]
		if r <= 0.0:
			return id
	return "bolak"


## 이 거리(0 발밑 ~ 1 먼 물)에서 지금 가장 잘 나오는 어종 (거리 게이지 옆 표시)
static func top_at(ctx: Dictionary, depth: float) -> String:
	var c := ctx.duplicate()
	c["depth"] = depth
	var best := ""
	var best_w := -1.0
	for id in FISH:
		var w := weight_of(id, c)
		if w > best_w:
			best_w = w
			best = id
	return best


## 버릇 한 줄 설명 (도감, 잡은 카드)
static func habit_text(id: String) -> String:
	return {
		"dive": "물자마자 바위로 세게 파고들어요. 첫 번째 차고 나갈 때를 버텨요",
		"shake": "짧게 자주 처박아요. 좌우를 부지런히 맞춰요",
		"long": "한 번 차고 나가면 길게 가요. 장력을 식히며 버텨요",
		"jump": "물 위로 뛰어올라 바늘을 털어요. 뛰는 동안 손을 떼지 마요",
	}.get(get_fish(id).get("habit", ""), "")


## 예전 방식 (밝기만 본다)
static func pick(rng: RandomNumberGenerator, brightness: float) -> String:
	return pick_ctx(rng, {"brightness": brightness})


## size_bonus: 0~1. 나이스 캐스트, 좋은 미끼 같은 걸로 큰 개체가 조금 더 잘 나온다
static func roll_size(rng: RandomNumberGenerator, id: String, size_bonus := 0.0) -> float:
	var f := get_fish(id)
	# 작은 개체가 더 흔하게: 두 번 뽑아 작은 쪽에 가깝게
	var k := minf(rng.randf(), rng.randf()) * 0.6 + rng.randf() * 0.4
	k = clampf(k + size_bonus * rng.randf() * 0.35, 0.0, 1.0)
	return snappedf(lerpf(f.min_cm, f.max_cm, k), 0.1)


## 크기 별점 1~3
static func stars(id: String, size_cm: float) -> int:
	var f := get_fish(id)
	var k := inverse_lerp(f.min_cm, f.max_cm, size_cm)
	return 3 if k >= 0.72 else (2 if k >= 0.4 else 1)


## 그 어종 최대 크기의 90% 이상이면 대물
static func is_trophy(id: String, size_cm: float) -> bool:
	var f := get_fish(id)
	return inverse_lerp(f.min_cm, f.max_cm, size_cm) >= 0.9


## 팔 때 값: 기본값 × 크기 × 희귀도
static func value_of(id: String, size_cm: float) -> int:
	var f := get_fish(id)
	var k := inverse_lerp(f.min_cm, f.max_cm, size_cm)
	var v: float = f.price * (0.7 + k * 0.8) * rarity(id).price
	return int(roundf(v / 100.0) * 100.0)
