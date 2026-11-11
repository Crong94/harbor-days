class_name Walkers
extends RefCounted
## 마을 지도 위를 걷는 주민 (2026-11-11 사용자 선택: 지도 위 주민 걷기).
## 그림: assets/art/sd_guest/<id>_walk.png 한 줄 8칸 (1, 2 앞 / 3, 4 뒤 / 5~8 오른쪽 옆 한 걸음. 왼쪽은 좌우 뒤집기)
## 길: 지도 그림 비율 좌표 꺾은선. 끝까지 가면 잠깐 서 있다가 되돌아온다.
## 나오는 시간: hours [시작 분, 끝 분). 누르면 lines 중 하나를 말한다 (지도 아래 알림).
## 길은 지도 그림(map_village.png)의 배 대는 둑(y 0.36), 가게 앞 큰길(y 0.445), 항구 위쪽 둑길(y 0.265)을 따른다.

const SPEED := 0.012 # 걷는 빠르기 (지도 너비 비율 / 초)
const PAUSE := 1.6 # 길 끝에서 서 있는 시간 (초)
const STEP_FPS := 6.0 # 걸음 그림 넘기는 빠르기

const LIST := [
	{"id": "junho", "name": "준호", "hours": [8 * 60, 19 * 60],
		"path": [Vector2(0.44, 0.364), Vector2(0.52, 0.364)],
		"lines": ["형님, 오늘 물때 좋대요! 찌 하나 더 챙겨 가요.", "새 릴 들어왔어요. 구경만 해도 돼요.", "방파제 끝 테트라포드는 미끄러우니까 조심해요."]},
	{"id": "gyeongja", "name": "경자", "hours": [7 * 60, 20 * 60],
		"path": [Vector2(0.555, 0.365), Vector2(0.62, 0.365)],
		"lines": ["모이 떨어지면 말만 해. 바로 갖다줄게.", "오늘은 배추가 싱싱하네.", "장부는 내가 봐 줄 수도 있어. 공짜는 아니고."]},
	{"id": "bokja", "name": "복자", "hours": [9 * 60, 21 * 60],
		"path": [Vector2(0.38, 0.447), Vector2(0.45, 0.447), Vector2(0.52, 0.445)],
		"lines": ["어머 {player|아/야}! 밥은 먹고 다니니?", "우리 집 반찬 남으면 갖다줄게.", "손님 많았다며? 소문 다 났어."]},
	{"id": "mansu", "name": "만수", "hours": [5 * 60, 12 * 60],
		"path": [Vector2(0.40, 0.266), Vector2(0.50, 0.264), Vector2(0.60, 0.262)],
		"lines": ["바다는 서두르는 사람한테 고기 안 준다.", "물 들어올 때 노 젓는 거여.", "흠. 오늘은 바람이 동쪽이구먼."]},
	{"id": "sundeok", "name": "순덕 할머니", "hours": [8 * 60, 18 * 60],
		"path": [Vector2(0.27, 0.448), Vector2(0.34, 0.447)],
		"lines": ["아이고 우리 {player}. 오늘도 고생 많았제.", "천천히 해. 바다는 안 도망가.", "영감도 이맘때면 저 둑길을 걸었어."]},
]


## 지금 시각에 나와 있는 주민들
static func active(minutes: int) -> Array:
	return LIST.filter(func(w): return minutes >= int(w.hours[0]) and minutes < int(w.hours[1]))


static func get_walker(id: String) -> Dictionary:
	for w in LIST:
		if w.id == id:
			return w
	return {}


static func path_length(path: Array) -> float:
	var l := 0.0
	for i in range(1, path.size()):
		l += (path[i] as Vector2).distance_to(path[i - 1])
	return l


## 꺾은선 위 거리 d 지점과 그 구간 방향
static func point_on(path: Array, d: float) -> Array:
	for i in range(1, path.size()):
		var a: Vector2 = path[i - 1]
		var b: Vector2 = path[i]
		var seg := a.distance_to(b)
		if d <= seg or i == path.size() - 1:
			return [a.lerp(b, clampf(d / maxf(seg, 0.0001), 0.0, 1.0)), (b - a).normalized()]
		d -= seg
	return [path[0], Vector2.RIGHT]


## t초 때의 자리: {pos, dir(걷는 방향, 서 있으면 ZERO), phase(0~1 왕복 위치)}. offset으로 주민마다 출발을 엇갈린다
static func pose(path: Array, t: float, offset := 0.0) -> Dictionary:
	var l := path_length(path)
	var walk := l / SPEED
	var cycle := 2.0 * (walk + PAUSE)
	var c := fposmod(t + offset * cycle, cycle)
	if c < walk:
		var p: Array = point_on(path, c * SPEED)
		return {"pos": p[0], "dir": p[1]}
	c -= walk
	if c < PAUSE:
		return {"pos": path[path.size() - 1], "dir": Vector2.ZERO}
	c -= PAUSE
	if c < walk:
		var p2: Array = point_on(path, l - c * SPEED)
		return {"pos": p2[0], "dir": -(p2[1] as Vector2)}
	return {"pos": path[0], "dir": Vector2.ZERO}


## 방향과 시간 → 걷기 시트 칸 (0부터)과 좌우 뒤집기. 서 있으면 앞모습 첫 칸
static func frame(dir: Vector2, t: float) -> Array:
	var step := int(t * STEP_FPS)
	if dir == Vector2.ZERO:
		return [0, false]
	if absf(dir.x) >= absf(dir.y):
		return [4 + step % 4, dir.x < 0.0]
	if dir.y < 0.0:
		return [2 + step % 2, false]
	return [step % 2, false]
