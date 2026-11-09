class_name GearDB
extends RefCounted
## 낚싯대와 릴 데이터.
## 그림은 assets/art/rod_<id>.png, reel_<id>.png (사용자에게 받음). 없으면 선과 원으로 대신 보여 준다.
##
## 낚싯대 그림 규칙: 가로로 곧게 눕힌 모습, 손잡이가 왼쪽, 낚싯대 끝이 오른쪽.
##   grip: 손으로 쥐는 곳, seat: 릴이 붙는 곳, tip: 낚싯대 끝 (그림 가로 길이 대비 비율)
## 릴 그림 규칙: 옆모습, 위쪽 가운데가 낚싯대에 붙는 다리.
##
## cast: 최대 던지기 거리 배율, strength: 줄 장력이 덜 오르는 정도
## speed: 감는 속도 배율, drag: 물고기가 당길 때 장력이 덜 오르는 정도

const RODS := {
	"old_float": {
		"name": "낡은 릴찌낚싯대", "price": 0,
		"desc": "식당 창고에서 찾은 낚싯대. 낡았지만 아직 쓸 만하다.",
		"cast": 0.75, "strength": 0.0,
		"grip": 0.06, "seat": 0.2, "tip": 0.99, "color": Color("3a3a42"),
	},
	"starter_float": {
		"name": "입문용 찌낚싯대", "price": 45000,
		"desc": "준호네 낚시방 추천 입문 장비. 가볍고 멀리 던지기 쉽다.",
		"cast": 0.9, "strength": 0.1,
		"grip": 0.06, "seat": 0.2, "tip": 0.99, "color": Color("2f5f8a"),
	},
	"carbon_rock": {
		"name": "카본 갯바위 찌낚싯대", "price": 180000,
		"desc": "갯바위 꾼들이 쓰는 낚싯대. 멀리 던지고 힘센 고기도 버틴다.",
		"cast": 1.0, "strength": 0.25,
		"grip": 0.06, "seat": 0.2, "tip": 0.99, "color": Color("1f1f24"),
	},
}

const REELS := {
	"cheap_spinning": {
		"name": "저가형 스피닝릴", "price": 0,
		"desc": "줄이 가끔 꼬이는 오래된 릴.",
		"speed": 1.0, "drag": 0.0, "color": Color("8a8f98"),
	},
	"spinning_2500": {
		"name": "2500번 스피닝릴", "price": 60000,
		"desc": "부드럽게 감기는 표준 스피닝릴.",
		"speed": 1.2, "drag": 0.1, "color": Color("c9a24a"),
	},
	"lever_brake": {
		"name": "레버 브레이크 릴", "price": 220000,
		"desc": "갯바위 찌낚시 전용 릴. 물고기가 차고 나갈 때 줄을 풀어 준다.",
		"speed": 1.3, "drag": 0.25, "color": Color("b5463a"),
	},
}

const DEFAULT_ROD := "old_float"
const DEFAULT_REEL := "cheap_spinning"


static func rod(id: String) -> Dictionary:
	return RODS.get(id, RODS[DEFAULT_ROD])


static func reel(id: String) -> Dictionary:
	return REELS.get(id, REELS[DEFAULT_REEL])


## 낚시 규칙에 장비 능력치를 넣는다.
static func apply(logic: FishingLogic, rod_id: String, reel_id: String) -> void:
	var r := rod(rod_id)
	var l := reel(reel_id)
	logic.cast_mult = r.cast
	logic.reel_mult = l.speed
	logic.tension_mult = clampf(1.0 - r.strength * 0.5 - l.drag * 0.5, 0.5, 1.0)
