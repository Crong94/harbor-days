# 이어가기 (2026-11-09, 브랜치 main, 원격 없음)

환경: **cloud** (Claude Code 클라우드 컨테이너). GitHub를 쓰지 않아서 원격 레포가 없고, 코드는 구글 드라이브의 git bundle로만 넘어간다.

```
오늘의 바다(Godot 4 생활 시뮬레이션 낚시 게임) 개발을 이어서 해 줘.

## 답변 방식
- 생각하는 과정을 포함한 모든 답변은 한국어로 답변한다.
- 설명은 간략하고 쉽게 한다.
- 애매하거나 모호한 부분이 있다면 질문을 통해 해결하고 넘어간다.

## 지금까지 상황 (cloud, 원격 레포 없음)
- 프로젝트: Godot 4.4.1, GDScript, 2D, 1280x720, 웹 내보내기. 폴더 이름 oneului-bada, 브랜치 main
- 코드는 구글 드라이브 내 드라이브 `오늘의바다_백업` 폴더에만 있다 (개인 계정)
  - 기본 백업: `oneului-bada-20261109-0615.bundle` (커밋 8586b84까지)
  - 추가분 백업: `oneului-bada-inc-8586b84-to-HEAD.bundle` (그 뒤 커밋 전부, 마지막 커밋은 이 HANDOFF.md를 담은 커밋)
  - 참조 그림: `오늘의바다_백업/ref` 폴더 (설정화, 키 비주얼, 시안 B, SD 몸, 낚싯대, 볼락 세밀화, 방파제 그림), `ref/sheets` (물고기 시트 12장)
- 복원 방법 (드라이브 커넥터는 큰 파일을 내려받지 못하므로 사용자가 첨부해 준다)
  1. 사용자에게 위 bundle 두 개를 이 대화에 첨부해 달라고 요청
  2. `git clone <0615.bundle> oneului-bada` 후 `cd oneului-bada && git pull <inc.bundle> main`
  3. `tools/setup_godot.sh` (Godot와 웹 템플릿 설치, github.com 릴리스 다운로드는 허용됨)
  4. `pip install scipy numpy pillow` (그림 자르기 도구용)
  5. `godot --headless --path . --import` 후 `godot --headless --path . --script res://tests/run_tests.gd` → 88개 통과 확인
  6. 그림 원본이 필요하면 드라이브 ref 폴더 파일을 사용자에게 첨부 요청해서 `docs/ref/`에 둔다 (git에 넣지 않음)
- 먼저 읽을 것: `CLAUDE.md` (작업 규칙), `docs/HANDOFF.md` (이 문서), `docs/그림_요청_목록.md`, `docs/찌낚시_동작_조사.md`, `docs/물고기_그림_목록.md`, 기획서 `docs/오늘의바다_시나리오_v3.md`
- 만든 것
  - 타이틀 → 사직서(플레이어명 입력) → 간판(가게명 입력) → 새벽 방파제 낚시 → 마을 지도
  - 낚시: 방파제 끝 뒤쪽 시점, 배경 `assets/art/bg_fishing_dawn.jpg`. 실제 찌낚시 동작 반영 (백스윙 1시, 던지기, 찌 보기 45도, 견제 70도 = 오른쪽 클릭/Shift, 찌 흘러감, 입질 때 점점 잠김, 헛챔질, 챔질 85도, 펌핑: 누르면 숙이며 감기 떼면 세워 버티기, 들어 올리기 연출 뒤 물고기 카드)
  - SD 주인공은 몸, 낚싯대, 릴을 따로 조립 (`scripts/fishing/player_rig.gd`). 장비를 바꾸면 그림과 능력치가 바뀜 (`scripts/data/gear_db.gd`, 지도 화면의 장비 버튼)
  - 첫 물고기는 볼락 고정, 새벽에 볼락이 잘 물고 밝아지면 줄어듦. 어종 3종(볼락, 망상어, 노래미)
  - 마을 지도: 장소 14곳, 이동 시간, 진행 표시로 해금 (`scripts/data/locations.gd`). 지도 그림은 아직 없음
  - 조사 자동 처리 대사 템플릿 `{player|이/가}` 등, 기본 이름 한바다 / 오늘의 식탁
- 받은 그림 중 게임에 들어간 것: `player_sd_body.png`, `rod_old_float.png`, `bg_fishing_dawn.jpg`, `fish_bolak.png`(세밀화), 임시 `fish_mangsang.png`·`fish_noraemi.png`(아이콘풍 시트 조각)

## 확정된 결정
- 제목 〈오늘의 바다〉, 주인공 1994년 2월생, 2020년 3월 만 26세 첫 취업, 7년 차 퇴사
- 엔진 Godot 4. GitHub는 계정 정지 문제가 풀릴 때까지 쓰지 않는다 (remote, push, Actions 금지)
- 화풍: 깔끔한 2D 셀 채색 코지 게임 스타일 (수채화는 접음: 사용자가 요즘 트렌드에 맞는 깔끔한 그림을 원함)
- 주인공 얼굴 기준: 1차 시안 B + 옅은 수염. 낚시 화면의 주인공은 SD 2.5등신 뒷모습
- 물고기 그림은 **세밀화풍** (아이콘풍 시트는 임시)
- 낚시 화면은 방파제 끝에서 바다를 보는 뒤쪽 시점, 바다가 넓게 보이게
- 그림은 절대 직접 만들지 않는다. 코드로 그리는 장식 그림도 새로 만들지 않는다 (사용자가 코드 그림을 촌스럽다고 함). 낚싯줄, 찌, 게이지 같은 판정 표시만 선으로 그린다
- 백업: 코드는 드라이브 bundle, 드라이브 업로드는 한 번에 약 3.1MB까지라 큰 경우 **추가분 bundle**로 올린다 (사용자 선택). 그림 원본은 git에 넣지 않고 드라이브 ref 폴더에 한 장씩 올린다

## 사용자 선호
- 그림 프롬프트: md 파일 말고 채팅 코드 블록으로, 한국어와 영어 둘 다, ChatGPT용 (Midjourney 설정 넣지 않음, 비율은 문장으로)
- **첨부할 이미지 파일을 먼저 보내고 바로 아래에 프롬프트**. 한 번에 하나씩, 결과를 받으면 다음 단계로
- 투명 배경이 필요한 그림은 `배경은 완전히 투명한 PNG(알파 채널). 배경 없이 대상만.` / `Transparent background, PNG with alpha channel, isolated subject with no background.` 문구를 넣는다. 흰 배경으로 오면 `tools/remove_white_bg.py`로 지운다
- 그림을 받으면 게임에 바로 넣고 스크린샷으로 보여 준다
- 문장에 쉼표 남발, 줄표(—, ㅡ) 쓰지 않기. 자연스러운 구어체

## 환경 제약
- 컨테이너는 매번 새로 만들어진다: Godot, 웹 템플릿, scipy/numpy 다시 설치 필요
- 네트워크: drive.google.com, drive.usercontent.google.com, cdn.jsdelivr.net 차단. github.com 릴리스와 npm, PyPI는 허용
- 드라이브 커넥터: 업로드 한 번에 약 3.1MB, 큰 파일 다운로드 불가 (대화에 텍스트로 들어옴)
- 화면 확인: 웹 빌드 후 `python3 -m http.server 8765 --directory build/web`, Playwright로 스크린샷. 낚시 상태는 `window.__fish` (상태|장력|이야기중|잡은수|던진힘)
- 웹 빌드는 엔진 파일이 44MB라 Artifact로 공유할 수 없다 (파일당 15MB 한도)

## 이번에 해 줬으면 하는 것
1. 복원하고 테스트 88개 통과 확인
2. **APK 분석**: 드라이브 `오늘의바다_백업/hanjeopsi-269.apk` (284MB). 사용자가 직접 개발한 이전 게임(바다 한 접시, Yeoul)이라 저작권 문제 없음. 받는 방법: get_environment → 사용자 승인으로 네트워크 허용 목록에 drive.usercontent.google.com, drive.google.com 추가 → 사용자가 APK를 '링크가 있는 사람은 볼 수 있음'으로 공유 → curl로 받기 (다 받으면 다시 비공개로 돌리라고 안내). 풀어서 엔진, 그림, 소리, 물고기와 레시피 데이터, 대사, 코드 구조를 목록으로 정리해 보여 주고, 무엇을 가져올지 사용자와 정한 뒤 오늘의 바다에 적용
3. 그림 진행 (이미지 → 프롬프트 한 단계씩)
   - 프롬프트 9 `rod_starter_float.png` 결과 대기 중 (참조: 이미지 10 낡은 릴찌낚싯대, 같은 구도로 디자인만 변경). 다음 `rod_carbon_rock.png`
   - 릴 3종 `reel_cheap_spinning.png`, `reel_spinning_2500.png`, `reel_lever_brake.png` (옆모습, 위쪽 가운데가 낚싯대에 붙는 다리, 투명)
   - `bg_fishing_morning.jpg`: `bg_fishing_dawn`과 같은 구도의 아침 (밝기만큼 섞임)
   - 망상어, 노래미 세밀화 (참조: `볼락_세밀화.png`)
   - 그 뒤: 마을 지도 `map_village`, 식당 내부와 외관, 항구
   - 그림이 오면 위치 비율을 그림에 맞춘다 (낚싯대 grip/seat/tip/axis는 gear_db, 손 위치는 player_rig HAND, 배경은 fishing.gd의 WATER_NEAR_Y 등)
4. 코드: 〈첫 번째 손님〉 식당 장면 (볼락 생선구이, 최순덕), 아무 시간대에나 방파제 낚시 (지금 낚시 장면은 첫날 새벽 튜토리얼 전용이라 지도와 연결 안 됨), 준호네 낚시방 장비 구매
마지막: 테스트 통과 확인, 웹 빌드 스크린샷, 커밋, `tools/backup.sh`로 bundle을 만들어 드라이브 `오늘의바다_백업`에 업로드 (3.1MB 넘으면 지난 백업 커밋부터의 추가분 bundle)
```
