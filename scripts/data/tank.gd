class_name Tank
extends RefCounted
## 활어 수조 (11-24 사용자 요청). 처음엔 없고 경자상회에서 산다. 단계를 건너뛰지 않고 하나씩 키운다.
## 수조에 넣은 고기는 살아 있어서 상하지 않는다. 꺼내면 그날 잡은 것처럼 싱싱하다.
## 밤에 아이스박스에서 상할 고기가 있으면 자리가 남는 만큼 값진 것부터 수조로 옮겨 살려 둔다.

## 단계별 수조. slots: 몇 마리 살려 둘 수 있나
const LEVELS := [
	{"name": "고무 함지 수조", "slots": 2, "price": 30000,
		"desc": "고무 함지에 바닷물을 받아 둔다. 두 마리쯤은 하루 이틀 버틴다."},
	{"name": "기포기 수조", "slots": 4, "price": 60000,
		"desc": "기포기로 산소를 넣어 준다. 네 마리까지 살려 둔다."},
	{"name": "냉각 활어 수조", "slots": 7, "price": 120000,
		"desc": "물을 차게 지켜 주는 냉각기 수조. 일곱 마리까지 팔팔하다."},
]


## 지금 단계(0이면 없음)의 정보. 없으면 빈 사전
static func level_info(level: int) -> Dictionary:
	return LEVELS[level - 1] if level >= 1 and level <= LEVELS.size() else {}


## 다음에 살 단계 정보. 다 샀으면 빈 사전
static func next_info(level: int) -> Dictionary:
	return level_info(level + 1)


static func slots(level: int) -> int:
	return int(level_info(level).get("slots", 0))
