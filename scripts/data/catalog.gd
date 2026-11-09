class_name Catalog
extends RefCounted
## 바다 한 접시(이전 게임)에서 가져온 어종 71종과 레시피 50개.
## 원본 JSON: assets/data/species.json, assets/data/recipes.json
## 어종 id는 바다 한 접시 표기(bollak, mangsangeo)라서 오늘의 바다 FishDB id와 다르다. FishDB의 "catalog" 값으로 잇는다.
##
## 어종 항목: id, name, minSize, maxSize, basePrice, strength(1~3), months(1~12월 출현 배율), hint, desc, spots
## 레시피 항목: id, name, species, tool, price, raw, steps[{flavor, target}]
## 요리 그림은 assets/art/dish/<레시피 id>.png, 조리도구 그림은 assets/art/cook_tool/<tool>.png

const SPECIES_PATH := "res://assets/data/species.json"
const RECIPES_PATH := "res://assets/data/recipes.json"

static var _species := {}
static var _recipes := {}
static var _flavors := {}
static var _loaded := false


static func _load() -> void:
	if _loaded:
		return
	_loaded = true
	var s = _read_json(SPECIES_PATH)
	if s is Dictionary:
		for e in s.get("species", []):
			_species[e.id] = e
	var r = _read_json(RECIPES_PATH)
	if r is Dictionary:
		for e in r.get("recipes", []):
			_recipes[e.id] = e
		for f in r.get("flavors", []):
			_flavors[f.id] = f


static func _read_json(path: String) -> Variant:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_warning("데이터 파일을 열 수 없음: " + path)
		return null
	return JSON.parse_string(f.get_as_text())


static func species_ids() -> Array:
	_load()
	return _species.keys()


static func species(id: String) -> Dictionary:
	_load()
	return _species.get(id, {})


static func recipe_ids() -> Array:
	_load()
	return _recipes.keys()


static func recipe(id: String) -> Dictionary:
	_load()
	return _recipes.get(id, {})


## 한 어종으로 만들 수 있는 레시피들
static func recipes_for(species_id: String) -> Array:
	_load()
	var out := []
	for id in _recipes:
		if _recipes[id].species == species_id:
			out.append(_recipes[id])
	return out


## 맛 정보: id, name(짠맛), tool(소금), review[딱 맞음, 모자람, 지나침]
static func flavor(id: String) -> Dictionary:
	_load()
	return _flavors.get(id, {})


## 그 달(1~12)에 얼마나 잘 나오는지 (바다 한 접시 기준 배율, 1.0이 보통)
static func month_factor(species_id: String, month: int) -> float:
	var m: Array = species(species_id).get("months", [])
	if m.size() != 12:
		return 1.0
	return float(m[clampi(month, 1, 12) - 1])


static func dish_art(recipe_id: String) -> String:
	return "dish/" + recipe_id


static func tool_art(tool: String) -> String:
	return "cook_tool/" + tool
