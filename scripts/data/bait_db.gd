class_name BaitDB
extends RefCounted
## 미끼. 그림은 바다 한 접시 장비 아이콘 assets/art/gear_icon/bait-N.png
## likes: 이 미끼를 특히 좋아하는 어종 (FishDB id). 좋아하면 출현 가중치 LIKE_MULT배
## wait: 입질까지 기다리는 시간 배율 (작을수록 빨리 문다)
## amount: 한 번 사면 몇 번 쓰는지. 크릴은 창고에 잔뜩 있어서 끝이 없다(-1)

const LIKE_MULT := 2.4

const BAITS := {
	"krill": {
		"name": "크릴", "price": 0, "amount": -1, "wait": 1.0, "icon": "bait-8",
		"likes": [],
		"desc": "무엇이든 조금씩 무는 기본 미끼. 창고에 한 상자 있다.",
	},
	"worm": {
		"name": "청갯지렁이", "price": 4000, "amount": 10, "wait": 0.9, "icon": "bait-1",
		"likes": ["bolak", "noraemi", "ureok"],
		"desc": "꿈틀거려서 바위 물고기들이 못 참는다.",
	},
	"shrimp": {
		"name": "생새우", "price": 6000, "amount": 8, "wait": 1.0, "icon": "bait-2",
		"likes": ["gamseongdom", "bolak"],
		"desc": "비싸지만 큰 고기가 좋아하는 미끼. 감성돔 꾼들이 쓴다.",
	},
	"squid": {
		"name": "오징어살", "price": 5000, "amount": 10, "wait": 1.05, "icon": "bait-4",
		"likes": ["ssombaengi", "ureok"],
		"desc": "질겨서 잘 안 떨어진다. 바닥 고기들이 좋아한다.",
	},
	"paste": {
		"name": "떡밥", "price": 3000, "amount": 12, "wait": 0.85, "icon": "bait-7",
		"likes": ["hakgongchi", "mangsang"],
		"desc": "물에 풀려서 떼고기를 모은다. 학공치와 망상어가 잘 모인다.",
	},
}

const DEFAULT := "krill"
## 상점에 진열하는 순서
const ORDER := ["krill", "worm", "shrimp", "squid", "paste"]


static func bait(id: String) -> Dictionary:
	return BAITS.get(id, BAITS[DEFAULT])


static func like_mult(bait_id: String, fish_id: String) -> float:
	return LIKE_MULT if fish_id in bait(bait_id).likes else 1.0


static func icon_art(id: String) -> String:
	return "gear_icon/" + bait(id).icon


## 이 미끼를 좋아하는 어종 이름 목록 (상점, 미끼 고르기 안내용)
static func liked_names(id: String) -> String:
	var names: Array = []
	for f in bait(id).likes:
		names.append(FishDB.get_fish(f).name)
	return ", ".join(PackedStringArray(names)) if not names.is_empty() else "골고루"
