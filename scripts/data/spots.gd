class_name Spots
extends RefCounted
## 낚시터 (2026-11-18). 북쪽 방파제와 검은여 갯바위.
##
## 검은여 갯바위 (기획서: 물때를 알아야 들어가는 중급 낚시터, 만수 개인 퀘스트 〈묶어둔 배〉의 보상 "물때 읽기, 갯바위 출입"):
## - 방파제에서 감성돔을 한 번 잡으면(flags caught_gamseongdom) 만수가 데려가 준다(Story mansu_rocks → flags learned_tide)
## - 물이 빠질 때만 들어간다. 간조는 하루 두 번(TIDE_CYCLE 간격)이고 날마다 TIDE_SHIFT분씩 늦어진다.
##   간조 앞뒤 LOW_SPAN분 동안 열린다. 그 안에서도 낚시 시간대(DayFlow.FISHING_SLOTS)여야 한다
## - 바위 고기(우럭, 쏨뱅이, 노래미)와 감성돔이 잘 나오고 조금 더 크다. 방파제 단골(망상어, 학공치)은 드물다
## 장면이 아닌 규칙만 담아 헤드리스로 시험한다.

const SPOTS := {
	"breakwater": {
		"name": "북쪽 방파제", "fish": {}, "size_bonus": 0.0,
		"intro": "북쪽 방파제. 빨간 등대 아래 늘 앉던 자리.",
		"bg_prefix": "bg_fishing_",
	},
	"rocks": {
		"name": "검은여 갯바위", "size_bonus": 0.15,
		"fish": {"ureok": 2.6, "ssombaengi": 1.8, "noraemi": 1.5, "gamseongdom": 4.0, "bolak": 0.8, "mangsang": 0.35, "hakgongchi": 0.3, "nongeo": 1.6},
		"intro": "검은여 갯바위. 물이 빠진 틈에 드러난 검은 바위 끝.",
		"bg_prefix": "bg_fishing_rocks_", # 그림 요청 중 (밤, 새벽, 아침, 저녁 _v). 없으면 방파제 그림
		# 해: 산 없이 탁 트인 수평선(그림 세로 0.344)의 해돋이 빛 자리(가로 0.515)에서 떠오른다. 그림이 있을 때만
		"sun_low": Vector2(0.515, 0.36), "sun_clip": 0.344,
	},
}

## 첫날 첫 간조 시각 (분). 간조 사이 간격, 날마다 늦어지는 분, 간조 앞뒤로 열리는 분
const FIRST_LOW := 3 * 60
const TIDE_CYCLE := 745 # 12시간 25분
const TIDE_SHIFT := 50
const LOW_SPAN := 90


static func get_spot(id: String) -> Dictionary:
	return SPOTS.get(id, SPOTS.breakwater)


## 시각별 배경 그림표 (SeaBackdrop.FISHING_SCHEDULE의 이름 앞부분만 바꾼다). 그 낚시터 그림이 하나라도 없으면 방파제 그림표
static func schedule(spot: String, base: Array) -> Array:
	var prefix: String = get_spot(spot).get("bg_prefix", "bg_fishing_")
	if prefix == "bg_fishing_":
		return base
	var out := []
	for e in base:
		var id: String = String(e[1]).replace("bg_fishing_", prefix)
		if not ArtSlot.has_art(id):
			return base
		out.append([e[0], id])
	return out


## 해가 떠오르는 자리와 수평선 자르기 [sun_low, sun_clip]. 그 낚시터 그림을 쓰지 않으면(schedule이 방파제 그림표) 방파제 값
static func sun_of(spot: String, base: Array, sched: Array) -> Array:
	var sp := get_spot(spot)
	if sched == base or not sp.has("sun_low"):
		return [SeaBackdrop.SUN_LOW, -1.0]
	return [sp.sun_low, float(sp.sun_clip)]


## 지도 장소 id → 낚시터 id. 낚시터가 아니면 방파제
static func of_location(loc: String) -> String:
	return loc if SPOTS.has(loc) else "breakwater"


## 이 낚시터에서 그 어종이 나오는 배율
static func fish_mult(spot: String, fish_id: String) -> float:
	return float(get_spot(spot).fish.get(fish_id, 1.0))


## 그날 간조 시각들 (0~24시 안, 분)
static func low_tides(day: int) -> Array:
	var first := (FIRST_LOW + (day - 1) * TIDE_SHIFT) % TIDE_CYCLE
	var out := []
	var t := first
	while t < 24 * 60:
		out.append(t)
		t += TIDE_CYCLE
	return out


## 그날 갯바위에 들어갈 수 있는 때 [[시작, 끝]...] (0~24시로 자름)
static func rocks_windows(day: int) -> Array:
	var out := []
	for low in low_tides(day):
		out.append([maxi(0, int(low) - LOW_SPAN), mini(24 * 60, int(low) + LOW_SPAN)])
	return out


## 이 시각에 물이 빠져 있는지. 빠져 있으면 물이 다시 들어오는 시각, 아니면 -1
static func rocks_until(day: int, minutes: int) -> int:
	for w in rocks_windows(day):
		if minutes >= int(w[0]) and minutes < int(w[1]):
			return int(w[1])
	return -1


## 갯바위에서 지금 낚시할 수 있는지 (물이 빠졌고 낚시 시간대)
static func can_fish_rocks(day: int, minutes: int, day_fished := false) -> bool:
	return rocks_until(day, minutes) >= 0 and DayFlow.can_fish(minutes, day_fished)


## 갯바위 낚시가 끝나는 시각 (물이 들어오거나 시간대가 끝나는 것 중 먼저)
static func rocks_end(day: int, minutes: int) -> int:
	var until := rocks_until(day, minutes)
	var slot_end := DayFlow.fishing_end(minutes)
	return mini(until, slot_end) if until >= 0 else slot_end


## 오늘 갯바위 낚시를 할 수 있는 때 (물 빠진 때와 낚시 시간대가 겹치는 곳) [[시작, 끝]...]
static func rocks_fishing_times(day: int) -> Array:
	var out := []
	for w in rocks_windows(day):
		for s in DayFlow.FISHING_SLOTS:
			var a := maxi(int(w[0]), int(s[2]))
			var b := mini(int(w[1]), int(s[3]))
			if b - a >= 20:
				out.append([a, b])
	out.sort_custom(func(x, y): return x[0] < y[0])
	return out


## "오전 06:10~07:40" 꼴로 이어 쓴다. 없으면 빈 문자열
static func times_text(times: Array) -> String:
	var parts := PackedStringArray()
	for t in times:
		parts.append("%s~%s" % [Bus.clock(int(t[0])), Bus.clock(int(t[1]))])
	return ", ".join(parts)
