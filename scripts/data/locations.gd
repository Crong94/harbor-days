class_name Locations
extends RefCounted
## 물빛울포 장소 목록과 지도 규칙.
##
## pos는 지도 그림 위의 위치를 0~1 비율로 적는다 (왼쪽 위가 0,0).
## 지도 그림: 오늘의 바다 전용 세로 지도 map_village.png (2026-11-10). 위가 북쪽, 바다와 항구는 동쪽.
## 핀은 그림 속 건물에 맞췄다. 그림을 바꾸면 pos만 고치면 된다.
## unlock은 GameState.flags 이름이다. 빈 문자열이면 처음부터 열려 있다.

const LIST := {
	"shop": {
		"name": "{shop}", "pos": Vector2(0.43, 0.40), "unlock": "",
		"scene": "", "desc": "내 작은 식당",
	},
	"home": {
		"name": "우리 집", "pos": Vector2(0.21, 0.32), "unlock": "",
		"scene": "", "desc": "오래된 작은 단층집",
	},
	"breakwater": {
		"name": "북쪽 방파제", "pos": Vector2(0.90, 0.27), "unlock": "",
		"scene": "res://scenes/fishing/fishing.tscn", "desc": "빨간 등대가 있는 입문 낚시터",
	},
	"market": {
		"name": "물빛 수산시장", "pos": Vector2(0.56, 0.47), "unlock": "",
		"scene": "", "desc": "반쯤 문을 닫은 오래된 시장",
	},
	"tackle": {
		"name": "준호네 낚시방", "pos": Vector2(0.45, 0.33), "unlock": "",
		"scene": "res://scenes/shop/tackle_shop.tscn", "desc": "장비, 미끼, 수리",
	},
	"diner": {
		"name": "복자네 밥집", "pos": Vector2(0.20, 0.47), "unlock": "",
		"scene": "", "desc": "마을에 하나 남은 밥집",
	},
	"store": {
		"name": "경자상회", "pos": Vector2(0.15, 0.56), "unlock": "",
		"scene": "", "desc": "50년 된 구멍가게",
	},
	"hall": {
		"name": "마을회관", "pos": Vector2(0.19, 0.15), "unlock": "chapter2_done",
		"scene": "", "desc": "게시판과 마을 의뢰",
	},
	"school": {
		"name": "물빛분교", "pos": Vector2(0.40, 0.14), "unlock": "chapter2_done",
		"scene": "", "desc": "학생이 한 명뿐인 분교",
	},
	"guesthouse": {
		"name": "등대민박", "pos": Vector2(0.57, 0.25), "unlock": "chapter2_done",
		"scene": "", "desc": "방 다섯 개짜리 민박",
	},
	"rocks": {
		"name": "검은여 갯바위", "pos": Vector2(0.86, 0.66), "unlock": "learned_tide",
		"scene": "", "desc": "물때를 알아야 들어갈 수 있는 중급 낚시터",
	},
	"lab": {
		"name": "해양생태 연구소", "pos": Vector2(0.56, 0.72), "unlock": "chapter3_start",
		"scene": "", "desc": "서윤이 일하는 연구소",
	},
	"beach": {
		"name": "야광충 해변", "pos": Vector2(0.07, 0.85), "unlock": "found_glow_beach",
		"scene": "", "desc": "여름밤에만 빛나는 작은 만",
	},
	"island": {
		"name": "동백섬", "pos": Vector2(0.85, 0.12), "unlock": "has_boat",
		"scene": "", "desc": "배로만 갈 수 있는 무인도",
	},
}

## 지도 위 거리 1.0을 걸어가는 데 드는 분
const MINUTES_PER_UNIT := 40.0
const MIN_TRAVEL := 5
const BOAT_ONLY := ["island"]


static func get_loc(id: String) -> Dictionary:
	return LIST.get(id, {})


static func is_unlocked(id: String, flags: Dictionary) -> bool:
	var cond: String = get_loc(id).get("unlock", "")
	return cond.is_empty() or flags.get(cond, false)


## 두 장소 사이 이동 시간(분). 5분 단위로 반올림한다.
static func travel_minutes(from_id: String, to_id: String) -> int:
	if from_id == to_id:
		return 0
	var a: Vector2 = get_loc(from_id).get("pos", Vector2.ZERO)
	var b: Vector2 = get_loc(to_id).get("pos", Vector2.ZERO)
	var m := a.distance_to(b) * MINUTES_PER_UNIT
	if to_id in BOAT_ONLY or from_id in BOAT_ONLY:
		m += 20.0 # 배 타는 시간
	return maxi(MIN_TRAVEL, int(round(m / 5.0)) * 5)
