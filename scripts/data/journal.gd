class_name Journal
extends RefCounted
## 장부와 기록 (기획서 10.4). 하루가 끝날 때(GameState.end_day) 그날을 한 장으로 남긴다.
## 장면이 아닌 규칙만 담아 헤드리스로 시험한다. 화면은 수첩(GameMenu)의 일지 탭.
##
## 한 장: {"day", "weather", "tide", "caught": {어종 id: 마리}, "sales", "spent", "line"}
## 오늘의 한 줄: 그날 장면들이 남긴 메모(GameState.note) 중 가장 중요한 것. 메모가 없으면 숫자로 짓는다

const MAX_PAGES := 400


## 오늘 하루를 한 장으로 만든다 (end_day에서 장부를 비우기 전에 부른다)
static func page(gs: Object) -> Dictionary:
	var sea := SeaDay.of(gs.day)
	var caught := {}
	for e in gs.caught_today:
		caught[e.id] = int(caught.get(e.id, 0)) + 1
	return {
		"day": gs.day,
		"weather": sea.weather_name,
		"tide": sea.tide,
		"caught": caught,
		"sales": gs.sales_today,
		"spent": gs.spent_today,
		"line": line(gs.notes_today, gs.caught_today.size(), gs.sales_today, gs.spent_today),
	}


## 오늘의 한 줄. notes: [{"p": 중요도, "text"}]
static func line(notes: Array, caught: int, sales: int, spent: int) -> String:
	var best := {}
	for n in notes:
		if best.is_empty() or int(n.p) > int(best.p):
			best = n
	if not best.is_empty():
		return best.text
	if caught == 0 and sales == 0:
		return "한 마리도 못 잡고 장사도 못 했다. 내일은 물때를 보고 나가자."
	if caught == 0:
		return "오늘은 낚싯대를 쉬었다. 그래도 가게 불은 켰다."
	if sales == 0:
		return "%d마리 잡았다. 장사는 쉬었다." % caught
	var net := sales - spent
	return ("%d마리 잡고 %s 남겼다." if net >= 0 else "%d마리 잡았지만 %s 손해를 봤다.") % [caught, _won(absi(net))]


## 잡은 고기 한 줄. 예: "볼락 4, 망상어 2"
static func caught_text(caught: Dictionary) -> String:
	if caught.is_empty():
		return "없음"
	var parts: Array = []
	for id in FishDB.FISH:
		if caught.has(id):
			parts.append("%s %d" % [FishDB.get_fish(id).name, caught[id]])
	return ", ".join(PackedStringArray(parts))


static func _won(n: int) -> String:
	var s := str(n)
	var out := ""
	while s.length() > 3:
		out = "," + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return s + out + "원"
