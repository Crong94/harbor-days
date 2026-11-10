class_name SaveGame
extends RefCounted
## 진행 저장과 불러오기. GameState의 변수들을 파일 하나에 담는다.
##
## 무엇을 저장하나: GameState 스크립트에 선언된 변수 전부 (이름이 _로 시작하는 것과 SKIP은 뺀다).
## 그래서 GameState에 새 변수를 더하면 따로 손대지 않아도 같이 저장된다.
## 설정(진동, 화면 흔들림)은 settings.cfg에 따로 저장하므로 여기서는 뺀다.
## 언제 저장하나: 마을 지도에 올 때마다 (scenes/map/map.gd). 낚시나 영업 도중에는 저장하지 않는다.
## 형식: Godot 변수 그대로(store_var). 정수와 실수가 섞이지 않는다.

const PATH := "user://save.dat"
const VERSION := 1
const SKIP := ["vibration_on", "screen_shake_on"]


## 저장할 변수 이름들
static func fields(gs: Object) -> Array:
	var out: Array = []
	var script: Script = gs.get_script()
	if script == null:
		return out
	for p in script.get_script_property_list():
		var n: String = p.name
		if not (p.usage & PROPERTY_USAGE_SCRIPT_VARIABLE):
			continue
		if n.begins_with("_") or n in SKIP:
			continue
		if typeof(gs.get(n)) == TYPE_OBJECT:
			continue
		out.append(n)
	return out


## 지금 상태를 Dictionary로 (배열과 사전은 복사본)
static func snapshot(gs: Object) -> Dictionary:
	var d := {}
	for n in fields(gs):
		var v = gs.get(n)
		d[n] = v.duplicate(true) if (v is Array or v is Dictionary) else v
	return d


## Dictionary의 값을 상태에 넣는다. 없는 항목과 형이 다른 항목은 건드리지 않는다 (망가진 파일 대비)
static func restore(gs: Object, d: Dictionary) -> void:
	for n in fields(gs):
		if not d.has(n):
			continue
		var v = d[n]
		if typeof(v) != typeof(gs.get(n)):
			continue
		gs.set(n, v.duplicate(true) if (v is Array or v is Dictionary) else v)


## 처음 상태로 되돌린다 (새로 시작). 설정은 그대로 둔다
static func reset(gs: Object) -> void:
	var fresh: Object = gs.get_script().new()
	restore(gs, snapshot(fresh))
	fresh.free()


static func write(gs: Object, path := PATH) -> bool:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return false
	f.store_var({"version": VERSION, "data": snapshot(gs)})
	f.close()
	return true


## 저장 파일 내용. 없거나 망가졌으면 빈 Dictionary
static func read(path := PATH) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null or f.get_length() < 8:
		return {}
	# store_var는 맨 앞 4바이트에 내용 길이를 적는다. 길이가 안 맞으면 잘렸거나 다른 파일이다
	if int(f.get_32()) != f.get_length() - 4:
		return {}
	f.seek(0)
	var v = f.get_var()
	f.close()
	if not (v is Dictionary) or not (v.get("data") is Dictionary):
		return {}
	return v.data


static func exists(path := PATH) -> bool:
	return not read(path).is_empty()


## 불러와서 상태에 넣는다. 저장이 없으면 false
static func load_into(gs: Object, path := PATH) -> bool:
	var d := read(path)
	if d.is_empty():
		return false
	restore(gs, d)
	return true
