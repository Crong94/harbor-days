class_name Orders
extends RefCounted
## 식당 주문서: 날마다 마을 사람 한 명이 원하는 물고기를 부탁한다.
## 낚시 화면 위쪽에 쪽지로 보이고, 조건에 맞는 물고기를 잡으면 칸이 찬다.
## 다 채우면 보상(돈)을 받는다. 같은 날짜는 언제나 같은 주문이 나온다.
##
## 대사는 템플릿({player}, {shop}). 화면에 띄울 때 GameState.line()으로 바꾼다.
## 맥락 (11-19 사용자: 퀘스트가 갑자기 생긴다): 첫 손님 순덕 할머니가 "먹고 싶은 거 생기면 가게 문에 쪽지 붙여 둘게"라고
## 말하고 간 다음 날부터 쪽지가 붙는다. 만난 사람(met 플래그)만 주문을 낸다. 아직 모르는 사람이 갑자기 주문하지 않게.

## call: 이야기 글에서 부르는 이름. react: 저녁에 직접 구운 접시를 먹고 하는 말 [별 3, 2, 1]
const CUSTOMERS := [
	{"name": "최순덕", "call": "순덕 할머니", "met": "met_sundeok", "lines": [
		"{player|이/가} 굽는 %s 한번 더 먹고 싶네.",
		"우리 영감이 %s 좋아했지. 몇 마리만 부탁해.",
	], "react": [
		"아이고, 이거 제대로네. 또 올게.",
		"먹을 만하네. 다음엔 더 잘하겄지.",
		"음... 그래도 따뜻한 밥은 고맙네.",
	]},
	{"name": "박만수", "call": "만수 할아버지", "met": "met_mansu", "lines": [
		"%s 잡아 와 봐라. 실력 좀 보자.",
		"오늘 물때면 %s 나온다. 놓치지 말고.",
	], "react": [
		"...잘 구웠네. 손이 좀 늘었구먼.",
		"먹을 만하다. 불 앞에서 조금 더 참아 봐라.",
		"고기는 좋은데 굽는 게 아직이네.",
	]},
	{"name": "이준호", "call": "준호", "met": "met_junho", "lines": [
		"형 %s 잡으면 사진 좀 찍어 줘요. 가게에 붙이게.",
		"손님들이 %s 어디서 잡냐고 물어봐서요. 몇 마리만요.",
	], "react": [
		"형 이거 진짜 맛있어요. 가게에 소문낼게요!",
		"오, 괜찮은데요? 다음엔 더 기대할게요.",
		"음... 형, 그래도 잘 먹었어요.",
	]},
	{"name": "문경자", "call": "경자 할머니", "met": "met_kyungja", "lines": [
		"가게 보느라 장을 못 봤어. %s 좀 구해 줘.",
		"오늘은 %s 먹고 싶네. 값은 장부에 달지 말고 바로 줄게.",
	], "react": [
		"맛있다. 이건 안 잊어버리게 장부에 적어 놔야겠네.",
		"괜찮네. 나이 드니까 이만하면 됐어.",
		"음... 그래도 애썼다.",
	]},
	{"name": "김복자", "call": "복자 사장님", "met": "met_bokja", "lines": [
		"우리 집에 %s 떨어졌다. 니가 좀 잡아 온나.",
		"니 실력 좀 보자. %s 실한 걸로.",
	], "react": [
		"...이거 누가 했노. 세라가? 잘하네.",
		"나쁘지 않네. 삼십 년 하믄 나만큼 하겠다.",
		"쯧. 다음에 우리 집 와서 좀 배우고 가라.",
	]},
	{"name": "오용팔", "call": "용팔 아저씨", "met": "met_yongpal", "lines": [
		"경매에는 안 올릴 거고 내가 먹을 %s 좀 부탁하자.",
		"요새 %s 값이 좋다. 근데 오늘은 팔지 말고 내한테 줘.",
	], "react": [
		"캬. 이 정도면 경매에 올려도 첫 손에 나간다.",
		"음 좋네. 물건이 좋으니까.",
		"물건은 좋았는데 내 입이 까다롭나 보다.",
	]},
	{"name": "정태식", "call": "이장님", "met": "met_taesik", "lines": [
		"저기 %s 좀 부탁드려도 될까요? 회의가 길어져서 밥때를 놓쳤어요.",
		"군청에서 손님이 오셨는데 %s 자랑을 좀 했거든요.",
	], "react": [
		"아이고 이거 서류에 도장 찍어 드리고 싶네요.",
		"잘 먹었습니다. 속이 든든해요.",
		"어... 네. 잘 먹었습니다.",
	]},
	{"name": "김해솔", "call": "해솔이", "met": "met_haesol", "lines": [
		"아저씨 %s 어떻게 생겼어요? 잡으면 저 보여 주세요!",
		"할머니가 %s 먹으면 키 큰대요. 진짜예요?",
	], "react": [
		"우와! 우리 할머니 것보다 맛있어요. 비밀이에요!",
		"맛있어요. 가시만 없으면 더 좋겠어요.",
		"음... 아저씨 저 사탕 하나 먹어도 돼요?",
	]},
]


## 손님 한 명의 정보 (이름으로 찾는다). 없으면 빈 Dictionary
static func customer(name: String) -> Dictionary:
	for c in CUSTOMERS:
		if c.name == name:
			return c
	return {}


## 이야기 글에서 부르는 이름. 예: "순덕 할머니"
static func call_name(name: String) -> String:
	return customer(name).get("call", name)

## 주문에 나올 수 있는 어종과 몇 마리
const POOL := [
	["bolak", 2], ["bolak", 3], ["noraemi", 2],
	["ssombaengi", 2], ["ureok", 1], ["hakgongchi", 2],
]


## 주문을 낼 수 있는 손님들. flags가 null이면 모두 (도구, 옛 테스트)
static func customers_met(flags) -> Array:
	if flags == null:
		return CUSTOMERS
	return CUSTOMERS.filter(func(c): return flags.get(c.met, false))


## 그날의 주문. 첫날(튜토리얼)은 주문이 없다. flags를 주면 만난 사람 가운데서만 고른다
static func of(day: int, flags = null) -> Dictionary:
	if day <= 1:
		return {}
	var who := customers_met(flags)
	if who.is_empty():
		return {}
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("주문-%d" % day)
	var c: Dictionary = who[rng.randi() % who.size()]
	# 철이 아닌 고기(여름 학공치)는 주문하지 않는다
	var month := int(Calendar.date(day).month)
	var pool := POOL.filter(func(q): return FishDB.season_mult(q[0], month) >= 0.3)
	var p: Array = pool[rng.randi() % pool.size()]
	var fish: String = p[0]
	var f := FishDB.get_fish(fish)
	# 너무 작은 건 안 받는다: 최소 크기와 평균 사이
	var min_cm := snappedf(lerpf(f.min_cm, f.max_cm, 0.25), 1.0)
	var line: String = c.lines[rng.randi() % c.lines.size()] % f.name
	return {
		"customer": c.name,
		"fish": fish,
		"count": p[1],
		"min_cm": min_cm,
		"reward": int(FishDB.value_of(fish, lerpf(f.min_cm, f.max_cm, 0.5)) * p[1] / 1000.0) * 1000,
		"line": line,
	}


## 이 물고기가 주문 조건에 맞는지
static func matches(order: Dictionary, fish_id: String, size_cm: float) -> bool:
	return not order.is_empty() and order.fish == fish_id and size_cm >= order.min_cm


## 쪽지에 쓰는 짧은 조건. 예: "볼락 20cm 이상"
static func goal_text(order: Dictionary) -> String:
	if order.is_empty():
		return ""
	return "%s %dcm 이상" % [FishDB.get_fish(order.fish).name, int(order.min_cm)]
