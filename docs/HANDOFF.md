# 이어가기 (2026-11-09, 브랜치 main, 원격 없음)

환경: **코드** (사용자 PC에서 도는 Claude Code). 클라우드에서 만든 것을 로컬로 옮겨 이어 간다. 설치와 복원 방법은 `docs/LOCAL_SETUP.md`.

```
오늘의 바다(Godot 4 생활 시뮬레이션 낚시 게임) 개발을 내 PC에서 이어서 해 줘.

## 답변 방식
- 생각하는 과정을 포함한 모든 답변은 한국어로 답변한다.
- 설명은 간략하고 쉽게 한다.
- 애매하거나 모호한 부분이 있다면 질문을 통해 해결하고 넘어간다.

## 지금까지 상황 (코드 환경, 내 PC 로컬 git, 원격 레포 없음)
- 프로젝트 루트: `C:\Users\<USER>\Desktop\오늘의 바다` (브랜치 main). 클라우드에서 만든 것을 bundle로 옮겨 왔다 (`docs/LOCAL_SETUP.md`)
- `docs/ref/`에 참조 그림이 이미 들어 있다
- 엔진: Godot 4.4.1 Standard, GDScript, 2D, 1280x720. Godot 실행 파일 위치는 사용자에게 한 번 물어서 확인한다 (PATH에 없을 수 있음)
- 먼저 읽을 것: `CLAUDE.md` (작업 규칙), `docs/LOCAL_SETUP.md`, `docs/그림_요청_목록.md`, `docs/찌낚시_동작_조사.md`, `docs/물고기_그림_목록.md`, 기획서 `docs/오늘의바다_시나리오_v3.md`
- 참조 그림 원본은 git에 없다. 사용자가 드라이브 `오늘의바다_백업/ref`를 `docs/ref/`에 풀어 둔다 (없으면 요청)
- 만든 것
  - 타이틀 → 사직서(플레이어명 입력) → 간판(가게명 입력) → 새벽 방파제 낚시(튜토리얼) → 〈첫 번째 손님〉 식당 → 마을 지도
  - 낚시: 방파제 끝 뒤쪽 시점, 배경 `assets/art/bg_fishing_dawn.jpg`. 실제 찌낚시 동작 반영 (백스윙 1시, 던지기, 찌 보기 45도, 견제 70도 = 오른쪽 클릭/Shift, 찌 흘러감, 입질 때 점점 잠김, 헛챔질, 챔질 85도, 펌핑: 누르면 숙이며 감기 떼면 세워 버티기, 들어 올리기 연출 뒤 물고기 카드)
  - 첫날 뒤에는 지도에서 북쪽 방파제를 골라 아무 시간대에나 낚시. 시각에 따라 밝기가 바뀌고(FishingLogic.brightness_at) 그만하기나 밤 11시에 끝
  - SD 주인공은 몸, 낚싯대, 릴을 따로 조립 (`scripts/fishing/player_rig.gd`). 장비를 바꾸면 그림과 능력치가 바뀜 (`scripts/data/gear_db.gd`, 지도 화면의 장비 버튼)
  - 첫 물고기는 볼락 고정, 새벽에 볼락이 잘 물고 밝아지면 줄어듦. 어종 3종(볼락, 망상어, 노래미)
  - 〈첫 번째 손님〉 (`scenes/restaurant/first_guest.gd`): 볼락구이 요리(간 맞추기 → 굽기, `scripts/cooking/cooking_logic.gd`), 결과에 따라 순덕 대사가 바뀜, 첫 매출 7,000원, 장부 첫 줄, 다음 날로
  - 준호네 낚시방 (`scenes/shop/tackle_shop.gd`): 낚싯대 3종, 릴 3종 구매와 장착
  - 소리: `Sound` 오토로드. 배경음악(타이틀, 바다, 마을, 시장)과 낚시, 요리, 상점 효과음
  - 마을 지도: 장소 14곳, 이동 시간, 진행 표시로 해금 (`scripts/data/locations.gd`). 지도 그림은 아직 없음
  - 조사 자동 처리 대사 템플릿 `{player|이/가}` 등, 기본 이름 한바다 / 오늘의 식탁
  - 테스트 171개 (`tests/run_tests.gd`)
- 바다 한 접시(이전 게임, Godot 4 + C#) APK에서 가져온 것: 소리 36개, 어종 71종과 레시피 50개 데이터(`assets/data`, `Catalog`), 요리 50접시, 조리도구, 화로 등 주방, 재료, 장비 아이콘. 자세한 건 CLAUDE.md의 〈바다 한 접시 자료〉
- 받은 그림 중 게임에 들어간 것: `player_sd_body.png`, `rod_old_float.png`, `bg_fishing_dawn.jpg`, `fish_bolak.png`(세밀화), 임시 `fish_mangsang.png`·`fish_noraemi.png`(아이콘풍 시트 조각)

## 확정된 결정
- 제목 〈오늘의 바다〉, 주인공 1994년 2월생, 2020년 3월 만 26세 첫 취업, 7년 차 퇴사
- 엔진 Godot 4. GitHub는 계정 정지 문제가 풀릴 때까지 쓰지 않는다 (remote, push, Actions 금지). 로컬 커밋만
- 화풍: 깔끔한 2D 셀 채색 코지 게임 스타일 (수채화는 접음: 사용자가 요즘 트렌드에 맞는 깔끔한 그림을 원함)
- 주인공 얼굴 기준: 1차 시안 B + 옅은 수염. 낚시 화면의 주인공은 SD 2.5등신 뒷모습
- 물고기 그림은 **세밀화풍** (아이콘풍 시트는 임시)
- 낚시 화면은 방파제 끝에서 바다를 보는 뒤쪽 시점, 바다가 넓게 보이게
- 그림은 절대 직접 만들지 않는다. 코드로 그리는 장식 그림도 새로 만들지 않는다 (사용자가 코드 그림을 촌스럽다고 함). 낚싯줄, 찌, 게이지 같은 판정 표시만 선으로 그린다
- 백업: `./tools/backup.sh`(Git Bash)로 bundle을 만들어 사용자가 드라이브 `오늘의바다_백업`에 올린다. 그림 원본은 git에 넣지 않는다

## 사용자 선호
- 그림 프롬프트: md 파일 말고 채팅 코드 블록으로, 한국어와 영어 둘 다, ChatGPT용 (Midjourney 설정 넣지 않음, 비율은 문장으로)
- **첨부할 이미지를 먼저 알려 주고(로컬 파일 경로나 이미지 보여 주기) 바로 아래에 프롬프트**. 한 번에 하나씩, 결과를 받으면 다음 단계로
- 투명 배경이 필요한 그림은 `배경은 완전히 투명한 PNG(알파 채널). 배경 없이 대상만.` / `Transparent background, PNG with alpha channel, isolated subject with no background.` 문구를 넣는다. 흰 배경으로 오면 `tools/remove_white_bg.py`로 지운다
- 그림을 받으면 게임에 바로 넣고 실행해서 확인한다
- 문장에 쉼표 남발, 줄표(—, ㅡ) 쓰지 않기. 자연스러운 구어체

## 환경 제약
- 사용자는 휴대폰 Claude 앱에서 Remote Control로 이 PC 세션에 붙어 작업하기도 한다. PC가 켜져 있고 데스크톱 앱이 열려 있어야 한다. 휴대폰에 그림이나 파일을 보여 줄 때는 SendUserFile로 보낸다
- 로컬이라 드라이브 파일은 사용자가 브라우저로 직접 받아 폴더에 넣어 준다
- Godot가 PATH에 없을 수 있다. 테스트는 `<Godot 폴더>/Godot_v4.4.1-stable_win64_console.exe --headless --path . --script res://tests/run_tests.gd`
- 그림 도구(Python)는 numpy, scipy, pillow가 필요하다
- 비밀 값은 없다

## 이번에 해 줬으면 하는 것
1. 상태 확인: `git log --oneline -3`, 테스트 171개 통과, 에디터에서 F5로 실행되는지 사용자에게 확인 (Godot: `C:\Users\<USER>\Tools\Godot\`, 바탕 화면에 바로가기)
2. 그림 진행 (이미지 → 프롬프트 한 단계씩, 휴대폰에서도 보이게 첨부 이미지는 SendUserFile로 보낸다)
   - 프롬프트 9 `rod_starter_float.png` 결과 대기 중 (참조: `docs/ref/낚싯대_낡은릴찌.png`, 같은 구도로 디자인만 변경. 새 남색 광택 몸통, 검은 EVA 그립, 은색 릴시트와 가이드, 하늘색 띠 두 줄). 다음 `rod_carbon_rock.png`
   - 릴 3종 `reel_cheap_spinning.png`, `reel_spinning_2500.png`, `reel_lever_brake.png` (옆모습, 위쪽 가운데가 낚싯대에 붙는 다리, 투명)
   - `bg_fishing_morning.jpg`: `bg_fishing_dawn`과 같은 구도의 아침 (밝기만큼 섞임. 참조 `docs/ref/낚시화면_새벽_2차.png`)
   - 망상어, 노래미 세밀화 (참조 `docs/ref/볼락_세밀화.png`)
   - 새 장면용: `bg_shop_inside_day`(식당 내부), `npc_sundeok`(최순덕), `bg_tackle_shop`, `npc_junho` (`docs/그림_요청_목록.md`)
   - 그 뒤: 마을 지도 `map_village`, 식당 외관, 항구 (프롬프트 초안 `docs/배경_지도_프롬프트.md`, 화풍은 클린 셀 채색으로)
   - 그림이 오면 위치 비율을 그림에 맞춘다 (낚싯대 grip/seat/tip/axis는 gear_db, 손 위치는 player_rig HAND, 배경은 fishing.gd의 WATER_NEAR_Y 등)
3. 코드 다음 후보: 잡은 물고기 시장에 팔기, 식당 영업(손님 여러 명, 메뉴 고르기), 바다 한 접시 어종 데이터로 계절별 어종 늘리기
마지막: 테스트 통과 확인, 실행 확인, 로컬 커밋, `./tools/backup.sh`로 백업 만들고 드라이브에 올리라고 안내
```
