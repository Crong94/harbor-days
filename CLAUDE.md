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
scripts/autoload  GameState (전역 상태)
scripts/ui        UiKit, SeaBackdrop(임시 배경), DialogueBox
scripts/util      Josa (조사 처리)
tests             헤드리스 테스트
tools             설치, 백업 스크립트
```
