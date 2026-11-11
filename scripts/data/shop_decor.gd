class_name ShopDecor
extends RefCounted
## 식당 가구와 장식 (2026-11-11 사용자: 의자, 꽃, 장식은 상점에서 사서 바꿔 끼운다).
## 배경 그림에는 의자, 화분, 바 위 장식, 벽 장식, 등을 그리지 않는다. 자리(슬롯)마다 투명 그림을 따로 얹는다.
## 그림: assets/art/decor/<item id>.png (그림 세션이 종류별로 받는다). 그림이 없으면 아무것도 그리지 않는다.
## 놓은 것: GameState.shop_decor {슬롯 id: 물건 id}, 가진 것: GameState.owned_decor [물건 id]
## 비어 있는 슬롯은 그 종류의 기본 물건(값 0)을 쓴다. 의자는 편할수록 손님이 더 오래 기다려 준다(comfort초).
## 자리 위치는 바닥 비율 (DiningLogic과 같은 좌표). 배경 그림이 정해지면 여기 숫자만 맞춘다.

const ART_DIR := "decor/"

## 슬롯 종류: chair 의자(손님 자리마다), bar 바 위 장식, wall 벽 장식, plant 바닥 화분
const KINDS := ["chair", "bar", "wall", "plant"]

## 물건 목록. price 0은 처음부터 있는 기본 물건
const ITEMS := {
	"chair_basic": {"kind": "chair", "name": "플라스틱 의자", "price": 0, "comfort": 0.0},
	"chair_wood": {"kind": "chair", "name": "나무 의자", "price": 30000, "comfort": 5.0},
	"chair_cushion": {"kind": "chair", "name": "방석 깐 의자", "price": 60000, "comfort": 10.0},
	"bar_none": {"kind": "bar", "name": "빈 바", "price": 0},
	"bar_flower": {"kind": "bar", "name": "작은 꽃병", "price": 15000},
	"bar_lamp": {"kind": "bar", "name": "작은 등", "price": 25000},
	"wall_none": {"kind": "wall", "name": "빈 벽", "price": 0},
	"wall_menu": {"kind": "wall", "name": "손글씨 차림표", "price": 10000},
	"wall_fish": {"kind": "wall", "name": "물고기 탁본", "price": 40000},
	"plant_none": {"kind": "plant", "name": "빈 자리", "price": 0},
	"plant_pot": {"kind": "plant", "name": "화분", "price": 20000},
}

## 종류별 기본 물건
const DEFAULTS := {"chair": "chair_basic", "bar": "bar_none", "wall": "wall_none", "plant": "plant_none"}

## 바 위 장식, 벽 장식, 화분 자리 (의자 자리는 DiningLogic.SEATS를 그대로 따른다)
const EXTRA_SLOTS := [
	{"id": "bar_0", "kind": "bar", "pos": Vector2(0.31, 0.40)},
	{"id": "bar_1", "kind": "bar", "pos": Vector2(0.69, 0.40)},
	{"id": "bar_2", "kind": "bar", "pos": Vector2(0.31, 0.68)},
	{"id": "bar_3", "kind": "bar", "pos": Vector2(0.69, 0.68)},
	{"id": "wall_0", "kind": "wall", "pos": Vector2(0.06, 0.25)},
	{"id": "wall_1", "kind": "wall", "pos": Vector2(0.94, 0.25)},
	{"id": "plant_0", "kind": "plant", "pos": Vector2(0.06, 0.88)},
	{"id": "plant_1", "kind": "plant", "pos": Vector2(0.94, 0.88)},
]


## 슬롯 전부 [{id, kind, pos}]. 의자 슬롯 id는 chair_<자리 번호>
static func slots() -> Array:
	var out := []
	for i in DiningLogic.SEATS.size():
		out.append({"id": "chair_%d" % i, "kind": "chair", "pos": DiningLogic.SEATS[i]})
	out.append_array(EXTRA_SLOTS)
	return out


static func slot(slot_id: String) -> Dictionary:
	for s in slots():
		if s.id == slot_id:
			return s
	return {}


static func item(item_id: String) -> Dictionary:
	return ITEMS.get(item_id, {})


## 그 슬롯에 지금 놓인 물건 (안 놓았으면 기본 물건)
static func item_in(decor: Dictionary, slot_id: String) -> String:
	var s := slot(slot_id)
	if s.is_empty():
		return ""
	var id: String = decor.get(slot_id, "")
	if id.is_empty() or item(id).get("kind", "") != s.kind:
		return DEFAULTS[s.kind]
	return id


static func owns(owned: Array, item_id: String) -> bool:
	return int(item(item_id).get("price", -1)) == 0 or owned.has(item_id)


## 놓기. 가진 물건이고 종류가 맞아야 한다
static func place(decor: Dictionary, owned: Array, slot_id: String, item_id: String) -> bool:
	var s := slot(slot_id)
	if s.is_empty() or item(item_id).get("kind", "") != s.kind or not owns(owned, item_id):
		return false
	decor[slot_id] = item_id
	return true


## 그 종류 슬롯 전부에 같은 물건을 놓는다 (의자를 한 번에 바꿀 때)
static func place_all(decor: Dictionary, owned: Array, kind: String, item_id: String) -> int:
	var n := 0
	for s in slots():
		if s.kind == kind and place(decor, owned, s.id, item_id):
			n += 1
	return n


## 그림 id (없으면 빈 문자열: 기본 "none" 물건은 그리지 않는다)
static func art_of(item_id: String) -> String:
	if item_id.ends_with("_none") or item_id.is_empty():
		return ""
	return ART_DIR + item_id


## 자리마다 의자가 늘려 주는 참을성 (초). DiningLogic.seat_bonus에 넣는다
static func seat_comfort(decor: Dictionary) -> Array:
	var out := []
	for i in DiningLogic.SEATS.size():
		out.append(float(item(item_in(decor, "chair_%d" % i)).get("comfort", 0.0)))
	return out
