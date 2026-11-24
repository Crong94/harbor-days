class_name Pantry
extends RefCounted
## 식당 채소 창고 (텃밭 채소와 달걀). 2026-11-24 곁들임(Sides)을 없애고 채소는 요리(Menu)를 만드는 재료로만 쓴다.
## 보관: GameState.produce {작물 id 또는 "egg": 개수}

const EGG := "egg"


static func name_of(id: String) -> String:
	if id == EGG:
		return "달걀"
	return str(CropDB.crop(id).get("name", "")) if CropDB.CROPS.has(id) else ""


## 그림 id
static func art_of(id: String) -> String:
	return "egg" if id == EGG else "crop_" + id


## 요리에 쓰지 않고 남겨 둘 것 {id: 개수}. 아직 못 들어준 순덕 할머니 부탁이 채소면 그 수만큼
static func reserve_for(gs: Object) -> Dictionary:
	var q: int = gs.sundeok_quest
	if q < 0 or q >= Coop.QUESTS.size():
		return {}
	var need: Dictionary = Coop.QUESTS[q].need
	if need.kind != "produce":
		return {}
	return {need.id: int(need.count)}
