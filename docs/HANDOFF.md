# 이어가기 (2026-11-10, 브랜치 main, 원격 없음)

환경: **코드** (사용자 PC에서 도는 Claude Code 데스크톱 앱). 레포: `C:\Users\<USER>\Desktop\오늘의 바다`

```
오늘의 바다(Godot 4 생활 시뮬레이션 낚시 게임) 개발을 내 PC에서 이어서 해 줘. 환경은 코드(로컬)야.

## 답변 방식
- 생각하는 과정을 포함한 모든 답변은 한국어로 답변한다.
- 설명은 간략하고 쉽게 한다.
- 애매하거나 모호한 부분이 있다면 질문을 통해 해결하고 넘어간다.

## 지금까지 상황
- 레포: C:\Users\<USER>\Desktop\오늘의 바다 (브랜치 main, 로컬 git만). 마지막 커밋 f4651df, 커밋 안 된 변경 없음 (이 HANDOFF.md만 새로 씀)
- 먼저 읽을 것: CLAUDE.md(작업 규칙, 방향 결정 포함), docs/UI_디자인_시스템.md(코지 UI, 헤더·메뉴, 접근성), docs/그림_요청_목록.md, docs/물고기_그림_목록.md, 기획서 docs/오늘의바다_시나리오_v3.md(3.2 마을 장소 표)
- Godot 4.4.1: C:\Users\<USER>\Tools\Godot\. Python 3.12: C:\Users\<USER>\AppData\Local\Programs\Python\Python312\python.exe (numpy, scipy, pillow, fonttools)
- 테스트: <Godot>\Godot_v4.4.1-stable_win64_console.exe --headless --path . --script res://tests/run_tests.gd → "369 통과, 0 실패"
- 장면 오류 검사: <Godot>_console.exe --headless --path . res://scenes/<장면>.tscn --quit-after 60 (종료 때 "resources still in use" 경고는 배경음악 재생 객체라 예전부터 있던 것)
- 화면 찍기: 임시 res://_shot/shot.tscn(스크립트에서 GameState 설정 후 장면 instantiate, 대사 강제 종료)을 만들어 <Godot>\Godot_v4.4.1-stable_win64.exe --path . res://_shot/shot.tscn --write-movie <스크래치>/x.png --fixed-fps 30 --quit-after 50 --resolution 720x1280 -- <인자>. 샌드박스 끄고 실행. 끝나면 _shot 삭제(커밋 금지)
- APK: <Godot>_console.exe --headless --path . --export-debug "Android" build/android/oneului-bada.apk (export_presets.cfg의 Android 프리셋, arm64, 디버그 서명). 안드로이드 템플릿(%APPDATA%\Godot\export_templates\4.4.1.stable, android 파일만)과 SDK(%LOCALAPPDATA%\Android\Sdk: build-tools 34, platform-tools) 설치됨. 지금 APK 87MB라 휴대폰 Claude 앱 전송 한도(30MB)를 넘는다. 앱 아이콘 미지정(Godot 기본)
- 그림 받는 방법 (이번 세션에 확립): Claude in Chrome 확장으로 사용자의 ChatGPT 프로젝트 대화 https://chatgpt.com/g/g-p-6af07332652c8191b12367fde94e54ec-oneulyibada/c/6af1c097-cf34-83ee-aa35-1fc488f0e73c 에 프롬프트를 넣고(입력창 find → 클릭 → type → 보내기 버튼 ref 클릭), 결과 이미지는 javascript로 img(naturalWidth 큰 것) blob을 fetch해 a.download로 내려받아 C:\Users\<USER>\Downloads 에서 복사. 페이지가 가상 스크롤이라 이미지가 DOM에 없으면 스크롤 컨테이너 scrollTop을 끝으로. 투명 PNG는 ChatGPT가 주는 파일 카드(sun_sprite_alpha.png처럼)를 열어 다운로드. Chrome 연속 다운로드는 사용자가 허용해 둠
- 이번 세션에 만든 것
  - 낚시 개편: 캐스팅 포인트(NICE CAST), 챔질 고리(PERFECT), 연속 PERFECT 물 오름, 좌우 줄다리기(반대로 끌기, 바위틈 파고들기 실패), 지침, 희귀도 7종(볼락, 망상어, 노래미, 쏨뱅이 / 우럭, 학공치 / 감성돔), 별점, 대물, 최대 기록, 미끼 5종(BaitDB, 낚시방 미끼 탭), 오늘의 바다(SeaDay 물때·날씨), 식당 주문서(Orders)
  - 주인공 SD: 사용자가 준 동작 시트를 tools/slice_grid.py로 잘라 assets/art/sd/back_01~12, front_01~12. PlayerRig가 상태별 프레임 + 여울 장비 그림(gear_icon/blank-n, butt-n, float-n)으로 낚싯대를 붙이고 휘게 그린다. 낚싯대·릴 10단계(GearDB, 여울 단계 그대로)
  - 코지 UI: UiKit 토큰을 SD 팔레트로, chunky(굵은 외곽선+아래 턱), 주아체(Jua, OFL). 공통 헤더 GameHeader(일차, 시각, 날씨·물때, 마리 수, 돈, 메뉴)와 GameMenu(가방, 도감, 장비, 설정). 낚시, 지도, 낚시방에 적용
  - 낚시 배경: 세로 9:16 밤·새벽·아침·저녁 4장(해 없음) + 투명 해 sun.png. SeaBackdrop.FISHING_SCHEDULE로 시각에 따라 이어 붙이고 sun_path로 해가 움직임. sea_water.gdshader로 받은 그림의 바다색 부분만 일렁이고 반짝임이 깜빡임
  - 마을 지도 1차: assets/art/map_village.png (세로 한 화면, 핀 14곳 scripts/data/locations.gd pos). 아래 "바뀐 점" 때문에 다시 뽑는다

## 확정된 결정
- 제목 〈오늘의 바다〉, 주인공 1994년 2월생 7년 차 개발자 퇴사, 기본 이름 한바다, 가게 오늘의 식탁
- Godot 4.4.1 GDScript 2D, 세로 720x1280, GitHub 금지(로컬 커밋만, 백업은 ./tools/backup.sh 후 사용자가 드라이브 오늘의바다_백업에 올림)
- 그림은 직접 만들지 않는다(코드 장식 그림 금지). 받은 그림을 움직이는 것(해 이동, 물결 셰이더, 크로스페이드)은 된다. 판정 표시(줄, 게이지, 포인트 물결, 화살표)만 코드로 그린다
- 화풍: 둥글고 귀여운 코지 (굵고 둥근 남보라 외곽선, 단순한 면, 볼터치, 파스텔). 기준 docs/ref/SD_설정화_3면.png와 물고기 시트
- 방향: 북쪽 방파제 끝에서 **동쪽 바다**를 본다 (화면 왼쪽 북, 오른쪽 남, 등 뒤 서). 해돋이 정면, 해넘이 등 뒤. 해는 05:15 산 위에서 서서히 나타나 오른쪽 위로 올라가 13시쯤 화면 위로 사라짐. 지도도 위가 북, 바다와 항구 입구가 동쪽
- 낚시 장비 그림은 여울 그림 그대로, 낚싯대·릴 10단계
- 바뀐 점 (이번 세션 마지막 사용자 요청)
  - **방파제 배치가 어색하다.** 방파제는 배가 정박한 항구를 파도에서 막으려고 있는 것. 지금 지도는 방파제가 항구를 제대로 감싸지 않아 어색함. 북쪽 방파제와 남쪽 방파제가 항구(배가 정박한 안쪽 물)를 양팔처럼 감싸고, 그 사이 좁은 항구 입구가 동쪽 먼바다로 열린 구조로 다시 뽑는다. 북쪽 방파제 끝에 빨간 등대(낚시 화면과 이어짐), 남쪽 방파제 끝에는 흰 등대가 자연스럽다
  - **마을 지도를 크게 다시 뽑는다.** 한 화면에 다 넣지 말고, 화면보다 큰 지도를 손가락으로 끌어(스크롤·드래그) 이동하는 방식이어도 좋다. 장소가 넉넉히 떨어져 각각 알아보기 쉽게
  - **확장성을 처음부터 고려.** 나중에 배를 타고 나가는 것(동백섬, 먼바다 어장, 여객선 항로), 갯바위, 야광충 해변, 3막 마을 발전(관광 지도) 등이 들어갈 자리를 처음부터 지도에 마련한다. 바다 쪽 여백을 넉넉히, 항구에 여객선 선착장과 어선 정박 자리, 먼바다로 나가는 뱃길이 보이게
- 접은 것: 유리+종이 UI(코지로 바꿈), 세밀화 물고기, 바다 한 접시 세밀한 애니 배경 계속 쓰기, player_sd_body 한 장 방식(동작 시트로 대체), 낚싯대·릴 새로 뽑기

## 사용자 선호
- 그림 프롬프트를 사용자에게 줄 때: 채팅 코드 블록, 한국어+영어, ChatGPT용(비율은 문장으로), "이미지 N → 프롬프트 N" 순서, 참조 그림은 SendUserFile로 먼저. 다만 이번 세션부터는 Claude가 Chrome으로 ChatGPT에 직접 넣어 뽑아도 된다고 함 (사용자가 원함)
- 그림을 받으면 바로 게임에 넣고 화면을 찍어 확인, 결과 화면은 SendUserFile로 보낸다 (휴대폰 원격 접속을 자주 함. 30MB 넘는 파일은 폰으로 못 보냄)
- 10년 차 프론트엔드 수준의 예쁜 요즘 UI. 디자인 관련 스킬(design:design-system, design:design-critique, design:accessibility-review)을 적극적으로 쓰길 원함
- 병렬로 할 수 있는 건 서브 에이전트로 병렬 진행해도 좋음 (같은 파일을 동시에 고치지 않게 나눠 맡기기)
- 대사와 글: 자연스러운 구어체, 쉼표 남발과 줄표 금지

## 환경 제약
- 큰 다운로드, 라이선스 동의, 메시지 보내기 같은 바깥으로 나가는 일은 먼저 허락받기 (이번 세션에 안드로이드 도구와 Google Android SDK 라이선스는 허락받고 설치함)
- 셸이 샌드박스로 막히면(Godot 창 띄우기, 레포 바깥 쓰기) 샌드박스를 끄고 실행
- rm -rf에 변수 경로를 쓰면 안전 검사에 막힘: "${S:?}/${m:?}" 형태로 쓴다
- git core.autocrlf=true (줄바꿈 경고 무시)
- 비밀 값 없음

## 이번에 해 줬으면 하는 것
1. 상태 확인: git log --oneline -3 (f4651df), 테스트 369 통과. 사용자가 build/backup의 최신 bundle(oneului-bada-20261110-0007)을 드라이브에 올렸는지, 폰에서 APK를 설치해 봤는지 물어 결과(어색한 점)를 받는다
2. 마을 지도 다시 뽑기 (Chrome으로 ChatGPT 대화에서)
   - 먼저 지도 설계를 사용자와 짧게 정한다: 크기(예: 세로 화면의 2~3배 세로 긴 지도, 또는 가로세로 모두 큰 지도), 구역 배치(서쪽 언덕 마을, 가운데 항구, 동쪽 먼바다, 남쪽 해안), 항구 구조(북·남 방파제가 항구를 감싸고 입구가 동쪽), 배 관련 자리(어선 정박, 여객선 선착장, 뱃길), 나중 장소 자리(동백섬, 먼바다 어장, 검은여 갯바위, 야광충 해변, 연구소, 관광 시설)
   - ChatGPT 이미지는 한 장 해상도에 한계가 있으니 큰 지도는 여러 조각(타일)으로 나눠 이어 뽑을지, 한 장을 크게 뽑을지도 같이 정한다
   - 기존 1차 지도 docs/ref/마을지도_세로_1차.png를 참조로 쓰되 방파제 구조는 위 결정대로 고친다. 글자, 나침반, 사람 없이
3. 지도 화면(scenes/map/map.gd)을 드래그·스크롤로 이동하는 큰 지도로 바꾸고 핀 위치(locations.gd pos)를 새 그림에 맞춘다. 지금 있는 곳 중심으로 시작, 헤더는 위에 고정. 이동 시간(travel_minutes)도 새 거리 기준으로 확인하고 테스트 수정
4. 북쪽 방파제 낚시 배경(동쪽을 봄)이 새 지도의 항구 구조와 어긋나지 않는지 확인. 낚시 화면 오른쪽(남쪽)에 남쪽 방파제나 항구 입구가 보이는 게 자연스러우면 사용자와 상의해 배경을 다시 뽑을지 정한다
5. APK 크기 줄이기(사용자가 원하면): 안 쓰는 그림(assets/art/ingredient, cook_tool, 안 쓰는 gear_icon 종류, 안 쓰는 dish, 예전 player/rod/bg jpg)을 export 제외 필터로 빼고, 큰 배경을 손실 압축으로 가져오기, 글꼴 정리. 앱 아이콘(그림 요청)도 정한다
마지막: 테스트 통과, 장면 오류 검사, 화면 찍어 확인(SendUserFile로 보내기), 로컬 커밋(메시지 끝에 Co-Authored-By 줄), ./tools/backup.sh로 백업 만들고 드라이브 오늘의바다_백업에 올리라고 안내, 필요하면 APK 다시 만들기
```
