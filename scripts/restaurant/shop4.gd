class_name Shop4
extends RefCounted
## 식당 4안 (2026-11-18 회사 PC 그림 세션 확정). 네 벽이 직각인 가게를 정면 위 한 시점으로 그린 빈 바탕 위에
## 주방 장비, 카운터, 스툴, 테이블, 소품을 낱장으로 얹는다. 그림은 assets/art/shop4/.
## 좌표와 그리는 순서는 그림 세션의 docs/ref/배경/식당_4안/4안_합친확인그림.py 그대로 (바탕 px, 982x1602).
##
## key: 그리는 순서. 손님과 함께 작은 것부터 그린다. 앉은 손님은 SEAT_KEY, 걷는 손님은 발 y(바탕 px)
## anchor: "tl" 왼쪽 위, "bl" 왼쪽 아래, "bc" 아래 가운데. w: 그릴 폭 (높이는 그림 비율대로). w가 0이면 그림 크기 그대로
## glow: 밤에도 어둡게 하지 않는다 (램프, 낮밤 따로 받은 구조물). var: 낮밤 따로 받은 그림 (_day, _night)
## 밤에는 glow가 아닌 물건과 손님에 NIGHT_TINT를 곱한다

const DIR := "shop4/"
const SIZE := Vector2(982, 1602)
const NIGHT_TINT := Color(0.86, 0.76, 0.74)

const STOOL_H := {"high": 111.0, "low": 82.0}
const STOOL_W := {"high": 67.0, "low": 63.0}
## 스툴 그림에서 방석 윗면, 방석 앞 테두리, 다리 가로대의 높이 비율
const STOOL_TOP := 5.0 / 720.0
const STOOL_FRONT := {"high": 240.0 / 720.0, "low": 240.0 / 530.0}
const STOOL_BAND := {"high": 300.0 / 720.0, "low": 300.0 / 530.0}

## 스툴 [종류, 가운데 x, 바닥 y, key]
const STOOLS := [
	["high", 478, 724, 724.0], ["high", 593, 724, 724.0], ["high", 708, 724, 724.0], ["high", 823, 724, 724.0],
	["high", 196, 700, 700.0], ["high", 196, 850, 850.0], ["high", 196, 1000, 1000.0], ["high", 196, 1150, 1150.0],
	["low", 307, 862, 749.0], ["low", 394, 862, 749.0], ["low", 311, 992, 992.0], ["low", 396, 992, 992.0],
	["low", 307, 1114, 1001.0], ["low", 394, 1114, 1001.0], ["low", 311, 1244, 1244.0], ["low", 396, 1244, 1244.0],
	["low", 672, 1218, 1194.0], ["low", 834, 1218, 1194.0],
]

## 물건 [그림, x, y, w, key, anchor, glow, var]
const ITEMS := [
	# 주방: 뒷벽(바닥선 y 354)에 정면 장비, 오른쪽 벽에 옆모습 화구 둘
	["kit2_shelf_tall", 300, 354, 110, 10.354, "bl", false, false],
	["kit2_sink", 418, 354, 130, 10.354, "bl", false, false],
	["kit2_worktable", 556, 354, 130, 10.354, "bl", false, false],
	["kit2_fridge", 756, 354, 128, 10.354, "bl", false, false],
	["kit2_stove_side_empty", 810, 472, 78, 10.472, "bl", false, false], # 냄비 없는 빈 화구 (조리 도구는 영업 판이 얹는다, 11-24)
	["kit2_stove_side_empty", 810, 550, 78, 10.55, "bl", false, false],
	["kit2_panrack", 588, 196, 66, 9.5, "tl", false, false],
	# 카운터(ㄱ자, 세로 팔 위를 잘라 직원 통로)와 픽업대
	["struct4_counterG2", 288, 303, 0, 20.0, "tl", true, true],
	["pickup_pass", 366, 598, 134, 25.0, "bc", false, false],
	# 테이블 둘, 창가 바, 칸막이와 2인 테이블
	["hall_table_4", 252, 800, 200, 794.0, "tl", false, false],
	["hall_table_4", 252, 1052, 200, 1046.0, "tl", false, false],
	["struct4_window_bar", 79, 541, 0, 1300.0, "tl", true, true],
	["struct4_partitionL", 631, 911, 0, 1.0, "tl", true, true],
	["hall_table_2", 694, 1048, 120, 1195.0, "tl", false, false],
	# 소품
	["deco_lamp_pendant", 470, 180, 60, 30.0, "tl", true, false],
	["deco_lamp_pendant", 690, 180, 60, 30.0, "tl", true, false],
	["deco_lamp_wall", 62, 420, 70, 5.0, "tl", true, false],
	["deco_lamp_wall", 62, 860, 70, 5.0, "tl", true, false],
	# (11-19 뺌: 가게 꾸미기와 겹침) ["deco_vase", 118, 600, 44, 1301.0, "bc", false, false],
	# (11-19 뺌: 가게 꾸미기와 겹침) ["deco_lantern", 118, 790, 24, 1301.0, "bc", true, false],
	# (11-19 뺌: 가게 꾸미기와 겹침) ["deco_lantern", 118, 930, 24, 1301.0, "bc", true, false],
	# (11-19 뺌: 가게 꾸미기와 겹침) ["deco_vase", 118, 1150, 44, 1301.0, "bc", false, false],
	["deco_cutlery", 536, 590, 56, 25.0, "bc", false, false],
	["deco_plates", 651, 590, 46, 25.0, "bc", false, false],
	["deco_condiments", 766, 590, 44, 25.0, "bc", false, false],
	["deco_plates", 856, 590, 42, 25.0, "bc", false, false],
	# (11-19 뺌: 가게 꾸미기와 겹침) ["deco_vine_leaf", 664, 895, 190, 1100.0, "tl", false, false],
	# (11-19 뺌: 가게 꾸미기와 겹침) ["deco_buoy", 836, 930, 42, 1100.0, "tl", false, false],
	["prop_beam_jars", 520, 113, 108, 4.0, "tl", true, true],
	# (11-19 뺌: 가게 꾸미기와 겹침) ["prop_beam_plant", 350, 64, 112, 4.0, "tl", true, true],
	# 앞벽 들보 앞 (문 앞)
	["deco_lamp_door", 491, 1322, 46, 5001.0, "bc", true, false],
	["crate_front_big", 84, 1566, 116, 5002.0, "bc", false, false],
	["crate_front_small", 170, 1564, 64, 5003.0, "bc", false, false],
	# (11-19 뺌: 가게 꾸미기와 겹침) ["deco_pot_purple", 268, 1566, 132, 5004.0, "bc", false, false],
	# (11-19 뺌: 가게 꾸미기와 겹침) ["deco_pot_pink", 714, 1566, 134, 5004.0, "bc", false, false],
	["deco_mat", 491, 1588, 170, 5001.0, "bc", false, false],
]
## 앞벽 들보: 아래쪽 스툴 다리가 들보 뒤로 가게 바탕의 이 띠를 한 번 더 덮는다
const BEAM := Rect2(0, 1245, 982, 57)
const BEAM_KEY := 5000.0

## 앉은 손님 그리는 순서 (DiningLogic.SEATS 순서)
const SEAT_KEY := [724.5, 724.5, 724.5, 724.5, 700.5, 1000.5, 750.0, 750.0, 992.5, 992.5,
	1002.0, 1002.0, 1244.5, 1244.5, 1196.0, 1196.0]
## 뒷모습 손님이 앉은 스툴 (STOOLS 번호). 스툴 방석 앞 테두리 아래를 손님 위에 다시 덮는다. -1이면 없음
const SEAT_STOOL := [0, 1, 2, 3, -1, -1, -1, -1, 10, 11, -1, -1, 14, 15, -1, -1]
## 칸막이 손님: 2인 테이블에서 엉덩이 높이(1166) 24px 위부터 아래를 손님 위에 다시 덮는다
const BOOTH_CUT := 1142.0


static func path(id: String, night: bool, variant: bool) -> String:
	return DIR + id + ("_night" if night else "_day") if variant else DIR + id


static func bg_id(night: bool) -> String:
	return DIR + ("bg_night" if night else "bg_day")


## 그림 크기(tex_size)로 실제 놓을 자리 (바탕 px)
static func rect_of(it: Array, tex_size: Vector2) -> Rect2:
	var w: float = float(it[3]) if float(it[3]) > 0.0 else tex_size.x
	var h := roundf(tex_size.y * w / tex_size.x) if float(it[3]) > 0.0 else tex_size.y
	var x: float = it[1]
	var y: float = it[2]
	match it[5]:
		"bc":
			x -= w / 2.0
			y -= h
		"bl":
			y -= h
	return Rect2(x, y, w, h)


static func stool_rect(s: Array) -> Rect2:
	var h: float = STOOL_H[s[0]]
	var w: float = STOOL_W[s[0]]
	return Rect2(float(s[1]) - w / 2.0, float(s[2]) - h, w, h)


## 뒷모습 손님 앞에 다시 덮을 스툴 모양 (방석 앞 테두리 곡선 아래 + 다리 가로대 아래). 바탕 px
static func stool_cover(s: Array) -> Array:
	var r := stool_rect(s)
	var h := r.size.y
	var top := r.position.y + STOOL_TOP * h
	var front: float = r.position.y + float(STOOL_FRONT[s[0]]) * h
	var band: float = r.position.y + float(STOOL_BAND[s[0]]) * h
	var ex := r.get_center().x
	var ey := (top + front) / 2.0
	var a := r.size.x / 2.0
	var b := (front - top) / 2.0
	var arc := PackedVector2Array()
	for i in 17:
		var x := ex - a + 2.0 * a * i / 16.0
		var t := (x - ex) / a
		arc.append(Vector2(x, ey + b * sqrt(maxf(0.0, 1.0 - t * t)) - 2.0))
	arc.append(Vector2(r.end.x, r.end.y))
	arc.append(Vector2(r.position.x, r.end.y))
	var legs := PackedVector2Array([Vector2(r.position.x, band - 2.0), Vector2(r.end.x, band - 2.0), r.end, Vector2(r.position.x, r.end.y)])
	return [arc, legs]
