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
2. Git Bash(Mac은 터미널)에서

```bash
cd /d/games
```

```bash
git clone https://github.com/crong94/oneului-bada.git
```

3. 이 저장소에서만 개인 메일로 커밋하도록 설정한다 (회사 PC는 전역 설정이 회사 메일이라 꼭 한다)

```bash
cd oneului-bada && git config user.name "Songok Kim" && git config user.email "thddhr14@gmail.com"
```

4. 확인

```bash
git log --oneline -3
```

처음 push할 때 GitHub 로그인 창이 뜨면 crong94 계정으로 로그인한다.

## 3. 참조 그림 넣기 (git에 넣지 않는 원본)

드라이브 `오늘의바다_백업/ref` 폴더를 통째로 내려받아 `oneului-bada/docs/ref/` 안에 풀어 둔다. `ref/sheets` 폴더도 `docs/ref/sheets/`로. 게임 실행에는 필요 없고, 그림 프롬프트에 첨부할 참조 그림과 물고기 시트 자르기에 쓴다.

## 4. 실행과 테스트

- 게임 실행: `Godot_v4.4.1-stable_win64.exe` 실행 → Import → `oneului-bada/project.godot` 선택 → 열리면 F5
- 처음 열면 리소스 가져오기가 자동으로 돈다
- 테스트 (Git Bash, Godot 폴더 경로는 자기 PC에 맞게)

```bash
"/d/tools/godot/Godot_v4.4.1-stable_win64_console.exe" --headless --path . --script res://tests/run_tests.gd
```

`결과: 88 통과, 0 실패`가 나오면 정상이다.

- 웹 빌드가 필요하면 에디터 메뉴 Editor → Manage Export Templates에서 4.4.1 템플릿을 받은 뒤 Project → Export → Web

## 5. Claude로 이어서 작업

1. Claude 데스크톱 앱 → Code 탭 → 폴더 선택에서 `oneului-bada` 폴더를 연다
2. `docs/HANDOFF.md`의 코드 블록을 복사해 첫 메시지로 붙여 넣는다

## 6. 매일 작업 흐름 (로컬과 GitHub)

- 시작할 때 `git pull`, 끝나면 커밋하고 `git push`
- 회사 PC에는 Godot를 깔지 않는다. 회사에서 고친 것은 push하면 GitHub Actions가 테스트를 돌린다. 결과는 github.com/crong94/oneului-bada → Actions 탭
- 웹 빌드가 필요하면 Actions 탭 → CI → Run workflow → "웹 빌드도 만들기" 체크. 결과 zip은 7일 보관
- 저장소가 공개라서 개인 정보, 비밀번호, 토큰은 넣지 않는다
- `./tools/backup.sh`(bundle, zip)는 GitHub가 안 될 때만 쓰는 예비 백업이다

## 7. APK (이전 게임 바다 한 접시)

드라이브 `오늘의바다_백업/hanjeopsi-269.apk`를 브라우저로 내려받아 **레포 바깥** 폴더에 둔다. 예: `D:\games\hanjeopsi-269.apk`. 직접 만든 게임이라 안의 그림, 데이터, 코드를 가져와도 된다. 284MB라 git에는 절대 넣지 않는다.
