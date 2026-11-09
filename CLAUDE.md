# 오늘의 바다 : 작업 규칙

남해 어촌 생활 시뮬레이션 게임. 기획은 `docs/오늘의바다_시나리오_v3.md`가 기준이다.

## 환경
- 엔진: Godot 4.4.1, GDScript, 2D, 렌더러 GL Compatibility (웹 내보내기 대응)
- 해상도: **세로 720x1280** (PC 창 540x960), stretch mode canvas_items. 2026-11-09 가로에서 세로로 바꿨다
- 글꼴: Pretendard 5굵기(UI, 본문) + 고운바탕 2굵기(제목). 모두 `assets/fonts`, OFL
- UI: `docs/UI_디자인_시스템.md` (물빛 유리 + 종이 혼합). 토큰과 컴포넌트는 `scripts/ui/ui_kit.gd`

## GitHub 사용 금지 (중요)
- 계정 문제 해결 전까지 **원격 저장소를 연결하거나 push하지 않는다.** `git remote add`, `git push`, GitHub Actions 설정 모두 금지.
- Git은 로컬 커밋만 한다.
- 작업이 끝나면 `tools/backup.sh`로 bundle과 zip을 만들고 사용자의 개인 구글 드라이브 `오늘의바다_백업` 폴더에 올린다.

## 다음 세션에서 이어 받는 법 (자세한 내용은 docs/HANDOFF.md)
1. 구글 드라이브 `오늘의바다_백업` 폴더에서 가장 최근 `oneului-bada-*.bundle`을 받는다.
2. `git clone oneului-bada-YYYYMMDD-HHMM.bundle oneului-bada`
3. Godot가 없으면 `tools/setup_godot.sh` 실행.

## 명령
로컬 Windows에서는 `godot` 대신 Godot 콘솔 실행 파일 경로를 쓴다 (`docs/LOCAL_SETUP.md`). 백업 스크립트는 Git Bash에서 실행.
```
godot --headless --path . --import                                 # 리소스 가져오기 (처음 한 번)
godot --headless --path . --script res://tests/run_tests.gd        # 테스트
godot --headless --path . --export-release "Web" build/web/index.html  # 웹 빌드
```

## 그림 규칙 (중요)
- **이미지는 절대 직접 만들지 않는다.** 코드로 그리는 장식 그림도 새로 만들지 않는다. 사용자가 ChatGPT로 뽑아서 준다 (사용자 평가: 코드로 그린 임시 배경은 촌스럽다)
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
- 참조 이미지는 `docs/ref/`에 보관한다. 용량이 커서 git에는 넣지 않고 구글 드라이브 `오늘의바다_백업/ref` 폴더에 따로 올린다 (드라이브 업로드 한도 10MB). 새 세션에서는 그 폴더에서 받아 `docs/ref/`에 넣는다
- 투명 배경이 필요한 그림(캐릭터, 물고기, 소품, 초상화, SD)은 프롬프트에 알파 채널 문구를 넣는다
  - 한국어: `배경은 완전히 투명한 PNG(알파 채널). 배경 없이 대상만.`
  - English: `Transparent background, PNG with alpha channel, isolated subject with no background.`
  - 가짜 체크무늬가 그려져 나오거나 흰 배경으로 나오면 받은 뒤 배경을 지워서 쓴다
- 배경 그림, 지도, 설정화는 투명 배경이 필요 없다
- 뽑는 순서: ① 설정화 ② 낚시 자세 ③ 볼락 ④ 망상어, 노래미 ⑤ 마을 지도 ⑥ 방파제 낮 ⑦ 방파제 밤 ⑧ 식당 외관 ⑨ 식당 내부 낮 ⑩ 식당 내부 밤 ⑪ 항구
- 화풍: 깔끔한 2D 셀 채색 코지 게임 스타일. 주인공 얼굴 기준은 1차 시안 B(현실적인 청년형) + 옅은 수염. 화풍 기준 그림은 `docs/ref/키비주얼_v2.png`
- 지금 임시 그림: 낚시 배경(`bg_fishing_night`, `bg_fishing_day`), 지도(`map_village`), 낚시방(`bg_tackle_shop`)은 바다 한 접시 그림이다. 오늘의 바다 전용 세로 그림으로 바꾼다

## 바다 한 접시 (이전 게임) 자료
- 사용자가 직접 만든 이전 게임이라 그림, 소리, 데이터를 가져와 써도 된다. Godot 4 + C# 게임이었다
- APK와 푼 파일은 레포 바깥 `C:\Users\<USER>\Desktop\오늘의바다_작업\`에 있다 (`hanjeopsi_풀린파일/`에 art, audio, data. `미리보기/`에 묶음 jpg). git에 넣지 않는다
- 프로젝트 폴더 안 `작업폴더/`, `Yeoul/`은 사용자가 둔 원본이다. `.git/info/exclude`와 `.gdignore`로 git과 Godot 모두에서 빠져 있다
- 물고기 아이콘(아이콘풍)과 세로 모바일 배경은 화풍과 화면 비율이 달라 가져오지 않았다
- 장면 실행 검사: `<Godot>_console.exe --headless --path . res://scenes/<장면>.tscn --quit-after 120` (테스트 스크립트 모드에서는 오토로드가 없어서 장면을 불러올 수 없다)

## 코드 규칙
- UI는 씬 파일을 최소로 두고 스크립트 `_ready()`에서 만든다. 색, 글자, 버튼, 패널은 `UiKit`의 토큰과 컴포넌트만 쓴다 (`docs/UI_디자인_시스템.md`). 새 화면도 유리 + 종이 규칙을 따른다
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
scenes/fishing    방파제 찌낚시. 첫날은 새벽 튜토리얼(첫 물고기 볼락), 그 뒤는 아무 시간대 자유 낚시
scenes/restaurant 〈첫 번째 손님〉 식당 장면 (볼락구이, 최순덕)
scenes/shop       준호네 낚시방 (장비 구매, 장착)
scenes/map        마을 지도. 장소 선택, 이동 시간, 해금 (scripts/data/locations.gd)
scripts/fishing   FishingLogic (낚시 규칙, 헤드리스 테스트 가능)
scripts/cooking   CookingLogic (간 맞추기, 굽기 규칙)
scripts/data      FishDB (어종), GearDB (장비), Locations (장소), Catalog (바다 한 접시 어종 71종, 레시피 50개)
assets/art        사용자에게 받은 그림 (docs/그림_요청_목록.md). dish, cook_tool, kitchen, ingredient, gear_icon은 바다 한 접시에서 가져옴
assets/audio      배경음악 bgm, 효과음 sfx (바다 한 접시에서 가져옴)
assets/data       species.json, recipes.json (바다 한 접시 데이터)
scripts/autoload  GameState (전역 상태), Sound (배경음악, 효과음)
scripts/ui        UiKit(디자인 시스템), SeaBackdrop(그림 없을 때 임시 배경), DialogueBox, ArtSlot(그림 자리)
scripts/util      Josa (조사 처리)
tests             헤드리스 테스트
tools             설치, 백업 스크립트
```
