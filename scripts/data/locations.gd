class_name Locations
extends RefCounted
## 물빛울포 장소 목록과 지도 규칙.
##
## pos는 지도 그림 위의 위치를 0~1 비율로 적는다 (왼쪽 위가 0,0).
## 지도 그림: 가로 3:2 확장 지도 map_village.png (2026-11-10, 1536x1024, 드라이브 ref의 map_village_확장_v3).
## 위쪽에 항구와 빨간 등대 방파제, 가운데 가게 거리, 아래쪽 언덕 마을과 해변, 오른쪽 터널과 동백섬.
## 핀은 보통 pos 위에 서서 아래 끝이 pos를 가리킨다. "pin": "below"면 pos 아래에 매달린다 (위에 자리가 없을 때).
## unlock은 GameState.flags 이름이다. 빈 문자열이면 처음부터 열려 있다.
## "hidden": true인 곳은 열리기 전까지 지도에 점도 보이지 않는다 (숨은 장소).

const LIST := {
	"shop": {
		"name": "{shop}", "pos": Vector2(0.361, 0.366), "unlock": "",
		"scene": "", "desc": "내 작은 식당",
	},
	"home": {
		"name": "우리 집", "pos": Vector2(0.498, 0.584), "unlock": "",
		"scene": "", "desc": "오래된 작은 단층집",
	},
	"garden": {
		"name": "우리 텃밭", "pos": Vector2(0.684, 0.454), "unlock": "",
		"scene": "res://scenes/garden/garden.tscn", "desc": "이랑 네 줄에 채소를 기르는 작은 텃밭",
	},
	"coop": {
		"name": "닭장", "pos": Vector2(0.658, 0.508), "unlock": "coop_open", "pin": "below",
		"scene": "res://scenes/coop/coop.tscn", "desc": "순덕 할머니가 준 닭들이 사는 작은 닭장",
	},
	"grandma": {
		"name": "순덕 할머니 집", "pos": Vector2(0.374, 0.564), "unlock": "met_sundeok",
		"scene": "res://scenes/village/sundeok_house.tscn", "desc": "바로 옆집 기와집. 할머니가 가끔 부탁을 한다",
	},
	"breakwater": {
		"name": "북쪽 방파제", "pos": Vector2(0.605, 0.227), "unlock": "",
		"scene": "res://scenes/fishing/fishing.tscn", "desc": "빨간 등대가 있는 입문 낚시터",
	},
	"market": {
		"name": "물빛 수산시장", "pos": Vector2(0.674, 0.286), "unlock": "",
		"scene": "res://scenes/market/market.tscn", "desc": "반쯤 문을 닫은 오래된 시장. 잡은 생선을 판다",
	},
	"tackle": {
		"name": "준호네 낚시방", "pos": Vector2(0.514, 0.366), "unlock": "",
		"scene": "res://scenes/shop/tackle_shop.tscn", "desc": "장비, 미끼, 수리",
	},
	"diner": {
		"name": "복자네 밥집", "pos": Vector2(0.439, 0.454), "unlock": "", "pin": "below",
		"scene": "", "desc": "마을에 하나 남은 밥집",
	},
	"store": {
		"name": "경자상회", "pos": Vector2(0.592, 0.366), "unlock": "",
		"scene": "", "desc": "50년 된 구멍가게",
	},
	"bus": {
		"name": "버스 정류장", "pos": Vector2(0.863, 0.313), "unlock": "",
		"scene": "", "desc": "요금을 내고 정해진 시간에 옆마을 가는 버스를 탄다",
	},
	"lookout": {
		"name": "뒷산 전망대", "pos": Vector2(0.220, 0.088), "unlock": "", "pin": "below",
		"scene": "", "desc": "마을과 바다가 한눈에 보이는 정자",
	},
	"hall": {
		"name": "마을회관", "pos": Vector2(0.329, 0.459), "unlock": "chapter2_done",
		"scene": "", "desc": "게시판과 마을 의뢰",
	},
	"school": {
		"name": "물빛분교", "pos": Vector2(0.555, 0.488), "unlock": "chapter2_done",
		"scene": "", "desc": "학생이 한 명뿐인 분교",
	},
	"guesthouse": {
		"name": "등대민박", "pos": Vector2(0.254, 0.198), "unlock": "chapter2_done",
		"scene": "", "desc": "방 다섯 개짜리 민박",
	},
	"rocks": {
		"name": "검은여 갯바위", "pos": Vector2(0.749, 0.586), "unlock": "learned_tide",
		"scene": "", "desc": "물때를 알아야 들어갈 수 있는 중급 낚시터",
	},
	"hidden_rocks": {
		"name": "숨은 갯바위", "pos": Vector2(0.866, 0.571), "unlock": "found_hidden_rocks", "hidden": true,
		"scene": "", "desc": "절벽 아래 밧줄 길로만 내려가는 비밀 낚시터",
	},
	"cave": {
		"name": "해식동굴", "pos": Vector2(0.589, 0.674), "unlock": "found_sea_cave", "hidden": true,
		"scene": "", "desc": "물이 빠질 때만 들어갈 수 있는 바닷가 동굴",
	},
	"lab": {
		"name": "해양생태 연구소", "pos": Vector2(0.192, 0.613), "unlock": "chapter3_start",
		"scene": "", "desc": "서윤이 일하는 연구소",
	},
	"beach": {
		"name": "야광충 해변", "pos": Vector2(0.339, 0.742), "unlock": "found_glow_beach",
		"scene": "", "desc": "여름밤에만 빛나는 작은 만",
	},
	"far_sea": {
		"name": "먼바다 바위섬", "pos": Vector2(0.850, 0.171), "unlock": "has_boat", "pin": "below",
		"scene": "", "desc": "배를 타고 나가는 배낚시 포인트",
	},
	"island": {
		"name": "동백섬", "pos": Vector2(0.866, 0.721), "unlock": "has_boat",
		"scene": "", "desc": "배로만 갈 수 있는 무인도",
	},
}

## 지도 위 거리 1.0을 걸어가는 데 드는 분
const MINUTES_PER_UNIT := 32.0
## 지도 그림의 가로:세로. pos는 0~1 비율이라 거리를 잴 때 가로를 이만큼 늘린다
const MAP_ASPECT := 1.5
const MIN_TRAVEL := 5
const BOAT_ONLY := ["island", "far_sea"]


static func get_loc(id: String) -> Dictionary:
	return LIST.get(id, {})


static func is_unlocked(id: String, flags: Dictionary) -> bool:
	var cond: String = get_loc(id).get("unlock", "")
	return cond.is_empty() or flags.get(cond, false)


## 지도에 핀이나 점을 보여 줄지. 숨은 장소는 열리기 전까지 안 보인다.
static func is_visible(id: String, flags: Dictionary) -> bool:
	return not get_loc(id).get("hidden", false) or is_unlocked(id, flags)


## 두 장소 사이 이동 시간(분). 5분 단위로 반올림한다.
static func travel_minutes(from_id: String, to_id: String) -> int:
	if from_id == to_id:
		return 0
	var a: Vector2 = get_loc(from_id).get("pos", Vector2.ZERO)
	var b: Vector2 = get_loc(to_id).get("pos", Vector2.ZERO)
	var m := Vector2(a.x * MAP_ASPECT, a.y).distance_to(Vector2(b.x * MAP_ASPECT, b.y)) * MINUTES_PER_UNIT
	if to_id in BOAT_ONLY or from_id in BOAT_ONLY:
		m += 20.0 # 배 타는 시간
	return maxi(MIN_TRAVEL, int(round(m / 5.0)) * 5)
