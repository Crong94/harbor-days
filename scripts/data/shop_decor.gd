class_name ShopDecor
extends RefCounted
## 식당 가구와 장식 (2026-11-11 사용자: 의자, 꽃, 장식은 상점에서 사서 바꿔 끼운다).
## 배경 그림에는 의자, 화분, 바 위 장식, 벽 장식, 등을 그리지 않는다. 자리(슬롯)마다 투명 그림을 따로 얹는다.
## 그림: assets/art/decor/<item id>.png (그림 세션이 종류별로 받는다). 그림이 없으면 아무것도 그리지 않는다.
## 놓은 것: GameState.shop_decor {슬롯 id: 물건 id}, 가진 것: GameState.owned_decor [물건 id]
## 비어 있는 슬롯은 그 종류의 기본 물건(값 0)을 쓴다. 의자는 편할수록 손님이 더 오래 기다려 준다(comfort초).
## 자리 위치는 식당 배경 그림 전체 비율, 아래 가운데 기준 (벽 장식만 가운데 기준). DiningLogic과 같은 좌표, 그림 세션이 잰 값.
## 사고 놓기: 식당 장부의 "가게 꾸미기". 한 종류는 한 번에 같은 물건으로 바꾼다 (place_all).

const ART_DIR := "decor/"

## 슬롯 종류 (2026-11-16, 슬롯 설계 7·8차): table U자 바(배경 크기 캔버스 그림), chair 의자(손님 자리마다), bar 바 위 장식,
## wall 벽 장식, plant 바닥 화분, hood 후드, stove 화구, tool 조리대 도구, shelf 뒷벽 선반 물건, lamp 천장 등, sign 간판, light 줄전구
const KINDS := ["table", "chair", "stove", "hood", "tool", "shelf", "lamp", "sign", "light", "bar", "wall", "plant"]

## 물건 목록. price 0은 처음부터 있는 기본 물건. native: 배경 그림 px 그대로(배율 1) 그린다
const ITEMS := {
	"table_old": {"kind": "table", "name": "낡은 나무 바", "price": 0},
	"table_honey": {"kind": "table", "name": "꿀색 원목 바", "price": 150000},
	"chair_basic": {"kind": "chair", "name": "플라스틱 의자", "price": 0, "comfort": 0.0},
	"chair_wood": {"kind": "chair", "name": "나무 의자", "price": 30000, "comfort": 5.0},
	"chair_cushion": {"kind": "chair", "name": "방석 깐 의자", "price": 60000, "comfort": 10.0},
	"stove_old": {"kind": "stove", "name": "낡은 가스 화구", "price": 0, "native": true},
	"stove_basic": {"kind": "stove", "name": "깨끗한 가스 화구", "price": 70000, "native": true},
	"hood_old": {"kind": "hood", "name": "낡은 후드", "price": 0},
	"hood_basic": {"kind": "hood", "name": "스테인리스 후드", "price": 80000},
	"tool_old": {"kind": "tool", "name": "찌그러진 도구통", "price": 0},
	"tool_utensils": {"kind": "tool", "name": "도구통", "price": 15000},
	"tool_board": {"kind": "tool", "name": "도마와 도구통", "price": 20000},
	"shelf_none": {"kind": "shelf", "name": "빈 선반", "price": 0},
	"shelf_old_pot": {"kind": "shelf", "name": "찌그러진 양은 냄비", "price": 0},
	"shelf_old_bowls": {"kind": "shelf", "name": "이 빠진 그릇", "price": 0},
	"shelf_old_rice": {"kind": "shelf", "name": "반쯤 빈 쌀 포대", "price": 0},
	"shelf_plant": {"kind": "shelf", "name": "작은 화분", "price": 15000},
	"shelf_bowls": {"kind": "shelf", "name": "흰 그릇 더미", "price": 15000},
	"shelf_towel_jars": {"kind": "shelf", "name": "행주 바구니와 유리병", "price": 15000},
	"shelf_fish_basket": {"kind": "shelf", "name": "마른 생선 바구니", "price": 20000},
	"shelf_rice_jars": {"kind": "shelf", "name": "쌀 포대와 단지", "price": 20000},
	"shelf_plate_set": {"kind": "shelf", "name": "접시와 양념병", "price": 20000},
	"shelf_pot_set": {"kind": "shelf", "name": "냄비와 양념병", "price": 25000},
	"shelf_pots_vine": {"kind": "shelf", "name": "냄비와 덩굴 화분", "price": 25000},
	"lamp_bulb_long": {"kind": "lamp", "name": "알전구 (긴 줄)", "price": 0, "native": true},
	"lamp_bulb_short": {"kind": "lamp", "name": "알전구 (짧은 줄)", "price": 0, "native": true},
	"lamp_paper": {"kind": "lamp", "name": "종이 등", "price": 20000},
	"lamp_bamboo": {"kind": "lamp", "name": "대나무 등", "price": 30000},
	"lamp_enamel": {"kind": "lamp", "name": "법랑 등", "price": 40000},
	"sign_old": {"kind": "sign", "name": "낡은 빈 간판", "price": 0},
	"sign_wood": {"kind": "sign", "name": "나무 간판", "price": 30000},
	"sign_paint": {"kind": "sign", "name": "그림 간판", "price": 50000},
	"light_none": {"kind": "light", "name": "줄전구 없음", "price": 0},
	"string_light": {"kind": "light", "name": "줄전구", "price": 35000},
	"bar_none": {"kind": "bar", "name": "빈 바", "price": 0},
	"bar_flower": {"kind": "bar", "name": "작은 꽃병", "price": 15000},
	"bar_lamp": {"kind": "bar", "name": "작은 등", "price": 25000},
	"wall_none": {"kind": "wall", "name": "빈 벽", "price": 0},
	"wall_menu": {"kind": "wall", "name": "손글씨 차림표", "price": 10000},
	"wall_fish": {"kind": "wall", "name": "물고기 탁본", "price": 40000},
	"plant_none": {"kind": "plant", "name": "빈 자리", "price": 0},
	"plant_pot": {"kind": "plant", "name": "화분", "price": 20000},
}

## 종류별 기본 물건 (슬롯에 default가 있으면 그게 먼저)
const DEFAULTS := {"table": "table_old", "chair": "chair_basic", "stove": "stove_old", "hood": "hood_old", "tool": "tool_old",
	"shelf": "shelf_none", "lamp": "lamp_bulb_short", "sign": "sign_old", "light": "light_none",
	"bar": "bar_none", "wall": "wall_none", "plant": "plant_none"}

## 종류별 그리기. h: 높이, w: 폭 (배경 그림 941px 기준). box가 있는 슬롯은 그 상자에 비율 그대로 꽉 차게.
## table은 배경 크기 캔버스를 그대로 덮는다. front: 요리사와 조리대 앞면 위에 그린다(화구, 도구).
## glow: 불빛이라 밤에도 밝기를 낮추지 않는다. center: 기준점이 그림 가운데 (벽 장식)
const DRAW := {
	"table": {"canvas": true}, "chair": {"h": 92.0}, "bar": {"h": 56.0}, "wall": {"h": 95.0, "center": true}, "plant": {"h": 110.0},
	"stove": {"front": true}, "tool": {"front": true}, "hood": {}, "shelf": {},
	"lamp": {"glow": true}, "sign": {"w": 318.0}, "light": {"w": 900.0, "glow": true},
}

## 의자 말고 슬롯 (슬롯 설계 7·8차, 배경 전체 비율, 기준점은 아래 가운데). box: 칸 크기(배경 px)
const EXTRA_SLOTS := [
	{"id": "table", "kind": "table", "pos": Vector2(0.5, 1.0)},
	{"id": "stove_L", "kind": "stove", "pos": Vector2(0.245, 0.452)},
	{"id": "hood_L", "kind": "hood", "pos": Vector2(0.243, 0.223), "box": Vector2(170, 122)},
	{"id": "tool_L", "kind": "tool", "pos": Vector2(0.136, 0.432), "box": Vector2(48, 58)},
	{"id": "shelf_U1", "kind": "shelf", "pos": Vector2(0.239, 0.293), "box": Vector2(158, 89)},
	{"id": "shelf_U2", "kind": "shelf", "pos": Vector2(0.420, 0.293), "box": Vector2(158, 89)},
	{"id": "shelf_U3", "kind": "shelf", "pos": Vector2(0.600, 0.293), "box": Vector2(158, 89)},
	{"id": "shelf_U4", "kind": "shelf", "pos": Vector2(0.781, 0.293), "box": Vector2(158, 89)},
	{"id": "shelf_D1", "kind": "shelf", "pos": Vector2(0.239, 0.349), "box": Vector2(158, 84)},
	{"id": "shelf_D2", "kind": "shelf", "pos": Vector2(0.420, 0.349), "box": Vector2(158, 84), "default": "shelf_old_pot"},
	{"id": "shelf_D3", "kind": "shelf", "pos": Vector2(0.600, 0.349), "box": Vector2(158, 84), "default": "shelf_old_bowls"},
	{"id": "shelf_D4", "kind": "shelf", "pos": Vector2(0.781, 0.349), "box": Vector2(158, 84), "default": "shelf_old_rice"},
	{"id": "lamp_1", "kind": "lamp", "pos": Vector2(0.085, 0.197), "lamp_h": 170.0, "default": "lamp_bulb_long"},
	{"id": "lamp_2", "kind": "lamp", "pos": Vector2(0.417, 0.141), "lamp_h": 150.0},
	{"id": "lamp_3", "kind": "lamp", "pos": Vector2(0.584, 0.141), "lamp_h": 150.0},
	{"id": "lamp_4", "kind": "lamp", "pos": Vector2(0.915, 0.197), "lamp_h": 170.0, "default": "lamp_bulb_long"},
	{"id": "sign", "kind": "sign", "pos": Vector2(0.511, 0.219)},
	{"id": "light", "kind": "light", "pos": Vector2(0.5, 0.114)},
	{"id": "bar_0", "kind": "bar", "pos": Vector2(0.336, 0.579)},
	{"id": "bar_1", "kind": "bar", "pos": Vector2(0.291, 0.738)},
	{"id": "bar_2", "kind": "bar", "pos": Vector2(0.662, 0.579)},
	{"id": "bar_3", "kind": "bar", "pos": Vector2(0.707, 0.738)},
	{"id": "wall_0", "kind": "wall", "pos": Vector2(0.069, 0.449)},
	{"id": "wall_1", "kind": "wall", "pos": Vector2(0.930, 0.208)},
	{"id": "plant_0", "kind": "plant", "pos": Vector2(0.06, 0.95)},
	{"id": "plant_1", "kind": "plant", "pos": Vector2(0.94, 0.95)},
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
		return s.get("default", DEFAULTS[s.kind])
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


## 사기: 아직 없고 돈이 되면 owned에 넣고 값을 돌려준다. 못 사면 -1
static func buy(owned: Array, item_id: String, money: int) -> int:
	var it := item(item_id)
	if it.is_empty() or owns(owned, item_id) or money < int(it.price):
		return -1
	owned.append(item_id)
	return int(it.price)


## 그 종류에 지금 놓인 물건 (첫 슬롯 기준. 놓을 때 종류 전체를 같이 바꾸므로 같다)
static func kind_item(decor: Dictionary, kind: String) -> String:
	for s in slots():
		if s.kind == kind:
			return item_in(decor, s.id)
	return DEFAULTS.get(kind, "")


## 종류별 물건 id (값 싼 순)
static func items_of(kind: String) -> Array:
	var out := []
	for id in ITEMS:
		if ITEMS[id].kind == kind:
			out.append(id)
	out.sort_custom(func(a, b): return int(ITEMS[a].price) < int(ITEMS[b].price))
	return out


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
