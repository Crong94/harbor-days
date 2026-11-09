class_name Orders
extends RefCounted
## 식당 주문서: 날마다 마을 사람 한 명이 원하는 물고기를 부탁한다.
## 낚시 화면 위쪽에 쪽지로 보이고, 조건에 맞는 물고기를 잡으면 칸이 찬다.
## 다 채우면 보상(돈)을 받는다. 같은 날짜는 언제나 같은 주문이 나온다.
##
## 대사는 템플릿({player}, {shop}). 화면에 띄울 때 GameState.line()으로 바꾼다.

const CUSTOMERS := [
	{"name": "최순덕", "lines": [
		"{player|이/가} 굽는 %s 한번 더 먹고 싶네.",
		"우리 영감이 %s 좋아했지. 몇 마리만 부탁해.",
	]},
	{"name": "박만수", "lines": [
		"%s 잡아 와 봐라. 실력 좀 보자.",
		"오늘 물때면 %s 나온다. 놓치지 말고.",
	]},
	{"name": "이준호", "lines": [
		"형 %s 잡으면 사진 좀 찍어 줘요. 가게에 붙이게.",
		"손님들이 %s 어디서 잡냐고 물어봐서요. 몇 마리만요.",
	]},
]

## 주문에 나올 수 있는 어종과 몇 마리
const POOL := [
	["bolak", 2], ["bolak", 3], ["mangsang", 2], ["noraemi", 2],
	["ssombaengi", 2], ["ureok", 1], ["hakgongchi", 2],
]


## 그날의 주문. 첫날(튜토리얼)은 주문이 없다.
static func of(day: int) -> Dictionary:
	if day <= 1:
		return {}
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("주문-%d" % day)
	var c: Dictionary = CUSTOMERS[rng.randi() % CUSTOMERS.size()]
	var p: Array = POOL[rng.randi() % POOL.size()]
	var fish: String = p[0]
	var f := FishDB.get_fish(fish)
	# 너무 작은 건 안 받는다: 최소 크기와 평균 사이
	var min_cm := snappedf(lerpf(f.min_cm, f.max_cm, 0.25), 1.0)
	var line: String = c.lines[rng.randi() % c.lines.size()] % f.name
	return {
		"customer": c.name,
		"fish": fish,
		"count": p[1],
		"min_cm": min_cm,
		"reward": int(FishDB.value_of(fish, lerpf(f.min_cm, f.max_cm, 0.5)) * p[1] * 1.5 / 1000.0) * 1000,
		"line": line,
	}


## 이 물고기가 주문 조건에 맞는지
static func matches(order: Dictionary, fish_id: String, size_cm: float) -> bool:
	return not order.is_empty() and order.fish == fish_id and size_cm >= order.min_cm


## 쪽지에 쓰는 짧은 조건. 예: "볼락 20cm 이상"
static func goal_text(order: Dictionary) -> String:
	if order.is_empty():
		return ""
	return "%s %dcm 이상" % [FishDB.get_fish(order.fish).name, int(order.min_cm)]
