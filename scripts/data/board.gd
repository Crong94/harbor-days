class_name Board
extends RefCounted
## 마을회관 의뢰 게시판 (2026-11-18, 기획서 챕터 3 "마을회관 게시판에 의뢰가 붙기 시작하면서")
##
## - 이장 정태식을 경자상회에서 처음 만나면(Story taesik_first) flags.hall_open이 켜지고 회관이 열린다
## - 날마다 의뢰가 한 장(가끔 두 장) 붙는다. 붙은 날부터 DAYS일 동안 남는다. 같은 날짜는 언제나 같은 의뢰
## - 의뢰: 생선 몇 마리(아이스박스에서, 크기는 상관없이 상하기 직전 것부터) 또는 텃밭 채소와 달걀(produce)
## - 회관에 맡기면 이장이 전해 준다. 보상은 돈과 평판. 갖다준 의뢰는 flags["bd_<id>"]
## 장면이 아닌 규칙만 담아 헤드리스로 시험한다.

const DAYS := 3
const REP := 2
## 보상 = 그 물건 값 × 이 배수 (생선은 생선 값, 채소는 곁들임 값 bonus. 그냥 팔거나 접시에 얹는 것보다 조금 낫게)
const FISH_RATE := 1.3
const PRODUCE_RATE := 2.5
const MIN_REWARD := 3000
## 달걀 한 알 값 (CropDB에 없어서 따로)
const EGG_VALUE := 800

## who: 게시판에 적는 이름. lines: 쪽지 글 (%s 자리에 "볼락 두 마리" 같은 물건)
const PEOPLE := [
	{"who": "최순덕", "met": "met_sundeok", "lines": ["제사상에 올릴 %s 구해 줄 사람.", "손주 오는데 %s 좀 있으면 좋겠네."]},
	{"who": "박만수", "met": "met_mansu", "lines": ["%s. 술안주로 쓸 거다.", "%s 구함. 값은 넉넉히 쳐 준다."]},
	{"who": "이준호", "met": "met_junho", "lines": ["가게 손님 맛보기용 %s 구해요!", "단골 아저씨가 %s 찾으세요. 부탁드려요."]},
	{"who": "경자상회", "met": "met_kyungja", "lines": ["%s 가져오면 외상 하나 지워 줌.", "가게에 놓고 팔 %s 구합니다."]},
	{"who": "복자네 밥집", "met": "met_bokja", "lines": ["점심 반찬에 쓸 %s 구해요.", "%s 급하게 필요해요. 복자."]},
	{"who": "오용팔", "met": "met_yongpal", "lines": ["도시 식당에서 %s 찾는다. 회관에 맡겨 줘.", "%s 모아 보내야 해서. 용팔."]},
	{"who": "정태식 이장", "met": "", "lines": ["경로당 잔치에 쓸 %s 구합니다.", "마을 회의 날 나눠 먹을 %s 부탁드립니다."]},
]

## [종류, id, 몇 개]. 달걀은 닭장이 열려야 나온다
const FISH_POOL := [["bolak", 2], ["bolak", 3], ["mangsang", 2], ["noraemi", 1], ["noraemi", 2], ["hakgongchi", 2], ["ssombaengi", 1]]
const PRODUCE_POOL := [["daepa", 3], ["kkaennip", 4], ["mu", 2], ["gochu", 3], ["baechu", 1], ["maneul", 3], ["egg", 3], ["egg", 4]]
const COUNT_WORD := ["", "한", "두", "세", "네", "다섯", "여섯"]


## 그날 새로 붙는 의뢰들 (1~2장). 회관이 열리기 전 날짜도 같은 규칙으로 만든다
## flags를 주면 아직 만나지 않은 사람 자리는 이장이 대신 붙인다 (모르는 사람이 갑자기 부탁하지 않게, 11-19)
static func posted_on(day: int, coop_open := false, flags = null) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("게시판-%d" % day)
	var n := 2 if rng.randf() < 0.3 else 1
	var out := []
	var used_people := []
	for i in n:
		var pi := rng.randi() % PEOPLE.size()
		if pi in used_people:
			pi = (pi + 1) % PEOPLE.size()
		used_people.append(pi)
		var person: Dictionary = PEOPLE[pi]
		if flags != null and not str(person.met).is_empty() and not flags.get(person.met, false):
			person = PEOPLE[PEOPLE.size() - 1] # 정태식 이장
		var produce := rng.randf() < 0.4
		var pick: Array
		if produce:
			var pool := PRODUCE_POOL.filter(func(p): return coop_open or p[0] != "egg")
			pick = pool[rng.randi() % pool.size()]
		else:
			# 어제, 그제 붙은 생선과 겹치지 않게 날짜만큼 밀어서 고른다
			var k: int = rng.randi() % 3 + day * 3 + i * 2
			pick = FISH_POOL[k % FISH_POOL.size()]
			# 철이 아닌 고기(여름 학공치)는 다음 칸으로 넘긴다
			var month := int(Calendar.date(day).month)
			for step in FISH_POOL.size():
				pick = FISH_POOL[(k + step) % FISH_POOL.size()]
				if FishDB.season_mult(pick[0], month) >= 0.3:
					break
		var kind := "produce" if produce else "fish"
		var item: String = pick[0]
		var count: int = pick[1]
		var line: String = person.lines[rng.randi() % person.lines.size()]
		out.append({
			"id": "%d-%d" % [day, i],
			"day": day,
			"who": person.who,
			"kind": kind,
			"item": item,
			"count": count,
			"text": line % thing_text(kind, item, count),
			"reward": reward_of(kind, item, count),
		})
	return out


## 오늘 게시판에 붙어 있는 의뢰 (아직 안 갖다준 것, 오래된 것부터)
static func open_on(today: int, flags: Dictionary) -> Array:
	var out := []
	for d in range(today - DAYS + 1, today + 1):
		if d < 2:
			continue
		for p in posted_on(d, flags.get("coop_open", false), flags):
			if not flags.get("bd_" + p.id, false):
				out.append(p)
	return out


## 며칠 남았는지 (오늘이 마지막 날이면 0)
static func days_left(p: Dictionary, today: int) -> int:
	return int(p.day) + DAYS - 1 - today


static func item_name(kind: String, item: String) -> String:
	if kind == "fish":
		return FishDB.get_fish(item).name
	if item == "egg":
		return "달걀"
	return CropDB.crop(item).name


## "볼락 두 마리", "대파 세 단", "달걀 네 알"
static func thing_text(kind: String, item: String, count: int) -> String:
	var unit := "마리" if kind == "fish" else ("알" if item == "egg" else "개")
	if kind == "produce" and item in ["daepa", "kkaennip"]:
		unit = "단" if item == "daepa" else "묶음"
	var word: String = COUNT_WORD[count] if count < COUNT_WORD.size() else str(count)
	return "%s %s %s" % [item_name(kind, item), word, unit]


static func reward_of(kind: String, item: String, count: int) -> int:
	var each: float
	if kind == "fish":
		var f := FishDB.get_fish(item)
		each = FishDB.value_of(item, lerpf(f.min_cm, f.max_cm, 0.5)) * FISH_RATE
	elif item == "egg":
		each = EGG_VALUE * PRODUCE_RATE
	else:
		each = int(CropDB.crop(item).bonus) * PRODUCE_RATE
	return maxi(MIN_REWARD, int(roundf(each * count / 500.0) * 500.0))


## 가진 수 (생선은 아이스박스에서 그 어종 수)
static func have(p: Dictionary, inventory: Array, produce: Dictionary) -> int:
	if p.kind == "fish":
		return inventory.filter(func(e): return e.id == p.item).size()
	return int(produce.get(p.item, 0))


static func can_deliver(p: Dictionary, inventory: Array, produce: Dictionary) -> bool:
	return have(p, inventory, produce) >= int(p.count)


## 갖다준다: 물건을 빼고 보상을 준다. gs는 GameState(또는 같은 모양). 성공하면 받은 돈, 못 하면 0
static func deliver(p: Dictionary, gs) -> int:
	if gs.flags.get("bd_" + p.id, false) or not can_deliver(p, gs.inventory, gs.produce):
		return 0
	if p.kind == "fish":
		# 오래된(상하기 직전) 것부터 낸다
		var mine: Array = gs.inventory.filter(func(e): return e.id == p.item)
		mine.sort_custom(func(a, b): return int(a.get("day", 0)) < int(b.get("day", 0)))
		for k in int(p.count):
			gs.inventory.erase(mine[k])
	else:
		gs.produce[p.item] = int(gs.produce[p.item]) - int(p.count)
		if int(gs.produce[p.item]) <= 0:
			gs.produce.erase(p.item)
	gs.flags["bd_" + p.id] = true
	var got := int(p.reward)
	if gs.flags.get("app_taesik_done", false):
		got = int(roundf(got * AppWork.BOARD_BONUS / 500.0) * 500.0) # 이장님 게시판 앱 (AppWork)
	gs.earn(got)
	gs.reputation += REP
	return got
