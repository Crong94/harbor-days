class_name AppWork
extends RefCounted
## 앱 만들기 (2026-11-19). 기획서 "개발자 특기 이벤트"와 개인 퀘스트 〈낚시방 살리기〉 〈외상장부〉 〈이장님의 엑셀〉.
## 주인공은 서울에서 개발자였다. 마을 사람이 부탁하면(Story 사건이 flags app_<id>를 켠다) 그 장소에서 앱을 만들어 준다.
##
## 미니게임: 할 일 카드가 섞여 나온다. 만드는 순서대로 누른다. 틀리면 실수 하나. 실수 MAX_MISS번이면 그날은 접는다.
## 한 앱은 단계 세 개. 하루에 한 단계만, 한 번 하는 데 WORK_MINUTES분. 다 만들면 보상.
## 보관: GameState.apps {앱 id: 마친 단계 수}, GameState.app_day {앱 id: 마지막으로 한 날}
## 장면이 아닌 규칙만 담아 헤드리스로 시험한다.

const WORK_MINUTES := 120
const MAX_MISS := 3

const APPS := {
	"junho": {"title": "낚시방 살리기", "who": "이준호", "place": "tackle", "start": "app_junho",
		"why": "손님이 없어 가게를 접을까 한다. 조황 정보 페이지와 예약 버튼이 있으면 좋겠단다.",
		"reward_text": "조황 앱 완성: 하루 서랍에 물때 집중 시간이 보이고 낚시방 물건이 10% 싸진다",
		"stages": [
			["화면 그리기", "물때 불러오기", "조황 글 올리기", "올리기 버튼 달기"],
			["날짜 고르기", "자리 수 세기", "예약 받기", "준호에게 알림 보내기"],
			["잡은 고기 사진 받기", "어종 고르기", "크기 적기", "조황판에 붙이기", "주소 알려 주기"],
		]},
	"kyungja": {"title": "외상장부", "who": "문경자", "place": "store", "start": "app_kyungja",
		"why": "서랍 속 외상장부 수십 권. 글씨가 바래서 이제 할머니도 못 읽는다.",
		"reward_text": "장부 정리 완성: 경자 할머니 사례금과 친밀도",
		"stages": [
			["장부 사진 찍기", "날짜별로 나누기", "이름 적기", "금액 적기"],
			["사람별로 묶기", "갚은 것 지우기", "남은 돈 더하기", "표로 보여 주기"],
			["큰 글씨로 바꾸기", "찾기 칸 달기", "할머니께 쓰는 법 알려 드리기", "옛 장부는 상자에 보관하기"],
		]},
	"taesik": {"title": "이장님의 엑셀", "who": "정태식", "place": "hall", "start": "app_taesik",
		"why": "마을 행정 파일이 엉망이다. 게시판 의뢰도 종이로만 붙여서 놓치는 게 많다.",
		"reward_text": "마을 게시판 앱 완성: 게시판 의뢰 사례가 20% 늘고 평판이 오른다",
		"stages": [
			["파일 모으기", "같은 칸 맞추기", "빈칸 채우기", "겹친 줄 지우기"],
			["주민 명단 만들기", "의뢰 칸 만들기", "마감일 적기", "다 한 의뢰 표시하기"],
			["회관 컴퓨터에 깔기", "이장님 비밀번호 정하기", "게시판 사진 올리기", "마을 방송으로 알리기"],
		]},
}
const REWARD_MONEY := {"kyungja": 100000}
const REWARD_FRIEND := {"kyungja": 20, "junho": 10, "taesik": 10}
const SHOP_DISCOUNT := 0.9 # 조황 앱을 만들면 낚시방 값
const BOARD_BONUS := 1.2 # 마을 게시판 앱을 만들면 의뢰 사례


static func app(id: String) -> Dictionary:
	return APPS.get(id, {})


static func stage(gs: Object, id: String) -> int:
	return int(gs.apps.get(id, 0))


static func done(gs: Object, id: String) -> bool:
	return stage(gs, id) >= app(id).stages.size()


static func started(gs: Object, id: String) -> bool:
	return gs.flags.get(app(id).start, false)


## 오늘 이 장소에서 할 수 있는 앱 (없으면 "")
static func available_at(gs: Object, place: String) -> String:
	for id in APPS:
		var a: Dictionary = APPS[id]
		if a.place == place and started(gs, id) and not done(gs, id) and int(gs.app_day.get(id, -1)) != int(gs.day):
			return id
	return ""


## 그 단계의 섞인 카드 (날짜로 정해진다)
static func shuffled(id: String, st: int, day: int) -> Array:
	var cards: Array = app(id).stages[st].duplicate()
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("앱-%s-%d-%d" % [id, st, day])
	for i in range(cards.size() - 1, 0, -1):
		var j := rng.randi() % (i + 1)
		var t = cards[i]
		cards[i] = cards[j]
		cards[j] = t
	# 우연히 그대로면 앞 두 장을 바꾼다
	if cards == app(id).stages[st]:
		var t2 = cards[0]
		cards[0] = cards[1]
		cards[1] = t2
	return cards


## 이 카드가 다음 순서인가 (picked: 지금까지 맞게 누른 수)
static func is_next(id: String, st: int, picked: int, card: String) -> bool:
	var order: Array = app(id).stages[st]
	return picked < order.size() and order[picked] == card


## 한 단계를 마친다 (성공이든 실패든 그날은 끝). 다 만들었으면 보상 글, 아니면 ""
static func finish_stage(gs: Object, id: String, ok: bool) -> String:
	gs.app_day[id] = int(gs.day)
	gs.time_minutes += WORK_MINUTES
	if not ok:
		return ""
	gs.apps[id] = stage(gs, id) + 1
	if not done(gs, id):
		return ""
	gs.flags["app_%s_done" % id] = true
	if REWARD_MONEY.has(id):
		gs.earn(int(REWARD_MONEY[id]))
	var who: String = app(id).who
	gs.friendship[who] = mini(int(gs.friendship.get(who, 0)) + int(REWARD_FRIEND.get(id, 0)), Friends.HEART * Friends.MAX_HEARTS)
	if id == "taesik":
		gs.reputation += 5
	return str(app(id).reward_text)


## 낚시방 값 (조황 앱을 만들면 싸진다)
static func shop_price(flags: Dictionary, price: int) -> int:
	if flags.get("app_junho_done", false):
		return int(roundf(price * SHOP_DISCOUNT / 100.0) * 100.0)
	return price
