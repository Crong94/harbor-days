class_name StoryCh3
extends RefCounted
## 네 번의 월요일을 버틴 뒤 메인 이야기 (2026-11-25). 기획서 1막 마무리와 2막 챕터 3 〈마을에 스며들다〉.
##   한 달 버팀 → 서윤과 연구소 → 경자 장부 속 건우 외상(선택) → 복자 〈두 식당〉 → 민박과 지우 → 민혁 〈한 명을 위한 운동회〉
## EVENTS의 형식은 Story와 같다 (Story.all()이 뒤에 붙여 쓴다). 여기서 더 쓰는 것:
##   friend: {이름: 친밀도}, rep: 평판, take: 가져갈 생선 {"kinds": 서로 다른 어종 수} 또는 {"fish": 마리 수}
##   choice: 대사 뒤 고르는 것 [{"text", "set", "friend", "note", "lines"}]
## STEPS: 메인 이야기 목록 줄 (Quests.main_quest). done 표시가 없는 첫 줄이 지금 할 일이다.

const START_DAY := 29 # 네 번째 월요일 아침
const FEAST_KINDS := 3 # 잔치에 낼 서로 다른 어종
const LUNCH_FISH := 3 # 어르신 점심에 낼 생선
const SPECIMENS := 3 # 서윤에게 보여 줄 표본 어종 수
const INVITES := ["sp_market", "sp_diner", "sp_breakwater", "sp_store"]

const EVENTS := [
	# ── 1막 마무리 ──
	{
		"id": "month_end", "note": "한 달을 버텼다. 은행에서 먼저 전화가 왔다.", "place": "home", "day": START_DAY,
		"needs": ["met_mansu", "met_yongpal", "met_kyungja", "met_bokja"],
		"set": ["act1_done"],
		"lines": [
			{"speaker": "", "text": "마당 평상에 앉아 장부를 펴는데 휴대폰이 울린다. 은행이다."},
			{"speaker": "은행 직원", "text": "{player} 고객님 안녕하세요. 귀촌 창업 대출 담당 도유나입니다."},
			{"speaker": "{player}", "face": "sad", "text": "아 네. 혹시 뭐가 잘못됐나요?"},
			{"speaker": "은행 직원", "text": "아니요. 첫 달 지난 분들께는 제가 한 번씩 전화를 드려요. 사실 이 전화까지 못 오는 분이 많거든요."},
			{"speaker": "은행 직원", "face": "smile", "text": "월요일마다 들어오는 걸 보니 장사는 되시나 봐요. 거기서는 주로 뭘 파세요?"},
			{"speaker": "{player}", "face": "smile", "text": "생선이요. 아침에 제가 잡은 거요."},
			{"speaker": "은행 직원", "face": "smile", "text": "서류에 적힌 사업 계획보다 낫네요. 저도 언젠가 현장 실사 핑계로 먹으러 갈게요."},
			{"speaker": "", "text": "전화를 끊고 나니 바다 냄새가 새삼스럽다. 처음 왔을 때 물빛울포는 그냥 싸게 나온 매물이었다."},
			{"speaker": "{player}", "face": "smile", "text": "한 달이네. 이제 겨우 한 달."},
		],
	},
	{
		"id": "mansu_month", "note": "만수 할아버지가 한 달 버틴 외지 사람은 오랜만이라고 했다.", "place": "breakwater", "day": START_DAY,
		"needs": ["act1_done"], "after": "month_end", "time": [6 * 60, 12 * 60],
		"set": ["mansu_month"], "friend": {"박만수": 6},
		"lines": [
			{"speaker": "", "text": "방파제 끝 만수 할아버지 옆자리에 빈 막걸리 잔이 하나 더 놓여 있다."},
			{"speaker": "박만수", "text": "한 달 됐다매."},
			{"speaker": "{player}", "text": "그걸 세고 계셨어요?"},
			{"speaker": "박만수", "face": "sad", "text": "귀촌한다고 온 사람이 니가 일곱 번째다. 여섯은 짐도 다 안 풀고 갔다."},
			{"speaker": "박만수", "text": "마을 사람들이 니한테 데면데면한 거는 니가 미워서가 아니다. 또 갈까 봐 그라는 기다."},
			{"speaker": "{player}", "text": "저는 갈 데가 없어서 못 가요."},
			{"speaker": "박만수", "face": "smile", "text": "허. 그거 좋은 이유네. 이장이 니 찾더라. 회관에 들러 봐라. 배운 사람이 필요하단다."},
		],
	},
	# ── 서윤과 연구소 ──
	{
		"id": "seoyun_first", "note": "해양생태 연구소의 한서윤 씨를 만났다. 내가 잡은 볼락 얘기를 한참 물었다.", "place": "hall", "day": START_DAY,
		"needs": ["mansu_month", "hall_open"], "after": "mansu_month", "time": [9 * 60, 18 * 60],
		"set": ["chapter3_start", "met_seoyun"],
		"lines": [
			{"speaker": "", "text": "회관 탁자에 바닷물이 뚝뚝 떨어지는 장화를 신은 사람이 앉아 있다. 이장이 반갑게 손을 흔든다."},
			{"speaker": "정태식", "face": "smile", "text": "마침 오셨네요. 이쪽은 연구소 한서윤 연구원이에요. 우리 바다 물고기를 다 세는 분입니다."},
			{"speaker": "한서윤", "text": "다 세지는 못해요. 그래서 왔어요. {player} 씨 맞죠? 방파제에서 매일 낚시하는 분."},
			{"speaker": "{player}", "text": "매일은 아니고 거의 매일이요."},
			{"speaker": "한서윤", "text": "시장에서 {player} 씨가 판 볼락을 봤어요. 이 해역에선 기록이 없는 체색이에요. 어디서 잡았어요? 정확히요."},
			{"speaker": "{player}", "text": "방파제 끝에서 열 걸음쯤 앞이요. 해 뜨기 직전에요."},
			{"speaker": "한서윤", "face": "smile", "text": "열 걸음. 해 뜨기 직전. 좋아요. 그런 게 필요했어요."},
			{"speaker": "정태식", "face": "sad", "text": "연구소가 내년 예산이 어찌 될지 모른답니다. 우리 바다가 특별하다는 자료가 있어야 한다네요."},
			{"speaker": "한서윤", "text": "잡은 고기를 연구소에 한 번 보여 주세요. 재고 사진만 찍고 돌려드려요. 연구비에서 사례도 나가요."},
			{"speaker": "", "text": "지도에 해양생태 연구소가 열렸어요."},
		],
	},
	{
		"id": "seoyun_lab", "note": "연구소에서 표본을 기록하기로 했다. 먼저 세 가지 고기다.", "place": "lab", "day": START_DAY, "needs": ["met_seoyun"],
		"set": ["lab_started"],
		"lines": [
			{"speaker": "", "text": "낡은 이층 건물. 수조마다 이름표가 붙어 있고 벽에는 손으로 그린 바다 지도가 걸려 있다."},
			{"speaker": "한서윤", "text": "왔네요. 저 혼자 쓰는 연구소치고는 넓죠? 작년까지는 네 명이었어요."},
			{"speaker": "{player}", "face": "sad", "text": "다들 어디 갔는데요?"},
			{"speaker": "한서윤", "face": "sad", "text": "예산 따라갔죠. 저는 아직 안 센 물고기가 있어서 남았고요."},
			{"speaker": "{player}", "face": "smile", "text": "안 끝난 일 두고 못 가는 거 뭔지 알아요. 저도 장애 알림 꺼져야 퇴근하던 사람이라."},
			{"speaker": "한서윤", "face": "smile", "text": "그럼 말이 통하겠네요. 우선 서로 다른 고기 세 가지만 보여 주세요. 하루에 한 마리씩이면 돼요."},
			{"speaker": "", "text": "연구소에서 하루 한 번 아이스박스나 수조의 고기를 기록해요. 고기는 그대로 돌려받아요."},
		],
	},
	{
		"id": "seoyun_data", "note": "서윤 씨가 물빛울포 이름의 뜻을 알려 줬다. 물빛이 우는 포구.", "place": "lab", "day": START_DAY, "needs": ["lab_started", "lab_3"],
		"set": ["lab_data"], "friend": {"한서윤": 12},
		"lines": [
			{"speaker": "", "text": "서윤이 화면에 점 세 개를 띄워 놓고 오래 들여다본다."},
			{"speaker": "한서윤", "text": "점이 세 개면 선을 그을 수 있어요. 이제 시작이에요."},
			{"speaker": "{player}", "text": "그런데 이 바다가 왜 특별하다고 생각해요?"},
			{"speaker": "한서윤", "text": "여름밤에 만 안쪽이 파랗게 빛난다는 기록이 있어요. 백 년 전 글에도 나와요. 야광충이죠."},
			{"speaker": "한서윤", "text": "이름도 거기서 왔대요. 물빛이 우는 포구. 그런데 저는 삼 년 동안 한 번도 못 봤어요."},
			{"speaker": "{player}", "text": "물빛이 운다..."},
			{"speaker": "", "text": "처음 듣는 말인데 어디선가 들은 것 같다. 아주 어릴 때. 누가 귀에 대고 말해 준 것처럼."},
			{"speaker": "한서윤", "face": "smile", "text": "계속 보여 주세요. 다음 여름엔 제 눈으로 보고 싶거든요."},
		],
	},
	# ── 경자 장부 속 건우 ──
	{
		"id": "geonwoo_ledger", "note": "외상장부에서 이십 년 된 소주 두 병을 찾았다. 이름은 박건우.", "place": "store", "day": START_DAY, "needs": ["lab_data"], "after": "seoyun_data",
		"set": ["geonwoo_found"],
		"lines": [
			{"speaker": "", "text": "경자 할머니가 장부 한 권을 펼친 채 가만히 있다. 종이 귀퉁이가 닳아서 둥글다."},
			{"speaker": "문경자", "text": "왔나. 거기 좀 앉아 봐라."},
			{"speaker": "", "text": "누렇게 바랜 줄 하나. 소주 두 병. 박건우. 그 줄만 이십 년째 지워지지 않았다."},
			{"speaker": "{player}", "text": "박건우... 만수 할아버지 댁이에요?"},
			{"speaker": "문경자", "face": "sad", "text": "아들이다. 배 나가는 날 아침에 와서 두 병 달라 하데. 하나는 아버지랑 하나는 친구랑 마신다고."},
			{"speaker": "문경자", "face": "sad", "text": "갔다 와서 갚는다고 웃으면서 나갔다. 그게 마지막이다."},
			{"speaker": "{player}", "face": "sad", "text": "그래서 안 지우신 거예요?"},
			{"speaker": "문경자", "text": "지우면 그 아이가 정말 없는 것 같아서. 만수 영감은 이 줄이 있는 줄도 모른다."},
			{"speaker": "문경자", "text": "나는 이제 모르겠다. 니가 보기엔 어떠냐. 알려 주는 게 맞겠나?"},
		],
		"choice": [
			{"text": "만수 할아버지께 전해 드릴게요", "set": ["geonwoo_choice", "geonwoo_told"], "note": "건우 씨 외상을 만수 할아버지께 전하기로 했다.",
				"lines": [
					{"speaker": "문경자", "text": "그래. 나는 못 하겠더라. 니가 해 다오."},
					{"speaker": "", "text": "경자 할머니가 그 장을 조심히 오려 봉투에 넣어 주었다. 아침에 방파제로 가 보자."},
				]},
			{"text": "그냥 간직해 두는 게 좋겠어요", "set": ["geonwoo_choice"], "friend": {"문경자": 15}, "note": "건우 씨 외상은 할머니 장부에 그대로 두기로 했다.",
				"lines": [
					{"speaker": "문경자", "face": "smile", "text": "그래. 이 줄 하나쯤은 안 갚은 채로 둬도 되겠지."},
					{"speaker": "", "text": "경자 할머니는 장부를 덮고 서랍 맨 안쪽에 넣었다."},
				]},
		],
	},
	{
		"id": "mansu_geonwoo", "note": "만수 할아버지는 봉투를 오래 쥐고 있다가 소주 두 병 값을 내밀었다.", "place": "breakwater", "day": START_DAY,
		"needs": ["geonwoo_told"], "after": "geonwoo_ledger", "time": [6 * 60, 12 * 60],
		"set": ["geonwoo_given"], "friend": {"박만수": 20},
		"lines": [
			{"speaker": "{player}", "text": "할아버지. 경자 할머니가 이걸 전해 달래요."},
			{"speaker": "", "text": "만수 할아버지는 종이를 한참 들여다본다. 찌가 잠겼다 떠올라도 돌아보지 않는다."},
			{"speaker": "박만수", "face": "sad", "text": "...두 병이네."},
			{"speaker": "박만수", "face": "sad", "text": "그날 아침에 내가 한 병밖에 안 마셨다. 저녁에 마저 마시자 했거든."},
			{"speaker": "", "text": "파도가 방파제를 세 번쯤 때릴 동안 아무도 말하지 않았다."},
			{"speaker": "박만수", "text": "경자한테 갖다줘라. 소주 두 병 값이다. 외상은 갚아야지."},
			{"speaker": "{player}", "text": "지우지 말라고 하실 것 같은데요."},
			{"speaker": "박만수", "face": "smile", "text": "돈은 받고 줄은 놔두라 캐라. 그 여편네는 그래 할 거다."},
		],
	},
	# ── 〈두 식당〉 ──
	{
		"id": "bokja_feast", "note": "마을 잔치에서 복자 사장님과 요리 대결을 하게 됐다.", "place": "diner", "day": START_DAY, "needs": ["geonwoo_choice"], "after": "geonwoo_ledger",
		"set": ["feast_open"],
		"lines": [
			{"speaker": "", "text": "밥집 벽에 이장이 쓴 종이가 붙어 있다. 물빛울포 봄맞이 마을 잔치."},
			{"speaker": "김복자", "text": "니도 봤제? 잔치 음식은 삼십 년 동안 내가 했다."},
			{"speaker": "{player}", "face": "smile", "text": "저는 먹으러만 갈게요."},
			{"speaker": "김복자", "face": "sad", "text": "그게 안 된다. 어르신들이 {shop|이랑/랑} 우리 집 중에 어데가 맛있냐고 난리다. 순덕 형님이 부추겼다."},
			{"speaker": "{player}", "face": "sad", "text": "저는 굽지도 못하는데요."},
			{"speaker": "김복자", "face": "smile", "text": "니 옆에 세라 있다 아이가. 생선은 니가 잡고 요리는 가가 하고. 나는 나 혼자다. 공평하제?"},
			{"speaker": "", "text": "잔치에 낼 생선으로 서로 다른 고기 세 가지를 아이스박스에 채워 마을회관으로 가요."},
		],
	},
	{
		"id": "bokja_battle", "note": "마을 잔치 요리 대결은 비겼다. 복자 사장님이 해물탕을 가르쳐 줬다.", "place": "hall", "day": START_DAY,
		"needs": ["feast_open", "ready_feast"], "after": "bokja_feast", "time": [9 * 60, 18 * 60],
		"set": ["feast_done", "learn_haemultang"], "take": {"kinds": FEAST_KINDS}, "rep": 8, "money": 50000, "friend": {"김복자": 12, "최순덕": 4, "박만수": 4, "문경자": 4},
		"lines": [
			{"speaker": "", "text": "회관 마당에 천막이 쳐졌다. 솥 두 개가 나란히 김을 뿜고 어르신들이 숟가락을 들고 줄을 섰다."},
			{"speaker": "최세라", "face": "smile", "text": "사장님 오늘 고기 좋네요. 걱정 마요. 저 부산에서 잔치 백 번은 했어요."},
			{"speaker": "김복자", "text": "부산은 부산이고 여기는 물빛울포다!"},
			{"speaker": "", "text": "세라는 세 가지 고기를 얇게 저며 무쳤고 복자는 같은 고기를 한 솥에 넣고 푹 끓였다."},
			{"speaker": "박만수", "text": "무친 거는 씹을수록 바다 맛이 나고. 끓인 거는 속이 풀리네."},
			{"speaker": "최순덕", "face": "smile", "text": "나는 못 고르겠네. 무침 한 입 국물 한 입 하니까 딱 좋구먼."},
			{"speaker": "문경자", "face": "smile", "text": "비긴 걸로 적어 놨어. 장부에 적힌 건 못 바꿔."},
			{"speaker": "김복자", "face": "sad", "text": "...무침 저거 어떻게 한 기고. 식초를 언제 넣노."},
			{"speaker": "최세라", "face": "smile", "text": "알려 드리면 사장님은 뭐 주실 건데요?"},
			{"speaker": "김복자", "face": "smile", "text": "하이고 야 봐라. 좋다. 내 해물탕 육수 알려 주꾸마. 아무한테도 안 준 기다."},
			{"speaker": "", "text": "복자 사장님의 해물탕을 배웠어요. 오늘 저녁부터 메뉴판에서 고를 수 있어요."},
		],
	},
	{
		"id": "bokja_wrist", "note": "복자 사장님 손목이 탈이 났다. 어르신들 점심을 하루 맡기로 했다.", "place": "diner", "day": START_DAY, "needs": ["feast_done"], "after": "bokja_battle",
		"set": ["wrist_asked"],
		"lines": [
			{"speaker": "", "text": "밥집 문에 '오늘 쉽니다'가 붙어 있다. 복자가 손목에 붕대를 감고 평상에 앉아 있다."},
			{"speaker": "{player}", "face": "sad", "text": "손목 왜 그러세요?"},
			{"speaker": "김복자", "face": "sad", "text": "잔치 때 솥을 들다가 삐끗했다. 삼십 년 동안 문 닫은 날이 세 번인데 네 번째가 됐네."},
			{"speaker": "김복자", "face": "sad", "text": "가게야 쉬믄 되는데 회관에 점심 드시러 오는 어르신들이 걱정이다. 내가 안 하믄 다들 찬물에 밥 말아 드신다."},
			{"speaker": "{player}", "text": "제가 생선 들고 갈게요. 세라 씨한테도 부탁해 볼게요."},
			{"speaker": "김복자", "text": "니가?"},
			{"speaker": "김복자", "face": "smile", "text": "...어르신들 이가 안 좋으니까 푹 익히라 캐라. 간은 싱겁게."},
			{"speaker": "", "text": "생선 세 마리를 들고 점심때(11시~14시) 마을회관으로 가요."},
		],
	},
	{
		"id": "bokja_lunch", "note": "회관에서 어르신들 점심을 차렸다. 복자 사장님이 김치를 한 통 줬다.", "place": "hall", "day": START_DAY,
		"needs": ["wrist_asked", "ready_lunch"], "time": [11 * 60, 14 * 60],
		"set": ["lunch_done"], "take": {"fish": LUNCH_FISH}, "rep": 6, "friend": {"김복자": 12, "정태식": 4, "최순덕": 4},
		"lines": [
			{"speaker": "", "text": "회관 방에 상 세 개를 붙였다. 세라가 생선을 푹 익혀 가시를 다 발라 놓았다."},
			{"speaker": "최순덕", "face": "smile", "text": "젊은 사람들이 차려 주는 밥을 다 먹어 보네."},
			{"speaker": "정태식", "text": "저도 한 그릇 먹어도 됩니까? 저는 어르신은 아니지만요."},
			{"speaker": "", "text": "그릇이 다 비었을 때 문가에 복자가 서 있었다. 언제부터 보고 있었는지 모른다."},
			{"speaker": "김복자", "text": "간이 싱겁네."},
			{"speaker": "{player}", "face": "sad", "text": "싱겁게 하라면서요."},
			{"speaker": "김복자", "face": "smile", "text": "그래. 딱 좋다고. 옛다 김치다. 사 먹지 말고 떨어지믄 말해라."},
			{"speaker": "", "text": "이날부터 복자는 손님이 넘치면 {shop|으로/로} 보냈고 {shop|은/는} 점심 손님을 복자네로 보냈다."},
		],
	},
	# ── 민박과 지우 ──
	{
		"id": "jiwoo_first", "note": "버스에서 내린 서지우 씨를 등대민박까지 데려다줬다.", "place": "bus", "day": START_DAY, "needs": ["lunch_done"], "after": "bokja_lunch", "time": [8 * 60, 17 * 60],
		"set": ["met_jiwoo"],
		"lines": [
			{"speaker": "", "text": "버스에서 커다란 화구 가방을 멘 사람이 내린다. 혼자다. 정류장 표지판을 앞뒤로 돌려 본다."},
			{"speaker": "서지우", "text": "저기요. 등대민박이 어느 쪽이에요? 지도 앱에는 바다 한가운데로 나와서요."},
			{"speaker": "{player}", "face": "smile", "text": "그 앱이 여기는 잘 몰라요. 저 빨간 등대 쪽 언덕이에요. 같이 가요."},
			{"speaker": "서지우", "face": "smile", "text": "감사합니다! 저는 서지우예요. 그림 그려요. 한 달만 살아 보려고 왔어요."},
			{"speaker": "{player}", "text": "한 달이요. 저도 처음엔 한 달만 버텨 보자 했는데."},
			{"speaker": "서지우", "text": "{player} 씨도 도망쳐 온 거예요?"},
			{"speaker": "", "text": "대답하기 전에 파도 소리가 먼저 났다."},
			{"speaker": "서지우", "face": "sad", "text": "...아 저도요."},
			{"speaker": "", "text": "지도에 등대민박이 열렸어요."},
		],
	},
	{
		"id": "mija_house", "note": "등대민박 미자 아주머니가 조식 생선을 부탁했다.", "place": "guesthouse", "day": START_DAY, "needs": ["met_jiwoo"],
		"set": ["met_mija", "inn_open"],
		"lines": [
			{"speaker": "", "text": "마당에 이불 빨래가 펄럭인다. 사다리 위에서 처마를 고치던 아저씨가 고개만 끄덕인다."},
			{"speaker": "윤미자", "face": "smile", "text": "어머 {shop} 사장님 아니야! 지우 데려다줬다며? 들어와 들어와. 저 양반은 우리 남편 강덕배. 원래 말이 없어."},
			{"speaker": "{player}", "face": "smile", "text": "방이 많네요."},
			{"speaker": "윤미자", "face": "sad", "text": "다섯 갠데 네 개가 창고야. 삼십 년 전 순덕 언니가 물빛여관 하던 걸 우리가 받았거든. 그땐 방이 모자랐는데."},
			{"speaker": "윤미자", "text": "손님이 와도 아침이 걱정이야. 요새 사람들은 조식을 보고 온다잖아."},
			{"speaker": "{player}", "text": "생선은 제가 갖다드릴 수 있어요."},
			{"speaker": "윤미자", "face": "smile", "text": "정말? 그럼 우리 손님들 저녁은 {shop|으로/로} 보낼게. 서로 좋잖아!"},
			{"speaker": "", "text": "등대민박에 하루 한 번 조식 생선을 낼 수 있어요. 생선을 내면 다음 날 저녁에 민박 손님이 한 명 더 와요."},
		],
	},
	{
		"id": "jiwoo_menu", "note": "지우 씨가 우리 가게 메뉴판을 새로 그려 줬다.", "place": "guesthouse", "day": START_DAY, "needs": ["inn_open"], "after": "mija_house", "time": [14 * 60, 19 * 60],
		"set": ["jiwoo_menu"], "rep": 10, "friend": {"서지우": 12, "윤미자": 4},
		"lines": [
			{"speaker": "", "text": "평상에 물감이 널려 있다. 지우가 두꺼운 종이를 등 뒤로 숨긴다."},
			{"speaker": "서지우", "text": "아직 보면 안 되는데. 아니다 그냥 보세요. 어제 {shop}에서 먹은 거 그린 거예요."},
			{"speaker": "", "text": "메뉴판이다. 볼락은 눈이 동그랗고 접시에서는 김이 오른다. 글씨는 바람에 조금 기울어 있다."},
			{"speaker": "{player}", "face": "smile", "text": "이거 저희 가게에 걸어도 돼요?"},
			{"speaker": "서지우", "face": "smile", "text": "그러려고 그렸어요. 저 반년 동안 한 장도 못 그렸거든요. 근데 밥 먹고 왔더니 손이 움직였어요."},
			{"speaker": "서지우", "face": "sad", "text": "서울에서는 그림이 다 숫자였어요. 몇 명이 봤는지 얼마에 팔렸는지."},
			{"speaker": "{player}", "text": "저도 그랬어요. 저는 장애 건수였고요."},
			{"speaker": "서지우", "face": "smile", "text": "그럼 우리 오늘은 안 세기로 해요. 한 달 뒤에 갈지 말지도요."},
			{"speaker": "", "text": "새 메뉴판을 걸었다. 들어오던 손님들이 문 앞에서 한 번씩 멈춰 선다."},
		],
	},
	# ── 〈한 명을 위한 운동회〉 ──
	{
		"id": "minhyuk_ask", "note": "분교 정민혁 선생님이 학생 한 명뿐인 운동회를 열고 싶어 한다.", "place": "school", "day": START_DAY, "needs": ["jiwoo_menu", "met_haesol"], "after": "jiwoo_menu",
		"set": ["met_minhyuk", "sports_ask"],
		"lines": [
			{"speaker": "", "text": "운동장에서 누가 혼자 하얀 줄을 긋고 있다. 줄은 자꾸 바람에 지워진다."},
			{"speaker": "정민혁", "face": "smile", "text": "아 해솔이가 말한 낚시 아저씨시군요. 담임 정민혁입니다. 학생이 하나라 교장도 급식도 저예요."},
			{"speaker": "{player}", "text": "뭐 하시는 거예요?"},
			{"speaker": "정민혁", "text": "운동회 준비요. 해솔이가 한 번도 못 해 봤거든요. 이어달리기를 하려면 이어받을 사람이 있어야 하는데."},
			{"speaker": "정민혁", "face": "sad", "text": "다들 애 하나 두고 무슨 운동회냐고 하세요. 근데 학생 한 명도 학생이잖아요. 운동회는 해야죠."},
			{"speaker": "{player}", "face": "smile", "text": "그럼 이어받을 사람을 데려오면 되겠네요."},
			{"speaker": "정민혁", "face": "smile", "text": "부탁드려도 될까요? 시장이랑 밥집이랑 방파제랑 경자상회. 네 군데만 와 주셔도 편이 갈라져요."},
			{"speaker": "", "text": "수산시장, 복자네 밥집, 북쪽 방파제(아침), 경자상회에 들러 운동회에 와 달라고 해 봐요."},
		],
	},
	{
		"id": "sp_market", "note": "용팔 아저씨가 운동회에 종을 들고 온단다.", "place": "market", "day": START_DAY, "needs": ["sports_ask"], "set": ["sp_market"], "friend": {"오용팔": 4},
		"lines": [
			{"speaker": "오용팔", "text": "운동회? 내가 달리기를 하믄 무릎이 경매에 나갈 판인데."},
			{"speaker": "{player}", "face": "smile", "text": "그럼 출발 신호라도 해 주세요. 총이 없대요."},
			{"speaker": "오용팔", "face": "smile", "text": "신호? 그거는 종이지! 이 종을 떼 가꾸마. 칠십 년 만에 운동회 구경 시켜 주자."},
		],
	},
	{
		"id": "sp_diner", "note": "복자 사장님이 김밥을 백 줄 싸겠다고 했다.", "place": "diner", "day": START_DAY, "needs": ["sports_ask"], "set": ["sp_diner"], "friend": {"김복자": 4},
		"lines": [
			{"speaker": "김복자", "face": "sad", "text": "해솔이 운동회라꼬? 왜 나한테 먼저 말을 안 했노. 그 아가 또 할매 힘들까 봐 그랬제."},
			{"speaker": "{player}", "text": "손목은 괜찮으세요?"},
			{"speaker": "김복자", "face": "smile", "text": "손목이 문제가. 김밥을 백 줄을 싸도 싼다. 온 동네 사람 다 데리고 온나!"},
		],
	},
	{
		"id": "sp_breakwater", "note": "만수 할아버지는 바쁘다면서 몇 시냐고 물었다.", "place": "breakwater", "day": START_DAY, "needs": ["sports_ask"], "time": [6 * 60, 12 * 60], "set": ["sp_breakwater"], "friend": {"박만수": 4},
		"lines": [
			{"speaker": "박만수", "text": "바쁘다."},
			{"speaker": "{player}", "text": "찌만 보고 계시잖아요."},
			{"speaker": "박만수", "text": "...줄다리기는 하나?"},
			{"speaker": "{player}", "face": "smile", "text": "네. 근데 사람이 모자라서 할지 말지 모르겠대요."},
			{"speaker": "박만수", "face": "smile", "text": "몇 시고."},
		],
	},
	{
		"id": "sp_store", "note": "경자 할머니가 운동회 상품으로 공책을 내놓았다.", "place": "store", "day": START_DAY, "needs": ["sports_ask"], "set": ["sp_store"], "friend": {"문경자": 4},
		"lines": [
			{"speaker": "문경자", "text": "운동회엔 공책이지. 손등에 도장 찍어 주고 공책 한 권씩."},
			{"speaker": "{player}", "text": "얼마 드리면 돼요?"},
			{"speaker": "문경자", "face": "smile", "text": "외상이다. 해솔이가 커서 갚으라 캐라. 내가 그때까지 가게 보고 있을 테니."},
		],
	},
	{
		"id": "sports_day", "note": "한 명을 위한 운동회에 온 마을이 모였다. 오늘은 오래 기억날 것 같다.", "place": "school", "day": START_DAY,
		"needs": ["sports_ask", "sp_market", "sp_diner", "sp_breakwater", "sp_store"], "after": "minhyuk_ask", "time": [9 * 60, 17 * 60],
		"set": ["ch3_done"], "rep": 15,
		"friend": {"김해솔": 15, "정민혁": 12, "김복자": 6, "박만수": 6, "문경자": 6, "오용팔": 6, "최순덕": 6, "정태식": 6, "이준호": 6, "한서윤": 6, "서지우": 6, "윤미자": 6},
		"lines": [
			{"speaker": "", "text": "운동장에 만국기 대신 고깃배 깃발이 걸렸다. 의자가 모자라 다들 생선 상자를 뒤집어 앉았다."},
			{"speaker": "김해솔", "face": "smile", "text": "선생님! 사람이 왜 이렇게 많아요? 다 우리 학교에 온 거예요?"},
			{"speaker": "정민혁", "face": "smile", "text": "응. 다 네 운동회에 온 거야."},
			{"speaker": "오용팔", "face": "smile", "text": "자 출발선! 하나 둘!"},
			{"speaker": "", "text": "경매 종이 울렸다. 온 마을을 깨우던 그 소리다. 시장 쪽 갈매기들이 한꺼번에 날아올랐다."},
			{"speaker": "", "text": "이어달리기는 해솔이가 준호에게, 준호가 서윤에게, 서윤이 지우에게, 지우가 나에게 바통을 넘겼다."},
			{"speaker": "이준호", "face": "smile", "text": "형 뒤에서 세라 씨가 쫓아와요! 뛰어요!"},
			{"speaker": "", "text": "줄다리기는 만수 할아버지가 앉은 편이 이겼다. 할아버지는 앉은 채로 한 걸음도 안 끌려갔다."},
			{"speaker": "정태식", "face": "sad", "text": "이 마을 사람이 이렇게 한자리에 모인 게... 저 이장 하고 처음입니다."},
			{"speaker": "최순덕", "face": "smile", "text": "모일 일이 없어서 못 모였지. 모일 일을 만드니까 오는 거여."},
			{"speaker": "김복자", "face": "smile", "text": "보소 다들! 김밥 식는다! {player|아/야} 니도 이리 앉아라. 니 자리 여다."},
			{"speaker": "", "text": "복자가 빈 생선 상자를 손바닥으로 탁탁 쳤다. 내 자리였다."},
			{"speaker": "김해솔", "face": "smile", "text": "아저씨 저 손등에 도장 일곱 개 받았어요! 전부 일 등이에요!"},
			{"speaker": "{player}", "face": "smile", "text": "혼자 뛰었으니까?"},
			{"speaker": "김해솔", "face": "smile", "text": "아니요. 다 같이 뛰었으니까요."},
			{"speaker": "", "text": "〈마을에 스며들다〉를 마쳤어요."},
		],
	},
]

## 메인 이야기 줄: done(끝 표시), ev(그 사건 id, after를 기다릴 때 씀), title, who, why, goal, target, pre([표시, 할 일, 장소] 먼저 할 일)
const STEPS := [
	{"done": "act1_done", "ev": "month_end", "title": "한 달", "who": "나", "why": "네 번의 월요일이 지났다. 집에서 숨 좀 돌리자.", "goal": "낮에 우리 집에 들르기", "target": "home"},
	{"done": "mansu_month", "ev": "mansu_month", "title": "한 달", "who": "만수 할아버지", "why": "방파제에서 할아버지가 기다린다.", "goal": "아침에 북쪽 방파제 가기 · ~12:00", "target": "breakwater"},
	{"done": "met_seoyun", "ev": "seoyun_first", "title": "물빛의 정체", "who": "이장님", "why": "\"이장이 니 찾더라. 배운 사람이 필요하단다.\"", "goal": "마을회관 들르기 · 9:00~18:00", "target": "hall",
		"pre": ["hall_open", "경자상회에서 이장님 만나기 · 9:00~19:00", "store"]},
	{"done": "lab_started", "ev": "seoyun_lab", "title": "물빛의 정체", "who": "서윤", "why": "\"이 해역에선 기록이 없는 체색이에요.\"", "goal": "해양생태 연구소 가 보기", "target": "lab"},
	{"done": "lab_data", "ev": "seoyun_data", "title": "물빛의 정체", "who": "서윤", "why": "이 바다가 특별하다는 자료가 있어야 연구소가 남는다.", "goal": "연구소에 서로 다른 고기 기록하기", "target": "lab"},
	{"done": "geonwoo_choice", "ev": "geonwoo_ledger", "title": "지우지 않은 외상", "who": "경자 할머니", "why": "할머니가 요즘 장부 한 권을 펴 놓고 앉아 계신다.", "goal": "경자상회 들르기", "target": "store"},
	{"done": "geonwoo_given", "ev": "mansu_geonwoo", "only": "geonwoo_told", "title": "지우지 않은 외상", "who": "경자 할머니", "why": "\"나는 못 하겠더라. 니가 해 다오.\"", "goal": "만수 할아버지께 봉투 전하기 · 아침 방파제", "target": "breakwater"},
	{"done": "feast_open", "ev": "bokja_feast", "title": "두 식당", "who": "복자 사장님", "why": "밥집 벽에 마을 잔치 종이가 붙었다.", "goal": "복자네 밥집 들르기", "target": "diner"},
	{"done": "feast_done", "ev": "bokja_battle", "title": "두 식당", "who": "복자 사장님", "why": "\"생선은 니가 잡고 요리는 세라가 하고. 공평하제?\"", "goal": "서로 다른 고기 세 가지 들고 회관 가기 · 9:00~18:00", "target": "hall"},
	{"done": "wrist_asked", "ev": "bokja_wrist", "title": "두 식당", "who": "복자 사장님", "why": "잔치가 끝나고 밥집이 조용하다.", "goal": "복자네 밥집 들르기", "target": "diner"},
	{"done": "lunch_done", "ev": "bokja_lunch", "title": "두 식당", "who": "복자 사장님", "why": "\"내가 안 하믄 다들 찬물에 밥 말아 드신다.\"", "goal": "생선 세 마리 들고 회관 가기 · 11:00~14:00", "target": "hall"},
	{"done": "met_jiwoo", "ev": "jiwoo_first", "title": "한 달 더", "who": "나", "why": "버스에서 누가 내린다는 소문이다.", "goal": "버스 정류장 가 보기 · 8:00~17:00", "target": "bus"},
	{"done": "inn_open", "ev": "mija_house", "title": "한 달 더", "who": "지우", "why": "지우를 데려다준 등대민박에 인사하러 가자.", "goal": "등대민박 들르기", "target": "guesthouse"},
	{"done": "jiwoo_menu", "ev": "jiwoo_menu", "title": "한 달 더", "who": "지우", "why": "지우가 평상에서 무언가를 그리고 있다고 한다.", "goal": "오후에 등대민박 가기 · 14:00~19:00", "target": "guesthouse"},
	{"done": "sports_ask", "ev": "minhyuk_ask", "title": "한 명을 위한 운동회", "who": "민혁 선생님", "why": "분교 운동장에 누가 하얀 줄을 긋고 있다.", "goal": "물빛분교 들르기", "target": "school",
		"pre": ["met_haesol", "오후에 복자네 밥집에서 해솔이 만나기 · 14:00~19:00", "diner"]},
	{"done": "sp_all", "ev": "", "title": "한 명을 위한 운동회", "who": "민혁 선생님", "why": "\"이어달리기를 하려면 이어받을 사람이 있어야 하는데.\"", "goal": "운동회에 와 달라고 하기", "target": ""},
	{"done": "ch3_done", "ev": "sports_day", "title": "한 명을 위한 운동회", "who": "민혁 선생님", "why": "\"학생 한 명도 학생이잖아요. 운동회는 해야죠.\"", "goal": "운동회 날 분교 가기 · 9:00~17:00", "target": "school"},
]
const INVITE_NAMES := {"sp_market": ["수산시장", "market"], "sp_diner": ["복자네 밥집", "diner"], "sp_breakwater": ["아침 방파제", "breakwater"], "sp_store": ["경자상회", "store"]}


static func event(id: String) -> Dictionary:
	for e in EVENTS:
		if e.id == id:
			return e
	return {}


static func invited(flags: Dictionary) -> int:
	return INVITES.filter(func(k): return flags.get(k, false)).size()


static func _done(s: Dictionary, flags: Dictionary) -> bool:
	if s.has("only") and not flags.get(s.only, false):
		return true
	if s.done == "sp_all":
		return invited(flags) >= INVITES.size()
	return flags.get(s.done, false)


## 지금 할 메인 이야기 줄. 다 했으면 빈 Dictionary
static func step(gs: Object) -> Dictionary:
	var f: Dictionary = gs.flags
	for s in STEPS:
		if _done(s, f):
			continue
		var out: Dictionary = s.duplicate()
		out["progress"] = ""
		if s.has("pre") and not f.get(s.pre[0], false):
			out.goal = s.pre[1]
			out.target = s.pre[2]
			return out
		var ev := event(s.ev)
		if ev.has("after") and int(f.get("evday_" + str(ev.after), 0)) >= int(gs.day):
			out.goal = "오늘은 여기까지. 내일 이어져요"
			out.target = ""
			return out
		match s.done:
			"lab_data":
				var n := mini(gs.specimens.size(), SPECIMENS)
				out.progress = "%d/%d" % [n, SPECIMENS]
				if n >= SPECIMENS:
					out.goal = "연구소에서 서윤과 이야기하기"
			"feast_done":
				out.progress = "%d/%d" % [mini(kinds(gs.inventory), FEAST_KINDS), FEAST_KINDS]
			"lunch_done":
				out.progress = "%d/%d" % [mini(gs.inventory.size(), LUNCH_FISH), LUNCH_FISH]
			"sp_all":
				out.progress = "%d/%d" % [invited(f), INVITES.size()]
				for k in INVITES:
					if not f.get(k, false):
						out.goal = "운동회에 와 달라고 하기 · %s" % INVITE_NAMES[k][0]
						out.target = INVITE_NAMES[k][1]
						break
		return out
	return {}


static func kinds(inventory: Array) -> int:
	var seen := {}
	for e in inventory:
		seen[e.id] = true
	return seen.size()


## 가져갈 생선을 값싼 것부터 꺼낸다 (kinds면 어종마다 하나)
static func take(gs: Object, t: Dictionary) -> void:
	var list: Array = gs.inventory.duplicate()
	list.sort_custom(func(a, b): return FishDB.value_of(a.id, a.size) < FishDB.value_of(b.id, b.size))
	var left := int(t.get("kinds", t.get("fish", 0)))
	var seen := {}
	for e in list:
		if left <= 0:
			return
		if t.has("kinds") and seen.has(e.id):
			continue
		seen[e.id] = true
		gs.inventory.erase(e)
		left -= 1
