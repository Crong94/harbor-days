class_name StaffDB
extends RefCounted
## 식당 알바 (2026-11-11 사용자: 한 번 뽑으면 계속 나오고, 서빙과 주방 중 골라 맡긴다).
## 그림은 여울 레포(Crong94/Yeoul)에서 가져온 여울, 차세라 (assets/art/staff, 원본 docs/ref/인물/여울_레포).
## 뽑은 알바: GameState.staff {역할: 알바 id}. 일당은 가게를 연 날 영업이 끝날 때 나간다.
##   서빙: 완성 접시를 알아서 나른다 (DiningLogic.helper_serve)
##   주방: 주인공이 주방 앞에 없어도 화로가 익는다 (DiningLogic.helper_kitchen)

const ROLES := {"serve": "서빙", "kitchen": "주방"}

const LIST := {
	"yeoul": {"name": "여울", "role": "serve", "wage": 20000,
		"desc": "요리사 앞치마가 잘 어울리는 알바생. 완성된 접시를 손님에게 날라 줘요.",
		"art": "staff/yeoul_stand", "walk": ["staff/yeoul_walk_1", "staff/yeoul_walk_2"], "serve_art": "staff/yeoul_serve",
		"portrait": "staff/yeoul_portrait"},
	"sera": {"name": "세라", "role": "kitchen", "wage": 15000,
		"desc": "빨간 고글을 쓴 씩씩한 알바생. 사장이 홀에 있어도 화로를 지켜요.",
		"art": "staff/sera_stand", "walk": [], "serve_art": "staff/sera_point",
		"portrait": "staff/sera_portrait"},
}


static func get_staff(id: String) -> Dictionary:
	return LIST.get(id, {})


## 그 역할을 맡은 알바 id (없으면 빈 문자열)
static func in_role(staff: Dictionary, role: String) -> String:
	return str(staff.get(role, ""))


static func is_hired(staff: Dictionary, id: String) -> bool:
	return staff.values().has(id)


## 뽑기. 그 알바의 역할 자리에 앉힌다 (이미 누가 있으면 바꾼다)
static func hire(staff: Dictionary, id: String) -> bool:
	var s := get_staff(id)
	if s.is_empty():
		return false
	staff[s.role] = id
	return true


static func fire(staff: Dictionary, id: String) -> void:
	for role in staff.keys():
		if staff[role] == id:
			staff.erase(role)


## 하루 일당 합
static func wages(staff: Dictionary) -> int:
	var n := 0
	for role in staff:
		n += int(get_staff(staff[role]).get("wage", 0))
	return n
