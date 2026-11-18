class_name Shop4Prop
extends Control
## 식당 4안 물건 한 장 (Shop4). DiningFloor가 손님과 함께 key 순서로 줄 세운다.
## polys가 있으면 그림 전체가 아니라 그 모양(바탕 px)만 그린다. 손님 앞에 와야 할 스툴 아랫부분,
## 칸막이 테이블 아랫부분, 앞벽 들보를 손님 위에 한 번 더 덮을 때 쓴다.

var dining # DiningFloor (타입을 적으면 헤드리스 시험에서 GameState까지 끌려온다)
var tex: Texture2D
var rect := Rect2() # 바탕 px
var key := 0.0
var tint := Color.WHITE
var polys: Array = [] # [PackedVector2Array] 바탕 px


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if dining:
		dining.resized.connect(queue_redraw)


func _draw() -> void:
	if dining == null or tex == null:
		return
	var a: Vector2 = dining.to_screen(rect.position / Shop4.SIZE)
	var b: Vector2 = dining.to_screen(rect.end / Shop4.SIZE)
	if polys.is_empty():
		draw_texture_rect(tex, Rect2(a, b - a), false, tint)
		return
	for poly in polys:
		var pts := PackedVector2Array()
		var uvs := PackedVector2Array()
		for p in poly:
			var q := Vector2(clampf(p.x, rect.position.x, rect.end.x), clampf(p.y, rect.position.y, rect.end.y))
			pts.append(dining.to_screen(q / Shop4.SIZE))
			uvs.append((q - rect.position) / rect.size)
		draw_polygon(pts, PackedColorArray([tint]), uvs, tex)
