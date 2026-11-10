# 오늘의 바다 : 작업 규칙

남해 어촌 생활 시뮬레이션 게임. 기획은 `docs/오늘의바다_시나리오_v3.md`가 기준이다.

## 환경
- 엔진: Godot 4.4.1, GDScript, 2D, 렌더러 GL Compatibility (웹 내보내기 대응)
- 해상도: **세로 720x1280** (PC 창 540x960), stretch mode canvas_items. 2026-11-09 가로에서 세로로 바꿨다
- 글꼴: 주아(제목, 버튼, 숫자) + Pretendard 5굵기(본문) + 고운바탕 2굵기(사직서처럼 편지 느낌일 때만). 모두 `assets/fonts`, OFL
- UI: `docs/UI_디자인_시스템.md` (둥글고 귀여운 코지: 굵은 외곽선 + 입체 턱, SD 그림 팔레트). 토큰과 컴포넌트는 `scripts/ui/ui_kit.gd`

## 작업 환경 세 곳과 동기화 (중요, 2026-11-10 확정)
어디서든 같은 레포(같은 이력)로 작업한다. 기준은 집 노트북에서 이어 온 세로 버전이다.

| 곳 | 하는 일 |
|---|---|
| 집 노트북 | Godot가 있다. 코드, 테스트, 화면 찍어 확인까지 전부 |
| 회사 PC | Godot를 설치하지 않는다. 그림 뽑기와 문서 위주. 코드를 고쳤다면 테스트는 노트북에서 한다 |
| GitHub `Crong94/harbor-days` (공개) | 가끔 올리는 백업. 사용자가 올리자고 할 때나 큰 단락이 끝났을 때만 push |
| 구글 드라이브 `오늘의바다_백업` | **기기 사이를 잇는 주된 통로.** 세션이 끝날 때마다 bundle을 올린다 |

- 세션 시작: 드라이브의 가장 최근 `oneului-bada-*.bundle`을 받아 `git pull <bundle 경로> main`. 레포가 없으면 `git clone <bundle> oneului-bada`
- 세션 끝: 커밋 → `tools/backup.sh` → `build/backup/`의 새 bundle을 드라이브 `오늘의바다_백업`에 올린다 (80MB쯤이라 커넥터로는 못 올린다. 사용자가 직접 올리거나 Google Drive 데스크톱 폴더에 복사)
- 두 기기에서 동시에 작업하지 않는다. 한쪽에서 bundle을 올린 뒤 다른 쪽에서 받는다
- 커밋 작성자는 레포 로컬 설정 `Songok Kim <thddhr14@gmail.com>`만 쓴다
- 공개 레포라서 비밀번호, 토큰, 개인 메일, 집 위치, PC 사용자 폴더 경로 같은 개인 정보는 파일과 커밋 메시지에 넣지 않는다
- push할 때 로그인 창이 뜨면 사용자가 Crong94로 직접 로그인한다. GitHub Actions는 두지 않는다 (넣으려면 먼저 묻는다)
- GitHub의 `old-landscape` 브랜치는 회사 PC에서 잠깐 갈라졌던 가로 1280x720 버전이다. 합치지 않는다. 거기서 가져온 것은 확장 지도 시안(`docs/ref/map_village_확장_v3.jpg`)뿐이다

## 명령
로컬 Windows에서는 `godot` 대신 Godot 콘솔 실행 파일 경로를 쓴다 (`docs/LOCAL_SETUP.md`). 백업 스크립트는 Git Bash에서 실행.
```
godot --headless --path . --import                                 # 리소스 가져오기 (처음 한 번)
godot --headless --path . --script res://tests/run_tests.gd        # 테스트
godot --headless --path . --export-release "Web" build/web/index.html  # 웹 빌드
```

## 그림 규칙 (중요)
- **이미지는 절대 직접 만들지 않는다.** 코드로 그리는 장식 그림도 새로 만들지 않는다. 모든 그림은 ChatGPT로 받는다 (사용자 평가: 코드로 그린 임시 배경은 촌스럽다)
- 그림을 뽑을 때는 **사용자에게 ChatGPT 대화 링크를 받아** 그 대화에서 Chrome으로 진행한다. 링크를 받기 전에 아무 대화나 열어 요청하지 않는다. 받은 결과는 보여 주고 검토받은 뒤 게임과 드라이브 ref에 넣는다
- 배경 그림이 들어오면 SeaBackdrop의 코드 그림 대신 그림(art_base, art_blend)을 쓴다
- 물고기 그림은 사용자가 준 시트(드라이브 ref/sheets)를 `tools/slice_sheet.py`로 잘라 쓴다. 볼락도 시트 조각으로 통일했다(세밀화는 이질적이라 접음). 어떤 조각이 어떤 어종인지는 `docs/물고기_그림_목록.md`
- 그림, 일러스트, 캐릭터, 배경 이미지는 **직접 만들지 않는다.** 필요한 그림은 `docs/그림_요청_목록.md`에 적고 사용자에게 요청한다.
- 그림 자리는 `ArtSlot`으로 비워 둔다. `assets/art/<id>.png`가 들어오면 자동으로 표시된다.
- 낚싯대, 줄, 찌, 게이지처럼 판정을 보여 주는 요소만 코드로 선을 그린다. 지금 배경(SeaBackdrop)은 그림이 오기 전까지 쓰는 임시 도형이다.

## 사용자에게 그림 프롬프트를 줄 때 (사용자 요청, 꼭 지킬 것)
- 프롬프트를 md 파일로 주지 않는다. **채팅에 바로 코드 블록으로** 준다
- 한국어와 영어 두 버전을 함께 준다
- 사용자는 **ChatGPT**로 그림을 뽑는다. Midjourney 설정(`--ar`, `--no`)은 넣지 않고, 비율은 프롬프트 문장 안에 적는다 (예: `세로로 긴 2:3 비율`, `vertical 2:3 aspect ratio`)
- **이미지 → 프롬프트 순서로** 준다. 첨부할 이미지는 이름만 적지 말고 **실제 이미지 파일을 먼저 보내고**(SendUserFile), 바로 아래에 그 이미지와 쓸 프롬프트를 준다. 여러 장이면 `이미지 1 / 프롬프트 1 / 이미지 2 / 프롬프트 2 ...` 형식
- 앞 그림 결과물이 뒤 그림의 참조가 되는 것(같은 구도의 아침, 밤 버전 등)은 결과를 받은 뒤 그 그림을 참조로 보내며 다음 단계를 준다
- 세로 화면이므로 배경은 `세로로 긴 9:16 비율` / `vertical 9:16 aspect ratio`로 받는다
- 방향: 북쪽 방파제 끝에서 **동쪽 바다**를 본다 (왼쪽 북, 오른쪽 남, 등 뒤 서). 해돋이는 정면, 해넘이는 등 뒤. 배경과 지도는 이 방향에 맞춘다. 해는 배경과 따로(`sun.png`) 받아 코드로 움직인다
- 참조 이미지는 `docs/ref/`에 보관한다. 용량이 커서 git에는 넣지 않고 구글 드라이브 `오늘의바다_백업/ref` 폴더에 따로 올린다 (드라이브 업로드 한도 10MB). 새 세션에서는 그 폴더에서 받아 `docs/ref/`에 넣는다
- 투명 배경이 필요한 그림(캐릭터, 물고기, 소품, 초상화, SD)은 프롬프트에 알파 채널 문구를 넣는다
  - 한국어: `배경은 완전히 투명한 PNG(알파 채널). 배경 없이 대상만.`
  - English: `Transparent background, PNG with alpha channel, isolated subject with no background.`
  - 가짜 체크무늬가 그려져 나오거나 흰 배경으로 나오면 받은 뒤 배경을 지워서 쓴다
- 배경 그림, 지도, 설정화는 투명 배경이 필요 없다
- 뽑는 순서: ① 설정화 ② 낚시 자세 ③ 볼락 ④ 망상어, 노래미 ⑤ 마을 지도 ⑥ 방파제 낮 ⑦ 방파제 밤 ⑧ 식당 외관 ⑨ 식당 내부 낮 ⑩ 식당 내부 밤 ⑪ 항구
- 화풍: 둥글고 귀여운 코지 (굵고 둥근 남보라 외곽선, 단순한 면, 볼터치, 파스텔). 기준 그림은 `docs/ref/SD_설정화_3면.png`(주인공)와 물고기 시트(`assets/art/fish_bolak.png`)
- 지금 임시 그림: 낚시 배경(`bg_fishing_night`, `bg_fishing_day`), 지도(`map_village`), 낚시방(`bg_tackle_shop`)은 바다 한 접시 그림이다. 오늘의 바다 전용 세로 그림으로 바꾼다

## 바다 한 접시 (이전 게임) 자료
- 사용자가 직접 만든 이전 게임이라 그림, 소리, 데이터를 가져와 써도 된다. Godot 4 + C# 게임이었다
- APK와 푼 파일은 레포 바깥, 레포와 나란히 있는 `오늘의바다_작업\` 폴더에 있다 (`hanjeopsi_풀린파일/`에 art, audio, data. `미리보기/`에 묶음 jpg). git에 넣지 않는다
- 프로젝트 폴더 안 `작업폴더/`, `Yeoul/`은 사용자가 둔 원본이다. `.git/info/exclude`와 `.gdignore`로 git과 Godot 모두에서 빠져 있다
- 물고기 아이콘(아이콘풍)과 세로 모바일 배경은 화풍과 화면 비율이 달라 가져오지 않았다
- 장면 실행 검사: `<Godot>_console.exe --headless --path . res://scenes/<장면>.tscn --quit-after 120` (테스트 스크립트 모드에서는 오토로드가 없어서 장면을 불러올 수 없다)

## 코드 규칙
- UI는 씬 파일을 최소로 두고 스크립트 `_ready()`에서 만든다. 색, 글자, 버튼, 패널은 `UiKit`의 토큰과 컴포넌트만 쓴다 (`docs/UI_디자인_시스템.md`). 새 화면도 코지 규칙(chunky 상자, 주아체 제목)을 따른다
- 화면 확인: `Godot_v4.4.1-stable_win64.exe --path . res://scenes/<장면>.tscn --write-movie <폴더>/x.png --fixed-fps 30 --quit-after 75 --resolution 720x1280`로 프레임을 찍어 본다
- 플레이어명, 가게명이 들어가는 대사는 템플릿으로 쓰고 `GameState.line()`으로 바꾼다.
  - `{player}`, `{shop}`, `{pet}`
  - 조사: `{player|이/가}`, `{shop|은/는}`, `{player|아/야}`, `{shop|으로/로}` (받침 있을 때 / 없을 때 순서)
- 대사 문체: 자연스러운 구어체. 쉼표 남발과 줄표(—, ㅡ) 사용 금지.
- 새 로직에는 `tests/run_tests.gd`에 테스트를 추가한다.

## 폴더
```
assets/fonts      폰트
docs              기획 문서
scenes/title      타이틀
scenes/prologue   사직서(플레이어명 입력), 간판(가게명 입력)
scenes/fishing    방파제 찌낚시. 첫날은 새벽 튜토리얼(첫 물고기 볼락), 그 뒤는 아무 시간대 자유 낚시. 캐스팅 포인트, 챔질 PERFECT, 좌우 줄다리기, 미끼, 물때·날씨, 주문
scenes/restaurant 〈첫 번째 손님〉 식당 장면 (볼락구이, 최순덕)
scenes/shop       준호네 낚시방 (장비 구매, 장착)
scenes/garden     우리 텃밭. 이랑 네 줄에 심고 거두기 (CropDB)
scenes/village    순덕 할머니 집 (부탁 세 가지, 다 들어주면 닭장 열림)
scenes/coop       닭장 (모이 주기, 달걀 줍기, 모이 사기). 규칙은 scripts/data/coop.gd
scenes/map        마을 지도. 장소 선택, 이동 시간, 해금 (scripts/data/locations.gd)
scripts/fishing   FishingLogic (낚시 규칙, 헤드리스 테스트 가능)
scripts/cooking   CookingLogic (간 맞추기, 굽기 규칙)
scripts/data      FishDB (어종 7종, 희귀도), GearDB (낚싯대·릴 10단계), BaitDB (미끼), SeaDay (물때·날씨), Orders (식당 주문), Locations (장소), CropDB (텃밭 네 칸과 작물 6종, docs/텃밭_설계.md), Catalog (바다 한 접시 어종 71종, 레시피 50개)
assets/art        사용자에게 받은 그림 (docs/그림_요청_목록.md). dish, cook_tool, kitchen, ingredient, gear_icon은 바다 한 접시에서 가져옴
assets/art/sd     주인공 SD 동작 프레임 (back_01~12 낚시 뒷모습, front_01~12 앞모습)
assets/audio      배경음악 bgm, 효과음 sfx (바다 한 접시에서 가져옴)
assets/data       species.json, recipes.json (바다 한 접시 데이터)
scripts/autoload  GameState (전역 상태), Sound (배경음악, 효과음)
scripts/ui        UiKit(디자인 시스템), SeaBackdrop(그림 없을 때 임시 배경), DialogueBox, ArtSlot(그림 자리)
scripts/util      Josa (조사 처리)
tests             헤드리스 테스트
tools             설치, 백업 스크립트, 그림 자르기 (slice_sheet: 낱개 그림 시트, slice_grid: 동작 시트)
```
