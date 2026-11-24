class_name Friends
extends RefCounted
## 선물과 친밀도 (2026-11-19). 기획서 2.5 "친밀도별 호칭 변화"의 첫 단계.
##
## - 마을 사람이 있는 곳에 가면 하루 한 번 선물을 줄 수 있다 (생선, 텃밭 채소, 달걀, 갯벌 것)
## - 아주 좋아하는 것 LOVE, 좋아하는 것 LIKE, 그 밖 BASE만큼 친밀도가 오른다. HEART마다 하트 하나, 최대 MAX_HEARTS
## - 하트가 오를 때 한마디를 하고, 정해진 하트에서 요리법을 알려 준다(flags learn_<메뉴 id>, Menu가 쓴다)
## 보관: GameState.friendship {이름: 점수}, GameState.gift_day {이름: 마지막으로 선물한 날}
## 장면이 아닌 규칙만 담아 헤드리스로 시험한다.

const HEART := 20
const MAX_HEARTS := 5
const LOVE := 12
const LIKE := 7
const BASE := 3

## 선물 물건 id: 생선은 "fish:<어종>", 채소와 달걀은 "produce:<id>", 갯벌 것은 "sea:<id>"
## place: 지도 장소. time: [시작, 끝] (없으면 그곳이 열려 있을 때). met: 만난 표시
const PEOPLE := {
	"최순덕": {"call": "순덕 할머니", "place": "grandma", "met": "met_sundeok",
		"love": ["fish:bolak"], "like": ["produce:daepa", "produce:mu", "produce:egg", "goods:yakgwa"],
		"lines": ["또 왔어? 들어와 앉아.", "{player|이/가} 오니까 집이 훤하네.", "{player|아/야}. 니는 우리 손주나 마찬가지여."],
		"teach": {1: "jorim", 2: "baechuguk"}},
	"박만수": {"call": "만수 할아버지", "place": "breakwater", "met": "met_mansu", "time": [6 * 60, 12 * 60],
		"love": ["fish:gamseongdom", "goods:makgeolli"], "like": ["fish:ureok", "fish:noraemi", "sea:nakji"],
		"lines": ["...뭘 이런 걸 다.", "오늘 물 좋다. 너도 앉아라.", "니는 바다 냄새가 나기 시작했다."],
		"teach": {1: "maeuntang"}},
	"이준호": {"call": "준호", "place": "tackle", "met": "met_junho",
		"love": ["fish:hakgongchi", "goods:coffee"], "like": ["produce:egg", "sea:ge"],
		"lines": ["형 또 오셨어요? 커피 드실래요?", "형 덕분에 가게에 사람이 좀 와요.", "형은 진짜 우리 가게 일 번 단골이에요."],
		"teach": {1: "muchim", 2: "chobap"}},
	"문경자": {"call": "경자 할머니", "place": "store", "met": "met_kyungja",
		"love": ["sea:nakji"], "like": ["produce:kkaennip", "produce:egg", "fish:noraemi"],
		"lines": ["외상은 안 된다. 농담이다.", "니 오면 장부 볼 맛이 난다.", "우리 가게 의자 하나는 니 자리다."],
		"teach": {1: "maneul", 2: "kkaennip"}},
	"김복자": {"call": "복자 사장님", "place": "diner", "met": "met_bokja",
		"love": ["sea:bajirak"], "like": ["produce:gochu", "produce:maneul", "fish:ssombaengi", "goods:yakgwa"],
		"lines": ["밥은 먹고 다니나?", "니 가게 소문 들었다. 잘 하데.", "니는 이제 우리 동네 사람이다."],
		"teach": {1: "jiri", 2: "haemultang"}},
	"오용팔": {"call": "용팔 아저씨", "place": "market", "met": "met_yongpal",
		"love": ["fish:gamseongdom"], "like": ["fish:ureok", "sea:gul", "goods:makgeolli"],
		"lines": ["오, 물건 좋네.", "니가 오면 시장에 사람 냄새가 난다.", "언젠가 종 한번 같이 쳐 보자."]},
	"정태식": {"call": "이장님", "place": "hall", "met": "met_taesik",
		"love": ["produce:baechu"], "like": ["produce:mu", "fish:bolak", "goods:coffee", "goods:yakgwa"],
		"lines": ["아이고 이런 걸 다.", "사장님 같은 분이 마을에 와서 다행이에요.", "마을 일은 사장님하고 의논해야겠어요."],
		"teach": {1: "pajjim"}},
	"김해솔": {"call": "해솔이", "place": "school", "met": "met_haesol", "time": [14 * 60, 19 * 60],
		"love": ["sea:ge", "goods:candy"], "like": ["produce:egg", "fish:bolak"],
		"lines": ["우와 이거 나 주는 거예요?", "삼촌 오늘도 낚시했어요?", "삼촌은 내 베프예요!"],
		"teach": {1: "jeon"}},
	"정민혁": {"call": "민혁 선생님", "place": "school", "met": "met_minhyuk", "time": [9 * 60, 14 * 60],
		"love": ["goods:coffee"], "like": ["produce:egg", "fish:bolak", "goods:yakgwa"],
		"lines": ["해솔이가 좋아하겠네요.", "덕분에 학교가 시끌시끌해졌어요.", "여기 남길 잘했다는 생각이 요즘 들어요."]},
	"한서윤": {"call": "서윤", "place": "lab", "met": "met_seoyun", "time": [9 * 60, 19 * 60],
		"love": ["sea:ge"], "like": ["sea:gul", "fish:ssombaengi", "goods:coffee"],
		"lines": ["고마워요. 이건 먹는 거죠? 표본 아니고.", "{player} 씨 기록은 숫자가 정직해요.", "여름에 야광충 보러 같이 가요. 조사예요. 조사."]},
	"윤미자": {"call": "미자 아주머니", "place": "guesthouse", "met": "met_mija", "time": [6 * 60, 14 * 60],
		"love": ["goods:yakgwa"], "like": ["produce:baechu", "fish:noraemi", "produce:daepa"],
		"lines": ["어머 손도 크네!", "우리 집 방 하나는 늘 비워 둘게.", "아들보다 자주 본다니까 정말."]},
	"서지우": {"call": "지우", "place": "guesthouse", "met": "met_jiwoo", "time": [14 * 60, 19 * 60],
		"love": ["goods:candy"], "like": ["goods:coffee", "fish:hakgongchi", "produce:kkaennip"],
		"lines": ["이거 그려도 돼요?", "한 달 더 있을까 봐요. 아직 비밀이에요.", "여기 바다는 매일 색이 달라요. 다 그리려면 오래 걸리겠죠?"]},
}


static func person(name: String) -> Dictionary:
	return PEOPLE.get(name, {})


## 이 장소에 지금 있는 사람 (만난 사람만). 없으면 ""
static func who_at(place: String, minutes: int, flags: Dictionary) -> String:
	for n in PEOPLE:
		var p: Dictionary = PEOPLE[n]
		if p.place != place or not flags.get(p.met, false):
			continue
		if p.has("time") and (minutes < int(p.time[0]) or minutes >= int(p.time[1])):
			continue
		return n
	return ""


## 어른에게는 "께", 아이와 또래에게는 "에게". 예: "해솔이에게"
static func to(name: String) -> String:
	var call: String = person(name).get("call", Orders.call_name(name))
	return call + ("에게" if name in ["김해솔", "이준호", "서지우", "한서윤"] else "께")


static func points(gs: Object, name: String) -> int:
	return int(gs.friendship.get(name, 0))


static func hearts(pts: int) -> int:
	return mini(MAX_HEARTS, pts / HEART)


## 오늘 선물할 수 있나
static func can_give(gs: Object, name: String) -> bool:
	return int(gs.gift_day.get(name, -1)) != int(gs.day)


## 그 사람이 이 물건을 얼마나 좋아하나: "love", "like", "base"
static func taste(name: String, thing: String) -> String:
	var p := person(name)
	if thing in p.get("love", []):
		return "love"
	if thing in p.get("like", []):
		return "like"
	return "base"


static func gain(t: String) -> int:
	return LOVE if t == "love" else (LIKE if t == "like" else BASE)


## 선물할 수 있는 물건 목록 [{"thing", "name", "count", "entry"(생선이면 아이스박스 한 마리)}]. 생선은 어종마다 가장 작은 것 하나
static func giftables(gs: Object) -> Array:
	var out := []
	var by_fish := {}
	for e in gs.inventory:
		if not by_fish.has(e.id) or float(e.size) < float(by_fish[e.id].size):
			by_fish[e.id] = e
	for id in by_fish:
		out.append({"thing": "fish:" + id, "name": FishDB.get_fish(id).name, "count": gs.inventory.filter(func(x): return x.id == id).size(), "entry": by_fish[id]})
	for id in gs.produce:
		if int(gs.produce[id]) > 0:
			out.append({"thing": "produce:" + id, "name": Pantry.name_of(id), "count": int(gs.produce[id])})
	for id in gs.seafood:
		if int(gs.seafood[id]) > 0:
			out.append({"thing": "sea:" + id, "name": Flat.name_of(id), "count": int(gs.seafood[id])})
	for id in gs.goods:
		if int(gs.goods[id]) > 0 and Store.GOODS.has(id):
			out.append({"thing": "goods:" + id, "name": Store.GOODS[id].name, "count": int(gs.goods[id])})
	return out


## 선물한다. 결과 {"taste", "gain", "hearts_before", "hearts", "line", "learned": 메뉴 id 또는 ""}. 못 하면 빈 Dictionary
static func give(gs: Object, name: String, g: Dictionary) -> Dictionary:
	if not can_give(gs, name) or person(name).is_empty():
		return {}
	var thing: String = g.thing
	var parts := thing.split(":")
	match parts[0]:
		"fish":
			if not gs.inventory.has(g.entry):
				return {}
			gs.inventory.erase(g.entry)
		"produce":
			if int(gs.produce.get(parts[1], 0)) <= 0:
				return {}
			gs.produce[parts[1]] = int(gs.produce[parts[1]]) - 1
			if int(gs.produce[parts[1]]) <= 0:
				gs.produce.erase(parts[1])
		"sea":
			if int(gs.seafood.get(parts[1], 0)) <= 0:
				return {}
			gs.seafood[parts[1]] = int(gs.seafood[parts[1]]) - 1
			if int(gs.seafood[parts[1]]) <= 0:
				gs.seafood.erase(parts[1])
		"goods":
			if int(gs.goods.get(parts[1], 0)) <= 0:
				return {}
			gs.goods[parts[1]] = int(gs.goods[parts[1]]) - 1
			if int(gs.goods[parts[1]]) <= 0:
				gs.goods.erase(parts[1])
	WeekGoals.add(gs, "gifts")
	var t := taste(name, thing)
	var before := hearts(points(gs, name))
	gs.friendship[name] = mini(points(gs, name) + gain(t), HEART * MAX_HEARTS)
	gs.gift_day[name] = int(gs.day)
	var after := hearts(points(gs, name))
	var learned := ""
	var p := person(name)
	var lines: Array = p.lines
	var line := ""
	if after > before:
		line = lines[mini(after - 1, lines.size() - 1)]
		for h in p.get("teach", {}):
			if int(h) > before and int(h) <= after:
				if not Menu.on_menu(gs.flags, str(p.teach[h])): # 잔치나 연구로 이미 배웠으면 다시 알려 주지 않는다
					learned = str(p.teach[h])
				gs.flags["learn_" + str(p.teach[h])] = true
	return {"taste": t, "gain": gain(t), "hearts_before": before, "hearts": after, "line": line, "learned": learned}


## 선물 받고 하는 말 (하트가 안 올랐을 때)
static func react(t: String) -> String:
	match t:
		"love":
			return "어머, 이거 내가 제일 좋아하는 건데!"
		"like":
			return "오, 고마워. 잘 먹을게."
	return "고마워. 마음만으로도 좋네."


## "♥♥♡♡♡"
static func heart_text(h: int) -> String:
	return "♥".repeat(h) + "♡".repeat(MAX_HEARTS - h)
