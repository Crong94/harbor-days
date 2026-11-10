class_name CropDB
extends RefCounted
## 우리 텃밭. 이랑 네 줄이 칸 네 개다. 칸마다 작물을 하나씩 심어서 한 번에 네 종류까지 기른다.
##
## 칸 하나는 {} (빈 칸) 또는 {"crop": 작물 id, "day": 심은 날}.
## 상태는 날짜로만 정한다: 심은 날부터 days일이 지나면 수확할 수 있다. 그 전에는 자라는 중.
## 작물은 식당의 곁들임 재료다. 주재료는 그대로 직접 낚은 생선만 쓴다.
## price: 씨앗 값, days: 다 자라는 데 걸리는 날, amount: 한 번 수확하는 양, bonus: 곁들이면 접시 값에 더해지는 돈

const SLOTS := 4

## 지도 그림(map_village, 1536x1024)에서 이랑 조각을 덮을 자리. tools/make_garden_rows.py가 알려 준다
const PLOT_RECT := Rect2(976, 433, 138, 101)
const ROW_ART_DIR := "res://assets/art/garden/"

const EMPTY := "empty"
const GROWING := "growing"
const READY := "ready"

const CROPS := {
	"daepa": {
		"name": "대파", "price": 1000, "days": 2, "amount": 4, "bonus": 500,
		"desc": "금방 자란다. 구이에도 탕에도 들어간다.",
	},
	"kkaennip": {
		"name": "깻잎", "price": 1500, "days": 2, "amount": 6, "bonus": 500,
		"desc": "회 한 점을 싸 먹기 좋다.",
	},
	"mu": {
		"name": "무", "price": 2000, "days": 3, "amount": 3, "bonus": 1000,
		"desc": "조림과 맑은탕의 시원한 맛.",
	},
	"gochu": {
		"name": "고추", "price": 2000, "days": 3, "amount": 5, "bonus": 800,
		"desc": "매운탕에 빠지면 섭섭하다.",
	},
	"baechu": {
		"name": "배추", "price": 3000, "days": 4, "amount": 3, "bonus": 1500,
		"desc": "오래 걸리지만 쓸 데가 많다.",
	},
	"maneul": {
		"name": "마늘", "price": 3000, "days": 5, "amount": 6, "bonus": 1200,
		"desc": "가장 오래 걸린다. 구이 옆에 통으로 굽는다.",
	},
}


static func crop(id: String) -> Dictionary:
	return CROPS.get(id, {})


## 빈 텃밭 (빈 칸 네 개)
static func new_garden() -> Array:
	var g: Array = []
	for i in SLOTS:
		g.append({})
	return g


## 칸의 상태: EMPTY, GROWING, READY
static func stage(slot: Dictionary, today: int) -> String:
	if slot.is_empty():
		return EMPTY
	return READY if days_left(slot, today) <= 0 else GROWING


## 수확까지 남은 날. 빈 칸은 0
static func days_left(slot: Dictionary, today: int) -> int:
	if slot.is_empty():
		return 0
	return maxi(0, int(crop(slot.crop).days) - (today - int(slot.day)))


## 지도 위에 덮을 이랑 조각 그림 경로. 빈 칸이면 빈 문자열 (지도 그림의 빈 밭이 그대로 보인다)
static func row_art(slot: Dictionary, today: int, index: int) -> String:
	var st := stage(slot, today)
	if st == EMPTY:
		return ""
	return ROW_ART_DIR + "%s_%s_%d.png" % [slot.crop, st, index]


## 자란 정도 0~1 (그림을 고를 때 쓴다)
static func growth(slot: Dictionary, today: int) -> float:
	if slot.is_empty():
		return 0.0
	return clampf(float(today - int(slot.day)) / float(crop(slot.crop).days), 0.0, 1.0)


## 심을 수 있는지. 문제가 없으면 빈 문자열, 있으면 안내 문구
static func plant_error(garden: Array, index: int, crop_id: String, money: int) -> String:
	if index < 0 or index >= garden.size():
		return "없는 이랑이에요."
	if not CROPS.has(crop_id):
		return "없는 씨앗이에요."
	if not garden[index].is_empty():
		return "이미 심은 이랑이에요."
	if money < int(crop(crop_id).price):
		return "돈이 모자라요."
	return ""


## 지금 자라고 있는 작물 종류 (겹치지 않게)
static func kinds(garden: Array) -> Array:
	var out: Array = []
	for slot in garden:
		if not slot.is_empty() and not slot.crop in out:
			out.append(slot.crop)
	return out
