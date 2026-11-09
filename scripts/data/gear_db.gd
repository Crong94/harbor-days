class_name GearDB
extends RefCounted
## 낚싯대와 릴 10단계. 단계와 능력치는 바다 한 접시 gear.json을 그대로 따르고 이름과 설명만 오늘의 바다에 맞췄다.
##
## 그림 (바다 한 접시 장비 그림, assets/art/gear_icon)
##   낚싯대 n단계: blank-n (낚시 화면 대 몸통), rod-n (상점 아이콘), float-n (그 단계 찌)
##   릴 n단계: butt-n (낚시 화면 밑동+릴, 대 몸통은 butt 위에 잇는다), reel-n (상점 아이콘)
##   배치 숫자 BLANK_LOOK, BUTT_LOOK은 바다 한 접시 gearlook.json
##
## 낚싯대: cast 최대 던지기 거리(reach), strength 물고기 힘을 받아 주는 정도(absorb), hook 챔질 여유(초)
## 릴: speed 감는 속도 배율, drag 장력이 덜 오르는 정도(1 - tensionMul), slack 줄 느슨함을 버티는 추가 시간(초)
## unlock: start 처음부터, shop 낚시방에서 판매, story 이야기 진행으로 받음(unlock_text), later 다음 바다

const RODS := {
	"rod_1": {"tier": 1, "name": "창고 낚싯대", "price": 0, "unlock": "start",
		"desc": "식당 창고에서 찾은 낡은 낚싯대. 낡았지만 아직 쓸 만하다.",
		"cast": 0.74, "strength": 0.0, "hook": 0.0},
	"rod_2": {"tier": 2, "name": "갯바위 찌낚싯대 1호", "price": 80000, "unlock": "shop",
		"desc": "먼 물까지 닿고 물고기 힘을 조금 받아 준다.",
		"cast": 0.8, "strength": 0.25, "hook": 0.08},
	"rod_3": {"tier": 3, "name": "감성돔 전용대", "price": 300000, "unlock": "shop",
		"desc": "허리가 부드러워서 큰 고기가 차고 나가도 크게 받아 준다.",
		"cast": 0.86, "strength": 0.45, "hook": 0.16},
	"rod_4": {"tier": 4, "name": "카본 갯바위대 1.5호", "price": 450000, "unlock": "shop",
		"desc": "가볍고 질기다. 챔질이 빠르다.",
		"cast": 0.9, "strength": 0.5, "hook": 0.19},
	"rod_5": {"tier": 5, "name": "등대지기 낚싯대", "price": 600000, "unlock": "story", "unlock_text": "마을 부탁 4개 해결",
		"desc": "마을 일을 도운 값. 박만수 할아버지가 손봐 줬다.",
		"cast": 0.93, "strength": 0.55, "hook": 0.22},
	"rod_6": {"tier": 6, "name": "물비늘 감성돔대", "price": 800000, "unlock": "story", "unlock_text": "1장 마치기",
		"desc": "1장을 마친 기념으로 받은 대. 햇빛에 물비늘처럼 반짝인다.",
		"cast": 0.95, "strength": 0.6, "hook": 0.25},
	"rod_7": {"tier": 7, "name": "줄 서는 집 명인대", "price": 1000000, "unlock": "story", "unlock_text": "줄 서는 식당 되기",
		"desc": "손님이 줄 서는 식당이 되면 받을 수 있는 명인의 대.",
		"cast": 0.97, "strength": 0.64, "hook": 0.27},
	"rod_8": {"tier": 8, "name": "흑룡 원투대", "price": 0, "unlock": "later",
		"desc": "먼 바다의 대물을 노린다.",
		"cast": 0.98, "strength": 0.68, "hook": 0.29},
	"rod_9": {"tier": 9, "name": "홍염 명품대", "price": 0, "unlock": "later",
		"desc": "아무나 쥘 수 없는 대.",
		"cast": 0.99, "strength": 0.72, "hook": 0.31},
	"rod_10": {"tier": 10, "name": "청해 전설대", "price": 0, "unlock": "later",
		"desc": "바다가 허락한 대.",
		"cast": 1.0, "strength": 0.76, "hook": 0.34},
}

const REELS := {
	"reel_1": {"tier": 1, "name": "녹슨 스피닝릴", "price": 0, "unlock": "start",
		"desc": "감을 때마다 끼익 소리가 난다.",
		"speed": 1.0, "drag": 0.0, "slack": 0.0},
	"reel_2": {"tier": 2, "name": "2500번 스피닝릴", "price": 60000, "unlock": "shop",
		"desc": "부드럽고 빨리 감긴다.",
		"speed": 1.11, "drag": 0.1, "slack": 0.16},
	"reel_3": {"tier": 3, "name": "레버브레이크릴", "price": 250000, "unlock": "shop",
		"desc": "물고기가 차고 나갈 때 줄을 풀어 줘서 잘 안 끊어진다.",
		"speed": 1.22, "drag": 0.2, "slack": 0.32},
	"reel_4": {"tier": 4, "name": "3000번 레버릴", "price": 420000, "unlock": "shop",
		"desc": "더 빨리 감기고 더 잘 버틴다.",
		"speed": 1.28, "drag": 0.24, "slack": 0.4},
	"reel_5": {"tier": 5, "name": "맛집 축하 릴", "price": 600000, "unlock": "story", "unlock_text": "동네 맛집 되기",
		"desc": "식당이 동네 맛집이 된 날 받는다.",
		"speed": 1.33, "drag": 0.28, "slack": 0.48},
	"reel_6": {"tier": 6, "name": "단골들의 선물 릴", "price": 800000, "unlock": "story", "unlock_text": "단골 여섯 명",
		"desc": "단골 여섯 명이 돈을 모아 사 줬다.",
		"speed": 1.39, "drag": 0.32, "slack": 0.56},
	"reel_7": {"tier": 7, "name": "소문난 집 레버릴", "price": 1000000, "unlock": "story", "unlock_text": "줄 서는 식당 되기",
		"desc": "줄 서는 식당이 되면 받을 수 있다.",
		"speed": 1.44, "drag": 0.36, "slack": 0.64},
	"reel_8": {"tier": 8, "name": "흑룡 레버릴", "price": 0, "unlock": "later",
		"desc": "다음 바다에서.",
		"speed": 1.5, "drag": 0.4, "slack": 0.72},
	"reel_9": {"tier": 9, "name": "홍염 레버릴", "price": 0, "unlock": "later",
		"desc": "다음 바다에서.",
		"speed": 1.55, "drag": 0.44, "slack": 0.8},
	"reel_10": {"tier": 10, "name": "청해 전설릴", "price": 0, "unlock": "later",
		"desc": "다음 바다에서.",
		"speed": 1.6, "drag": 0.48, "slack": 0.88},
}

const DEFAULT_ROD := "rod_1"
const DEFAULT_REEL := "reel_1"

## 대 몸통 그림(blank-n) 배치: 몸통 가운데 x 비율, 맨 아래 굵기(px)
const BLANK_LOOK := [
	[0.222, 38.2], [0.224, 44.7], [0.227, 46.1], [0.225, 46.5], [0.225, 42.9],
	[0.224, 48.1], [0.23, 47.1], [0.231, 46.8], [0.231, 51.7], [0.226, 51.4],
]
## 밑동+릴 그림(butt-n) 배치: 맨 위 대 몸통 가운데 x 비율, 대 몸통 굵기(px)
const BUTT_LOOK := [
	[0.766, 30], [0.756, 30], [0.742, 31], [0.734, 31], [0.749, 31],
	[0.76, 31], [0.748, 31], [0.737, 32], [0.733, 31], [0.757, 31],
]
## 밑동 그림에서 손으로 쥐는 곳 (세로 비율). 릴 다리 바로 아래 코르크 윗부분
const BUTT_GRIP_Y := 0.74


static func rod(id: String) -> Dictionary:
	return RODS.get(id, RODS[DEFAULT_ROD])


static func reel(id: String) -> Dictionary:
	return REELS.get(id, REELS[DEFAULT_REEL])


## 낚싯대나 릴 상점 진열 목록 (단계 순서). kind: "rod", "reel"
static func shop_list(kind: String) -> Array:
	var table: Dictionary = RODS if kind == "rod" else REELS
	var ids: Array = []
	for id in table:
		if table[id].unlock in ["shop", "story"]:
			ids.append(id)
	ids.sort_custom(func(a, b): return table[a].tier < table[b].tier)
	return ids


## 낚시 규칙에 장비 능력치를 넣는다.
static func apply(logic: FishingLogic, rod_id: String, reel_id: String) -> void:
	var r := rod(rod_id)
	var l := reel(reel_id)
	logic.cast_mult = r.cast
	logic.hook_bonus = r.hook
	logic.reel_mult = l.speed
	logic.slack_bonus = l.slack
	logic.tension_mult = clampf((1.0 - l.drag) * (1.0 - r.strength * 0.45), 0.35, 1.0)


static func icon_art(item: Dictionary) -> String:
	return "gear_icon/%s-%d" % ["rod" if item.has("cast") else "reel", item.tier]


static func blank_art(rod_id: String) -> String:
	return "gear_icon/blank-%d" % rod(rod_id).tier


static func butt_art(reel_id: String) -> String:
	return "gear_icon/butt-%d" % reel(reel_id).tier


static func float_art(rod_id: String) -> String:
	return "gear_icon/float-%d" % rod(rod_id).tier
