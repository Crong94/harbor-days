class_name HudText
extends RefCounted
## 헤더와 메뉴에 쓰는 글자 만들기 (순수 함수). 오토로드(GameState, Sound)를 쓰지 않아서 헤드리스 테스트에서 부를 수 있다.


static func date_text(day: int) -> String:
	return "%d일차" % day


## 예: "새벽 05:12", "오전 09:30", "오후 13:05", "저녁 19:00", "밤 22:40"
static func clock_text(minutes: float) -> String:
	var m := int(minutes) % (24 * 60)
	var hr := m / 60
	var period := "새벽" if hr < 6 else ("오전" if hr < 12 else ("오후" if hr < 18 else ("저녁" if hr < 21 else "밤")))
	return "%s %02d:%02d" % [period, hr, m % 60]


## 예: "맑음 · 9물 물때 좋음"
static func sea_text(info: Dictionary) -> String:
	return "%s · %s%s" % [info.weather_name, info.tide, " 물때 좋음" if info.tide_good else ""]


## 아이스박스를 어종별로 묶는다: id → {count, best, value}
static func group_inventory(inv: Array) -> Dictionary:
	var out := {}
	for e in inv:
		var g: Dictionary = out.get(e.id, {"count": 0, "best": 0.0, "value": 0})
		g.count += 1
		g.best = maxf(g.best, e.size)
		g.value += FishDB.value_of(e.id, e.size)
		out[e.id] = g
	return out
