class_name Places
extends RefCounted
## 빈 장소 넷의 낮 할 일 (2026-11-25 사용자 결정). 모두 하루 한 번. 화면은 scenes/places/*.tscn
##   전망대: 망원경으로 내일과 모레 바다 보기 / 분교: 해솔이와 물고기 이름 맞히기
##   민박: 조식 생선 납품(다음 날 외지 손님 한 명 더) / 연구소: 잡은 고기 표본 기록
## 보관: GameState.specimens {어종: 가장 큰 cm}, flags place_<id> = 마지막으로 한 날
## 장면이 아닌 규칙만 담아 헤드리스로 시험한다.

const MINUTES := {"lookout": 30, "school": 60, "guesthouse": 20, "lab": 30}


static func done_today(gs: Object, id: String) -> bool:
	return int(gs.flags.get("place_" + id, 0)) == int(gs.day)


static func mark(gs: Object, id: String) -> void:
	gs.flags["place_" + id] = int(gs.day)
	gs.time_minutes += int(MINUTES[id])


## 지금 그곳의 할 일이 열려 있나
static func is_open(gs: Object, id: String, minutes: int) -> bool:
	match id:
		"lookout":
			return minutes < 19 * 60 # 어두워지면 안 보인다
		"school":
			return gs.flags.get("met_haesol", false) and minutes >= 14 * 60 and minutes < 19 * 60
		"guesthouse":
			return gs.flags.get("inn_open", false) and minutes < 21 * 60
		"lab":
			return gs.flags.get("lab_started", false) and minutes >= 9 * 60 and minutes < 19 * 60
	return false


## 오늘 아직 안 했고 지금 할 수 있는 곳들 (하루 서랍)
static func left_today(gs: Object, minutes: int) -> Array:
	return MINUTES.keys().filter(func(id): return Locations.is_unlocked(id, gs.flags) and not done_today(gs, id) and is_open(gs, id, minutes))


static func _add_friend(gs: Object, name: String, n: int) -> void:
	gs.friendship[name] = clampi(int(gs.friendship.get(name, 0)) + n, 0, Friends.HEART * Friends.MAX_HEARTS)


static func _shuffle(a: Array, rng: RandomNumberGenerator) -> void:
	for i in range(a.size() - 1, 0, -1):
		var j := rng.randi() % (i + 1)
		var t = a[i]
		a[i] = a[j]
		a[j] = t


# ─── 전망대 ─────────────────────────────────────────

static func _fish_names(info: Dictionary, brightness: float) -> String:
	return ", ".join(PackedStringArray(SeaDay.best_fish(info, brightness, 2).map(func(id): return FishDB.get_fish(id).name)))


## 내일과 모레 바다 [{"title", "lines"}]
static func forecast(day: int) -> Array:
	var out := []
	for k in [1, 2]:
		var d: int = day + k
		var info := SeaDay.of(d)
		var lines := ["%s · %s%s" % [info.weather_name, info.tide, " · 물때 좋음" if info.tide_good else ""]]
		if not str(info.school).is_empty():
			lines.append("%s 떼가 먼바다에서 들어오고 있어요!" % FishDB.get_fish(info.school).name)
		lines.append("낮에 잘 물 고기: %s" % _fish_names(info, 1.0))
		lines.append("어두울 때 잘 물 고기: %s" % _fish_names(info, 0.0))
		lines.append(Tide.times_text(d))
		out.append({"title": ("내일 " if k == 1 else "모레 ") + Calendar.short_text(d), "lines": lines})
	return out


# ─── 분교 ───────────────────────────────────────────

const QUIZ := 3
const QUIZ_CHOICES := 4
const QUIZ_FRIEND := 2
const QUIZ_GIFTS := ["egg", "daepa", "mu", "gochu", "kkaennip"]


## 오늘 문제 [{"fish", "kind": "art"(그림) 또는 "fact"(버릇), "choices": [어종 id...]}]
static func quiz(day: int) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("분교퀴즈-%d" % day)
	var ids: Array = FishDB.FISH.keys()
	_shuffle(ids, rng)
	var out := []
	for i in QUIZ:
		var f: String = ids[i]
		var others: Array = FishDB.FISH.keys().filter(func(x): return x != f)
		_shuffle(others, rng)
		var ch: Array = others.slice(0, QUIZ_CHOICES - 1)
		ch.append(f)
		_shuffle(ch, rng)
		out.append({"fish": f, "kind": "fact" if i == QUIZ - 1 else "art", "choices": ch})
	return out


## 마지막 문제의 힌트 (도감 요령). 물고기 이름은 들어가지 않는다
static func quiz_fact(fish: String) -> String:
	var parts := PackedStringArray()
	for r in DexInfo.facts(fish):
		parts.append(("%s: %s" % [r[0], r[1]]).replace(str(FishDB.get_fish(fish).name), "나"))
	return "\n".join(parts)


## 수업을 마친다. 다 맞히면 학교 텃밭에서 난 것 하나. 돌려주는 값: 받은 재료 id 또는 ""
static func finish_quiz(gs: Object, right: int) -> String:
	if done_today(gs, "school"):
		return ""
	mark(gs, "school")
	_add_friend(gs, "김해솔", right * QUIZ_FRIEND)
	if right < QUIZ:
		return ""
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("분교선물-%d" % int(gs.day))
	var id: String = QUIZ_GIFTS[rng.randi() % QUIZ_GIFTS.size()]
	gs.produce[id] = int(gs.produce.get(id, 0)) + 1
	return id


# ─── 민박 ───────────────────────────────────────────

const INN_RATE := 0.65 # 생선 값의 배수 (수산시장 0.4, 읍내 0.5)
const INN_GUEST := 1


## 오늘 조식에 필요한 마리 수 (날짜로 정해진다)
static func inn_count(day: int) -> int:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("민박조식-%d" % day)
	return rng.randi_range(2, 3)


## 낼 생선: 비싼 생선은 빼고 값싼 것부터
static func inn_fish(gs: Object) -> Array:
	var list: Array = gs.inventory.filter(func(e): return not DayFlow.too_pricey(e.id, e.size))
	list.sort_custom(func(a, b): return FishDB.value_of(a.id, a.size) < FishDB.value_of(b.id, b.size))
	return list.slice(0, inn_count(int(gs.day)))


static func inn_pay(list: Array) -> int:
	var v := 0
	for e in list:
		v += FishDB.value_of(e.id, e.size)
	return int(roundf(v * INN_RATE / 100.0) * 100.0)


## 조식 생선을 낸다. 받은 돈, 못 내면 0
static func inn_deliver(gs: Object) -> int:
	var list := inn_fish(gs)
	if done_today(gs, "guesthouse") or list.size() < inn_count(int(gs.day)):
		return 0
	var pay := inn_pay(list)
	for e in list:
		gs.inventory.erase(e)
	gs.earn(pay)
	mark(gs, "guesthouse")
	_add_friend(gs, "윤미자", 3)
	return pay


## 어제 조식을 냈으면 오늘 저녁에 민박 손님이 한 명 더 온다
static func inn_guests(flags: Dictionary, day: int) -> int:
	return INN_GUEST if day > 1 and int(flags.get("place_guesthouse", 0)) == day - 1 else 0


# ─── 연구소 ─────────────────────────────────────────

const PAY_NEW := {"common": 8000, "rare": 15000, "legend": 40000}
const PAY_RECORD := 3000
const RECORD_STEP := 2.0 # 이만큼 더 커야 기록을 새로 쓴다
## [어종 수, 연구비, 평판]
const STAGES := [[3, 20000, 2], [5, 50000, 4], [8, 150000, 10]]


## 이 고기를 기록하면 받는 연구비 (기록할 것이 없으면 0)
static func specimen_pay(gs: Object, e: Dictionary) -> int:
	if not gs.specimens.has(e.id):
		return int(PAY_NEW.get(FishDB.get_fish(e.id).rarity, 8000))
	return PAY_RECORD if float(e.size) >= float(gs.specimens[e.id]) + RECORD_STEP else 0


## 보여 줄 수 있는 고기 (아이스박스와 수조, 어종마다 가장 큰 것 하나). 연구비 큰 순서
static func specimen_choices(gs: Object) -> Array:
	var best := {}
	for e in gs.inventory + gs.tank:
		if not best.has(e.id) or float(e.size) > float(best[e.id].size):
			best[e.id] = e
	var out: Array = best.values()
	out.sort_custom(func(a, b): return specimen_pay(gs, a) > specimen_pay(gs, b))
	return out


## 기록한다. {"pay", "new": 처음 보는 어종인지, "stage": 이번에 채운 단계(어종 수) 또는 0, "bonus"}. 못 하면 빈 Dictionary
static func record(gs: Object, e: Dictionary) -> Dictionary:
	var pay := specimen_pay(gs, e)
	if pay <= 0 or done_today(gs, "lab"):
		return {}
	var fresh: bool = not gs.specimens.has(e.id)
	gs.specimens[e.id] = float(e.size)
	mark(gs, "lab")
	_add_friend(gs, "한서윤", 3 if fresh else 1)
	var r := {"pay": pay, "new": fresh, "stage": 0, "bonus": 0}
	if fresh:
		for s in STAGES:
			if gs.specimens.size() == int(s[0]):
				r.stage = int(s[0])
				r.bonus = int(s[1])
				gs.reputation += int(s[2])
				gs.flags["lab_%d" % int(s[0])] = true
	gs.earn(pay + int(r.bonus))
	return r
