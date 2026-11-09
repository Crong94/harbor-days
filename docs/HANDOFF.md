# 이어가기 (2026-11-09 밤, 브랜치 main, 원격 없음)

환경: **코드** (사용자 PC에서 도는 Claude Code 데스크톱 앱). 레포: `C:\Users\<USER>\Desktop\오늘의 바다`

```
오늘의 바다(Godot 4 생활 시뮬레이션 낚시 게임) 개발을 내 PC에서 이어서 해 줘. 환경은 코드(로컬)야.

## 답변 방식
- 생각하는 과정을 포함한 모든 답변은 한국어로 답변한다.
- 설명은 간략하고 쉽게 한다.
- 애매하거나 모호한 부분이 있다면 질문을 통해 해결하고 넘어간다.

## 지금까지 상황
- 레포: C:\Users\<USER>\Desktop\오늘의 바다 (브랜치 main, 로컬 git만). 커밋 안 된 변경 없음
- 먼저 읽을 것: CLAUDE.md(작업 규칙), docs/UI_디자인_시스템.md, docs/그림_요청_목록.md(〈세로 화면 그림〉 섹션), docs/물고기_그림_목록.md, 기획서 docs/오늘의바다_시나리오_v3.md
- Godot 4.4.1: C:\Users\<USER>\Tools\Godot\ (바탕 화면에 바로가기). Python 3.12: C:\Users\<USER>\AppData\Local\Programs\Python\Python312\python.exe (numpy, scipy, pillow 설치됨)
- 테스트: <Godot>\Godot_v4.4.1-stable_win64_console.exe --headless --path . --script res://tests/run_tests.gd → "171 통과, 0 실패"
- 장면 오류 검사: <Godot>_console.exe --headless --path . res://scenes/<장면>.tscn --quit-after 60 (테스트 스크립트 모드에서는 오토로드가 없어 장면을 못 부른다)
- 화면 찍기: <Godot>\Godot_v4.4.1-stable_win64.exe --path . res://scenes/<장면>.tscn --write-movie <스크래치폴더>/x.png --fixed-fps 30 --quit-after 75 --resolution 720x1280. 대사 뒤 숨은 상태는 임시 res://_shot/ 장면을 만들어 강제로 띄워 찍고, 끝나면 _shot 폴더를 지운다(커밋 금지)
- 만든 것
  - 흐름: 타이틀 → 사직서(플레이어명) → 간판(가게명) → 새벽 방파제 낚시 튜토리얼(첫 물고기 볼락) → 〈첫 번째 손님〉 식당(볼락구이 간 맞추기와 굽기, 최순덕, 장부) → 마을 지도
  - 첫날 뒤 자유 낚시(아무 시간대, 그만하기나 밤 11시에 끝), 준호네 낚시방(낚싯대 3, 릴 3 구매·장착), 소리(Sound 오토로드)
  - 화면은 세로 720x1280 (PC 창 540x960). UiKit 디자인 시스템(유리+종이, Pretendard+고운바탕)으로 전 화면을 짰지만 사용자가 "다 별로"라고 해서 다시 짤 예정
  - 낚시 화면: 배경 위쪽을 확대해 방파제 아래를 잘라 냄(SeaBackdrop.art_view, fishing.gd의 ART_VIEW, FEET)
- 바다 한 접시(사용자가 만든 이전 게임 '여울', Godot 4 + C#) 자료: 레포 바깥 C:\Users\<USER>\Desktop\오늘의바다_작업\
  - hanjeopsi_풀린파일\ (art 831장 PNG, audio 36개 ogg, data JSON 17개), 미리보기\ (묶음 jpg)
  - 이미 가져온 것: 소리 전부, species.json과 recipes.json(Catalog), 요리·조리도구·주방·재료 그림, 장비 아이콘(assets/art/gear_icon)
  - 임시로 쓰는 세로 배경: bg_fishing_night, bg_fishing_day, map_village, bg_tackle_shop (여울 그림, 다시 뽑아서 교체 예정)
- 레포 안 작업폴더\, Yeoul\ 은 사용자 원본. .git/info/exclude와 .gdignore로 git과 Godot에서 빠져 있다

## 확정된 결정
- 제목 〈오늘의 바다〉, 주인공 1994년 2월생, 7년 차 개발자 퇴사. 기본 이름 한바다, 가게 오늘의 식탁
- 엔진 Godot 4.4.1 GDScript 2D. GitHub 금지(remote, push, Actions 전부). 로컬 커밋만, 백업은 ./tools/backup.sh(Git Bash)로 만든 bundle을 사용자가 드라이브 오늘의바다_백업에 올린다
- 화면은 세로 모바일 720x1280
- 그림은 절대 직접 만들지 않는다. 코드로 그린 장식 그림도 안 된다. 낚싯줄, 찌, 게이지 같은 판정 표시만 선으로 그린다
- 바뀐 점 (이번 세션)
  - **화풍을 "둥글고 귀여운 코지"로 통일**: 물고기 시트 그림(둥근 굵은 남색 외곽선, 단순한 면, 한 단계 그림자, 볼터치, 파스텔)이 기준. SD, 배경, 지도, 초상화 전부 이 화풍으로 다시 뽑는다
  - 접은 것: 세밀화 물고기(이질적, 볼락도 시트 sheet11_11로 교체), 여울의 세밀한 애니 배경을 계속 쓰는 것, 키비주얼_v2 기준 애니 셀 채색, 유리+종이 UI(세련된 앱 느낌이라 귀여운 그림과 안 맞음)
  - **낚시 장비 그림(낚싯대, 릴, 찌 등)은 새로 뽑지 않고 여울 그림을 그대로 쓴다.** 그래서 rod_starter_float, rod_carbon_rock, 릴 3종 프롬프트는 접었다
  - 마을 지도는 오늘의 바다 전용 세로 지도로 새로 뽑는다

## 사용자 선호
- 그림 프롬프트: 채팅 코드 블록, 한국어와 영어 둘 다, ChatGPT용(Midjourney 옵션 없이 비율은 문장으로)
- **"이미지 N → 프롬프트 N" 순서**. 첨부할 참조 그림은 SendUserFile로 먼저 보내고 바로 아래에 그 그림과 쓸 프롬프트. 앞 그림 결과가 뒤 그림의 참조가 되면 결과를 받은 뒤 다음 것을 준다
- 투명 배경 그림에는 "배경은 완전히 투명한 PNG(알파 채널). 배경 없이 대상만." / "Transparent background, PNG with alpha channel, isolated subject with no background." 흰 배경으로 오면 tools/remove_white_bg.py, 여러 개 시트는 tools/slice_sheet.py
- 그림을 받으면 바로 게임에 넣고 화면을 찍어 확인한다
- 10년 차 프론트엔드 개발자 수준, 요즘 트렌드의 예쁜 UI를 원한다
- 대사와 글: 자연스러운 구어체, 쉼표 남발과 줄표(—, ㅡ) 금지
- 휴대폰 Claude 앱으로 원격 접속하기도 한다. 그림이나 파일은 SendUserFile로 보낸다

## 환경 제약
- 드라이브 파일은 사용자가 브라우저로 받아 폴더에 넣어 준다 (큰 파일은 커넥터로 받지 않는다)
- 셸 명령이 샌드박스로 막히면(Godot 창 띄우기, 레포 바깥 쓰기) 샌드박스를 끄고 실행한다
- git core.autocrlf=true (줄바꿈 경고는 무시해도 됨)
- 비밀 값 없음

## 이번에 해 줬으면 하는 것
1. 상태 확인: git log --oneline -3, 테스트 171 통과. 사용자가 build/backup의 가장 최근 bundle을 드라이브에 올렸는지 확인
2. 그림 프롬프트 1 결과 받기: 주인공 SD 설정화(정면, 옆, 뒤 3면, 둥근 코지 화풍, 투명). 참조는 assets/art/fish_bolak.png(화풍)와 docs/ref/설정화_회색배경.png(옷). 사용자가 결과를 주면 docs/ref/에 저장하고 마음에 드는지 확인. 안 왔으면 두 장을 보내고 같은 프롬프트를 다시 준다
3. SD 확정 뒤 이어서 (하나씩, 이미지 → 프롬프트)
   - 낚시용 SD 뒷모습 몸 그림 player_sd_body.png 다시 (낚싯대 없이 오른손으로 쥔 자세). 손 위치는 scripts/fishing/player_rig.gd의 HAND
   - 같은 화풍의 세로 배경: 새벽 낚시(bg_fishing_dawn_v)와 아침(bg_fishing_morning_v), 마을 지도(map_village), 타이틀(bg_title), 사무실, 식당 외관과 빈 간판, 식당 내부, 최순덕·이준호 초상화, UI 아이콘 시트 (docs/그림_요청_목록.md 〈세로 화면 그림〉)
4. 낚시 장비를 여울 그림으로 교체: 여울 hanjeopsi_풀린파일\art\gear\ 의 blank-N(대 몸통), butt-N(밑동+릴), float-N(찌) 등을 assets/art로 가져와 PlayerRig가 이 그림으로 낚싯대와 릴을 그리게 바꾼다. 배치 비율은 여울 data\gearlook.json(buttTop, buttBlank, blanks 등)과 poses.json 참고. GearDB의 낚싯대·릴을 여울 단계(gear.json rods, reels)와 어떻게 이을지 사용자와 정한다
5. UI 다시 짜기: SD와 배경이 나오면 그 외곽선 색과 팔레트를 뽑아 UiKit 토큰을 "둥글고 귀여운 코지"로 바꾼다 (통통한 버튼, 굵은 둥근 외곽선, 파스텔 카드, 아래쪽 입체 그림자 등). 제목 글꼴을 귀여운 둥근 글꼴로 바꿀지 사용자에게 묻는다. docs/UI_디자인_시스템.md도 같이 고친다
6. 그림이 오면 위치 비율 맞추기: 지도 핀(scripts/data/locations.gd pos), 낚시 배경(fishing.gd의 WATER_NEAR_Y, WATER_FAR_Y, FEET, ART_VIEW), 손 위치(player_rig HAND)
마지막: 테스트 통과, 장면 오류 검사, 화면 찍어 확인, 로컬 커밋(메시지 끝에 Co-Authored-By 줄), ./tools/backup.sh로 백업 만들고 드라이브 오늘의바다_백업에 올리라고 안내
```
