extends SceneTree
## 두 달 돈 흐름 재기 (사람이 한 달을 직접 해 보기 전에 숫자로 먼저 본다).
## 실행: godot --headless --path . --script res://tools/money_balance.gd
##
## 하루: 낚시(시간대별 실제 초 길이 안에서 던지고 기다리고 싸운다) → 아이스박스 10칸 → 저녁 영업(DiningLogic 그대로)
## → 특별 손님 한 접시(별 2개로 셈) → 알바 일당 → 매달 1일 고정비(Loan).
## 낚시 실력은 fight_balance.gd의 "평범하게 잘하는 사람". 장비는 창고 장비(1단계).
## 시장에는 안 판다 (식당 값이 시장의 2배가 넘어서). 넘치는 생선은 가장 싼 것을 놓아준다 (store_catch와 같다).

const REAL_SEC_PER_GAME_MIN := 1.2 # scenes/fishing/fishing.gd
const CAST_SEC := 2.5 # 누르고 날아가 찌가 서기까지
const HOOK_SEC := 0.6 # 입질부터 챔질까지
const HOOK_OK := 0.85 # 챔질 성공률 (놓치면 다시 던진다)
const DAYS := 62 # 3월 1일 ~ 5월 1일 (4월 1일, 5월 1일 고정비까지)

## 하는 사람 유형: 날마다 어느 시간대를 낚시하는가
const PROFILES := {
	"낮만": ["day"],
	"낮+밤": ["day", "night"],
}

var _fight_rng := 0


## 규칙 비교. price: 보통 손님 접시 값에 더 곱할 배수, special_cap: 특별 손님 한 접시 끝,
## guests: 하루 보통 손님 수 끝 [최소, 최대] (빈 배열이면 지금 규칙), cost: 접시마다 재료비, order: 주문 보상 배수
## 다른 안을 재 보려면 여기에 줄을 더한다. (11-16에 잰 안: 예전 값은 첫 달 300만~450만 원이 남았다)
const VARIANTS := {
	"지금 규칙": {"price": 1.0, "special_cap": DayFlow.SPECIAL_MAX, "guests": [], "cost": DayFlow.DISH_COST, "order": 1.0},
}


func _init() -> void:
	var only_staff := OS.get_cmdline_user_args().has("--staff")
	for vname in VARIANTS:
		print("■ ", vname)
		for pname in PROFILES:
			var staffs: Array = [{}, {"serve": "yeoul"}, {"serve": "yeoul", "kitchen": "sera"}] if only_staff else [{}]
			for staff in staffs:
				_run(pname, PROFILES[pname], staff, VARIANTS[vname])
	quit()


func _run(pname: String, slots: Array, staff: Dictionary, v: Dictionary) -> void:
	var money := 180_000
	var debt := 30_000_000
	var arrears := 0
	var inv: Array = []
	var tot := {"fish": 0, "dine": 0, "special": 0, "order": 0, "wage": 0, "bills": 0, "guests": 0, "missed": 0, "angry": 0, "caught": 0}
	var month_end := []
	for day in range(1, DAYS + 1):
		var r := Loan.settle(day, money, debt, 550_000, arrears)
		if not r.is_empty():
			month_end.append([Calendar.short_text(day - 1), money])
			if r.paid > 0:
				money -= r.paid
				tot.bills += r.paid
			arrears = r.arrears
			debt = r.debt
		if day == DAYS:
			break
		# 상한 것 버리기: 어제 잡은 건 오늘 저녁까지 (GameState.spoiling_tonight)
		inv = inv.filter(func(e): return int(e.day) >= day - 1)
		var sea := SeaDay.of(day)
		var order := Orders.of(day)
		var filled := 0
		for s in slots:
			var caught := _fish_session(day, s, sea)
			tot.caught += caught.size()
			for e in caught:
				if not order.is_empty() and filled < int(order.count) and Orders.matches(order, e.id, e.size):
					filled += 1
					if filled >= int(order.count):
						money += int(order.reward * float(v.order))
						tot.order += int(order.reward * float(v.order))
					continue # 주문 생선은 보낸다
				inv.append(e)
				if inv.size() > 10:
					var low := 0
					for i in inv.size():
						if FishDB.value_of(inv[i].id, inv[i].size) < FishDB.value_of(inv[low].id, inv[low].size):
							low = i
					inv.remove_at(low)
		# 특별 손님: 주문을 낸 사람이 와서 가장 값진 생선 한 마리 (별 2)
		if not order.is_empty() and not inv.is_empty():
			var best := 0
			for i in inv.size():
				if FishDB.value_of(inv[i].id, inv[i].size) > FishDB.value_of(inv[best].id, inv[best].size):
					best = i
			var p := mini(int(v.special_cap), int(DayFlow.special_price(inv[best].id, inv[best].size, 2) * float(v.price))) - int(v.cost)
			money += p
			tot.special += p
			inv.remove_at(best)
		# 보통 손님 영업: 사람 대신 알바 둘이 다 한다고 놓고 돌린다 (사람이 하면 비슷하거나 조금 더 빠르다)
		# 손님 수 끝이 있으면 그 수만큼만 생선을 내놓는다 (나머지는 아이스박스에 남는다)
		var rest: Array = []
		var sub: Array = inv
		if not (v.guests as Array).is_empty():
			var grng := RandomNumberGenerator.new()
			grng.seed = hash("손님끝-%d" % day)
			var cap := grng.randi_range(int(v.guests[0]), int(v.guests[1]))
			var ok := inv.filter(func(e): return not DayFlow.too_pricey(e.id, e.size))
			ok.sort_custom(func(a, b): return FishDB.value_of(a.id, a.size) > FishDB.value_of(b.id, b.size))
			sub = ok.slice(0, cap)
			rest = inv.filter(func(e): return not sub.has(e))
		tot["inv_n"] = int(tot.get("inv_n", 0)) + inv.size()
		tot["inv_pricey"] = int(tot.get("inv_pricey", 0)) + inv.filter(func(e): return DayFlow.too_pricey(e.id, e.size)).size()
		var dd := DiningLogic.new()
		dd.setup(day, [], DayFlow.GUESTS)
		tot["sched"] = int(tot.get("sched", 0)) + dd.schedule.size()
		var d := DiningLogic.new()
		d.helper_serve = true
		d.helper_kitchen = true
		d.setup(day, sub, DayFlow.GUESTS)
		var t := 0.0
		while not d.is_over() and t < 400.0:
			d.update(0.1)
			t += 0.1
		inv = rest + d.inventory
		var dine := int(d.sales * float(v.price)) - d.served.size() * int(v.cost)
		money += dine
		tot.dine += dine
		tot.guests += d.served.size()
		tot.missed += d.missed
		tot.angry += d.angry
		var w := StaffDB.wages(staff)
		money -= w
		tot.wage += w
	var days := DAYS - 1
	print("── %s, 알바 %s" % [pname, ", ".join(PackedStringArray(staff.values())) if not staff.is_empty() else "없음"])
	print("  하루 평균: 잡음 %.1f마리, 손님 %.1f명 받음(못 받음 %.1f, 화남 %.1f)" % [float(tot.caught) / days, float(tot.guests) / days, float(tot.missed) / days, float(tot.angry) / days])
	print("  하루 평균 수입: 영업 %d, 특별 %d, 주문 %d → %d원 / 일당 %d원" % [tot.dine / days, tot.special / days, tot.order / days, (tot.dine + tot.special + tot.order) / days, tot.wage / days])
	print("  저녁 아이스박스 평균 %.1f마리 (그중 보통 손님에게 못 내는 비싼 고기 %.1f), 온 손님 %.1f명" % [float(tot.get("inv_n", 0)) / days, float(tot.get("inv_pricey", 0)) / days, float(tot.get("sched", 0)) / days])
	for m in month_end:
		print("  %s 끝 통장: %s" % [m[0], m[1]])
	print("  두 달 고정비 낸 돈 %d, 밀린 돈 %d, 5월 1일 뒤 통장 %d" % [tot.bills, arrears, money])


## 한 시간대 낚시. 잡은 생선 [{id, size, day}]
func _fish_session(day: int, slot_id: String, sea: Dictionary) -> Array:
	var slot: Array = []
	for s in DayFlow.FISHING_SLOTS:
		if s[0] == slot_id:
			slot = s
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("낚시-%d-%s" % [day, slot_id])
	var real_left := float(mini(slot[3] - slot[2], DayFlow.DAY_SESSION if slot_id == "day" else 9999)) * REAL_SEC_PER_GAME_MIN
	var minute := float(slot[2])
	var out := []
	while real_left > 0.0:
		var b := FishingLogic.brightness_at(minute)
		var wait := rng.randf_range(FishingLogic.WAIT_MIN, FishingLogic.WAIT_MAX) * (1.0 + b * 0.6) / maxf(float(sea.bite), 0.3)
		var spent := CAST_SEC + wait + HOOK_SEC
		if rng.randf() < HOOK_OK:
			var id := FishDB.pick_ctx(rng, {"brightness": b, "depth": rng.randf_range(0.2, 0.8), "weather": sea.weather})
			var f := _fight(id)
			spent += f.t
			if f.ok and spent <= real_left:
				out.append({"id": id, "size": FishDB.roll_size(rng, id), "day": day})
		real_left -= spent
		minute += spent / REAL_SEC_PER_GAME_MIN
	return out


## tools/fight_balance.gd와 같은 사람 흉내 (창고 장비)
func _fight(id: String) -> Dictionary:
	_fight_rng += 1
	var l := FishingLogic.new()
	l.rng.seed = 5000 + _fight_rng
	l.forgiving = false
	l.catch_count = 1
	GearDB.apply(l, "rod_1", "reel_1")
	l.force_first_fish = id
	l.catch_count = 0
	l.state = FishingLogic.State.BITE
	var z := l.perfect_zone()
	l.bite_depth = (z.x + z.y) / 2.0
	l._timer = 1.0
	l.cast_power = 0.6
	l.press()
	l.forgiving = false
	var held := true
	var t := 0.0
	var seen_run := 0.0
	var past: Array = []
	while l.state == FishingLogic.State.REELING and t < 60.0:
		past.append(l.tension)
		var seen: float = past[maxi(0, past.size() - 1 - 21)]
		if seen >= 0.7:
			held = false
		elif seen <= 0.45:
			held = true
		if l.jump_t > 0.0:
			held = true
		seen_run = seen_run + 1.0 / 60.0 if l.run_dir != 0 else 0.0
		l.steer = -l.run_dir if seen_run >= 0.35 else 0.0
		l.update(1.0 / 60.0, held or (l.run_dir != 0 and seen_run >= 0.35))
		t += 1.0 / 60.0
	return {"ok": l.state == FishingLogic.State.CAUGHT, "t": t}
