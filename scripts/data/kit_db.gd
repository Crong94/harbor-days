class_name KitDB
extends RefCounted
## 낚시방 도구 (2026-11-19 사용자: 여울을 참고해 쿨러, 낚싯줄, 통발, 태클박스 등을 더해 달라).
## 여울 레포 godot/data/gear.json의 tackles(쿨러)와 kits(줄, 바늘, 찌, 미끼통, 뜰채, 헤드랜턴, 의자, 장화, 통발)를 옮겼다.
## 여울은 단계가 10개(상점 1~4, 보상 5~7, 다음 지역 8~10)지만 여기는 상점 4단계만 둔다. 미끼통은 태클박스로 이름을 바꿨다.
##
## 쿨러: GameState.cooler(단계 0부터)와 icebox_size(칸 수). 0단계는 처음 가진 아이스박스
## 도구: GameState.kits {id: 단계(1부터)}. 없으면 0. 효과는 apply()로 FishingLogic에 넣는다
## 장면이 아닌 규칙만 담아 헤드리스로 시험한다.

const COOLERS := [
	{"name": "스티로폼 아이스박스", "desc": "식당 창고에 있던 것. 10마리 들어간다", "price": 0, "size": 10},
	{"name": "아이스 쿨러", "desc": "15마리. 뚜껑이 꼭 닫힌다", "price": 50000, "size": 15},
	{"name": "대형 아이스박스", "desc": "22마리. 얼음 가득", "price": 180000, "size": 22},
	{"name": "활어 쿨러", "desc": "30마리. 물이 돌아서 고기가 산다", "price": 320000, "size": 30},
]

## effect의 {0}에 단계 값. icon은 assets/art/kit/<id>.png (그림 요청 중, 없으면 빈 칸)
const KITS := [
	{"id": "line", "name": "낚싯줄", "effect": "장력이 {0}% 덜 오른다",
		"levels": [["나일론 원줄 2호", 8000, 3], ["하늘 원줄 2호", 25000, 5], ["갯바위 원줄 2.5호", 60000, 7], ["플로로 원줄 3호", 120000, 9]]},
	{"id": "hook", "name": "바늘", "effect": "줄이 느슨해도 {0}초 더 버틴다",
		"levels": [["감성돔 바늘 2호", 8000, 0.15], ["하늘 바늘 3호", 25000, 0.25], ["올리브 바늘 3호", 60000, 0.35], ["청 바늘 4호", 120000, 0.45]]},
	{"id": "float", "name": "찌", "effect": "챔질 여유가 {0}초 늘어난다",
		"levels": [["막대찌", 8000, 0.03], ["주황 구멍찌", 25000, 0.05], ["연두 구멍찌", 60000, 0.07], ["파랑 구멍찌", 120000, 0.09]]},
	{"id": "tacklebox", "name": "태클박스", "effect": "미끼 한 묶음이 {0}개 더 들어간다",
		"levels": [["작은 태클박스", 8000, 2], ["하늘 태클박스", 25000, 4], ["카키 태클박스", 60000, 6], ["파도 태클박스", 120000, 8]]},
	{"id": "net", "name": "뜰채", "effect": "남은 거리 {0}%에서 바로 떠 올린다",
		"levels": [["접이식 뜰채", 8000, 4], ["하늘 뜰채", 25000, 7], ["카키 뜰채", 60000, 10], ["청 뜰채", 120000, 13]]},
	{"id": "lamp", "name": "헤드랜턴", "effect": "밤낚시 입질이 {0}% 빨리 온다",
		"levels": [["작은 헤드랜턴", 8000, 6], ["하늘 헤드랜턴", 25000, 10], ["카키 헤드랜턴", 60000, 14], ["적색 헤드랜턴", 120000, 18]]},
	{"id": "chair", "name": "낚시 의자", "effect": "입질이 {0}% 빨리 온다",
		"levels": [["접이식 의자", 8000, 4], ["하늘 의자", 25000, 6], ["캠핑 의자", 60000, 8], ["파도 의자", 120000, 10]]},
	{"id": "boots", "name": "장화", "effect": "비 오는 날 입질이 {0}% 빨리 온다",
		"levels": [["고무 장화", 8000, 3], ["카키 장화", 25000, 5], ["남색 장화", 60000, 7], ["갯바위 장화", 120000, 9]]},
	{"id": "trap", "name": "통발", "effect": "방파제에 두면 밤새 {0}마리가 든다",
		"levels": [["대나무 통발", 8000, 1], ["나무 통발", 25000, 1], ["초록 통발", 60000, 2], ["파랑 통발", 120000, 2]]},
]

## 통발에 드는 고기 (바위틈 고기). 여울 trapPool에서 우리 어종만
const TRAP_POOL := ["noraemi", "ssombaengi", "ureok"]
## 통발 한 칸에 고기가 들 확률
const TRAP_CHANCE := 0.75


static func cooler(tier: int) -> Dictionary:
	return COOLERS[clampi(tier, 0, COOLERS.size() - 1)]


static func kit(id: String) -> Dictionary:
	for k in KITS:
		if k.id == id:
			return k
	return {}


## 가진 단계 (0 없음)
static func level(kits: Dictionary, id: String) -> int:
	return int(kits.get(id, 0))


## 지금 단계의 값 (없으면 0)
static func value(kits: Dictionary, id: String) -> float:
	var lv := level(kits, id)
	var k := kit(id)
	if lv <= 0 or k.is_empty():
		return 0.0
	return float(k.levels[mini(lv, k.levels.size()) - 1][2])


## "장력이 5% 덜 오른다"
static func effect_text(id: String, lv: int) -> String:
	var k := kit(id)
	if lv <= 0 or k.is_empty():
		return ""
	var v: float = k.levels[lv - 1][2]
	var s := str(int(v)) if is_equal_approx(v, roundf(v)) else str(v)
	return str(k.effect).replace("{0}", s)


## 다음 단계 [이름, 값, 효과 값]. 끝까지 샀으면 빈 배열
static func next_level(kits: Dictionary, id: String) -> Array:
	var k := kit(id)
	var lv := level(kits, id)
	if k.is_empty() or lv >= k.levels.size():
		return []
	return k.levels[lv]


## 도구 효과를 낚시 규칙에 넣는다 (GearDB.apply 다음에 부른다). night: 밤낚시, weather: 오늘 날씨
static func apply(logic: FishingLogic, kits: Dictionary, night: bool, weather: String) -> void:
	logic.tension_mult *= 1.0 - value(kits, "line") / 100.0
	logic.slack_bonus += value(kits, "hook")
	logic.hook_bonus += value(kits, "float")
	logic.land_at = value(kits, "net") / 100.0
	var faster := value(kits, "chair")
	if night:
		faster += value(kits, "lamp")
	if weather == "rain":
		faster += value(kits, "boots")
	logic.bite_mult *= 1.0 + faster / 100.0


## 밤새 통발에 든 고기. 이미 든 고기(waiting)가 있으면 그만큼 자리가 없다. 새로 든 것만 돌려준다 [{id, size}]
static func trap_night(kits: Dictionary, waiting: int, day: int) -> Array:
	var n := int(value(kits, "trap")) - waiting
	var out := []
	if n <= 0:
		return out
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("통발-%d" % day)
	for i in n:
		if rng.randf() < TRAP_CHANCE:
			var id: String = TRAP_POOL[rng.randi() % TRAP_POOL.size()]
			out.append({"id": id, "size": FishDB.roll_size(rng, id)})
	return out
