class_name Story
extends RefCounted
## 1년 차 봄 첫 주 이야기 (기획서 챕터 2~3 앞부분). 순덕 할머니 부탁과 닭장은 Coop이 맡는다. 장면이 아닌 규칙과 대사만 담아 헤드리스로 시험한다.
##
## 사건: 지도에서 그 장소로 가면 한 번만 나오는 대화. 조건이 맞는 것 중 목록 앞의 것 하나만 나온다.
##   place: 장소 id, day: 이 날부터, needs: 먼저 켜져 있어야 할 flags, time: [시작, 끝] 분 (없으면 아무 때나)
##   set: 끝나면 켤 flags, money: 받는 돈. 본 사건은 flags["ev_<id>"]로, 본 날은 flags["evday_<id>"]로 표시한다
##   after: 이 사건을 본 다음 날부터 (같은 날엔 안 나옴)
## 잡담: 장소 화면이 아직 없는 곳에 가면 나오는 짧은 대화. 날짜마다 돌아가며 나온다 (지금까지 "준비 중" 토스트였던 자리)
##
## 대사 규칙 (CLAUDE.md): 자연스러운 구어체, 쉼표 남발과 줄표 금지. 이름은 {player}, {shop} 템플릿

const EVENTS := [
	{
		"id": "mansu_mend", "note": "방파제 노인은 박만수 할아버지였다. 견제하는 법을 배웠다.", "place": "breakwater", "day": 2, "needs": ["first_guest_done"], "time": [6 * 60, 12 * 60],
		"set": ["met_mansu"],
		"lines": [
			{"speaker": "", "text": "방파제 끝에 어제 그 노인이 또 앉아 있다. 오늘은 혼자 막걸리 한 병을 옆에 두었다."},
			{"speaker": "박만수", "face": "smile", "text": "또 왔나. 서울 양반 생각보다 부지런하네."},
			{"speaker": "{player}", "face": "smile", "text": "어제 말씀해 주신 대로 해 보려고요. 저는 {player|이에요/예요}."},
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
			{"speaker": "{player}", "face": "smile", "text": "네. {shop|을/를} 시작한 {player|이에요/예요}."},
			{"speaker": "오용팔", "face": "sad", "text": "나는 여기 경매 보는 오용팔이다. 예전엔 새벽마다 배가 스무 척씩 들어왔는데 요새는 종 칠 일이 없어."},
			{"speaker": "오용팔", "face": "smile", "text": "잡은 고기 남으면 가져와. 흔한 건 식당에서 굽는 게 낫고 비싼 놈은 내가 도시로 넘겨 줄게."},
			{"speaker": "", "text": "수산시장은 새벽 5시부터 오후 5시까지 열어요. 잡은 다음 날 밤이면 생선이 상하니 그 전에 팔아요."},
		],
	},
	{
		"id": "kyungja_store", "note": "경자상회 할머니 서랍에 외상장부가 수십 권 있었다.", "place": "store", "day": 3, "needs": [],
		"set": ["met_kyungja"],
		"lines": [
			{"speaker": "", "text": "유리문에 붙은 담배 광고가 다 바랬다. 계산대 뒤에 작은 할머니가 장부를 넘기고 있다."},
			{"speaker": "문경자", "text": "{shop} 사장이지? 순덕 언니한테 들었어."},
			{"speaker": "{player}", "face": "smile", "text": "벌써 소문이 났네요."},
			{"speaker": "문경자", "face": "smile", "text": "이 동네는 하루면 다 알아. 나는 문경자. 여기서 오십 년째 가게 본다."},
			{"speaker": "", "text": "계산대 옆 서랍에 손때 묻은 공책이 수십 권 쌓여 있다."},
			{"speaker": "{player}", "text": "그게 다 장부예요?"},
			{"speaker": "문경자", "face": "sad", "text": "외상장부. 마을 사람 누가 뭘 얼마나 가져갔는지 다 여기 있어. 안 갚은 사람도 있고 못 갚게 된 사람도 있고."},
			{"speaker": "문경자", "face": "smile", "text": "소금이나 양념 떨어지면 와. 식당 하는 사람한테는 싸게 줄게."},
		],
	},
	{
		"id": "bokja_diner", "note": "복자네 밥집 사장님이 망하지만 말고 버텨 보라고 했다.", "place": "diner", "day": 4, "needs": [],
		"set": ["met_bokja"],
		"lines": [
			{"speaker": "", "text": "점심 장사를 막 끝낸 밥집에서 고소한 냄새가 흘러나온다. 앞치마를 두른 아주머니가 팔짱을 끼고 나온다."},
			{"speaker": "김복자", "face": "sad", "text": "니가 그 새로 온 식당 사장이가? 우리 집 손님 뺏으러 왔나."},
			{"speaker": "{player}", "face": "sad", "text": "아니에요. 저는 저녁에만 열고 잡은 생선만 구워요."},
			{"speaker": "김복자", "face": "sad", "text": "흥. 생선 굽는 게 쉬운 줄 아나 보네. 순덕 형님이 간이 세다 카던데."},
			{"speaker": "{player}", "face": "sad", "text": "그 얘기 벌써 들으셨어요?"},
			{"speaker": "김복자", "text": "이 마을에 비밀이 어디 있노. 나는 김복자다. 이 마을 밥은 삼십 년 동안 내가 했다."},
			{"speaker": "김복자", "face": "smile", "text": "그래도 불 꺼진 데 불 켜진 건 좋다. 망하지만 말고 버텨 봐라."},
		],
	},
	{
		"id": "mansu_tide", "note": "만수 할아버지한테 물때를 배웠다. 감성돔 한 마리 올리면 갯바위에 데려가 준단다.", "place": "breakwater", "day": 5, "needs": ["met_mansu"], "time": [6 * 60, 12 * 60],
		"set": ["learned_tide_talk"],
		"lines": [
			{"speaker": "박만수", "text": "니 물때 볼 줄 아나."},
			{"speaker": "{player}", "text": "물때요? 화면 위에 7물 이런 거요?"},
			{"speaker": "박만수", "text": "바다는 보름마다 숨을 크게 쉬었다 작게 쉬었다 한다. 물이 많이 움직이는 사리 때는 고기가 밥 먹으러 나온다."},
			{"speaker": "박만수", "face": "sad", "text": "조금 무시 때는 물이 잠잠해서 고기도 게으르다. 그런 날은 일찍 들어가서 가게나 봐라."},
			{"speaker": "박만수", "text": "검은여 갯바위는 물이 빠져야 들어간다. 물때 모르고 들어가믄 바다가 길을 막아 뿐다."},
			{"speaker": "{player}", "face": "smile", "text": "거기 데려가 주실 수 있어요?"},
			{"speaker": "박만수", "face": "sad", "text": "...아직은 멀었다. 여기서 감성돔 한 마리 올리믄 그때 생각해 보자."},
			{"speaker": "", "text": "위쪽 헤더에 '물때 좋음'이 뜨는 날은 입질이 빨라요."},
		],
	},
	{
		# 기획서 5장 김해솔: 복자의 손녀, 물빛분교의 유일한 학생, 질문이 끝이 없다. 고양이 고등어와 논다
		"id": "haesol_first", "note": "복자네 손녀 해솔이를 만났다. 질문이 끝이 없다.", "place": "diner", "day": 6, "needs": ["met_bokja"], "time": [14 * 60, 19 * 60],
		"set": ["met_haesol"],
		"lines": [
			{"speaker": "", "text": "밥집 평상에 책가방을 멘 여자아이가 엎드려 공책에 뭔가를 쓰고 있다. 발치에서 고등어 무늬 고양이가 졸고 있다."},
			{"speaker": "김해솔", "text": "아저씨가 그 새로 생긴 식당 사장님이에요?"},
			{"speaker": "{player}", "face": "smile", "text": "응. {shop} 하는 {player|이야/야}."},
			{"speaker": "김해솔", "face": "smile", "text": "저는 김해솔이에요. 여기 밥집이 우리 할머니 가게예요. 아저씨는 왜 서울에서 왔어요? 서울엔 바다 없어요?"},
			{"speaker": "{player}", "face": "sad", "text": "바다가 멀었어. 맨날 모니터만 보고 살았거든."},
			{"speaker": "김해솔", "text": "모니터요? 그럼 고등어는 왜 이름이 고등어예요? 얘 이름도 고등어예요."},
			{"speaker": "{player}", "face": "smile", "text": "그건 아저씨도 모르겠다. 다음에 같이 찾아볼까?"},
			{"speaker": "김해솔", "face": "sad", "text": "좋아요. 근데 저 숙제가 우리 마을 자랑하기인데 쓸 게 하나도 없어요. 학교에 학생이 저 하나뿐이라서요."},
			{"speaker": "김해솔", "face": "smile", "text": "아저씨 분교에 놀러 와요! 선생님도 맨날 심심하대요."},
			{"speaker": "", "text": "지도에 물빛분교가 열렸어요. 해솔이는 학교 끝난 오후에 마을을 돌아다녀요."},
		],
	},
	# ── 해솔 개인 퀘스트 〈해솔이의 숙제〉 (기획서 5장): '우리 마을 자랑하기' 숙제를 돕고 낚시를 가르쳐 준다.
	#    분교에서 숙제를 받고 → 전망대, 시장, 경자상회에서 자랑 세 가지 → 방파제에서 해솔이 첫 볼락 → 분교에서 발표 → 밥집에서 복자가 고마워함
	#    모두 해솔이 학교 끝난 오후(14~19시)에만. 진행은 flags hw_* (HAESOL_HW_STEPS)
	{
		"id": "haesol_hw_start", "note": "해솔이 숙제 '우리 마을 자랑하기'를 돕기로 했다. 자랑 세 가지를 모으자.", "place": "school", "day": 7, "needs": ["met_haesol"], "time": [14 * 60, 19 * 60],
		"set": ["hw_haesol"],
		"lines": [
			{"speaker": "", "text": "교실 창가 책상 하나에 해솔이가 턱을 괴고 앉아 있다. 칠판에 '우리 마을 자랑하기 발표'라고 적혀 있다."},
			{"speaker": "김해솔", "face": "smile", "text": "아저씨 진짜 왔네요! 고등어도 데려올 걸 그랬어요."},
			{"speaker": "{player}", "text": "숙제는 좀 썼어?"},
			{"speaker": "김해솔", "face": "sad", "text": "하나도 못 썼어요. 선생님은 마을 어른들한테 물어보래요. 근데 다들 이 동네엔 자랑할 게 없대요."},
			{"speaker": "{player}", "face": "smile", "text": "그럼 같이 물어보러 다니자. 아저씨도 이 마을 아직 잘 몰라서 궁금하거든."},
			{"speaker": "김해솔", "face": "smile", "text": "진짜요? 그럼 세 개만 찾아요. 세 개면 발표할 수 있어요!"},
			{"speaker": "", "text": "해솔이와 마을 자랑 세 가지를 모아요. 오후에 뒷산 전망대, 수산시장, 경자상회에 가 보세요."},
		],
	},
	{
		"id": "hw_lookout", "note": "해솔이 숙제 하나: 뒷산 전망대에서 보는 마을.", "place": "lookout", "day": 7, "needs": ["hw_haesol"], "time": [14 * 60, 19 * 60],
		"set": ["hw_lookout"],
		"lines": [
			{"speaker": "", "text": "정자에 오르니 해솔이가 먼저 와서 숨을 몰아쉬고 있다."},
			{"speaker": "김해솔", "text": "여기 맨날 오는 덴데 이게 자랑이에요?"},
			{"speaker": "{player}", "text": "저기 봐. 빨간 등대랑 섬들이 줄 서 있잖아. 서울에서는 이런 거 보려면 돈 내고 비행기 타야 해."},
			{"speaker": "김해솔", "face": "smile", "text": "우와. 그럼 우리 마을은 공짜로 보는 거네요. 하나 적었어요!"},
		],
	},
	{
		"id": "hw_market", "note": "해솔이 숙제 둘: 수산시장 경매 종.", "place": "market", "day": 7, "needs": ["hw_haesol", "met_yongpal"], "time": [14 * 60, 17 * 60],
		"set": ["hw_market"],
		"lines": [
			{"speaker": "", "text": "해솔이가 경매 종 앞에 쪼그려 앉아 있다. 용팔 아저씨가 종을 닦다가 웃는다."},
			{"speaker": "오용팔", "face": "smile", "text": "해솔이 숙제가? 이 종은 내 아버지 때부터 쳤다. 칠십 년도 넘었지."},
			{"speaker": "김해솔", "text": "칠십 년이요? 우리 할머니보다 나이 많아요?"},
			{"speaker": "오용팔", "text": "그렇지. 배가 들어오면 이 종이 온 마을을 깨웠다. 요새는 쉬는 날이 많아서 그렇지."},
			{"speaker": "{player}", "face": "smile", "text": "아저씨가 고기 많이 잡아 오면 이 종도 자주 울리겠네."},
			{"speaker": "김해솔", "face": "smile", "text": "두 개째! 칠십 살 먹은 종이요."},
		],
	},
	{
		"id": "hw_store", "note": "해솔이 숙제 셋: 경자상회 외상장부.", "place": "store", "day": 7, "needs": ["hw_haesol", "met_kyungja"], "time": [14 * 60, 19 * 60],
		"set": ["hw_store"],
		"lines": [
			{"speaker": "", "text": "해솔이가 계산대에 매달려 경자 할머니 장부를 들여다보고 있다."},
			{"speaker": "문경자", "text": "이건 보면 안 돼. 어른들 비밀이야."},
			{"speaker": "김해솔", "face": "sad", "text": "그럼 뭐가 자랑이에요?"},
			{"speaker": "문경자", "face": "smile", "text": "돈 없을 때 그냥 가져가라고 할 수 있는 가게. 오십 년 동안 그런 데가 여기 하나 있었다고 써."},
			{"speaker": "{player}", "text": "그거 진짜 자랑이네요. 서울엔 그런 가게 없어요."},
			{"speaker": "김해솔", "face": "smile", "text": "세 개째예요! 근데 아저씨 하나 더 하고 싶어요. 저 낚시 해 보고 싶어요."},
		],
	},
	{
		"id": "hw_fishing", "note": "해솔이가 방파제에서 첫 볼락을 잡았다. 내 첫 물고기도 볼락이었다.", "place": "breakwater", "day": 7,
		"needs": ["hw_lookout", "hw_market", "hw_store"], "time": [14 * 60, 19 * 60],
		"set": ["hw_fished"],
		"lines": [
			{"speaker": "", "text": "방파제 끝에 해솔이가 작은 대나무 낚싯대를 들고 서 있다. 할머니 창고에서 찾았다고 한다."},
			{"speaker": "김해솔", "text": "아저씨 이거 어떻게 해요? 할머니는 위험하다고 혼자는 하지 말래요."},
			{"speaker": "{player}", "face": "smile", "text": "찌를 물 위에 띄우고 기다리는 거야. 찌가 쏙 들어가면 그때 들어 올려."},
			{"speaker": "", "text": "해솔이는 한참 동안 숨도 안 쉬고 찌만 본다. 그러다 찌가 쏙 들어갔다."},
			{"speaker": "김해솔", "face": "smile", "text": "들어갔어요! 들어갔어요! 아저씨 이거 무거워요!"},
			{"speaker": "{player}", "text": "천천히. 줄 감으면서 들어 올려."},
			{"speaker": "", "text": "손바닥만 한 볼락 한 마리가 햇빛에 반짝이며 올라왔다."},
			{"speaker": "{player}", "face": "smile", "text": "볼락이네. 아저씨가 여기 와서 처음 잡은 것도 볼락이었어."},
			{"speaker": "김해솔", "face": "smile", "text": "진짜요? 그럼 우리 둘 다 첫 물고기가 똑같네요. 이것도 숙제에 쓸래요. 우리 마을은 바다에서 볼락이 나와요!"},
			{"speaker": "", "text": "해솔이는 볼락을 바다에 놓아주었다. 내일 학교에서 발표한다고 한다."},
		],
	},
	{
		"id": "haesol_hw_done", "note": "해솔이가 마을 자랑 발표를 했다. 선생님이 참 잘했다고 했단다.", "place": "school", "day": 8, "needs": ["hw_fished"], "after": "hw_fishing", "time": [14 * 60, 19 * 60],
		"set": ["haesol_hw_done"],
		"lines": [
			{"speaker": "", "text": "교실 뒤 게시판에 해솔이 숙제가 붙어 있다. 맨 위에 크게 '우리 마을 자랑 네 가지'라고 적혀 있다."},
			{"speaker": "김해솔", "face": "smile", "text": "아저씨! 발표 했어요. 선생님이 박수를 엄청 크게 쳤어요. 학생이 저 하나라 박수 치는 사람도 선생님 하나지만요."},
			{"speaker": "{player}", "face": "smile", "text": "잘했네. 뭐가 제일 좋았대?"},
			{"speaker": "김해솔", "text": "볼락이요. 선생님도 낚시 배우고 싶대요. 근데 아저씨 네 번째는 몰래 하나 더 적었어요."},
			{"speaker": "{player}", "text": "뭔데?"},
			{"speaker": "김해솔", "face": "smile", "text": "서울에서 온 아저씨가 생선 구워 주는 가게가 생겼다고요. 그게 제일 큰 자랑이래요."},
			{"speaker": "", "text": "〈해솔이의 숙제〉를 마쳤어요. 복자네 밥집에 들러 보세요."},
		],
	},
	{
		"id": "haesol_bokja_thanks", "note": "복자 할머니가 해솔이 숙제 고맙다며 생선튀김 비법을 알려 줬다.", "place": "diner", "day": 8, "needs": ["haesol_hw_done"],
		"set": ["recipe_fish_fry"],
		"lines": [
			{"speaker": "김복자", "face": "sad", "text": "니가 우리 해솔이 숙제 봐줬다매. 그 아가 저녁 내내 볼락 얘기만 하더라."},
			{"speaker": "{player}", "face": "smile", "text": "해솔이가 다 했어요. 저는 따라다니기만 했고요."},
			{"speaker": "김복자", "text": "그래도 고맙다. 엄마 아빠 멀리 있는 아가 그래 웃는 거 오랜만에 봤다."},
			{"speaker": "김복자", "face": "smile", "text": "옛다. 우리 집 생선튀김 반죽 비법이다. 아무한테도 안 가르쳐 준 기다. 망하지 말라고 주는 거다."},
			{"speaker": "", "text": "복자 할머니의 생선튀김 비법을 배웠어요. 이제 가게에서 생선튀김도 팔 수 있어요."},
		],
	},
	{
		"id": "mansu_rocks", "note": "감성돔을 올렸더니 만수 할아버지가 검은여 갯바위 가는 길을 알려 줬다.", "place": "breakwater", "day": 2, "needs": ["learned_tide_talk", "caught_gamseongdom"],
		"set": ["learned_tide"],
		"lines": [
			{"speaker": "", "text": "방파제 끝에서 만수 할아버지가 일어나 바지를 턴다."},
			{"speaker": "박만수", "text": "감성돔 올렸다매. 용팔이가 온 동네에 떠들고 다니더라."},
			{"speaker": "{player}", "face": "smile", "text": "운이 좋았어요. 손이 아직도 얼얼해요."},
			{"speaker": "박만수", "face": "smile", "text": "운도 실력이다. 약속은 약속이니 검은여 가는 길 알려 주꾸마."},
			{"speaker": "박만수", "text": "물은 하루 두 번 빠진다. 날마다 한 시간 가까이씩 늦어지고. 빠진 앞뒤 한 시간 반만 들어가라."},
			{"speaker": "박만수", "face": "sad", "text": "물 들어오는 거 보이믄 고기 물고 있어도 바로 나와라. 바다는 기다려 주지 않는다."},
			{"speaker": "", "text": "검은여 갯바위가 열렸어요. 지도에서 갯바위를 누르면 오늘 물 빠지는 시간이 나와요. 우럭과 감성돔이 잘 나와요."},
		],
	},
	{
		"id": "taesik_first", "note": "이장 정태식 아저씨를 만났다. 마을회관 게시판에 붙은 의뢰를 들어주면 된다.", "place": "store", "day": 9, "needs": ["first_guest_done"], "time": [9 * 60, 19 * 60],
		"set": ["hall_open", "met_taesik"],
		"lines": [
			{"speaker": "", "text": "경자상회 평상에 양복 조끼를 입은 아저씨가 서류 봉투를 끼고 앉아 있다."},
			{"speaker": "문경자", "text": "마침 잘 왔다. 이장 양반이 니 찾더라."},
			{"speaker": "정태식", "text": "아이고 반갑습니다. 이장 정태식입니다. 인사가 늦었지요. {shop} 사장님 맞으시죠?"},
			{"speaker": "{player}", "face": "smile", "text": "네. {player|이에요/예요}. 잘 부탁드려요."},
			{"speaker": "정태식", "text": "다름이 아니라 회관 게시판에 마을 부탁을 붙여 두거든요. 근데 요새는 들어줄 젊은 사람이 없어서 종이만 누렇게 바래요."},
			{"speaker": "정태식", "face": "smile", "text": "생선이든 채소든 회관에 맡겨 주시면 제가 전해 드릴게요. 사례도 섭섭지 않게 하고요."},
			{"speaker": "", "text": "마을회관이 열렸어요. 게시판 의뢰는 붙은 날부터 사흘 동안 남아요."},
		],
	},
	# ── 갯벌, 앱 만들기 (11-19): 새로 할 거리는 마을 사람이 먼저 말을 꺼낸다 ──
	{
		"id": "bokja_flat", "note": "복자 사장님이 물 빠지면 아래 갯벌에서 바지락을 캐 보라고 했다.", "place": "diner", "day": 5, "needs": ["met_bokja"], "time": [9 * 60, 18 * 60],
		"set": ["flat_open"],
		"lines": [
			{"speaker": "", "text": "밥집 앞 고무 대야에 바지락이 가득하다. 복자가 소금물을 붓고 있다."},
			{"speaker": "{player}", "text": "이거 다 어디서 났어요?"},
			{"speaker": "김복자", "text": "어디긴. 해변 아래 갯벌이지. 물 빠지믄 호미 하나로 한 바가지다."},
			{"speaker": "김복자", "face": "smile", "text": "니 고기만 잡지 말고 갯벌도 가 봐라. 숨구멍 뽕뽕 난 데를 파믄 나온다."},
			{"speaker": "김복자", "text": "물 들어오기 시작하믄 미련 두지 말고 나오고."},
			{"speaker": "", "text": "갯벌이 열렸어요. 낮에 물이 빠졌을 때만 들어가요. 지도에서 갯벌을 누르면 오늘 물 빠지는 시간이 나와요."},
		],
	},
	{
		"id": "junho_app_ask", "note": "준호가 가게를 접을까 고민 중이다. 조황 페이지를 만들어 주기로 했다.", "place": "tackle", "day": 6, "needs": ["met_junho", "first_guest_done"],
		"set": ["app_junho"],
		"lines": [
			{"speaker": "", "text": "낚시방 계산대에 준호가 턱을 괴고 앉아 있다. 오늘은 기어비 얘기를 안 한다."},
			{"speaker": "이준호", "face": "sad", "text": "형. 이번 달도 손님이 열 명이 안 돼요. 그냥 접고 도시 가야 하나 봐요."},
			{"speaker": "{player}", "text": "다들 여기 낚시방이 있는 줄도 모르는 거 아니야?"},
			{"speaker": "이준호", "face": "sad", "text": "그러니까요. 요즘은 다 휴대폰으로 조황 보고 예약하고 오잖아요."},
			{"speaker": "{player}", "face": "smile", "text": "그거 내가 해 줄 수 있어. 서울에서 하던 일이 그거였거든."},
			{"speaker": "이준호", "face": "smile", "text": "진짜요? 형 개발자였어요?"},
			{"speaker": "", "text": "낚시방에서 하루 한 단계씩 앱을 만들어 줄 수 있어요. 한 번에 두 시간 걸려요."},
		],
	},
	{
		"id": "kyungja_ledger_ask", "note": "경자 할머니 외상장부를 컴퓨터로 옮겨 드리기로 했다.", "place": "store", "day": 10, "needs": ["met_kyungja", "ev_kyungja_store"],
		"set": ["app_kyungja"],
		"lines": [
			{"speaker": "", "text": "경자상회 서랍이 다 열려 있다. 할머니가 돋보기를 쓰고 누런 장부를 넘긴다."},
			{"speaker": "문경자", "face": "sad", "text": "이 집 외상이 얼마였는지 내가 못 읽겠다. 글씨가 다 날아갔어."},
			{"speaker": "{player}", "text": "할머니, 그거 제가 사진 찍어서 컴퓨터에 옮겨 드릴까요?"},
			{"speaker": "문경자", "text": "그런 것도 되나? 되믄 해 봐라. 공짜로는 안 시킨다."},
			{"speaker": "", "text": "경자상회에서 하루 한 단계씩 장부를 옮길 수 있어요."},
		],
	},
	{
		"id": "taesik_excel_ask", "note": "이장님 엑셀 파일을 정리하고 마을 게시판 앱을 만들어 드리기로 했다.", "place": "hall", "day": 12, "needs": ["met_taesik"],
		"set": ["app_taesik"],
		"lines": [
			{"speaker": "", "text": "회관 컴퓨터 앞에서 이장이 한숨을 쉰다. 화면에 칸이 다 어긋난 표가 떠 있다."},
			{"speaker": "정태식", "face": "sad", "text": "군청에 낼 서류인데 이게 왜 이렇게 되는지 모르겠어요."},
			{"speaker": "{player}", "text": "보여 주세요. 이 정도면 금방 고쳐요."},
			{"speaker": "정태식", "face": "smile", "text": "사장님이 그런 것도 하세요? 그럼 게시판도 종이 말고 휴대폰으로 볼 수 있게 될까요?"},
			{"speaker": "", "text": "마을회관에서 하루 한 단계씩 앱을 만들 수 있어요. 다 만들면 게시판 의뢰 사례가 늘어요."},
		],
	},
]

## 세라와 처음 여는 저녁 장사 (2026-11-19 사용자: 주인공은 요리에 소질이 없고, 세라와 마음이 맞아 식당을 같이 한다).
## 세라는 순덕 할머니 손녀. 부산 횟집 주방에서 오 년 일하고 내려왔다. 첫날 아침 주인공이 볼락을 태울 때 할머니와 들어와 대신 구웠다(first_guest).
## 처음 저녁 장사를 여는 날 이 대화가 나온다 (service). 끝나면 flags sera_first_shift
const SERA_FIRST_SHIFT := [
	{"speaker": "", "text": "세라가 앞치마 끈을 질끈 묶고 화구에 불을 올린다."},
	{"speaker": "최세라", "face": "smile", "text": "첫 저녁 장사네요. 긴장돼요?"},
	{"speaker": "{player}", "face": "smile", "text": "솔직히 좀요. 그래도 세라 씨가 있으니까."},
	{"speaker": "최세라", "text": "사장님은 손님 얼굴만 봐요. 굽는 건 제가 할게요."},
	{"speaker": "", "text": "세라는 늘 조리대 뒤에서 생선을 굽는다. 다 구운 접시가 조리대 끝에 나오면 눌러서 손님에게 갖다줘요."},
	{"speaker": "", "text": "접시가 세 개 넘게 쌓이면 세라가 다음 생선을 못 내려서 타요. 얼른 날라요."},
]

## 장소 화면이 없는 곳의 잡담 (날마다 돌아가며 하나)
const SMALL_TALK := {
	"home": [
		[{"speaker": "", "text": "오래된 단층집. 마당의 녹슨 평상에 앉으니 바다 냄새가 난다."}],
		[{"speaker": "{player}", "text": "이불을 말려야 하는데. 오늘은 바람이 좋네."}],
	],
	"store": [
		[{"speaker": "문경자", "text": "오늘은 뭐 필요해? 굵은소금 새로 들어왔어."}],
		[{"speaker": "문경자", "face": "sad", "text": "만수 영감은 막걸리 외상이 석 달 치야. 그래도 꼭 갚는 사람이라 놔둬."}],
	],
	"diner": [
		[{"speaker": "김복자", "face": "sad", "text": "또 왔나. 우리 집 반찬 훔쳐 갈라꼬?"}],
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
	"school": [
		[{"speaker": "", "text": "운동장에 그네 하나와 녹슨 축구 골대가 있다. 교실 창문으로 책상 하나가 보인다."}],
		[{"speaker": "김해솔", "face": "smile", "text": "아저씨! 오늘 받아쓰기 백 점 맞았어요. 학생이 저 혼자라 일 등도 저예요."}],
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
		if ev.has("after") and (not flags.has("evday_" + ev.after) or day <= int(flags["evday_" + ev.after])):
			ok = false
		if ok:
			return ev
	return {}


## 사건을 본 것으로 표시하고 결과(flags, 돈)를 넣는다
static func finish(ev: Dictionary, gs: Object) -> void:
	gs.flags["ev_" + ev.id] = true
	gs.flags["evday_" + ev.id] = int(gs.day)
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
