# 이어가기 (2026-11-10, 브랜치 main, 원격 GitHub Crong94/harbor-days 공개)

환경: **코드** (집 노트북에서 도는 Claude Code). 회사 PC에서 GitHub 연결까지 마쳤고, 집 노트북에서 Godot로 실행 확인과 개발을 이어 간다. 설치와 원격 사용 방법은 `docs/LOCAL_SETUP.md` (2번 코드 받기, 8번 집 노트북 원격).

```
오늘의 바다(Godot 4 생활 시뮬레이션 낚시 게임) 개발을 집 노트북에서 이어서 해 줘.

## 답변 방식
- 생각하는 과정을 포함한 모든 답변은 한국어로 답변한다.
- 설명은 간략하고 쉽게 한다.
- 애매하거나 모호한 부분이 있다면 질문을 통해 해결하고 넘어간다.

## 지금까지 상황
- 환경: 코드 (집 노트북의 Claude Code). 이 노트북에서는 처음 여는 레포일 수 있다
- 레포: GitHub `Crong94/harbor-days` (공개), 브랜치 `main`. 마지막 커밋은 이 이어가기 문서를 올린 커밋 (그 앞은 `5d7eb1f 저장소 이름을 harbor-days로 변경`)
- 회사 PC 로컬 폴더 이름은 `oneului-bada`, 새로 clone하면 `harbor-days`. 이름만 다르고 같은 레포다
- GitHub Actions 첫 실행 성공: 테스트 `결과: 126 통과, 0 실패` (Linux, Godot 4.4.1 헤드리스)
- 먼저 읽을 것: `CLAUDE.md` (작업 규칙), `docs/LOCAL_SETUP.md`, `docs/그림_요청_목록.md`, 기획서 `docs/오늘의바다_시나리오_v3.md`

## 이번(11-10)에 한 것
1. GitHub로 옮김 (회사 PC)
   - 예전 방식(로컬 커밋만, bundle을 드라이브에 백업)을 끝내고 `Crong94/harbor-days`(공개)에 push한다
   - 커밋 작성자를 이력 전체에서 `Songok Kim <thddhr14@gmail.com>`으로 다시 썼다. 그래서 커밋 해시가 바뀌었다. **예전 bundle(`oneului-bada-*.bundle`)이나 예전 폴더에서 pull하거나 합치지 않는다.** 노트북에 예전 폴더가 있으면 그대로 두고 새로 clone한다
   - `.github/workflows/ci.yml`: 게임 코드(scripts, scenes, tests, assets, project.godot, export_presets.cfg)가 바뀐 push/PR에서만 테스트. 웹 빌드는 Actions 탭에서 Run workflow, "웹 빌드도 만들기" 체크할 때만 (결과 zip 7일 보관)
   - 저장소 이름은 처음 oneului-bada로 만들었다가 harbor-days로 바꿨다 (사용자가 소리 나는 대로 쓴 영어 이름이 별로라서)
2. 마을 지도 (그 전 세션)
   - 시안 A(클린 셀 채색 3/4 조감도) 확정. 원본은 드라이브 `오늘의바다_백업/ref/map_village_확장_v3.png`, 게임에는 `assets/art/map_village.jpg`
   - 확장 요소: 동백섬 선착장과 정자(배로 이동), 터널과 버스 정류장(옆마을), 숨은 갯바위, 해식동굴, 뒷산 전망대, 가두리, 먼바다 바위섬(배낚시), 빈 건물 터 2곳, 닭장(닭은 안 그림), 빈 이랑 텃밭
   - 지도 화면 코드: `ArtSlot`의 `cover`, `cover_focus`(3:2 지도를 16:9에 꽉 채움, `map.gd`의 `MAP_FOCUS`), `locations.gd` 핀 위치와 새 장소 8곳, `"pin": "below"`, `"hidden": true`(`Locations.is_visible`), 지도 HUD를 오른쪽 위로 옮김. **테스트는 통과했지만 Godot 화면으로는 아직 한 번도 못 봤다**

## 확정된 결정
- 제목 〈오늘의 바다〉, 주인공 1994년 2월생, 7년 차 퇴사. 엔진 Godot 4.4.1, GDScript, 1280x720
- Git: 시작할 때 `git pull`, 끝나면 커밋하고 `git push`. 작성자는 이 레포 로컬 설정 `Songok Kim <thddhr14@gmail.com>`만 쓴다
- 공개 레포라서 비밀번호, 토큰, 개인 메일, 집 위치 같은 개인 정보는 파일과 커밋 메시지에 넣지 않는다
- **회사 PC에는 Godot나 게임 관련 프로그램을 설치하지 않는다.** Godot 실행과 화면 확인은 집 노트북에서 한다
- Actions는 아껴 쓴다. 워크플로를 늘리거나 트리거를 넓히려면 먼저 사용자에게 묻는다
- 큰 파일(참조 그림 원본, APK)은 git 밖, 드라이브 `오늘의바다_백업`에 둔다. `tools/backup.sh`는 GitHub가 안 될 때만 쓰는 예비 백업
- 화풍: 깔끔한 2D 셀 채색 코지 게임 스타일. 물고기는 세밀화풍
- 그림은 절대 직접 만들지 않는다. 코드 장식 그림도 만들지 않는다. 판정 표시(낚싯대, 줄, 찌, 게이지)만 선으로
- 옆마을은 차 대신 버스로 간다. 요금을 내고 정해진 배차 시간에 탄다. 남해라 갯벌은 넣지 않는다

## 사용자 선호
- 그림은 Claude가 크롬으로 ChatGPT 프로젝트 "오늘의바다"(https://chatgpt.com/g/g-p-6af07332652c8191b12367fde94e54ec/project)에 직접 요청해서 받고, 결과를 보여 주고 검토받은 뒤 드라이브 ref에 올린다. 여러 시안을 받아 비교하게 하는 걸 좋아한다
- 그림 프롬프트는 채팅 코드 블록으로, 한국어와 영어 둘 다. 투명 배경이 필요한 그림은 알파 채널 문구를 넣는다
- 받은 파일은 다운로드 폴더에 두지 말고 작업 폴더로 옮긴다
- 문장에 쉼표 남발, 줄표(—, ㅡ) 쓰지 않기. 자연스러운 구어체
- 이름이나 방식은 몇 가지 후보를 표로 주고 추천 하나를 고르게 하는 걸 좋아한다

## 환경 제약
- 노트북에 Git, Godot 4.4.1 Standard(.NET 아님), Claude 데스크톱 앱이 필요하다. 없으면 `docs/LOCAL_SETUP.md` 1번대로 설치를 안내한다. Godot 콘솔 실행 파일 위치는 사용자에게 한 번 묻는다
- 첫 push 때 GitHub 로그인 창이 뜨면 사용자가 Crong94로 직접 로그인한다 (Claude가 비밀번호를 넣지 않는다)
- 회사 PC나 폰에서 이 노트북 세션에 붙어 쓰려면 Remote Control이 켜져 있어야 한다 (`docs/LOCAL_SETUP.md` 8번)
- 참조 그림 원본은 git에 없다. 필요할 때 드라이브 `오늘의바다_백업/ref`를 `docs/ref/`에 받는다

## 이번에 해 줬으면 하는 것
1. 노트북 준비
   - 레포가 없으면 `git clone https://github.com/Crong94/harbor-days.git` 후 레포 안에서 `git config user.name "Songok Kim"`, `git config user.email "thddhr14@gmail.com"`. 있으면 `git pull`
   - `git log --oneline -3`으로 위 커밋이 보이는지 확인
   - Godot 위치를 묻고 `--headless --path . --import` 후 테스트를 돌려 `126 통과, 0 실패`인지 확인
   - Claude 설정에서 Remote Control 자동 연결과 작업 중 절전 막기가 켜져 있는지, Windows 전원 설정(전원 연결 시 절전 안 함, 덮개 닫을 때 아무것도 안 함)을 했는지 사용자에게 확인 (8번 문서)
2. **지도 화면 실행 확인** (마지막 화면이 지도). 에디터에서 처음 열 때 `map_village.jpg`가 import 되는지도 본다
   - 화면 흉내로 찾은 겹침: **경자상회(store) 핀과 물빛분교(school) 핀이 겹친다**. 분교 핀을 아래(`"pin": "below"`, 운동장 쪽)로 내리거나 x를 조금 옮긴다
   - 숨은 장소 2곳이 처음엔 안 보이는지, HUD가 오른쪽 위에 잘 붙는지, 1280x720과 다른 창 크기에서 핀이 그림을 따라가는지
   - 확인한 화면은 스크린샷으로 사용자에게 보여 준다
3. **텃밭 시험**: 지도에서 텃밭 부분만 잘라 ChatGPT에 작물 하나를 심은 모습으로 고치게 하고, 원래 자리에 덮어 지도에서 어색하지 않은지 보여 준다. 괜찮으면 빈 밭, 자라는 중, 수확 가능 세 상태로 간다
4. 이전부터 남은 일 (사용자와 순서를 정해서)
   - APK 분석: 사용자가 직접 만든 이전 게임 `hanjeopsi-269.apk`(드라이브 `오늘의바다_백업`). 레포 바깥에 풀어서 무엇을 가져올지 정한다. git에는 넣지 않는다
   - 그림: 릴 3종, `bg_fishing_morning`, 식당 내부와 외관, 항구 등 (`docs/그림_요청_목록.md`에서 ✅ 없는 것)
   - 코드: 〈첫 번째 손님〉 식당 장면, 아무 시간대 방파제 낚시(지도와 연결), 준호네 낚시방 장비 구매, 버스(요금과 배차 시간 안내)
마지막: 로컬 테스트 통과, 실행 확인, 커밋하고 `git push`, Actions 테스트가 초록불인지 확인. 다음 세션용으로 `docs/HANDOFF.md`를 갱신한다
```
