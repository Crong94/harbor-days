# 오늘의 바다 : 작업 규칙

남해 어촌 생활 시뮬레이션 게임. 기획은 `docs/오늘의바다_시나리오_v3.md`가 기준이다.

## 환경
- 엔진: Godot 4.4.1, GDScript, 2D, 렌더러 GL Compatibility (웹 내보내기 대응)
- 해상도: 1280x720, stretch mode canvas_items
- 폰트: `assets/fonts/NotoSansKR-Regular.ttf` (한글 11,172자 전체 포함, OFL)

## GitHub 사용 금지 (중요)
- 계정 문제 해결 전까지 **원격 저장소를 연결하거나 push하지 않는다.** `git remote add`, `git push`, GitHub Actions 설정 모두 금지.
- Git은 로컬 커밋만 한다.
- 작업이 끝나면 `tools/backup.sh`로 bundle과 zip을 만들고 사용자의 개인 구글 드라이브 `오늘의바다_백업` 폴더에 올린다.

## 다음 세션에서 이어 받는 법
1. 구글 드라이브 `오늘의바다_백업` 폴더에서 가장 최근 `oneului-bada-*.bundle`을 받는다.
2. `git clone oneului-bada-YYYYMMDD-HHMM.bundle oneului-bada`
3. Godot가 없으면 `tools/setup_godot.sh` 실행.

## 명령
```
godot --headless --path . --import                                 # 리소스 가져오기 (처음 한 번)
godot --headless --path . --script res://tests/run_tests.gd        # 테스트
godot --headless --path . --export-release "Web" build/web/index.html  # 웹 빌드
```

## 그림 규칙 (중요)
- 그림, 일러스트, 캐릭터, 배경 이미지는 **직접 만들지 않는다.** 필요한 그림은 `docs/그림_요청_목록.md`에 적고 사용자에게 요청한다.
- 그림 자리는 `ArtSlot`으로 비워 둔다. `assets/art/<id>.png`가 들어오면 자동으로 표시된다.
- 낚싯대, 줄, 찌, 게이지처럼 판정을 보여 주는 요소만 코드로 선을 그린다. 지금 배경(SeaBackdrop)은 그림이 오기 전까지 쓰는 임시 도형이다.

## 사용자에게 그림 프롬프트를 줄 때 (사용자 요청, 꼭 지킬 것)
- 프롬프트를 md 파일로 주지 않는다. **채팅에 바로 코드 블록으로** 준다
- 한국어와 영어 두 버전을 함께 준다
- 사용자는 **ChatGPT**로 그림을 뽑는다. Midjourney 설정(`--ar`, `--no`)은 넣지 않고, 비율은 프롬프트 문장 안에 적는다 (예: `세로로 긴 2:3 비율`, `vertical 2:3 aspect ratio`)
- **이미지 → 프롬프트 순서로 하나씩** 준다. 첨부할 이미지는 이름만 적지 말고 **실제 이미지 파일을 먼저 보내고**, 바로 아래에 그 이미지와 쓸 프롬프트를 준다
- 한 번에 다 주지 않는다. 앞 그림 결과물이 뒤 그림의 참조가 되므로 사용자가 결과를 보내면 그 그림을 다음 참조 이미지로 보내며 다음 단계를 준다
- 참조 이미지는 `docs/ref/`에 보관한다
- 투명 배경이 필요한 그림(캐릭터, 물고기, 소품, 초상화, SD)은 프롬프트에 알파 채널 문구를 넣는다
  - 한국어: `배경은 완전히 투명한 PNG(알파 채널). 배경 없이 대상만.`
  - English: `Transparent background, PNG with alpha channel, isolated subject with no background.`
  - 가짜 체크무늬가 그려져 나오거나 흰 배경으로 나오면 받은 뒤 배경을 지워서 쓴다
- 배경 그림, 지도, 설정화는 투명 배경이 필요 없다
- 뽑는 순서: ① 설정화 ② 낚시 자세 ③ 볼락 ④ 망상어, 노래미 ⑤ 마을 지도 ⑥ 방파제 낮 ⑦ 방파제 밤 ⑧ 식당 외관 ⑨ 식당 내부 낮 ⑩ 식당 내부 밤 ⑪ 항구
- 화풍: 깔끔한 2D 셀 채색 코지 게임 스타일. 주인공 얼굴 기준은 1차 시안 B(현실적인 청년형) + 옅은 수염

## 코드 규칙
- UI는 씬 파일을 최소로 두고 스크립트 `_ready()`에서 만든다. 색, 글자 크기, 버튼은 `scripts/ui/ui_kit.gd`의 상수와 함수만 쓴다.
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
scenes/fishing    새벽 방파제 찌낚시 (첫 물고기 볼락)
scenes/map        마을 지도. 장소 선택, 이동 시간, 해금 (scripts/data/locations.gd)
scripts/fishing   FishingLogic (낚시 규칙, 헤드리스 테스트 가능)
scripts/data      FishDB (어종 데이터)
assets/art        사용자에게 받은 그림 (docs/그림_요청_목록.md)
scripts/autoload  GameState (전역 상태)
scripts/ui        UiKit, SeaBackdrop(임시 배경), DialogueBox, ArtSlot(그림 자리)
scripts/util      Josa (조사 처리)
tests             헤드리스 테스트
tools             설치, 백업 스크립트
```
