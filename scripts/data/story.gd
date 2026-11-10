class_name Story
extends RefCounted
## 1년 차 봄 첫 주 이야기 (기획서 챕터 2~3 앞부분). 순덕 할머니 부탁과 닭장은 Coop이 맡는다. 장면이 아닌 규칙과 대사만 담아 헤드리스로 시험한다.
##
## 사건: 지도에서 그 장소로 가면 한 번만 나오는 대화. 조건이 맞는 것 중 목록 앞의 것 하나만 나온다.
##   place: 장소 id, day: 이 날부터, needs: 먼저 켜져 있어야 할 flags, time: [시작, 끝] 분 (없으면 아무 때나)
##   set: 끝나면 켤 flags, money: 받는 돈. 본 사건은 flags["ev_<id>"]로 표시한다
## 잡담: 장소 화면이 아직 없는 곳에 가면 나오는 짧은 대화. 날짜마다 돌아가며 나온다 (지금까지 "준비 중" 토스트였던 자리)
##
## 대사 규칙 (CLAUDE.md): 자연스러운 구어체, 쉼표 남발과 줄표 금지. 이름은 {player}, {shop} 템플릿

const EVENTS := [
	{
		"id": "mansu_mend", "note": "방파제 노인은 박만수 할아버지였다. 견제하는 법을 배웠다.", "place": "breakwater", "day": 2, "needs": ["first_guest_done"], "time": [5 * 60, 11 * 60],
		"set": ["met_mansu"],
		"lines": [
			{"speaker": "", "text": "방파제 끝에 어제 그 노인이 또 앉아 있다. 오늘은 혼자 막걸리 한 병을 옆에 두었다."},
			{"speaker": "박만수", "text": "또 왔나. 서울 양반 생각보다 부지런하네."},
			{"speaker": "{player}", "text": "어제 말씀해 주신 대로 해 보려고요. 저는 {player|이에요/예요}."},
			{"speaker": "박만수", "text": "박만수다. 이 동네서 고기 잡은 지 오십 년 됐다."},
			{"speaker": "박만수", "text": "찌가 물살 따라 흘러가믄 고기 앞을 그냥 지나쳐 뿐다. 뒷줄을 살짝 잡아 줘라. 그게 견제다."},
			{"speaker": "박만수", "text": "찌가 제자리에 서믄 고기가 금방 붙는다. 대신 너무 세게 잡지는 말고."},
			{"speaker": "", "text": "찌를 기다릴 때 오른쪽 아래 견제 단추를 누르고 있으면 찌가 멈추고 입질이 빨라져요."},
		],
	},
	{
		"id": "yongpal_first", "note": "시장 경매사 오용팔 아저씨를 만났다. 남는 고기는 시장에 넘기면 된다.", "place": "market", "day": 2, "needs": [],
		"set": ["met_yongpal"],
		"lines": [
			{"speaker": "", "text": "셔터가 반쯤 내려간 시장 안쪽에서 누가 커다란 종을 닦고 있다."},
			{"speaker": "오용팔", "text": "어, 처음 보는 얼굴인데. 혹시 그 백반집 자리에 새로 들어온 사람이가?"},
			{"speaker": "{player}", "text": "네. {shop|을/를} 시작한 {player|이에요/예요}."},
			{"speaker": "오용팔", "text": "나는 여기 경매 보는 오용팔이다. 예전엔 새벽마다 배가 스무 척씩 들어왔는데 요새는 종 칠 일이 없어."},
			{"speaker": "오용팔", "text": "잡은 고기 남으면 가져와. 흔한 건 식당에서 굽는 게 낫고 비싼 놈은 내가 도시로 넘겨 줄게."},
			{"speaker": "", "text": "수산시장은 새벽 5시부터 오후 5시까지 열어요. 잡은 다음 날 밤이면 생선이 상하니 그 전에 팔아요."},
		],
	},
	{
		"id": "kyungja_store", "note": "경자상회 할머니 서랍에 외상장부가 수십 권 있었다.", "place": "store", "day": 3, "needs": [],
		"set": ["met_kyungja"],
		"lines": [
			{"speaker": "", "text": "유리문에 붙은 담배 광고가 다 바랬다. 계산대 뒤에 작은 할머니가 장부를 넘기고 있다."},
			{"speaker": "문경자", "text": "{shop} 사장이지? 순덕 언니한테 들었어."},
			{"speaker": "{player}", "text": "벌써 소문이 났네요."},
			{"speaker": "문경자", "text": "이 동네는 하루면 다 알아. 나는 문경자. 여기서 오십 년째 가게 본다."},
			{"speaker": "", "text": "계산대 옆 서랍에 손때 묻은 공책이 수십 권 쌓여 있다."},
			{"speaker": "{player}", "text": "그게 다 장부예요?"},
			{"speaker": "문경자", "text": "외상장부. 마을 사람 누가 뭘 얼마나 가져갔는지 다 여기 있어. 안 갚은 사람도 있고 못 갚게 된 사람도 있고."},
			{"speaker": "문경자", "text": "소금이나 양념 떨어지면 와. 식당 하는 사람한테는 싸게 줄게."},
		],
	},
	{
		"id": "bokja_diner", "note": "복자네 밥집 사장님이 망하지만 말고 버텨 보라고 했다.", "place": "diner", "day": 4, "needs": [],
		"set": ["met_bokja"],
		"lines": [
			{"speaker": "", "text": "점심 장사를 막 끝낸 밥집에서 고소한 냄새가 흘러나온다. 앞치마를 두른 아주머니가 팔짱을 끼고 나온다."},
			{"speaker": "김복자", "text": "니가 그 새로 온 식당 사장이가? 우리 집 손님 뺏으러 왔나."},
			{"speaker": "{player}", "text": "아니에요. 저는 저녁에만 열고 잡은 생선만 구워요."},
			{"speaker": "김복자", "text": "흥. 생선 굽는 게 쉬운 줄 아나 보네. 순덕 형님이 간이 세다 카던데."},
			{"speaker": "{player}", "text": "그 얘기 벌써 들으셨어요?"},
			{"speaker": "김복자", "text": "이 마을에 비밀이 어디 있노. 나는 김복자다. 이 마을 밥은 삼십 년 동안 내가 했다."},
			{"speaker": "김복자", "text": "그래도 불 꺼진 데 불 켜진 건 좋다. 망하지만 말고 버텨 봐라."},
		],
	},
	{
		"id": "mansu_tide", "note": "만수 할아버지한테 물때를 배웠다. 감성돔 한 마리 올리면 갯바위에 데려가 준단다.", "place": "breakwater", "day": 5, "needs": ["met_mansu"], "time": [5 * 60, 11 * 60],
		"set": ["learned_tide_talk"],
		"lines": [
			{"speaker": "박만수", "text": "니 물때 볼 줄 아나."},
			{"speaker": "{player}", "text": "물때요? 화면 위에 7물 이런 거요?"},
			{"speaker": "박만수", "text": "바다는 보름마다 숨을 크게 쉬었다 작게 쉬었다 한다. 물이 많이 움직이는 사리 때는 고기가 밥 먹으러 나온다."},
			{"speaker": "박만수", "text": "조금 무시 때는 물이 잠잠해서 고기도 게으르다. 그런 날은 일찍 들어가서 가게나 봐라."},
			{"speaker": "박만수", "text": "검은여 갯바위는 물이 빠져야 들어간다. 물때 모르고 들어가믄 바다가 길을 막아 뿐다."},
			{"speaker": "{player}", "text": "거기 데려가 주실 수 있어요?"},
			{"speaker": "박만수", "text": "...아직은 멀었다. 여기서 감성돔 한 마리 올리믄 그때 생각해 보자."},
			{"speaker": "", "text": "위쪽 헤더에 '물때 좋음'이 뜨는 날은 입질이 빨라요."},
		],
	},
]

## 장소 화면이 없는 곳의 잡담 (날마다 돌아가며 하나)
const SMALL_TALK := {
	"home": [
		[{"speaker": "", "text": "오래된 단층집. 마당의 녹슨 평상에 앉으니 바다 냄새가 난다."}],
		[{"speaker": "{player}", "text": "이불을 말려야 하는데. 오늘은 바람이 좋네."}],
	],
	"store": [
		[{"speaker": "문경자", "text": "오늘은 뭐 필요해? 굵은소금 새로 들어왔어."}],
		[{"speaker": "문경자", "text": "만수 영감은 막걸리 외상이 석 달 치야. 그래도 꼭 갚는 사람이라 놔둬."}],
	],
	"diner": [
		[{"speaker": "김복자", "text": "또 왔나. 우리 집 반찬 훔쳐 갈라꼬?"}],
		[{"speaker": "김복자", "text": "생선은 불 앞에서 서두르면 안 된다. 기다릴 줄 알아야 맛이 난다."}],
	],
	"bus": [
		[{"speaker": "", "text": "낡은 정류장 표지판. 읍내 가는 버스는 하루 네 번이다. 시간표 종이가 바람에 펄럭인다."}],
		[{"speaker": "", "text": "버스를 기다리는 사람은 아무도 없다. 갈매기 한 마리가 의자에 앉아 있다."}],
	],
	"lookout": [
		[{"speaker": "", "text": "뒷산 정자에 오르니 물빛울포가 한눈에 보인다. 빨간 등대 너머로 섬들이 줄지어 떠 있다."}],
		[{"speaker": "{player}", "text": "여기서 보니 마을이 생각보다 작네. 그래도 내 가게 지붕은 보인다."}],
	],
	"shop": [
		[{"speaker": "", "text": "{shop}. 의자 다리는 아직 흔들리지만 테이블은 반짝반짝 닦아 두었다."}],
	],
}


## 이 장소에서 지금 나올 사건. 없으면 빈 Dictionary
static func pending(place: String, day: int, minutes: int, flags: Dictionary) -> Dictionary:
	for ev in EVENTS:
		if ev.place != place or day < ev.day or flags.get("ev_" + ev.id, false):
			continue
		var ok := true
		for f in ev.needs:
			if not flags.get(f, false):
				ok = false
		if ev.has("time") and (minutes < ev.time[0] or minutes >= ev.time[1]):
			ok = false
		if ok:
			return ev
	return {}


## 사건을 본 것으로 표시하고 결과(flags, 돈)를 넣는다
static func finish(ev: Dictionary, gs: Object) -> void:
	gs.flags["ev_" + ev.id] = true
	for f in ev.get("set", []):
		gs.flags[f] = true
	if int(ev.get("money", 0)) > 0:
		gs.earn(int(ev.money))
	if ev.has("note"):
		gs.note(ev.note, 3)


## 장소 화면이 없는 곳의 잡담 한 묶음. 없으면 빈 배열
static func small_talk(place: String, day: int) -> Array:
	var list: Array = SMALL_TALK.get(place, [])
	if list.is_empty():
		return []
	return list[day % list.size()]
