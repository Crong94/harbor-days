# 로컬 PC에서 다시 구성하기

클라우드에서 만든 오늘의 바다를 내 PC로 옮겨 이어서 개발하는 방법이다. Windows 기준이고, Mac은 괄호 안에 적었다.

## 1. 설치 (처음 한 번)

| 프로그램 | 받는 곳 | 비고 |
|---|---|---|
| Git | git-scm.com | Windows는 Git Bash가 같이 깔린다 |
| Godot 4.4.1 (Standard, .NET 아님) | godotengine.org → Download → Archive → 4.4.1 | 압축만 풀면 실행된다. `Godot_v4.4.1-stable_win64.exe`와 `..._console.exe` 두 개가 나온다 |
| Claude 데스크톱 앱 | claude.ai/download | Code 탭에서 내 PC 폴더로 작업한다. 터미널을 좋아하면 Claude Code CLI도 된다 |
| Python 3 (선택) | python.org | 그림 배경 지우기, 시트 자르기 도구용. 설치 후 `pip install numpy scipy pillow` |
| Google Drive 데스크톱 (선택) | google.com/drive/download | 백업 폴더를 자동으로 드라이브에 올려 준다 |

## 2. 코드 받기

1. 작업 폴더를 만든다. 예: `D:\games` (Mac: `~/games`)
2. 아래 둘 중 하나를 받아 작업 폴더에 둔다
   - **전체 백업 하나**: `oneului-bada-full-<날짜>.bundle` (Claude 대화에서 받은 파일)
   - 또는 드라이브 `오늘의바다_백업`의 `oneului-bada-20261109-0615.bundle` + 가장 최근 `oneului-bada-inc-...bundle`
3. Git Bash(Mac은 터미널)를 열고

```bash
cd /d/games
```

전체 백업 하나를 받았다면

```bash
git clone oneului-bada-full-20261109.bundle oneului-bada
```

기본 + 추가분 두 개를 받았다면

```bash
git clone oneului-bada-20261109-0615.bundle oneului-bada
```

```bash
cd oneului-bada && git pull ../oneului-bada-inc-8586b84-to-HEAD.bundle main
```

4. 확인

```bash
git log --oneline -3
```

## 3. 참조 그림 넣기 (git에 넣지 않는 원본)

드라이브 `오늘의바다_백업/ref` 폴더를 통째로 내려받아 `oneului-bada/docs/ref/` 안에 풀어 둔다. `ref/sheets` 폴더도 `docs/ref/sheets/`로. 게임 실행에는 필요 없고, 그림 프롬프트에 첨부할 참조 그림과 물고기 시트 자르기에 쓴다.

## 4. 실행과 테스트

- 게임 실행: `Godot_v4.4.1-stable_win64.exe` 실행 → Import → `oneului-bada/project.godot` 선택 → 열리면 F5
- 처음 열면 리소스 가져오기가 자동으로 돈다
- 테스트 (Git Bash, Godot 폴더 경로는 자기 PC에 맞게)

```bash
"/d/tools/godot/Godot_v4.4.1-stable_win64_console.exe" --headless --path . --script res://tests/run_tests.gd
```

`결과: 171 통과, 0 실패`가 나오면 정상이다.

- 웹 빌드가 필요하면 에디터 메뉴 Editor → Manage Export Templates에서 4.4.1 템플릿을 받은 뒤 Project → Export → Web

## 5. Claude로 이어서 작업

1. Claude 데스크톱 앱 → Code 탭 → 폴더 선택에서 `oneului-bada` 폴더를 연다
2. `docs/HANDOFF.md`의 코드 블록을 복사해 첫 메시지로 붙여 넣는다

## 6. 백업 (GitHub 없이)

- git은 로컬 커밋만 한다 (`git remote add`, `git push` 금지, GitHub 계정 문제가 풀릴 때까지)
- 주 1회 이상 Git Bash에서

```bash
./tools/backup.sh
```

`build/backup/`에 bundle과 zip이 생긴다. 이 파일을 드라이브 `오늘의바다_백업`에 올린다. Google Drive 데스크톱을 쓰면 그 폴더에 복사만 하면 된다.

## 7. APK (이전 게임 바다 한 접시)

드라이브 `오늘의바다_백업/hanjeopsi-269.apk`를 브라우저로 내려받아 **레포 바깥** 폴더에 둔다. 예: `D:\games\hanjeopsi-269.apk`. 직접 만든 게임이라 안의 그림, 데이터, 코드를 가져와도 된다. 284MB라 git에는 절대 넣지 않는다.
