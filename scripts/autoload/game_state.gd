extends Node
## 게임 전체에서 공유하는 상태. 오토로드 이름: GameState

const DEFAULT_PLAYER_NAME := "한바다"
const DEFAULT_SHOP_NAME := "오늘의 식탁"
const PLAYER_NAME_MAX := 6
const SHOP_NAME_MAX := 10

const RANDOM_PLAYER_NAMES := ["하늘", "준", "도윤", "서진", "민호", "태오", "지안", "한결"]
const RANDOM_SHOP_NAMES := ["한 접시", "물빛식당", "갯내음", "등대 밥집", "파도 식탁", "오늘 잡은 집", "바닷가 부엌"]

## 기획서 2.2 금지어 목록. 실제 출시 전에 더 보강한다.
const BANNED_WORDS := ["시발", "씨발", "병신", "개새", "좆", "fuck", "shit"]

var player_name := DEFAULT_PLAYER_NAME
var shop_name := DEFAULT_SHOP_NAME
var pet_name := "고등어"

var money := 180_000
var debt := 30_000_000
var monthly_repayment := 550_000
## 못 갚고 밀린 상환금 (Loan). 다음 상환일에 같이 빠진다
var arrears := 0
## 제때 낸 주가 이어진 수 (Loan 신용 우대)
var pay_streak := 0
## 주방 장비 단계 {KitchenDB id: 단계}
var kitchen := {}
## 경자상회에서 산 선물 {Store.GOODS id: 개수}, 오늘 산 식재료 수
var goods := {}
var store_bought := {}
## 세라와 마지막으로 연구한 날 (Menu.research)
var research_day := 0
## 이번 주 도전 셈 (WeekGoals)
var week := {}
## 연체한 주 수 (지금까지 합)
var missed_payments := 0
var day := 1
## 다음에 지도에 오면 보여 줄 알림 (상환, 상한 생선 등). 보여 주면 비운다
var notices: Array = []
## 오늘 아침 소식 (하루 서랍에서 다시 본다). 알림은 토스트로 사라져도 여기 남는다. 다음 날 아침에 새로 쓴다
var news_today: Array = []
## 어제 장부 (하루 서랍 맨 위 숫자)
var yesterday_sales := 0
var yesterday_spent := 0
## 하루 서랍을 마지막으로 연 날. 오늘 아직 안 열었으면 탭에 빨간 점
var drawer_seen_day := 0
## 장부 일지 (Journal). 하루가 끝날 때마다 한 장씩
var journal: Array = []
## 오늘 있었던 일 메모 [{"p": 중요도, "text"}]. 그중 가장 중요한 것이 일지의 "오늘의 한 줄"이 된다
var notes_today: Array = []

## 낚시 기록. 항목 형식: {"id": "bolak", "size": 18.3, "day": 잡은 날}
var caught_today: Array = []
var inventory: Array = []
## 아이스박스에 넣을 수 있는 마리 수. 꽉 차면 가장 싼 고기를 놓아준다
var icebox_size := 10
## 낚시방 도구 (KitDB). cooler: 쿨러 단계(0부터, icebox_size를 정한다), kits: {도구 id: 단계}, trap_fish: 통발에 든 채 기다리는 고기
var cooler := 0
var kits := {}
var trap_fish: Array = []
## 갯벌에서 캔 것 {Flat id: 개수}
var seafood := {}
## 친밀도 {이름: 점수}, 마지막으로 선물한 날 {이름: 날} (Friends)
var friendship := {}
var gift_day := {}
## 앱 만들기 {앱 id: 마친 단계}, 마지막으로 한 날 {앱 id: 날} (AppWork)
var apps := {}
var app_day := {}
## 잡은 날을 포함해 생선이 버티는 날 수. 잡은 다음 날 저녁 장사까지 쓸 수 있다
const FRESH_DAYS := 2
## 어종 도감: 어종 id → 가장 큰 기록(cm)
var dex := {}

## 낚시 장비 (GearDB 참고)
var equipped_rod := GearDB.DEFAULT_ROD
var equipped_reel := GearDB.DEFAULT_REEL
var owned_rods: Array = [GearDB.DEFAULT_ROD]
var owned_reels: Array = [GearDB.DEFAULT_REEL]
## 미끼: id → 남은 수 (크릴은 -1, 끝이 없다)
## 활어 수조 (Tank). tank_level 0이면 없음. tank: 살려 둔 고기 (상하지 않는다)
var tank_level := 0
var tank: Array = []

## 미끼 남은 수. 크릴도 사서 쓴다 (11-24). 처음엔 창고에서 찾은 크릴 START_KRILL개
const START_KRILL := 30
var baits := {BaitDB.DEFAULT: START_KRILL}
var equipped_bait := BaitDB.DEFAULT

## 오늘의 주문 (Orders.of(day)). 잡은 수와 받았는지
var order_filled := 0
var order_done := false
## 가장 길게 이은 연속 PERFECT
var best_streak := 0

## 하루 시간 (자정부터 몇 분째인지). 07:00 = 420
var time_minutes := 7 * 60
## 지금 있는 장소 id (Locations.LIST 참고)
var current_location := "shop"
## 스토리 진행 표시. 장소 해금 조건 등에 쓴다. 예: flags["met_mansu"] = true
var flags := {}


## 하루 장부. 밤에 정리하고 비운다.
var sales_today := 0
var spent_today := 0

## 하루 흐름 (DayFlow). 오늘 가게를 열었는지, 밤 낚시를 했는지(했으면 내일 늦잠), 식당 평판
var opened_today := false
var night_fished := false
var day_fished := false # 오늘 낮 낚시를 했나 (하루 한 번, DayFlow)
var reputation := 0
## 식당 가구와 장식 (ShopDecor). 놓은 것 {슬롯 id: 물건 id}, 산 것 [물건 id]
var shop_decor := {}
## 저녁 영업 메뉴판 {"dishes": {어종: 요리}} (ServicePlan)
var service_plan := {}
var owned_decor: Array = []
## 뽑은 알바 {역할: 알바 id} (StaffDB). 한 번 뽑으면 그만두게 할 때까지 매일 나온다
var staff := {}

## 우리 텃밭 (CropDB). 칸 네 개, 칸마다 {} 또는 {"crop": id, "day": 심은 날}
var garden: Array = CropDB.new_garden()
## 수확해 둔 채소. 작물 id → 개수
var produce := {}

## 닭장과 순덕 할머니 부탁 (Coop)
var hens := 0
var chicken_feed := 0 # 모이를 줄 수 있는 남은 횟수
var hens_fed_today := false
var coop_eggs := 0 # 닭장에 쌓여 아직 줍지 않은 달걀
var sundeok_quest := 0 # 들어준 부탁 수
var sundeok_quest_day := 0 # 마지막으로 부탁을 들어준 날

## 설정 (메뉴 설정 탭). 바꾸면 SETTINGS_PATH에 저장하고 다음에 켤 때 불러온다
const SETTINGS_PATH := "user://settings.cfg"
## 진동 (Haptics가 본다)
var vibration_on := true
## 화면 흔들림 (낚시 입질, 챔질, 줄다리기 때 화면이 흔들리고 살짝 확대된다)
var screen_shake_on := true


func _ready() -> void:
	# 게임 전체 기본 모양 (글꼴, 스크롤바, 툴팁)
	get_tree().root.theme = UiKit.build_theme()
	load_settings()


func set_vibration(on: bool) -> void:
	vibration_on = on
	save_settings()


func set_screen_shake(on: bool) -> void:
	screen_shake_on = on
	save_settings()


func save_settings(path := SETTINGS_PATH) -> void:
	var c := ConfigFile.new()
	c.set_value("feel", "vibration", vibration_on)
	c.set_value("feel", "screen_shake", screen_shake_on)
	c.save(path)


## 저장된 설정을 불러온다. 파일이 없으면 지금 값(기본 켜짐)을 그대로 둔다
func load_settings(path := SETTINGS_PATH) -> void:
	var c := ConfigFile.new()
	if c.load(path) != OK:
		return
	vibration_on = bool(c.get_value("feel", "vibration", vibration_on))
	screen_shake_on = bool(c.get_value("feel", "screen_shake", screen_shake_on))


## 진행 저장 (SaveGame). 마을 지도에 올 때마다 자동으로 부른다
func save_game(path := SaveGame.PATH) -> bool:
	return SaveGame.write(self, path)


## 저장된 진행을 불러온다. 저장이 없으면 false
func load_game(path := SaveGame.PATH) -> bool:
	return SaveGame.load_into(self, path)


func has_save(path := SaveGame.PATH) -> bool:
	return SaveGame.exists(path)


## 새로 시작: 진행을 처음 상태로 되돌린다 (설정은 그대로)
func reset_game() -> void:
	SaveGame.reset(self)


func _exit_tree() -> void:
	UiKit.clear_fonts()


func has_flag(name: String) -> bool:
	return flags.get(name, false)


## 돈을 벌거나 쓴다. 장부에도 적는다.
func earn(amount: int) -> void:
	money += amount
	sales_today += amount


func spend(amount: int) -> void:
	money -= amount
	spent_today += amount


## 장비를 산다. kind는 "rod" 또는 "reel". 문제가 없으면 빈 문자열, 있으면 안내 문구를 돌려준다.
func buy_gear(kind: String, id: String) -> String:
	var table: Dictionary = GearDB.RODS if kind == "rod" else GearDB.REELS
	var owned: Array = owned_rods if kind == "rod" else owned_reels
	if not table.has(id):
		return "없는 물건이에요."
	if id in owned:
		return "이미 가지고 있어요."
	var price: int = AppWork.shop_price(flags, int(table[id].price))
	if money < price:
		return "돈이 모자라요."
	spend(price)
	owned.append(id)
	return ""


## 텃밭 이랑(index 0~3)에 씨앗을 사서 심는다. 문제가 없으면 빈 문자열, 있으면 안내 문구를 돌려준다.
func plant_crop(index: int, crop_id: String) -> String:
	var err := CropDB.plant_error(garden, index, crop_id, money)
	if not err.is_empty():
		return err
	spend(int(CropDB.crop(crop_id).price))
	garden[index] = {"crop": crop_id, "day": day}
	return ""


## 다 자란 이랑을 거둔다. 거둔 작물 id를 돌려준다. 아직이면 빈 문자열
func harvest_crop(index: int) -> String:
	if index < 0 or index >= garden.size():
		return ""
	var slot: Dictionary = garden[index]
	if CropDB.stage(slot, day) != CropDB.READY:
		return ""
	var id: String = slot.crop
	produce[id] = int(produce.get(id, 0)) + int(CropDB.crop(id).amount)
	garden[index] = {}
	return id


## 미끼를 산다. 문제가 없으면 빈 문자열, 있으면 안내 문구를 돌려준다.
## price를 주면 그 값으로 산다 (읍내 도매, Bus.bait_price)
func buy_bait(id: String, price := -1) -> String:
	if not BaitDB.BAITS.has(id):
		return "없는 물건이에요."
	var b := BaitDB.bait(id)
	var cost: int = AppWork.shop_price(flags, int(b.price)) if price < 0 else price
	if money < cost:
		return "돈이 모자라요."
	spend(cost)
	baits[id] = int(baits.get(id, 0)) + int(b.amount) + int(KitDB.value(kits, "tacklebox"))
	return ""


func bait_count(id: String) -> int:
	return int(baits.get(id, 0))


## 미끼 하나를 쓴다. 다 떨어지면 남은 미끼 가운데 하나로 바꾼다 (크릴 먼저)
func use_bait() -> void:
	var n := bait_count(equipped_bait)
	if n < 0:
		return
	n -= 1
	baits[equipped_bait] = n
	if n <= 0:
		baits.erase(equipped_bait)
		for id in BaitDB.ORDER:
			if bait_count(id) > 0:
				equipped_bait = id
				return
		equipped_bait = BaitDB.DEFAULT


## 던질 미끼가 남았는지
func has_bait() -> bool:
	return bait_count(equipped_bait) != 0


## 오늘 주문
func today_order() -> Dictionary:
	return Orders.of(day, flags)


## 잡은 물고기를 주문에 넣어 본다. 주문을 막 다 채웠으면 보상 금액, 아니면 0
## 다 채우면 주문한 생선을 아이스박스에서 꺼내 주문한 사람에게 보낸다 (보상만 받고 같은 생선을 저녁에 또 파는 일이 없게)
func offer_to_order(fish_id: String, size_cm: float) -> int:
	var o := today_order()
	if order_done or not Orders.matches(o, fish_id, size_cm):
		return 0
	order_filled += 1
	if order_filled >= o.count:
		order_done = true
		_deliver_order(o)
		earn(o.reward)
		note("%s 부탁한 %s %d마리를 보냈다." % [Josa.attach(Orders.call_name(o.customer), "이/가"), FishDB.get_fish(o.fish).name, o.count], 2)
		return o.reward
	return 0


## 주문 조건에 맞는 생선을 작은 것부터 count마리 꺼낸다
func _deliver_order(o: Dictionary) -> void:
	for n in o.count:
		var best := -1
		for i in inventory.size():
			var e: Dictionary = inventory[i]
			if Orders.matches(o, e.id, e.size) and (best < 0 or e.size < inventory[best].size):
				best = i
		if best < 0:
			return
		inventory.remove_at(best)


## 잡은 생선을 아이스박스에 넣는다. 꽉 차 있으면 가장 싼 한 마리(방금 잡은 것일 수도 있다)를 놓아준다.
## 놓아준 생선을 돌려준다. 다 들어갔으면 빈 Dictionary
## auto_release가 false면 넘친 채로 두고 빈 Dictionary를 돌려준다. 낚시 화면이 놓아줄 고기를 고르게 한다 (is_overfull, release_fish)
func store_catch(entry: Dictionary, auto_release := true) -> Dictionary:
	var e := entry.duplicate()
	if not e.has("day"):
		e["day"] = day
	inventory.append(e)
	if inventory.size() <= icebox_size or not auto_release:
		return {}
	var low := 0
	for i in inventory.size():
		if FishDB.value_of(inventory[i].id, inventory[i].size) < FishDB.value_of(inventory[low].id, inventory[low].size):
			low = i
	var out: Dictionary = inventory[low]
	inventory.remove_at(low)
	return out


## 아이스박스의 그 생선(entry)을 수산시장에 판다. 받은 돈, 없으면 0
func sell_fish(entry: Dictionary, price := -1) -> int:
	var i := inventory.find(entry)
	if i < 0:
		return 0
	inventory.remove_at(i)
	var got := Market.price(entry.id, entry.size) if price < 0 else price
	earn(got)
	return got


## 아이스박스가 넘쳤는지 (놓아줄 고기를 골라야 한다)
func is_overfull() -> bool:
	return inventory.size() > icebox_size


## 아이스박스의 그 생선을 바다에 놓아준다. 놓아줬으면 true
func release_fish(entry: Dictionary) -> bool:
	var i := inventory.find(entry)
	if i < 0:
		return false
	inventory.remove_at(i)
	return true


## 집에서 대출을 더 갚는다. 갚은 돈, 못 갚으면 0
func pay_extra() -> int:
	var n := Loan.extra_amount(money, debt)
	if n > 0:
		money -= n
		debt -= n
	return n


## 쿨러를 다음 단계로 산다. 문제가 없으면 빈 문자열
func buy_cooler() -> String:
	if cooler + 1 >= KitDB.COOLERS.size():
		return "더 큰 쿨러는 아직 없어요."
	var c := KitDB.cooler(cooler + 1)
	var cprice := AppWork.shop_price(flags, int(c.price))
	if money < cprice:
		return "돈이 모자라요."
	spend(cprice)
	cooler += 1
	icebox_size = int(c.size)
	return ""


## 수조를 다음 단계로 산다 (경자상회). 건너뛰지 않고 하나씩. 문제가 없으면 빈 문자열
func buy_tank() -> String:
	var nx := Tank.next_info(tank_level)
	if nx.is_empty():
		return "더 좋은 수조는 없어요."
	var p := Store.price(self, int(nx.price))
	if money < p:
		return "돈이 모자라요."
	spend(p)
	tank_level += 1
	return ""


func tank_free() -> int:
	return maxi(0, Tank.slots(tank_level) - tank.size())


## 아이스박스 고기를 수조로 옮긴다. 옮겼으면 true
func tank_put(entry: Dictionary) -> bool:
	if tank_free() <= 0 or not inventory.has(entry):
		return false
	inventory.erase(entry)
	entry["alive"] = true
	tank.append(entry)
	return true


## 수조 고기를 꺼내 아이스박스에 넣는다. 오늘 잡은 것처럼 싱싱하다. 꺼냈으면 true
func tank_take(entry: Dictionary) -> bool:
	if icebox_free() <= 0 or not tank.has(entry):
		return false
	tank.erase(entry)
	var e := entry.duplicate()
	e["day"] = day
	e.erase("alive")
	inventory.append(e)
	return true


## 도구를 다음 단계로 산다. 문제가 없으면 빈 문자열
func buy_kit(id: String) -> String:
	var nx := KitDB.next_level(kits, id)
	if nx.is_empty():
		return "이게 제일 좋은 거예요."
	var kprice := AppWork.shop_price(flags, int(nx[1]))
	if money < kprice:
		return "돈이 모자라요."
	spend(kprice)
	kits[id] = KitDB.level(kits, id) + 1
	return ""


## 고기를 바다로 돌려보내면 평판이 조금 오른다 (하루 RELEASE_REP_MAX번까지). 오른 만큼 돌려준다.
## 오늘 조과(caught_today)에 "released"로 이미 들어간 뒤에 부른다. 처음 놓아준 날은 일지에 남긴다
const RELEASE_REP_MAX := 3


func reward_release(entry: Dictionary) -> int:
	if not flags.get("first_release", false):
		flags["first_release"] = true
		note("%s %.0fcm를 바다로 돌려보냈다. 내년에 더 커서 만나자." % [FishDB.get_fish(entry.id).name, entry.size], 3)
	var n := caught_today.filter(func(e): return e.get("released", false)).size()
	if n > RELEASE_REP_MAX:
		return 0
	reputation += 1
	return 1


## 방파제에 오면 통발을 걷는다: 든 고기를 아이스박스에 넣고(넘치면 화면이 고르게 한다) 걷은 것을 돌려준다.
## 포획금지체장 이하는 넣지 않고 놓아준다 ("released": true로 표시해 돌려준다)
func haul_traps() -> Array:
	var got := trap_fish.duplicate()
	trap_fish.clear()
	for e in got:
		if FishDB.must_release(e.id, e.size):
			e["released"] = true
		else:
			store_catch(e, false)
		caught_today.append(e)
		if e.get("released", false):
			reward_release(e)
	return got


## 아이스박스에 자리가 남았는지
func icebox_free() -> int:
	return maxi(0, icebox_size - inventory.size())


## 오늘 밤을 넘기면 상하는 생선 (잡은 날을 포함해 FRESH_DAYS일째인 것)
func spoiling_tonight() -> Array:
	return inventory.filter(func(e): return day - int(e.get("day", day)) + 1 >= FRESH_DAYS)


## 아이스박스에서 그 어종 한 마리를 꺼낸다. 없으면 빈 Dictionary
func take_fish(id: String) -> Dictionary:
	for i in inventory.size():
		if inventory[i].id == id:
			var e: Dictionary = inventory[i]
			inventory.remove_at(i)
			return e
	return {}


## 하루를 마치고 다음 날 아침으로 넘어간다.
## wake_minutes를 주지 않으면 DayFlow 규칙대로 (밤 낚시를 했으면 늦잠)
func end_day(wake_minutes := -1) -> void:
	journal.append(Journal.page(self))
	if journal.size() > Journal.MAX_PAGES:
		journal.pop_front()
	notes_today = []
	yesterday_sales = sales_today
	yesterday_spent = spent_today
	news_today = []
	for t in WeekGoals.close_day(self):
		_news(t)
	# 수조가 있으면 오늘 밤 상할 고기를 값진 것부터 옮겨 살려 둔다
	var saving := spoiling_tonight()
	saving.sort_custom(func(a, b): return FishDB.value_of(a.id, a.size) > FishDB.value_of(b.id, b.size))
	var moved := 0
	for e in saving:
		if tank_put(e):
			moved += 1
	if moved > 0:
		_news("상할 뻔한 생선 %d마리를 수조로 옮겨 살려 뒀어요" % moved)
	# 냉장고가 좋으면 상할 생선 몇 마리를 하루 더 살린다 (한 마리에 한 번만)
	var cold := KitchenDB.value(kitchen, "fridge")
	var kept := 0
	saving = spoiling_tonight()
	saving.sort_custom(func(a, b): return FishDB.value_of(a.id, a.size) > FishDB.value_of(b.id, b.size))
	for e in saving:
		if kept < cold and not e.get("chilled", false):
			e["chilled"] = true
			e["day"] = int(e.get("day", day)) + 1
			kept += 1
	if kept > 0:
		_news("냉장고 덕분에 상할 생선 %d마리가 하루 더 버텨요" % kept)
	# 오래된 생선은 밤새 상해서 버린다
	var spoiled := spoiling_tonight()
	if not spoiled.is_empty():
		inventory = inventory.filter(func(e): return not spoiled.has(e))
		_news("아이스박스에서 생선 %d마리가 상해서 버렸어요. 잡은 다음 날 저녁까지 팔아요" % spoiled.size())
	Coop.next_day(self)
	# 밤새 통발에 고기가 든다 (KitDB trap). 잡은 날은 다음 날로 친다
	for t in KitDB.trap_night(kits, trap_fish.size(), day + 1):
		t["day"] = day + 1
		trap_fish.append(t)
	day += 1
	# 월요일은 대출, 월세, 공과금이 나가는 날 (Loan)
	var r := Loan.settle(day, money, debt, monthly_repayment, arrears, pay_streak)
	if not r.is_empty():
		if r.paid > 0:
			money -= r.paid
		else:
			missed_payments += 1
		arrears = r.arrears
		pay_streak = r.streak
		debt = r.debt
		_news(Loan.notice(r))
	time_minutes = wake_minutes if wake_minutes >= 0 else DayFlow.wake_time(night_fished)
	opened_today = false
	night_fished = false
	day_fished = false
	caught_today.clear()
	order_filled = 0
	order_done = false
	sales_today = 0
	spent_today = 0


func clock_text() -> String:
	var m := time_minutes % (24 * 60)
	var h := m / 60
	var period := "새벽" if h < 6 else ("오전" if h < 12 else ("오후" if h < 18 else "저녁" if h < 21 else "밤"))
	return "%s %s %02d:%02d" % [Calendar.short_text(day), period, h, m % 60]


## 오늘 있었던 일을 일지에 메모한다. 중요도가 가장 높은 메모가 그날의 한 줄이 된다 (템플릿 그대로 넣어도 된다)
func note(text: String, priority := 1) -> void:
	notes_today.append({"p": priority, "text": line(text)})


## 아침 소식 한 줄: 토스트로 띄우고(notices) 하루 서랍에도 남긴다(news_today)
func _news(t: String) -> void:
	notices.append(t)
	news_today.append(t)


## 쌓인 알림을 꺼내고 비운다
func pop_notices() -> Array:
	var out := notices.duplicate()
	notices.clear()
	return out

var _player_regex := RegEx.create_from_string("^[가-힣a-zA-Z0-9]+$")
var _shop_regex := RegEx.create_from_string("^[가-힣a-zA-Z0-9 ]+$")


## 대사 템플릿에 현재 이름들을 넣는다. 예: line("{shop|이/가}라...")
func line(template: String) -> String:
	return Josa.format(template, {
		"player": player_name,
		"shop": shop_name,
		"pet": pet_name,
	})


## 이름 검사. 문제가 없으면 빈 문자열, 있으면 안내 문구를 돌려준다.
func validate_player_name(text: String) -> String:
	return _validate(text, PLAYER_NAME_MAX, _player_regex, "한글, 영문, 숫자만 쓸 수 있어요.")


func validate_shop_name(text: String) -> String:
	return _validate(text, SHOP_NAME_MAX, _shop_regex, "한글, 영문, 숫자, 띄어쓰기만 쓸 수 있어요.")


func _validate(text: String, max_len: int, regex: RegEx, char_message: String) -> String:
	var t := text.strip_edges()
	if t.is_empty():
		return ""  # 빈 값은 기본값으로 처리하므로 통과
	if t.length() > max_len:
		return "%d자까지 쓸 수 있어요." % max_len
	if regex.search(t) == null:
		return char_message
	var lower := t.to_lower().replace(" ", "")
	for w in BANNED_WORDS:
		if lower.contains(w):
			return "다른 이름을 써 주세요."
	return ""


func random_player_name() -> String:
	return RANDOM_PLAYER_NAMES.pick_random()


func random_shop_name() -> String:
	return RANDOM_SHOP_NAMES.pick_random()


func format_won(amount: int) -> String:
	var s := str(abs(amount))
	var out := ""
	while s.length() > 3:
		out = "," + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return ("-" if amount < 0 else "") + s + out + "원"
