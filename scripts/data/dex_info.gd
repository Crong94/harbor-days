class_name DexInfo
extends RefCounted
## 도감 자세히 보기의 낚는 요령 줄들 (FishDB 숫자를 사람 말로 바꾼다). 헤드리스로 시험한다.


## [이름, 내용] 줄들: 사는 곳, 잘 무는 때, 좋아하는 날씨, 좋아하는 미끼, 힘, 버릇
static func facts(id: String) -> Array:
	var f := FishDB.get_fish(id)
	if f.is_empty():
		return []
	var z: Array = f.zone
	var where := "중간"
	if z[0] >= z[1] and z[0] >= z[2]:
		where = "발밑 (방파제 바로 앞)"
	elif z[2] >= z[1]:
		where = "먼 물"
	var night: float = f.night
	var when := "아무 때나"
	if night >= 0.4:
		when = "어두운 새벽과 밤"
	elif night <= -0.3:
		when = "밝은 낮"
	var weather_names: Array = []
	for w in f.weather:
		if float(f.weather[w]) > 1.0:
			weather_names.append(SeaDay.WEATHER[w].name)
	var baits: Array = []
	for b in BaitDB.ORDER:
		if id in BaitDB.bait(b).likes:
			baits.append(BaitDB.bait(b).name)
	var power := clampi(int(round(float(f.strength) * 5.0)), 1, 5)
	var out := [
		["사는 곳", where],
		["잘 무는 때", when],
		["제철", season_text(FishDB.season_months(id))],
		["좋아하는 날씨", ", ".join(PackedStringArray(weather_names)) if not weather_names.is_empty() else "가리지 않아요"],
		["좋아하는 미끼", ", ".join(PackedStringArray(baits)) if not baits.is_empty() else "크릴로도 충분해요"],
		["힘", "●".repeat(power) + "○".repeat(5 - power)],
	]
	var habit := FishDB.habit_text(id)
	if not habit.is_empty():
		out.append(["버릇", habit])
	return out


## 제철 달들을 이어진 구간으로. 예: [1, 2, 3, 11, 12] → "11월~3월"
static func season_text(months: Array) -> String:
	if months.is_empty() or months.size() >= 12:
		return "사계절"
	# 철이 시작하는 달: 앞 달이 철이 아닌 달
	var parts: Array = []
	for m in months:
		var prev: int = 12 if int(m) == 1 else int(m) - 1
		if prev in months:
			continue
		var end: int = m
		while true:
			var nx: int = 1 if end == 12 else end + 1
			if nx in months and nx != m:
				end = nx
			else:
				break
		parts.append("%d월" % m if end == m else "%d월~%d월" % [m, end])
	return ", ".join(PackedStringArray(parts))
