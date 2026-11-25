# 이어가기 (2026-11-24, 브랜치 claude/game-features-ui-improvements-98a600)

환경: 코드 (집 노트북 로컬 레포, Godot 있음). 아래 코드 블록을 새 대화 첫 메시지로 붙여 넣는다.

```
오늘의 바다(Godot 4.4.1 세로 어촌 생활 게임)에서 영업 빨리감기, 4주 뒤 이야기, 특별 손님 늘리기, 빈 장소 채우기를 이어서 해 줘.

## 답변 방식
- 생각하는 과정을 포함한 모든 답변은 한국어로 답변한다.
- 설명은 간략하고 쉽게 한다. caveman과 i-have-adhd 규칙은 켜 두고, 말투는 해요체로 한다.
- 애매하거나 모호한 부분이 있다면 질문을 통해 해결하고 넘어간다.

## 지금까지 상황 (환경: 코드, 집 노트북)
- 브랜치 claude/game-features-ui-improvements-98a600. main(056c2a2)보다 앞서 있고 아직 main에 합치지 않았다. push도 안 했다. 새 worktree면 이 브랜치에서 시작할 것
- 테스트 2,824개 통과. APK v0.4는 build/android/oneului-bada-1124-199a361.apk (폰 확인 전). 드라이브에는 안 올림
- 커밋 안 된 코드 변경 없음
- 먼저 읽을 것: CLAUDE.md, docs/오늘의바다_시나리오_v3.md, scripts/data/story.gd, quests.gd, locations.gd, orders.gd, friends.gd, scripts/restaurant/special_guest.gd, dining_logic.gd, scenes/restaurant/dining_floor.gd
- 11-24에 들어간 것
  - 요리: Menu 12가지, 곁들임(Sides) 삭제, 채소는 Pantry, 세라와 요리 연구(하루 하나)
  - 돈: Loan 매주 월요일 상환, 집에서 더 갚기, 팁(ServicePlan.settle), WeekGoals 이번 주 도전
  - 가게: 경자상회 실내(scenes/shop/store.gd), 주방 장비 5단계(KitchenDB)
  - 식당: 주인공은 왼쪽 위에 서고, 인물 키는 모두 바탕 170px
  - 조작: BackButton 오토로드(뒤로가기 두 번 종료), KeyboardLift, rise_in 크기 굳던 버그 수정
- 그림 세션 두 개(art-store-dishes, art-from-title)의 그림은 모두 합쳤다
- 화면 찍는 장면: 메인 폴더 _shot/ 의 ui, led, back, service_auto, dining_auto (git 제외). worktree에서는 복사해 쓴다

## 확정된 결정
- 비싼 생선(감성돔, 농어, 우럭)은 오늘 잡았거나 수조에서 꺼낸 것을 회로 제값, 하루 회 손님 2~3명. 묵은 것은 구이 12,500원까지
- 곁들임 없음. 채소와 달걀은 요리 재료. 생선은 낚시로만 얻는다
- 레시피는 하트 1~2개나 세라와 연구로 바로 메뉴판에 오른다
- 상환은 매주 월요일. 값 수준(싸게, 비싸게) 없음. 만족도가 높으면 팁, 음식값과 팁을 나눠 보여 준다
- 주인공은 요리하지 않고 서빙만, 요리는 세라
- 모든 대화는 말하는 사람 일러스트를 화면 오른쪽 아래에
- 접은 것: APK(그림) 용량 줄이기. 사용자가 아직 필요 없다고 함

## 사용자 선호
- 그림은 절대 직접 그리지 않는다. 새 세션에서 사용자가 준 ChatGPT 프로젝트로 받는다. 부족한 그림은 알아서 받고 판단해 커밋과 병합까지 해도 된다고 허락함 (이상하면 나중에 수정 요청). 프로젝트 주소는 공개 레포라 여기 적지 않는다. 필요하면 사용자에게 다시 받는다
- 화면은 직접 찍어 보여 준다. 결과부터 짧게
- 대사는 자연스러운 구어체. 쉼표 남발과 줄표 금지. 이름은 {player}, {shop} 템플릿
- main 병합, push, 드라이브 업로드는 사용자가 말할 때만

## 환경 제약
- Godot: Tools/Godot의 Godot_v4.4.1-stable_win64_console.exe (docs/LOCAL_SETUP.md). --import는 가끔 멎으니 다시 돌린다
- Git Bash 명령이 길면(대략 8천 자) 잘린다. 파일은 Write 도구로 쓴다
- 가져오기를 돌리면 .import 파일들이 줄바꿈만 바뀐 것으로 잡힌다. 커밋에 넣지 않는다
- docs/ref는 git에 없다

## 이번에 해 줬으면 하는 것
1. 영업 빨리감기: 손님을 기다리기만 하는 시간(할 일이 없을 때)을 빨리 넘긴다. 단추로 할지 저절로 할지 먼저 추천안을 내고 정한다. 손님이 화나거나 접시가 나오면 보통 속도로. 끝: 테스트와 자동 영업 녹화로 확인
2. 4주 뒤 이야기: 지금은 Quests가 main_debt(대출 줄이기)만 보여 준다. 시나리오 1막 뒤쪽과 2막 챕터 3(마을에 스며들다)부터 메인 이야기를 잇는다. 어디까지 만들지 먼저 범위를 제안한다
3. 특별 손님 늘리기: 지금 Orders.CUSTOMERS와 SpecialGuest.TALES에 최순덕, 박만수, 이준호 셋뿐이고 사연은 세 토막씩. 경자, 복자, 용팔, 태식, 해솔을 더하고 사연도 쓴다
4. 빈 장소 채우기: lookout(전망대), school(분교), guesthouse(민박), lab(연구소)는 장면이 없다. 낮에 할 일을 하나씩 준다. 새 배경과 인물 그림이 필요하면 그림 세션을 따로 연다
마지막: tests/run_tests.gd에 테스트 추가, 전체 테스트, 화면 확인, 작업 브랜치에 커밋(작성자는 레포 로컬 설정, 메시지 끝에 [skip ci]). 다 되면 APK를 만들지 물어본다
```
