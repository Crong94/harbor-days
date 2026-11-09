class_name Haptics
extends RefCounted
## 진동은 모두 여기서 낸다. 낚시 손맛(입질, 챔질, 줄다리기, 끊김, 낚아 올림)에 쓴다.
##
## 휴대폰(안드로이드, iOS): Input.vibrate_handheld(ms, 세기). 안드로이드는 export_presets.cfg의 permissions/vibrate가 켜져 있어야 한다
##   세기는 안드로이드 8 이상에서만 먹는다. iOS는 세기를 무시한다
## 웹: navigator.vibrate를 JavaScriptBridge로 직접 부른다. 쉼을 섞은 패턴을 한 번에 넘길 수 있고
##   진동을 지원하지 않는 브라우저(iOS 사파리 등)에서는 조용히 넘어간다
##   (Godot 웹의 vibrate_handheld도 navigator.vibrate를 쓰지만 지원하지 않는 브라우저에서 매번 콘솔에 글을 남긴다)
## PC: 아무 일도 하지 않는다
## 설정에서 진동을 끄면(GameState.vibration_on, 메뉴 설정 탭) 울리지 않는다.

## 이름 → [세기 0~1, 울림ms, 쉼ms, 울림ms, ...]
## 약한 것부터: 누름 < 톡톡 < 당김 < 입질 < 챔질 < PERFECT < 낚아 올림 < 끊김
const PATTERNS := {
	"tap": [0.2, 10], # 누르는 순간 (버튼, 힘 모으기 시작)
	"tick": [0.35, 16], # 힘 게이지가 포인트 구간에 들어감
	"cast": [0.4, 24], # 던짐
	"plop": [0.3, 18], # 찌가 물에 떨어짐
	"nibble": [0.3, 18], # 찌가 톡톡 떨림
	"pull": [0.35, 22], # 줄다리기 중 물고기가 당김 (짧게 반복)
	"exhausted": [0.5, 40], # 물고기가 지침
	"lost": [0.5, 110], # 놓침, 헛챔질, 바늘 빠짐
	"surge": [0.65, 70], # 물고기가 옆으로 차고 나감
	"bite": [0.75, 45, 55, 75], # 찌가 쭉 잠김 (쿵쿵)
	"hook": [0.75, 60], # 챔질 GOOD
	"danger": [0.85, 34], # 줄이 끊어지기 직전 (반복)
	"perfect": [1.0, 90, 40, 60], # 챔질 PERFECT
	"catch": [0.9, 50, 70, 140], # 낚아 올림
	"broke": [1.0, 240], # 줄 끊김
}

const MIN_MS := 8
const MAX_MS := 300


## 패턴 [세기, 울림, 쉼, 울림, ...]. 없는 이름이면 빈 배열
static func pattern(kind: String) -> Array:
	return PATTERNS.get(kind, [])


## 세기 0~1
static func amplitude(kind: String) -> float:
	var p := pattern(kind)
	return float(p[0]) if not p.is_empty() else 0.0


## 울림만 [[시작ms, 길이ms], ...]로 풀어 준다
static func pulses(kind: String) -> Array:
	var p := pattern(kind)
	var out: Array = []
	var t := 0
	for i in range(1, p.size()):
		var ms: int = p[i]
		if i % 2 == 1:
			out.append([t, ms])
		t += ms
	return out


## 울리는 전체 시간 (쉼 포함, ms)
static func total_ms(kind: String) -> int:
	var p := pattern(kind)
	var t := 0
	for i in range(1, p.size()):
		t += int(p[i])
	return t


## 실제로 울릴지 (설정이 켜져 있고 있는 패턴일 때)
static func should_play(kind: String, enabled: bool) -> bool:
	return enabled and PATTERNS.has(kind)


## 설정에서 진동이 켜져 있는지. 오토로드(GameState)는 테스트 스크립트에서 없으므로 이름으로 찾는다
static func enabled() -> bool:
	var tree := Engine.get_main_loop() as SceneTree
	var gs: Node = tree.root.get_node_or_null("GameState") if tree and tree.root else null
	return gs == null or bool(gs.get("vibration_on"))


## 진동을 한 번 낸다.
static func play(kind: String) -> void:
	if not should_play(kind, enabled()):
		return
	var p := pattern(kind)
	if OS.has_feature("web"):
		var ms := PackedStringArray()
		for i in range(1, p.size()):
			ms.append(str(p[i]))
		JavaScriptBridge.eval("if (navigator.vibrate) { navigator.vibrate([%s]); }" % ",".join(ms), true)
		return
	if not (OS.has_feature("android") or OS.has_feature("ios")):
		return
	var amp := amplitude(kind)
	var tree := Engine.get_main_loop() as SceneTree
	for pulse in pulses(kind):
		var start: int = pulse[0]
		var dur: int = pulse[1]
		if start == 0 or tree == null:
			Input.vibrate_handheld(dur, amp)
		else:
			tree.create_timer(start / 1000.0).timeout.connect(func(): Input.vibrate_handheld(dur, amp))
