class_name SpecialGuest
extends RefCounted
## 특별 손님 알아맞히기 대접 (2026-11-19 사용자: 특별 손님에게 조리해 주는 시스템이 재미없다 → "알아맞히기 대접").
##
## 영업 끝에 주문서를 낸 사람이 직접 온다. 대화 속에 힌트를 세 가지 흘린다.
##   1) 생선: 주문서에 적은 그 생선 (아침 쪽지와 같은 말)
##   2) 요리 갈래: 오늘 날씨와 기분 (국물, 구이, 튀김, 조림, 회). 주인공이 낼 수 있는 갈래 안에서만 바란다
##   3) 어떤 놈: 오늘 잡은 싱싱한 것, 큼직한 것, 자잘한 것 (2026-11-24 곁들임을 없애며 바꿈)
## 주인공은 아이스박스에서 생선 한 마리와 요리를 골라 세라에게 주문한다. 맞힌 수가 별이 된다(최소 하나).
## 별이 많을수록 팁(DayFlow.special_tip), 셋 다 맞히면 친밀도, 그리고 그 사람 사연이 한 토막씩 풀린다(flags tale_<이름> = 들은 수).
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
const PERFECT_FRIEND := 6

## 말투 (11-25 손님이 여덟 명으로 늘며 나눔). 표에 없으면 어르신 말투(위 STYLES, TRAITS의 hints)
##   polite: 젊은 사람과 이장의 존댓말, kid: 해솔
const TONES := {"이준호": "polite", "정태식": "polite", "김해솔": "kid"}
const TONE_HINTS := {
	"polite": {
		"fish": "%s 생각이 나서 왔어요.",
		"soup": ["바람이 차네요. 뜨끈한 국물이 당겨요.", "속이 좀 허해서 시원한 국물이면 좋겠어요."],
		"grill": ["오늘은 그냥 소금 쳐서 구운 게 좋겠어요.", "기름 쫙 빠지게 구운 걸로 부탁드려요."],
		"fry": ["바삭한 거 씹고 싶은 날이에요.", "맥주 한잔하려는데 바삭한 안주가 좋겠어요."],
		"braise": ["짭조름하게 졸인 거에 밥 비비고 싶어요.", "입맛이 없어서요. 밥도둑 같은 거 없을까요?"],
		"raw": ["날이 좋으니까 싱싱하게 날로 먹고 싶네요.", "오늘 잡은 거 있으면 썰어만 주세요."],
		"fresh": ["오늘 막 잡은 싱싱한 놈이면 좋겠어요.", "묵은 거 말고 오늘 건진 걸로요."],
		"big": ["이왕이면 큼직한 놈으로 부탁해요.", "둘이 먹어도 될 만큼 실한 놈 없을까요?"],
		"small": ["큰 놈은 부담스럽고 자잘한 게 좋아요.", "작고 야들야들한 놈으로요."],
	},
	"kid": {
		"fish": "저 %s 먹고 싶어서 왔어요!",
		"soup": ["밖에 추워요. 따뜻한 국물 주세요.", "국물에 밥 말아 먹고 싶어요."],
		"grill": ["소금 톡톡 뿌려서 구운 거요!", "불에 구운 냄새 나는 거 먹고 싶어요."],
		"fry": ["바삭바삭 소리 나는 거요!", "과자처럼 바삭한 게 좋아요."],
		"braise": ["짭짤한 양념에 밥 비벼 먹고 싶어요.", "할머니처럼 졸인 거요. 무는 빼도 돼요."],
		"raw": ["저도 회 먹을 줄 알아요!", "어른들처럼 썰어만 주세요."],
		"fresh": ["아저씨가 오늘 잡은 거예요? 오늘 잡은 걸로 주세요.", "방금 바다에서 나온 게 좋아요."],
		"big": ["제일 큰 거요! 선생님한테 자랑할 거예요.", "제 팔뚝보다 큰 거 있어요?"],
		"small": ["저는 작은 거요. 큰 건 다 못 먹어요.", "제 손바닥만 한 게 귀여워요."],
	},
}
## 들어와서 처음 하는 말: 주문을 채워 보냈을 때, 그 생선이 있을 때, 없을 때
const ASKS := {
	"elder": ["아까 보내 준 %s 잘 받았어. 오늘 저녁은 여기서 먹고 갈게.", "%s 있나? 오늘은 그게 땡기네.", "%s 없나 보네. 그럼 있는 걸로 줘."],
	"polite": ["아까 보내 준 %s 잘 받았어요. 오늘 저녁은 여기서 먹고 갈게요.", "%s 있어요? 오늘은 그게 당기네요.", "%s 없나 보네요. 그럼 있는 걸로 주세요."],
	"kid": ["아까 %s 잘 받았어요! 할머니가 저녁 먹고 와도 된대요.", "%s 있어요? 저 그거 먹으러 왔어요.", "%s 없어요? 그럼 다른 것도 괜찮아요."],
}

## 사연: 셋 다 맞힐 때마다 한 토막씩
const TALES := {
	"최순덕": [
		"우리 영감도 이 바다에서 고기 잡았어. 새벽마다 볼락 한 바구니씩 들고 왔지.",
		"아들은 부산 살아. 같이 가자는데 나는 이 집을 못 떠나겠어.",
		"이 식당 옛날 주인이 우리 영감 친구였어. 불 켜진 거 보니 그 양반 생각나더라.",
	],
	"박만수": [
		"순풍호라고 내 배가 있었다. 지금은 항구 끝에 묶여 있지.",
		"그 배 타고 나간 날 사람을 하나 잃었다. 내 아들이다. 그 뒤로는 배를 못 풀겠더라.",
		"니가 잡아 오는 고기 보면 그놈 생각이 난다. 고기 보는 눈이 닮았어.",
	],
	"이준호": [
		"형, 이 낚시방 아버지가 하던 거예요. 아버지 돌아가시고 제가 붙잡고 있어요.",
		"도시에서 회사 다니다 왔는데 솔직히 가끔 후회돼요.",
		"요즘은 형 덕분에 좀 할 만해요. 진짜로요.",
	],
	"문경자": [
		"이 가게 영감이랑 둘이 벽돌 쌓아 지었어. 간판 글씨도 영감이 썼지.",
		"영감 가고 문 닫을까 했는데 아침에 애들이 와서 두부 달라고 문을 두드리더라. 그래서 열었어.",
		"사람들은 내가 돈을 다 기억한다고 하지. 나는 돈 말고 그날 얼굴을 기억하는 거야.",
	],
	"김복자": [
		"밥집 첫날 매출이 얼마였는지 아나? 삼천 원이다. 그것도 순덕 형님이 세 그릇 값 내고 갔다.",
		"해솔이 엄마 아빠가 창원에 있다. 아가 밤에 엄마 찾을 때마다 내가 누룽지를 끓였다.",
		"니 왔을 때 내가 왜 그래 쌀쌀맞았는지 아나. 또 떠날까 봐 그랬다. 정 주고 나면 다 가더라.",
	],
	"오용팔": [
		"우리 아버지도 경매사였다. 나는 종소리 듣고 걸음마를 배웠다 하더라.",
		"스무 척 들어오던 때는 하루에 목이 세 번 쉬었다. 요새는 목이 너무 멀쩡해서 탈이다.",
		"아무도 없는 새벽에 종을 닦으면서 혼자 값을 불러 본다. 만 원 나왔습니다 하고. 어디 가서 말하지 마라.",
	],
	"정태식": [
		"저도 젊을 때는 군청에서 일했어요. 거기서는 이 마을이 지도에 점 하나더라고요.",
		"고향에 와서 이장 맡은 지 십이 년이에요. 처음엔 집이 여든 채였는데 지금은 서른한 채예요.",
		"밤에 회관 불이 켜져 있으면 저예요. 공문이 와도 혼자 읽고 혼자 걱정하느라고요.",
	],
	"김해솔": [
		"고등어는 제가 학교 가는 길에서 만났어요. 비 오는데 혼자 울고 있었거든요.",
		"엄마는 토요일마다 전화해요. 저는 학교에 친구 많다고 했어요. 고등어랑 선생님이요.",
		"저 커서 여기 살 거예요. 그때도 아저씨 가게 있어야 돼요. 약속이에요!",
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
	var th: Dictionary = TONE_HINTS.get(tone(name), {})
	var st_hints: Array = th.get(style, STYLES[style].hints)
	var tr_hints: Array = th.get(kind, TRAITS[kind].hints)
	return {
		"fish": fish, "style": style, "trait": kind,
		"hints": [
			str(th.get("fish", "%s 생각이 나서 왔어.")) % FishDB.get_fish(fish).name,
			st_hints[rng.randi() % st_hints.size()],
			tr_hints[rng.randi() % tr_hints.size()],
		],
	}


static func tone(name: String) -> String:
	return TONES.get(name, "elder")


## 들어와서 처음 하는 말. fish_name은 주문한 생선 이름
static func ask(name: String, fish_name: String, order_done: bool, wanted: bool) -> String:
	var a: Array = ASKS[tone(name)]
	if order_done:
		return a[0] % fish_name
	return a[1] % fish_name if wanted else a[2] % Josa.attach(fish_name, "은/는")


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
