class_name Sides
extends RefCounted
## 식당 곁들임 (텃밭 채소와 달걀). 주재료는 낚은 생선뿐이고, 곁들임은 접시 값을 조금 올린다 (docs/텃밭_설계.md).
## 접시를 낼 때 남은 곁들임 중 값이 가장 큰 것 하나를 자동으로 붙인다. 손 조작은 없다.
## 순덕 할머니 부탁에 드릴 채소는 남겨 둔다 (reserve).
## 보관: GameState.produce {작물 id 또는 "egg": 개수}

const EGG := "egg"
const EGG_BONUS := 700 # 달걀 하나 곁들이면 더 받는 돈 (계란말이 한 조각)


static func bonus(id: String) -> int:
	if id == EGG:
		return EGG_BONUS
	return int(CropDB.crop(id).get("bonus", 0)) if CropDB.CROPS.has(id) else 0


static func name_of(id: String) -> String:
	if id == EGG:
		return "달걀"
	return str(CropDB.crop(id).get("name", "")) if CropDB.CROPS.has(id) else ""


## 남겨 둘 것 {id: 개수}. 아직 못 들어준 순덕 할머니 부탁이 채소면 그 수만큼
static func reserve_for(gs: Object) -> Dictionary:
	var q: int = gs.sundeok_quest
	if q < 0 or q >= Coop.QUESTS.size():
		return {}
	var need: Dictionary = Coop.QUESTS[q].need
	if need.kind != "produce":
		return {}
	return {need.id: int(need.count)}


## 지금 붙일 곁들임 (없으면 빈 문자열). 값이 같으면 많이 남은 것부터
static func pick(pantry: Dictionary, reserve: Dictionary) -> String:
	var best := ""
	for id in pantry:
		var spare := int(pantry[id]) - int(reserve.get(id, 0))
		if spare <= 0 or bonus(id) <= 0:
			continue
		if best.is_empty() or bonus(id) > bonus(best) or (bonus(id) == bonus(best) and int(pantry[id]) > int(pantry[best])):
			best = id
	return best


## 하나 꺼낸다. 꺼낸 id (없으면 빈 문자열)
static func take(pantry: Dictionary, reserve: Dictionary) -> String:
	var id := pick(pantry, reserve)
	if not id.is_empty():
		pantry[id] = int(pantry[id]) - 1
	return id
