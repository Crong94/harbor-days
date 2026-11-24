class_name Quests
extends RefCounted
## 이야기 목록 (2026-11-19 사용자: 퀘스트가 갑자기 생겨서 맥락이 없다. 메인과 서브로 나눠 달라)
##
## 세 갈래로 나눈다.
## - 메인: 1막 줄기. 첫 손님 → 마을에 인사하기 → 네 번의 월요일 → 마을에 스며들다(StoryCh3) → 내 가게 만들기(대출 줄이기). 한 번에 하나만 보인다
## - 서브: 마을 사람 개인 이야기. 그 사람이 직접 부탁한 뒤에만 보인다 (부탁을 듣기 전에는 목록에 없다)
## - 오늘: 날마다 바뀌는 부탁. 가게 문 쪽지(Orders)와 마을회관 게시판(Board)
## 모든 줄에 who(누가)와 why(왜 하는지 한 줄)가 있다. 새 저장 값은 없고 flags와 GameState에서 그때그때 계산한다.
## 장면이 아닌 규칙만 담아 헤드리스로 시험한다. 화면은 DayBrief → DayDrawer가 그린다.
##
## 한 줄: {"id", "kind": "main"/"sub"/"daily", "title", "who", "why", "goal", "progress": "2/4" 또는 "", "target": 장소 id}

## 메인 〈마을에 인사하기〉에서 만날 사람: [met 플래그, 부르는 이름, 장소, 이 날부터, 어디서 만나는지]
const GREET := [
	["met_mansu", "방파제 노인", "breakwater", 2, "아침에 북쪽 방파제"],
	["met_yongpal", "시장 경매사", "market", 2, "물빛 수산시장"],
	["met_kyungja", "경자상회 할머니", "store", 3, "경자상회"],
	["met_bokja", "밥집 사장님", "diner", 4, "복자네 밥집"],
]


## 처음 버티는 주 수, 대출 고비 간격, 처음 대출
const BEAR_WEEKS := 4
const DEBT_STEP := 1_000_000
const START_DEBT := 30_000_000


## 지금 보이는 이야기 전부 (메인, 서브, 오늘 순서)
static func active(gs: Object) -> Array:
	var out: Array = []
	var m := main_quest(gs)
	if not m.is_empty():
		out.append(m)
	out.append_array(sub_quests(gs))
	out.append_array(daily_quests(gs))
	return out


static func of_kind(gs: Object, kind: String) -> Array:
	return active(gs).filter(func(q): return q.kind == kind)


# ─── 메인 ───────────────────────────────────────────

static func main_quest(gs: Object) -> Dictionary:
	var f: Dictionary = gs.flags
	if not f.get("first_guest_done", false):
		return _q("main_first_guest", "main", "첫 번째 손님", "나",
			"서울 생활을 접고 내려왔다. 낡은 식당에 다시 불을 켜 보자.",
			"방파제에서 고기를 잡아 식당 문 열기", "", "breakwater")
	var met := 0
	var next: Array = []
	for g in GREET:
		if f.get(g[0], false):
			met += 1
		elif next.is_empty() and int(gs.day) >= int(g[3]):
			next = g
	if met < GREET.size():
		var goal := "%s 찾아가기 · %s" % [next[1], next[4]] if not next.is_empty() else "내일 또 마을을 돌아보기"
		return _q("main_greet", "main", "마을에 인사하기", "순덕 할머니",
			"\"내일부턴 마을 사람들한테 얼굴도 좀 비추고. 장사는 인심이여.\"",
			goal, "%d/%d" % [met, GREET.size()], next[2] if not next.is_empty() else "")
	var weeks := (int(gs.day) - 1) / Loan.WEEK # 지나간 월요일 수
	if weeks < BEAR_WEEKS or (int(gs.arrears) > 0 and not f.get("act1_done", false)):
		var pay := Loan.next_pay_day(int(gs.day))
		var due := Loan.due(pay, int(gs.monthly_repayment), int(gs.arrears), int(gs.debt))
		var goal2 := "%s까지 %s 모으기 · 지금 %d%%" % [Calendar.text(pay), _won(due), clampi(int(100.0 * float(gs.money) / maxf(1.0, float(due))), 0, 100)]
		if int(gs.arrears) > 0:
			goal2 = "밀린 돈까지 %s 모으기 · %s" % [_won(due), Calendar.text(pay)]
		return _q("main_first_month", "main", "네 번의 월요일", "복자 사장님",
			"\"망하지만 말고 버텨 봐.\" 월요일마다 대출과 월세가 나간다.",
			goal2, "%d/%d주" % [mini(weeks, BEAR_WEEKS), BEAR_WEEKS], "shop")
	# 네 주를 버틴 뒤: 챕터 3 〈마을에 스며들다〉 (StoryCh3)
	var st := StoryCh3.step(gs)
	if not st.is_empty():
		return _q("main_ch3_" + str(st.done), "main", st.title, st.who, st.why, st.goal, st.progress, st.target)
	if int(gs.debt) > 0:
		# 대출 반씩 줄여 가기: 다음 고비까지 얼마
		var step := (int(gs.debt) - 1) / DEBT_STEP * DEBT_STEP
		return _q("main_debt", "main", "내 가게 만들기", "나",
			"이 가게가 온전히 {shop|이/가} 되는 날까지. 집에서 대출을 더 갚을 수 있다.",
			"대출을 %s까지 줄이기 · 지금 %s" % [_won(step), _won(int(gs.debt))], "%d%%" % int(100.0 * (START_DEBT - int(gs.debt)) / START_DEBT), "home")
	return _q("main_wait", "main", "온전한 내 가게", "",
		"대출을 다 갚았다. 이제 {shop|은/는} 온전히 내 가게다.",
		"다음 이야기는 준비 중이에요", "", "")


# ─── 서브 ───────────────────────────────────────────

static func sub_quests(gs: Object) -> Array:
	var f: Dictionary = gs.flags
	var out: Array = []
	# 순덕 〈할머니의 부탁〉: 첫 손님으로 만난 뒤부터, 닭장이 열리면 끝
	if f.get("met_sundeok", false) and not f.get("coop_open", false):
		var q: int = gs.sundeok_quest
		var goal := "할머니 댁에 들러 보기"
		if q > 0 and Coop.current_quest(gs) < 0:
			goal = "오늘은 들어드렸어요. 내일 다시 들르기"
		elif q > 0:
			goal = "다음 부탁 듣기: %s" % Coop.QUESTS[q].title
		out.append(_q("sub_sundeok", "sub", "할머니의 부탁", "순덕 할머니",
			"옆집 할머니. 혼자 지내셔서 이것저것 손이 필요하다.",
			goal, "%d/%d" % [q, Coop.QUESTS.size()], "grandma"))
	# 만수 〈묶어둔 배〉: 감성돔을 올리면 갯바위에 데려가 준다고 한 뒤부터
	if f.get("learned_tide_talk", false) and not f.get("learned_tide", false):
		var caught: bool = f.get("caught_gamseongdom", false)
		out.append(_q("sub_mansu", "sub", "묶어둔 배", "만수 할아버지",
			"\"감성돔 한 마리 올리믄 검은여에 데려가 주꾸마.\"",
			"방파제에서 할아버지께 보여 드리기" if caught else "방파제에서 감성돔 한 마리 올리기",
			"", "breakwater"))
	# 해솔 〈해솔이의 숙제〉: 숙제를 돕기로 한 뒤부터, 복자 할머니 인사까지
	if f.get("hw_haesol", false) and not f.get("ev_haesol_bokja_thanks", false):
		var got := 0
		var next_place := ""
		var next_name := ""
		for h in [["hw_lookout", "lookout", "뒷산 전망대"], ["hw_market", "market", "수산시장 경매 종"], ["hw_store", "store", "경자상회 외상장부"]]:
			if f.get(h[0], false):
				got += 1
			elif next_place.is_empty():
				next_place = h[1]
				next_name = h[2]
		var goal := "자랑거리 모으기 · %s" % next_name
		var target := next_place
		var prog := "%d/3" % got
		if got >= 3 and not f.get("hw_fished", false):
			goal = "해솔이와 방파제에서 낚시하기 · 오후"
			target = "breakwater"
			prog = ""
		elif f.get("hw_fished", false) and not f.get("haesol_hw_done", false):
			goal = "발표 날 분교에 가 보기 · 오후"
			target = "school"
			prog = ""
		elif f.get("haesol_hw_done", false):
			goal = "복자네 밥집에 들르기"
			target = "diner"
			prog = ""
		out.append(_q("sub_haesol", "sub", "해솔이의 숙제", "해솔",
			"\"우리 마을 자랑하기\" 숙제. 마을에 아이가 해솔이 하나라 도와줄 사람이 없다.",
			goal, prog, target))
	# 앱 만들기 (AppWork): 부탁을 들은 뒤부터 다 만들 때까지
	for id in AppWork.APPS:
		if AppWork.started(gs, id) and not AppWork.done(gs, id):
			var ap := AppWork.app(id)
			var today_done: bool = int(gs.app_day.get(id, -1)) == int(gs.day)
			out.append(_q("sub_app_" + id, "sub", ap.title, Friends.person(ap.who).get("call", ap.who), ap.why,
				"오늘은 했어요. 내일 이어서" if today_done else "앱 만들어 주기 · %s" % Locations.get_loc(ap.place).name,
				"%d/%d" % [AppWork.stage(gs, id), ap.stages.size()], "" if today_done else ap.place))
	# 세라와 연구 (Menu): 아직 모르는 요리 가운데 지금 재료가 있는 것 하나
	if gs.flags.get("sera_joined", false):
		for id in Menu.unknown(gs.flags):
			if Menu.can_research(gs, id):
				out.append(_q("sub_menu_" + id, "sub", "세라와 요리 연구", "세라",
					"\"재료만 주면 제가 해 볼게요.\"", "낮에 식당에서 새 요리 연구 · %s" % Menu.needs_text(id), "", "shop"))
				break
	return out


# ─── 오늘 ───────────────────────────────────────────

static func daily_quests(gs: Object) -> Array:
	var out: Array = []
	var o: Dictionary = gs.today_order()
	if not o.is_empty():
		var who := Orders.call_name(o.customer)
		var done: bool = gs.order_done
		out.append(_q("daily_order", "daily", "가게 문 쪽지", who,
			"\"%s\"" % _line(gs, o.line),
			"보냈어요" if done else "%s %d마리 · %s" % [Orders.goal_text(o), o.count, _won(int(o.reward))],
			"" if done else "%d/%d" % [int(gs.order_filled), int(o.count)], "" if done else "breakwater"))
	if gs.flags.get("hall_open", false):
		for p in Board.open_on(int(gs.day), gs.flags):
			var left := Board.days_left(p, int(gs.day))
			out.append(_q("daily_board_" + str(p.id), "daily", "게시판 의뢰", str(p.who),
				"\"%s\"" % str(p.text),
				"%s · %s" % [Board.thing_text(p.kind, p.item, int(p.count)), _won(int(p.reward))],
				"오늘까지" if left <= 0 else "D-%d" % left, "hall"))
	return out


# ─── 도움 ───────────────────────────────────────────

static func _q(id: String, kind: String, title: String, who: String, why: String, goal: String, progress: String, target: String) -> Dictionary:
	return {"id": id, "kind": kind, "title": title, "who": who, "why": why, "goal": goal, "progress": progress, "target": target}


## 이름 템플릿을 바꾼다 (GameState면 line(), 시험용 가짜면 그대로)
static func _line(gs: Object, t: String) -> String:
	return gs.line(t) if gs.has_method("line") else t


static func _won(n: int) -> String:
	var s := str(absi(n))
	var out := ""
	while s.length() > 3:
		out = "," + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return ("-" if n < 0 else "") + s + out + "원"
