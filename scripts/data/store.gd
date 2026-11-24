class_name Store
extends RefCounted
## 경자상회 (2026-11-24 사용자: 낚시점처럼 안으로 들어가 탭별로 사게). 화면은 scenes/shop/store.gd
## 탭: 식재료(요리에 넣는 채소와 달걀, 하루 STOCK개씩) / 선물 / 주방(KitchenDB) / 살림(활어 수조 Tank, 닭 모이 Coop)
## 텃밭에서 기르면 훨씬 싸다. 생선은 팔지 않는다 (식당 주재료는 직접 낚은 생선만)
## 보관: GameState.store_bought {"day": 날, id: 그날 산 수}, GameState.goods {선물 id: 개수}

const STOCK := 4
const INGREDIENTS := {"daepa": 800, "kkaennip": 800, "mu": 1200, "gochu": 1000, "maneul": 1200, "baechu": 1800, "egg": 1000}
const INGREDIENT_ORDER := ["daepa", "mu", "gochu", "kkaennip", "maneul", "baechu", "egg"]
const GOODS := {
	"makgeolli": {"name": "막걸리", "price": 3000, "desc": "만수 할아버지가 좋아하는 그 막걸리"},
	"coffee": {"name": "믹스커피", "price": 2500, "desc": "준호가 하루 다섯 잔 마시는 노란 커피"},
	"candy": {"name": "알사탕", "price": 2000, "desc": "해솔이 주머니에 늘 들어 있는 사탕"},
	"yakgwa": {"name": "약과", "price": 3500, "desc": "어르신들이 좋아하는 달고 쫀득한 약과"},
}


## 오늘 남은 수
static func stock(gs: Object, id: String) -> int:
	var b: Dictionary = gs.store_bought
	return maxi(0, STOCK - (int(b.get(id, 0)) if int(b.get("day", -1)) == int(gs.day) else 0))


static func price(gs: Object, base: int) -> int:
	# 외상장부 앱을 만들어 드리면 경자 할머니가 10% 깎아 준다
	return int(roundf(base * 0.9 / 100.0) * 100.0) if gs.flags.get("app_kyungja_done", false) else base


## 그 채소가 들어가는 요리 이름들
static func used_in(id: String) -> String:
	var out := PackedStringArray()
	for r in Menu.RECIPES:
		if Menu.RECIPES[r].needs.has("produce:" + id):
			out.append(Menu.RECIPES[r].name)
	return ", ".join(out)


## 문제가 없으면 빈 문자열
static func buy_ingredient(gs: Object, id: String) -> String:
	if not INGREDIENTS.has(id):
		return "그건 없다."
	if stock(gs, id) <= 0:
		return "오늘 건 다 나갔다. 내일 또 들어온다."
	var p := price(gs, int(INGREDIENTS[id]))
	if gs.money < p:
		return "돈이 모자라네. 외상은 안 된다."
	gs.spend(p)
	if int(gs.store_bought.get("day", -1)) != int(gs.day):
		gs.store_bought = {"day": int(gs.day)}
	gs.store_bought[id] = int(gs.store_bought.get(id, 0)) + 1
	gs.produce[id] = int(gs.produce.get(id, 0)) + 1
	return ""


static func buy_goods(gs: Object, id: String) -> String:
	if not GOODS.has(id):
		return "그건 없다."
	var p := price(gs, int(GOODS[id].price))
	if gs.money < p:
		return "돈이 모자라네. 외상은 안 된다."
	gs.spend(p)
	gs.goods[id] = int(gs.goods.get(id, 0)) + 1
	return ""


static func buy_gear(gs: Object, id: String) -> String:
	var np := KitchenDB.next_price(gs.kitchen, id)
	if np < 0:
		return "그거보다 좋은 건 없다."
	var p := price(gs, np)
	if gs.money < p:
		return "돈이 모자라네. 외상은 안 된다."
	gs.spend(p)
	gs.kitchen[id] = KitchenDB.level(gs.kitchen, id) + 1
	return ""
