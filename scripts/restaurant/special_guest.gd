class_name SpecialGuest
extends RefCounted
## 특별 손님 알아맞히기 대접 (2026-11-19 사용자: 특별 손님에게 조리해 주는 시스템이 재미없다 → "알아맞히기 대접").
##
## 영업 끝에 주문서를 낸 사람이 직접 온다. 대화 속에 힌트를 세 가지 흘린다.
##   1) 생선: 주문서에 적은 그 생선 (아침 쪽지와 같은 말)
##   2) 요리 갈래: 오늘 날씨와 기분 (국물, 구이, 튀김, 조림, 회). 주인공이 낼 수 있는 갈래 안에서만 바란다
##   3) 어떤 놈: 오늘 잡은 싱싱한 것, 큼직한 것, 자잘한 것 (2026-11-24 곁들임을 없애며 바꿈)
## 주인공은 아이스박스에서 생선 한 마리와 요리를 골라 세라에게 주문한다. 맞힌 수가 별이 된다(최소 하나).
## 셋 다 맞히면 웃돈, 친밀도, 그리고 그 사람 사연이 한 토막씩 풀린다(flags tale_<이름> = 들은 수).
## 장면이 아닌 규칙만 담아 헤드리스로 시험한다.

## 요리 갈래: 이름, 그 갈래에 드는 요리 id, 손님이 바랄 때 하는 말
const STYLES := {
	"soup": {"name": "국물", "dishes": ["maeuntang", "jiri", "haemultang", "baechuguk"],
		"hints": ["바람이 차네. 뜨끈한 국물이 당기는구먼.", "속이 좀 허해. 시원한 국물 한 숟갈 하면 살겠다."]},
	"grill": {"name": "구이", "dishes": ["grill", "maneul"],
		"hints": ["오늘은 그냥 소금 쳐서 구운 게 제일이지.", "기름 쫙 빠지게 구운 거 있잖아. 그거."]},
	"fry": {"name": "튀김", "dishes": ["fry", "kkaennip", "jeon"],
		"hints": ["바삭한 거 씹고 싶은 날이네.", "한잔 걸치려는데 안주로 바삭한 게 좋겠어."]},
	"braise": {"name": "조림", "dishes": ["jorim", "pajjim"],
		"hints": ["짭조름하게 졸인 거에 밥 비비고 싶네.", "입맛이 없어. 밥도둑 같은 거 없나."]},
	"raw": {"name": "회", "dishes": ["hoe", "muchim", "chobap"],
		"hints": ["날이 좋으니 싱싱한 걸 날로 먹고 싶네.", "오늘 잡은 거 있으면 썰어만 줘."]},
}
## 날씨마다 바라는 갈래 (앞일수록 잘 고른다)
const WEATHER_STYLE := {
	"rain": ["soup", "braise", "fry"], "windy": ["soup", "grill", "braise"],
	"cloudy": ["braise", "grill", "fry"], "sunny": ["raw", "grill", "fry"],
}
## 어떤 놈을 바라나: 손님 말, 세라가 짚어 줄 말
const TRAITS := {
	"fresh": {"hints": ["오늘 막 잡은 싱싱한 놈이면 좋겠어.", "묵은 거 말고 오늘 건진 걸로 줘."], "miss": "오늘 잡은 걸 바란 것 같고"},
	"big": {"hints": ["이왕이면 큼직한 놈으로 부탁해.", "여럿이 나눠 먹어도 될 만큼 실한 놈 없나."], "miss": "더 큼직한 놈을 바란 것 같고"},
	"small": {"hints": ["큰 놈은 부담스럽고 자잘한 게 좋아.", "작고 야들야들한 놈이 먹기 좋지."], "miss": "좀 더 작은 놈을 바란 것 같고"},
}
const PERFECT_TIP := 1.3
const PERFECT_FRIEND := 6

## 사연: 셋 다 맞힐 때마다 한 토막씩
const TALES := {
	"최순덕": [
		"우리 영감도 이 바다에서 고기 잡았어. 새벽마다 볼락 한 바구니씩 들고 왔지.",
		"딸은 서울 살아. 같이 올라가자는데 나는 이 집을 못 떠나겠어.",
		"이 식당 옛날 주인이 우리 영감 친구였어. 불 켜진 거 보니 그 양반 생각나더라.",
	],
	"박만수": [
		"순풍호라고 내 배가 있었다. 지금은 항구 끝에 묶여 있지.",
		"그 배 타고 마지막으로 나간 날 사람을 하나 잃었다. 그 뒤로는 못 나가겠더라.",
		"니가 잡아 오는 고기 보면 그 친구 생각이 난다. 고기 보는 눈이 닮았어.",
	],
	"이준호": [
		"형, 이 낚시방 아버지가 하던 거예요. 아버지 돌아가시고 제가 붙잡고 있어요.",
		"도시에서 회사 다니다 왔는데 솔직히 가끔 후회돼요.",
		"요즘은 형 덕분에 좀 할 만해요. 진짜로요.",
	],
}


## 오늘 그 손님이 바라는 것 {"fish", "style", "trait", "hints": [세 줄]}. styles_ok: 주인공이 낼 수 있는 갈래들
static func want(day: int, name: String, fish: String, weather: String, styles_ok: Array) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("대접-%d-%s" % [day, name])
	var style := "grill"
	for s in WEATHER_STYLE.get(weather, ["grill"]):
		if s in styles_ok and rng.randf() < 0.7:
			style = s
			break
	if not style in styles_ok:
		style = "grill"
	var kind: String = TRAITS.keys()[rng.randi() % TRAITS.size()]
	var st_hints: Array = STYLES[style].hints
	return {
		"fish": fish, "style": style, "trait": kind,
		"hints": [
			"%s 생각이 나서 왔어." % FishDB.get_fish(fish).name,
			st_hints[rng.randi() % st_hints.size()],
			TRAITS[kind].hints[rng.randi() % TRAITS[kind].hints.size()],
		],
	}


## 주인공이 낼 수 있는 갈래 (메뉴판에 오른 요리 기준). fish를 주면 그 생선으로 되는 갈래만
static func styles_ok(flags: Dictionary, fish := "") -> Array:
	var out := ["grill"]
	if flags.get("recipe_fish_fry", false):
		out.append("fry")
	for st in STYLES:
		for d in STYLES[st].dishes:
			if Menu.RECIPES.has(d) and Menu.on_menu(flags, d) and not st in out and (fish.is_empty() or Menu.fits_fish(d, fish)):
				out.append(st)
	return out


static func style_of(dish: String) -> String:
	for st in STYLES:
		if dish in STYLES[st].dishes:
			return st
	return "grill"


## 그 생선이 바라는 놈인가
static func trait_ok(kind: String, entry: Dictionary, today: int) -> bool:
	match kind:
		"fresh":
			return int(entry.get("day", today)) == today
		"big":
			return FishDB.stars(entry.id, entry.size) >= 2
	return FishDB.stars(entry.id, entry.size) == 1


## 고른 것 채점 {"fish": bool, "style": bool, "trait": bool, "stars": 1~3, "perfect": bool}
static func score(w: Dictionary, entry: Dictionary, dish: String, today: int) -> Dictionary:
	var f: bool = entry.id == w.fish
	var s: bool = style_of(dish) == w.style
	var d := trait_ok(w.trait, entry, today)
	var n := int(f) + int(s) + int(d)
	return {"fish": f, "style": s, "trait": d, "stars": clampi(n, 1, 3), "perfect": n == 3}


## 셋 다 맞혔을 때 들려주는 사연 한 토막 (다 들었으면 "")
static func next_tale(flags: Dictionary, name: String) -> String:
	var heard := int(flags.get("tale_" + name, 0))
	var list: Array = TALES.get(name, [])
	return list[heard] if heard < list.size() else ""


## 무엇이 맞고 틀렸는지 세라가 짚어 주는 말
static func review(w: Dictionary, sc: Dictionary) -> String:
	var miss := PackedStringArray()
	if not sc.fish:
		miss.append("%s 찾았는데" % Josa.attach(FishDB.get_fish(w.fish).name, "을/를"))
	if not sc.style:
		miss.append("%s 당겼던 것 같고" % Josa.attach(STYLES[w.style].name, "이/가"))
	if not sc.trait:
		miss.append(TRAITS[w.trait].miss)
	if miss.is_empty():
		return "딱 맞혔네요. 저 표정 봐요."
	return "다음엔 " + ", ".join(miss) + "."
