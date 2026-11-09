class_name FishDB
extends RefCounted
## 어종 데이터. 지금은 북쪽 방파제 봄 새벽에 나오는 세 종만 있다.
## strength: 당기는 힘 (0~1). dawn_bias: 어두울수록 잘 무는 정도 (볼락은 밝아지면 숨는다).
## catalog: Catalog(바다 한 접시 데이터)의 어종 id. grill: 생선구이 레시피 id (요리 그림 dish/<id>)

const FISH := {
	"bolak": {
		"name": "볼락",
		"min_cm": 12.0, "max_cm": 24.0,
		"strength": 0.5, "price": 4000, "weight": 6.0, "dawn_bias": 0.8,
		"catalog": "bollak", "grill": "bollak-gui",
		"body": Color("6b5a4a"), "belly": Color("b9a68f"),
		"desc": "눈이 크고 어두운 바다를 좋아하는 물고기. 새벽과 밤에 잘 물고, 해가 뜨면 바위틈에 숨는다.",
	},
	"mangsang": {
		"name": "망상어",
		"min_cm": 14.0, "max_cm": 26.0,
		"strength": 0.45, "price": 2500, "weight": 3.0, "dawn_bias": 0.0,
		"catalog": "mangsangeo", "grill": "mangsangeo-gui",
		"body": Color("8e9aa5"), "belly": Color("d9dee2"),
		"desc": "몸이 납작하고 은빛이 도는 방파제 단골. 알 대신 새끼를 낳는 물고기다.",
	},
	"noraemi": {
		"name": "노래미",
		"min_cm": 15.0, "max_cm": 30.0,
		"strength": 0.68, "price": 5000, "weight": 2.0, "dawn_bias": 0.2,
		"catalog": "noraemi", "grill": "noraemi-gui",
		"body": Color("6e6a3e"), "belly": Color("c7b98a"),
		"desc": "바위틈에 숨어 사는 얼룩무늬 물고기. 작아도 끌어올릴 때 힘이 좋다.",
	},
}


static func get_fish(id: String) -> Dictionary:
	return FISH.get(id, {})


## 밝기에 따라 가중치를 바꿔 한 종을 고른다.
static func pick(rng: RandomNumberGenerator, brightness: float) -> String:
	var total := 0.0
	var weights := {}
	for id in FISH:
		var f: Dictionary = FISH[id]
		var w: float = f.weight * (1.0 - f.dawn_bias * clampf(brightness, 0.0, 1.0) * 0.8)
		weights[id] = w
		total += w
	var r := rng.randf() * total
	for id in weights:
		r -= weights[id]
		if r <= 0.0:
			return id
	return "bolak"


static func roll_size(rng: RandomNumberGenerator, id: String) -> float:
	var f := get_fish(id)
	# 작은 개체가 더 흔하게: 두 번 뽑아 작은 쪽에 가깝게
	var k := minf(rng.randf(), rng.randf()) * 0.6 + rng.randf() * 0.4
	return snappedf(lerpf(f.min_cm, f.max_cm, k), 0.1)
