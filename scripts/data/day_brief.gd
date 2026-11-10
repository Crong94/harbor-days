class_name DayBrief
extends RefCounted
## 하루 서랍 내용 (여울 "N일차 오늘" 서랍을 참고해 다시 짬, 2026-11-10).
## 장면이 아닌 규칙만 담아 헤드리스로 시험한다. 화면은 DayDrawer가 그린다.
##
## 여울에서 고친 점
## - 같은 일이 여러 칸(오늘 저녁 VIP, 예약, 아침 소식)에 겹쳐 나오던 것을 한 번만 보여 준다
## - 긴 소식 문장 대신 맨 위 숫자 세 칸(어제 번 돈, 통장, 다음 상환)으로 먼저 보여 준다
## - "지금 할 일"은 지금 시각에 맞춰 할 수 있는 것만, 하는 순서대로. 줄을 누르면 지도에서 그 장소를 고른다
## - 남은 시간과 마감은 오른쪽에 짧게 (예: "~11:00", "D-3")
##
## gs는 GameState(또는 같은 변수를 가진 것). 돌려주는 값:
## {"title", "stats": [{"name", "value", "tone"}], "sections": [{"name", "rows": [{"text", "state", "tone", "target"}]}]}
## tone: "gold" 챙길 것, "good" 잘 됨, "bad" 나쁨, "info" 그냥 정보. target: 지도 장소 id (없으면 "")


static func build(gs: Object) -> Dictionary:
	var day: int = gs.day
	var m: int = gs.time_minutes
	return {
		"title": "%s 오늘" % Calendar.text(day),
		"stats": _stats(gs),
		"sections": [
			{"name": "지금 할 일", "rows": _todo(gs, day, m)},
			{"name": "오늘 주문", "rows": _order(gs, day)},
			{"name": "오늘의 바다", "rows": _sea(day, m)},
			{"name": "아침 소식", "rows": _news(gs)},
		].filter(func(s): return not s.rows.is_empty()),
	}


## 맨 위 숫자 세 칸
static func _stats(gs: Object) -> Array:
	var out: Array = []
	if gs.day > 1:
		var net: int = gs.yesterday_sales - gs.yesterday_spent
		out.append({"name": "어제 번 돈", "value": _won(net), "tone": "good" if net >= 0 else "bad"})
	out.append({"name": "통장", "value": _won(gs.money), "tone": "info"})
	if gs.debt > 0:
		var due: int = mini(gs.monthly_repayment + gs.arrears, gs.debt)
		var left := Loan.days_left(gs.day)
		var short: bool = gs.money < due
		out.append({"name": "상환 D-%d" % left, "value": _won(due), "tone": "bad" if (short and left <= Loan.WARN_DAYS) or gs.arrears > 0 else "info"})
	return out


## 지금 할 수 있는 일, 하는 순서대로
static func _todo(gs: Object, day: int, m: int) -> Array:
	var rows: Array = []
	var slot := DayFlow.fishing_slot(m)
	if not slot.is_empty() and slot.id != "night":
		rows.append({"text": "%s · 방파제" % slot.name, "state": "~%s" % _hm(slot.end), "tone": "gold", "target": "breakwater"})
	elif m < DayFlow.FISHING_SLOTS[0][2]:
		rows.append({"text": "새벽 낚시 · 방파제", "state": "5:00~", "tone": "info", "target": "breakwater"})
	var spoil: int = gs.spoiling_tonight().size()
	if not gs.inventory.is_empty() and Market.is_open(m):
		var t := "수산시장에서 비싼 고기 팔기"
		if spoil > 0:
			t = "오늘 밤 상할 생선 %d마리 팔기" % spoil
		rows.append({"text": t, "state": "~17:00", "tone": "gold" if spoil > 0 else "info", "target": "market"})
	var ready := 0
	for slot_g in gs.garden:
		if CropDB.stage(slot_g, day) == CropDB.READY:
			ready += 1
	if ready > 0:
		rows.append({"text": "텃밭에서 %d줄 거두기" % ready, "state": "지금", "tone": "gold", "target": "garden"})
	if gs.has_flag("first_guest_done") and not gs.opened_today and m < DayFlow.SHOP_CLOSE:
		var n: int = gs.inventory.size()
		var t2 := "저녁 장사 · 아이스박스 %d마리" % n if n > 0 else "저녁 장사 · 팔 생선이 없어요"
		rows.append({"text": t2, "state": "18:00~", "tone": "gold" if n > 0 else "bad", "target": "shop"})
	if m < DayFlow.FISHING_SLOTS[2][3] and (gs.opened_today or m >= DayFlow.SHOP_CLOSE):
		rows.append({"text": "밤 낚시 (내일은 늦잠)", "state": "21:00~", "tone": "info", "target": "breakwater"})
	if gs.opened_today or m >= DayFlow.SHOP_CLOSE:
		rows.append({"text": "집에 가서 자기", "state": "", "tone": "info", "target": "home"})
	return rows


## 오늘 주문 한 줄
static func _order(gs: Object, day: int) -> Array:
	var o := Orders.of(day)
	if o.is_empty():
		return []
	var who := Orders.call_name(o.customer)
	var text := "%s · %s %d마리" % [who, Orders.goal_text(o), o.count]
	if gs.order_done:
		return [{"text": text, "state": "보냄", "tone": "good", "target": ""}]
	return [{"text": text + " · " + _won(o.reward), "state": "%d/%d" % [gs.order_filled, o.count], "tone": "gold", "target": "breakwater"}]


## 날씨와 물때, 오늘 잘 무는 고기
static func _sea(day: int, m: int) -> Array:
	var info := SeaDay.of(day)
	var best: Array = SeaDay.best_fish(info, FishingLogic.brightness_at(m), 2)
	var names := ", ".join(PackedStringArray(best.map(func(id): return FishDB.get_fish(id).name)))
	return [
		{"text": "%s · %s%s" % [info.weather_name, info.tide, " · 물때 좋음" if info.tide_good else ""], "state": "", "tone": "good" if info.tide_good else "info", "target": ""},
		{"text": "잘 무는 고기: %s" % names, "state": "", "tone": "info", "target": ""},
	]


static func _news(gs: Object) -> Array:
	var rows: Array = []
	for t in gs.news_today:
		var bad: bool = t.contains("못 갚") or t.contains("상해서")
		rows.append({"text": t, "state": "", "tone": "bad" if bad else "info", "target": ""})
	return rows


static func _hm(minutes: int) -> String:
	return "%d:%02d" % [minutes / 60, minutes % 60]


static func _won(n: int) -> String:
	var s := str(absi(n))
	var out := ""
	while s.length() > 3:
		out = "," + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return ("-" if n < 0 else "") + s + out + "원"
