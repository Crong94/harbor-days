class_name Coop
extends RefCounted
## 텃밭 아래 닭장과 순덕 할머니 부탁. 설계는 docs/텃밭_설계.md
##
## 닭장은 처음엔 잠겨 있다(flags.coop_open). 순덕 할머니 부탁 세 가지를 들어주면 할머니가 병아리 두 마리와 모이를 주고 닭장이 열린다.
## 닭: 모이를 준 날 밤마다 닭 한 마리가 달걀 하나를 낳는다. 달걀은 닭장에 쌓였다가 주우면 GameState.produce["egg"]로 간다.
## 부탁은 하루에 하나씩만 들어줄 수 있다 (들어준 날에는 다음 부탁이 다음 날 나온다).

const FEED_PRICE := 3000 # 모이 한 포대 (경자상회 배달)
const FEED_PACK := 10 # 한 포대로 줄 수 있는 횟수
const EGG_MAX := 6 # 닭장에 쌓일 수 있는 달걀 수 (줍지 않으면 더 낳지 않는다)
const GIFT_HENS := 2
const GIFT_FEED := 10

## 순덕 할머니 부탁. need.kind: fish(id가 비면 아무 생선), produce(텃밭 채소)
const QUESTS := [
	{
		"title": "저녁거리 생선",
		"need": {"kind": "fish", "id": "", "count": 1},
		"ask": [
			{"speaker": "순덕", "face": "smile", "text": "아이고 {player|이/가} 왔구먼. 마침 잘 왔네."},
			{"speaker": "순덕", "text": "오늘 저녁 끓일 생선이 하나도 없어. 아무 거나 한 마리만 갖다 줄 수 있겄어?"},
		],
		"thanks": [
			{"speaker": "순덕", "face": "smile", "text": "어이구 실하다. 이걸로 맑은탕 끓이면 되겄네."},
			{"speaker": "순덕", "face": "smile", "text": "고마워. 내일 또 놀러 와."},
		],
	},
	{
		"title": "국에 넣을 대파",
		"need": {"kind": "produce", "id": "daepa", "count": 2},
		"ask": [
			{"speaker": "순덕", "text": "국을 끓이려는데 대파가 똑 떨어졌어."},
			{"speaker": "순덕", "text": "집 옆 텃밭에 대파 좀 심어서 두 단만 갖다 줄 수 있겄어?"},
		],
		"thanks": [
			{"speaker": "순덕", "face": "smile", "text": "직접 키운 거여? 향이 좋네."},
			{"speaker": "순덕", "face": "sad", "text": "그 텃밭이 원래 우리 영감이 일구던 데여. 다시 파릇해지니 보기 좋구먼."},
		],
	},
	{
		"title": "제사상에 올릴 볼락",
		"need": {"kind": "fish", "id": "bolak", "count": 2},
		"ask": [
			{"speaker": "순덕", "face": "sad", "text": "모레가 우리 영감 제사여."},
			{"speaker": "순덕", "face": "sad", "text": "그 양반이 볼락구이를 그렇게 좋아했어. 볼락 두 마리만 구해 줄 수 있겄어?"},
		],
		"thanks": [
			{"speaker": "순덕", "face": "smile", "text": "이렇게 큰 걸로 잡아 왔어? 영감이 보면 좋아하겄다."},
		],
	},
]

## 마지막 부탁을 들어준 뒤 이어지는 장면 (병아리 선물)
const GIFT_LINES := [
	{"speaker": "순덕", "text": "가만 있어 봐. 줄 게 있어."},
	{"speaker": "", "text": "할머니가 마루 밑에서 종이 상자를 꺼낸다. 안에서 삐약삐약 소리가 난다."},
	{"speaker": "{player}", "face": "smile", "text": "병아리네요?"},
	{"speaker": "순덕", "text": "옆 동네 사돈이 줬는디 나는 이제 키울 기운이 없어."},
	{"speaker": "순덕", "text": "텃밭 밑에 빈 닭장 있지? 그것도 영감이 지은 거여. 좀 손보면 쓸 만할 거구먼."},
	{"speaker": "", "text": "둘이서 녹슨 철망을 갈고 지붕에 새 판자를 덧댔다."},
	{"speaker": "순덕", "text": "모이는 한 포대 줄 테니까 떨어지면 경자네서 시켜. 모이 준 날은 꼭 알을 낳아."},
	{"speaker": "순덕", "face": "smile", "text": "{player|아/야}. 이 마을에 와 줘서 고마워."},
]


## 지금 받을 수 있는 부탁 번호. 다 들어줬거나 오늘 이미 하나 들어줬으면 -1
static func current_quest(gs: Object) -> int:
	if gs.sundeok_quest >= QUESTS.size():
		return -1
	if gs.sundeok_quest > 0 and gs.sundeok_quest_day == gs.day:
		return -1
	return gs.sundeok_quest


## 부탁한 것을 몇 개 가지고 있는지
static func have_count(gs: Object, need: Dictionary) -> int:
	if need.kind == "produce":
		return int(gs.produce.get(need.id, 0))
	var n := 0
	for e in gs.inventory:
		if str(need.id).is_empty() or e.id == need.id:
			n += 1
	return n


## 부탁한 것을 드린다. 문제가 없으면 빈 문자열, 있으면 안내 문구. 마지막 부탁이면 닭장이 열린다
static func give(gs: Object) -> String:
	var q := current_quest(gs)
	if q < 0:
		return "지금은 부탁이 없어요."
	var need: Dictionary = QUESTS[q].need
	if have_count(gs, need) < int(need.count):
		return "아직 모자라요."
	if need.kind == "produce":
		gs.produce[need.id] = int(gs.produce[need.id]) - int(need.count)
	else:
		for i in int(need.count):
			if str(need.id).is_empty():
				gs.inventory.remove_at(0)
			else:
				gs.take_fish(need.id)
	gs.sundeok_quest += 1
	gs.sundeok_quest_day = gs.day
	if gs.sundeok_quest >= QUESTS.size():
		open_coop(gs)
	return ""


## 할머니 선물: 병아리 두 마리와 모이 한 포대, 닭장 열림
static func open_coop(gs: Object) -> void:
	gs.flags["coop_open"] = true
	gs.hens = maxi(gs.hens, GIFT_HENS)
	gs.chicken_feed += GIFT_FEED


## 모이를 준다. 문제가 없으면 빈 문자열
static func feed(gs: Object) -> String:
	if gs.hens <= 0:
		return "닭장이 비어 있어요."
	if gs.hens_fed_today:
		return "오늘은 벌써 모이를 줬어요."
	if gs.chicken_feed <= 0:
		return "모이가 다 떨어졌어요."
	gs.chicken_feed -= 1
	gs.hens_fed_today = true
	return ""


## 모이 한 포대를 산다 (경자상회 배달)
static func buy_feed(gs: Object) -> String:
	if gs.money < FEED_PRICE:
		return "돈이 모자라요."
	gs.spend(FEED_PRICE)
	gs.chicken_feed += FEED_PACK
	return ""


## 닭장에 쌓인 달걀을 줍는다. 주운 개수를 돌려준다
static func collect(gs: Object) -> int:
	var n: int = gs.coop_eggs
	if n > 0:
		gs.produce["egg"] = int(gs.produce.get("egg", 0)) + n
		gs.coop_eggs = 0
	return n


## 밤사이: 모이를 먹은 닭은 알을 하나씩 낳는다
static func next_day(gs: Object) -> void:
	if gs.hens_fed_today:
		gs.coop_eggs = mini(EGG_MAX, gs.coop_eggs + gs.hens)
	gs.hens_fed_today = false
