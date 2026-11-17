class_name HallCover
extends Control
## 홀 식당(3안) 가구 덮개. 손님보다 앞에 있는 가구(바 의자 방석 아래, 테이블, 등받이, 창가 선반, 칸막이 의자)를
## 배경 그림에서 그 모양대로 잘라 손님 위에 다시 그린다. 새 그림이 아니라 배경을 한 번 더 그리는 것이다.
## 모양은 그림 세션 확인 그림(앉은손님_확인그림.py)이 확대 격자로 잰 값 그대로 (배경 px, 982x1602).
## DiningFloor가 손님과 함께 y 순서로 줄 세운다 (key = 그 자리 엉덩이 y 바로 뒤).

var dining # DiningFloor (타입을 적으면 헤드리스 시험에서 GameState까지 끌려온다)
const BG_SIZE := Vector2(982, 1602) # DiningFloor.BG_SIZE와 같은 값
var polys: Array = [] # [PackedVector2Array] 배경 px
var key := 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(_delta: float) -> void:
	if visible:
		queue_redraw()


func _draw() -> void:
	if dining == null or dining._bg_tex == null:
		return
	for poly in polys:
		var pts := PackedVector2Array()
		var uvs := PackedVector2Array()
		for p in poly:
			var n: Vector2 = p / BG_SIZE
			pts.append(dining.to_screen(n))
			uvs.append(n)
		draw_polygon(pts, PackedColorArray([Color.WHITE]), uvs, dining._bg_tex)


static func _rect(x0: float, y0: float, x1: float, y1: float) -> PackedVector2Array:
	return PackedVector2Array([Vector2(x0, y0), Vector2(x1, y0), Vector2(x1, y1), Vector2(x0, y1)])


static func _ellipse(x0: float, y0: float, x1: float, y1: float, n := 20) -> PackedVector2Array:
	var c := Vector2((x0 + x1) / 2.0, (y0 + y1) / 2.0)
	var r := Vector2((x1 - x0) / 2.0, (y1 - y0) / 2.0)
	var out := PackedVector2Array()
	for i in n:
		var a := TAU * i / n
		out.append(c + Vector2(cos(a) * r.x, sin(a) * r.y))
	return out


## 바 의자: 방석 윗면 타원의 앞 테두리 곡선 아래(엉덩이가 방석 안에 앉게) + 다리
static func _counter_stool(cx: float) -> Array:
	var ex := cx + 0.5
	var ey := 629.5
	var a := 30.5
	var b := 12.5
	var arc := PackedVector2Array()
	for i in 13:
		var x := ex - a + 2.0 * a * i / 12.0
		var t := (x - ex) / a
		arc.append(Vector2(x, ey + b * sqrt(maxf(0.0, 1.0 - t * t))))
	arc.append(Vector2(ex + a, 660))
	arc.append(Vector2(ex - a, 660))
	var legs := PackedVector2Array([Vector2(cx - 33, 650), Vector2(cx + 33, 650), Vector2(cx + 32, 660),
		Vector2(cx + 30, 720), Vector2(cx - 30, 720), Vector2(cx - 32, 660)])
	return [arc, legs]


## 창가 선반: y0 아래 선반 (선반 오른쪽 끝 x = 196 - (y - 560) * 91/490)
static func _shelf_below(y0: float) -> Array:
	var xr := 196.0 - (y0 - 560.0) * 91.0 / 490.0
	return [PackedVector2Array([Vector2(30, y0), Vector2(xr, y0), Vector2(105, 1050), Vector2(30, 1050)])]


## 등받이 의자 (손님 앞): 의자 전체에서 등받이와 방석 사이 틈만 뺀다
static func _back_chair(cx: float, rt: float, gap_bottom: float, legs_bottom: float) -> Array:
	return [
		_rect(cx - 32, rt, cx + 32, rt + 21),
		_rect(cx - 32, rt + 21, cx - 19, gap_bottom),
		_rect(cx + 20, rt + 21, cx + 32, gap_bottom),
		PackedVector2Array([Vector2(cx - 32.5, gap_bottom), Vector2(cx + 32.5, gap_bottom), Vector2(cx + 33, legs_bottom), Vector2(cx - 33, legs_bottom)]),
	]


## 가운데 테이블 (상판, 꽃병, 앞다리)
static func _table_mid() -> Array:
	return [PackedVector2Array([Vector2(282, 766), Vector2(475, 766), Vector2(479, 862), Vector2(276, 862)]),
		_ellipse(342, 752, 393, 792), _rect(277, 858, 292, 956), _rect(461, 858, 477, 956)]


## 아래 테이블
static func _table_low() -> Array:
	return [PackedVector2Array([Vector2(188, 1008), Vector2(392, 1008), Vector2(394, 1106), Vector2(186, 1106)]),
		_ellipse(255, 996, 308, 1036), _rect(186, 1100, 200, 1190), _rect(380, 1100, 394, 1190)]


## 칸막이 자리: 방석 아래 테두리 아래와 테이블 밑, 그리고 엉덩이 높이 아래 테이블 (y 1033부터)
static func _booth(left: bool) -> Array:
	var seat := PackedVector2Array([Vector2(658, 1067), Vector2(684, 1067), Vector2(700, 1070), Vector2(722, 1073),
		Vector2(750, 1073), Vector2(750, 1136), Vector2(658, 1136)]) if left else \
		PackedVector2Array([Vector2(794, 1073), Vector2(828, 1073), Vector2(845, 1070), Vector2(860, 1067),
		Vector2(886, 1067), Vector2(886, 1136), Vector2(794, 1136)])
	var y0 := 1033.0
	var xl := 713.0 + (y0 - 957.0) * 8.0 / 124.0
	var xr := 819.0 + (y0 - 957.0) * 14.0 / 124.0
	var table := PackedVector2Array([Vector2(xl, y0), Vector2(xr, y0), Vector2(833, 1081), Vector2(721, 1081)])
	return [seat, _rect(718, 1079, 830, 1140), table, _rect(763, 1078, 785, 1137)]


## 자리마다 덮개 (DiningLogic.SEATS 순서)
static func polys_for(seat: int) -> Array:
	match seat:
		0, 1, 2, 3:
			return _counter_stool([517.0, 621.0, 722.0, 823.0][seat])
		4:
			return _shelf_below(627.0)
		5:
			return _shelf_below(773.0)
		6, 7:
			return _table_mid()
		8:
			return _back_chair(335, 856, 903, 958)
		9:
			return _back_chair(424, 856, 903, 958)
		10, 11:
			return _table_low()
		12:
			return _back_chair(248, 1103, 1157, 1190)
		13:
			return _back_chair(337, 1103, 1157, 1190)
		14:
			return _booth(true)
		15:
			return _booth(false)
	return []
