class_name KitchenDB
extends RefCounted
## 주방 장비 다섯 가지, 1~5단계 (2026-11-24). 그림은 회사 PC 세션이 받아 둔 주방장비_5단계 (shop4/gear/<id>_lv_<단계>).
## 경자상회 주방 탭에서 한 단계씩 산다. 보관: GameState.kitchen {id: 단계}. 없으면 1단계(낡은 장비)
## 장면이 아닌 규칙만 담아 헤드리스로 시험한다.

const MAX := 5
const PRICES := [0, 40000, 110000, 240000, 450000] # 그 단계로 올리는 값 (1단계는 처음부터)
const LEVEL_NAMES := ["낡은", "닦아 쓴", "스테인리스", "업소용", "황동 장식"]

## effect의 {0}에 values[단계-1]
const GEAR := {
	"stove": {"name": "가스레인지", "effect": "굽는 시간 {0}% 짧음", "values": [0, 6, 12, 18, 25]},
	"work": {"name": "작업대", "effect": "접시 값 {0}% 더 받음", "values": [0, 2, 4, 6, 9]},
	"sink": {"name": "싱크대", "effect": "빈 그릇 {0}%는 저절로 치워짐", "values": [0, 15, 30, 45, 60]},
	"fridge": {"name": "냉장고", "effect": "상할 생선 {0}마리를 하루 더 살림", "values": [0, 1, 3, 5, 8]},
	"shelf": {"name": "그릇 선반", "effect": "손님이 {0}% 더 기다려 줌", "values": [0, 4, 8, 12, 18]},
}
const ORDER := ["stove", "work", "sink", "fridge", "shelf"]


static func level(kitchen: Dictionary, id: String) -> int:
	return clampi(int(kitchen.get(id, 1)), 1, MAX)


static func value(kitchen: Dictionary, id: String) -> int:
	return int(GEAR[id].values[level(kitchen, id) - 1])


static func full_name(id: String, lv: int) -> String:
	return "%s %s" % [LEVEL_NAMES[lv - 1], GEAR[id].name]


static func effect_text(id: String, lv: int) -> String:
	return str(GEAR[id].effect).replace("{0}", str(GEAR[id].values[lv - 1]))


## 다음 단계 값. 끝까지 올렸으면 -1
static func next_price(kitchen: Dictionary, id: String) -> int:
	var lv := level(kitchen, id)
	return -1 if lv >= MAX else int(PRICES[lv])


static func art(id: String, lv: int) -> String:
	return "shop4/gear/%s_lv_%d" % [id, lv]


## 장비 효과를 영업 규칙에 넣는다
static func apply(logic, kitchen: Dictionary) -> void:
	logic.cook_mult = 1.0 - value(kitchen, "stove") / 100.0
	logic.plate_bonus = 1.0 + value(kitchen, "work") / 100.0
	logic.auto_clean = value(kitchen, "sink") / 100.0
	logic.patience_mult *= 1.0 + value(kitchen, "shelf") / 100.0
