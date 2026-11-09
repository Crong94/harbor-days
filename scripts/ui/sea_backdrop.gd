class_name SeaBackdrop
extends Control
## 코드로 그리는 물빛울포 바다 배경. 하늘, 해, 바다 물결, 방파제와 빨간 등대.
## 실제 일러스트가 나오기 전까지 쓰는 임시 배경이다.

enum Mode { DUSK, NIGHT }

var mode := Mode.DUSK
var _t := 0.0

const HORIZON := 0.6 # 화면 높이 대비 수평선 위치


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _palette() -> Dictionary:
	if mode == Mode.NIGHT:
		return {
			"sky_top": Color("0d1b2e"), "sky_bottom": Color("2a3f63"),
			"sea_top": Color("1a3550"), "sea_bottom": Color("0a1626"),
			"sun": Color("f3ecd2"), "wave": Color(0.45, 0.85, 1.0, 0.55),
		}
	return {
		"sky_top": Color("6d8fb3"), "sky_bottom": Color("f4b39a"),
		"sea_top": Color("3a9a97"), "sea_bottom": Color("1d4f63"),
		"sun": Color("ffd9a0"), "wave": Color(1, 0.93, 0.85, 0.45),
	}


func _draw() -> void:
	var w := size.x
	var h := size.y
	var hy := h * HORIZON
	var p := _palette()

	_vertical_gradient(Rect2(0, 0, w, hy), p.sky_top, p.sky_bottom, 48)

	# 해 또는 달
	var sun_pos := Vector2(w * 0.3, hy - h * 0.06)
	draw_circle(sun_pos, h * 0.11, Color(p.sun, 0.18))
	draw_circle(sun_pos, h * 0.07, p.sun)

	# 먼 산
	var hills := PackedVector2Array([Vector2(0, hy)])
	for i in 13:
		var x := w * i / 12.0
		hills.append(Vector2(x, hy - h * (0.05 + 0.035 * sin(i * 1.7) + 0.02 * cos(i * 0.6))))
	hills.append(Vector2(w, hy))
	draw_colored_polygon(hills, Color(p.sky_top.darkened(0.35), 0.85))

	_vertical_gradient(Rect2(0, hy, w, h - hy), p.sea_top, p.sea_bottom, 32)

	# 해 반사광
	for i in 7:
		var y := hy + 10 + i * 14
		var half := (w * 0.06) * (1.0 - i * 0.1) * (0.8 + 0.2 * sin(_t * 1.5 + i))
		draw_line(Vector2(sun_pos.x - half, y), Vector2(sun_pos.x + half, y), Color(p.sun, 0.35), 3)

	# 물결
	for row in 6:
		var y0 := hy + (h - hy) * (0.15 + row * 0.15)
		var pts := PackedVector2Array()
		for i in 41:
			var x := w * i / 40.0
			pts.append(Vector2(x, y0 + sin(x * 0.02 + _t * (0.8 + row * 0.15) + row) * (3 + row)))
		draw_polyline(pts, p.wave, 2.0, true)

	_draw_breakwater_and_lighthouse(w, h, hy)


func _draw_breakwater_and_lighthouse(w: float, h: float, hy: float) -> void:
	var stone := Color("5b5f66") if mode == Mode.DUSK else Color("2b3240")
	var wall := PackedVector2Array([
		Vector2(w * 0.62, hy + h * 0.03), Vector2(w, hy - h * 0.0),
		Vector2(w, hy + h * 0.06), Vector2(w * 0.6, hy + h * 0.06),
	])
	draw_colored_polygon(wall, stone)

	var base := Vector2(w * 0.86, hy + h * 0.005)
	var tower_h := h * 0.26
	var bw := h * 0.045
	var tw := h * 0.03
	var red := Color("c8402f") if mode == Mode.DUSK else Color("8a2e25")
	var tower := PackedVector2Array([
		base + Vector2(-bw, 0), base + Vector2(bw, 0),
		base + Vector2(tw, -tower_h), base + Vector2(-tw, -tower_h),
	])
	draw_colored_polygon(tower, red)
	# 흰 띠
	for k in 2:
		var y1 := tower_h * (0.3 + k * 0.32)
		var y2 := y1 + tower_h * 0.08
		var lerp1: float = lerp(bw, tw, y1 / tower_h)
		var lerp2: float = lerp(bw, tw, y2 / tower_h)
		draw_colored_polygon(PackedVector2Array([
			base + Vector2(-lerp1, -y1), base + Vector2(lerp1, -y1),
			base + Vector2(lerp2, -y2), base + Vector2(-lerp2, -y2),
		]), Color("f3eee4"))
	# 등명부
	var top := base + Vector2(0, -tower_h)
	draw_rect(Rect2(top.x - tw * 1.1, top.y - h * 0.035, tw * 2.2, h * 0.035), Color("2b2a28"))
	var glow := 0.6 + 0.4 * sin(_t * 2.0)
	draw_circle(top + Vector2(0, -h * 0.018), h * 0.012, Color(1, 0.92, 0.6, 0.9))
	if mode == Mode.NIGHT:
		draw_circle(top + Vector2(0, -h * 0.018), h * 0.05, Color(1, 0.9, 0.55, 0.15 * glow))


func _vertical_gradient(rect: Rect2, top: Color, bottom: Color, steps: int) -> void:
	var step_h := rect.size.y / steps
	for i in steps:
		var c := top.lerp(bottom, float(i) / (steps - 1))
		draw_rect(Rect2(rect.position.x, rect.position.y + i * step_h, rect.size.x, step_h + 1), c)
