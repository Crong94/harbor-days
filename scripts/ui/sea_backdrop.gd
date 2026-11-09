class_name SeaBackdrop
extends Control
## 코드로 그리는 물빛울포 바다 배경. 하늘, 해, 별, 바다 물결, 방파제와 빨간 등대.
## 실제 일러스트가 나오기 전까지 쓰는 임시 배경이다.
## DAWN 모드에서는 brightness(0 어두운 새벽 ~ 1 해 뜬 아침)에 따라 하늘이 밝아진다.

enum Mode { DUSK, NIGHT, DAWN }

const HORIZON := 0.6 # 화면 높이 대비 수평선 위치
const WALL_START := 0.62 # 방파제가 시작되는 x 비율

const _DUSK := {
	"sky_top": Color("6d8fb3"), "sky_bottom": Color("f4b39a"),
	"sea_top": Color("3a9a97"), "sea_bottom": Color("1d4f63"),
	"sun": Color("ffd9a0"), "wave": Color(1, 0.93, 0.85, 0.45),
	"hill": Color("47546e"), "stone": Color("5b5f66"), "red": Color("c8402f"),
}
const _NIGHT := {
	"sky_top": Color("0d1b2e"), "sky_bottom": Color("2a3f63"),
	"sea_top": Color("1a3550"), "sea_bottom": Color("0a1626"),
	"sun": Color("f3ecd2"), "wave": Color(0.45, 0.85, 1.0, 0.55),
	"hill": Color("0f1a2a"), "stone": Color("2b3240"), "red": Color("8a2e25"),
}
const _DAWN_DARK := {
	"sky_top": Color("1a2340"), "sky_bottom": Color("b9798a"),
	"sea_top": Color("2b4664"), "sea_bottom": Color("121f33"),
	"sun": Color("ffb98a"), "wave": Color(0.85, 0.85, 1.0, 0.32),
	"hill": Color("1d2338"), "stone": Color("343a4a"), "red": Color("9a3428"),
}
const _MORNING := {
	"sky_top": Color("86b5d9"), "sky_bottom": Color("f9dcc0"),
	"sea_top": Color("43a3a2"), "sea_bottom": Color("1f5a6c"),
	"sun": Color("fff1cc"), "wave": Color(1, 1, 1, 0.45),
	"hill": Color("5b6f86"), "stone": Color("62666d"), "red": Color("cc4431"),
}

var mode := Mode.DUSK
var brightness := 0.0
var _t := 0.0

## 사용자에게 받은 배경 그림. 있으면 코드로 그린 임시 배경 대신 이 그림을 쓴다.
## art_base는 기본 그림, art_blend는 brightness만큼 위에 겹치는 그림 (예: 새벽 → 아침).
var art_base := ""
var art_blend := ""
var _base_tex: Texture2D
var _blend_tex: Texture2D


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if mode == Mode.DAWN and art_base.is_empty():
		art_base = "bg_breakwater_dawn"
		art_blend = "bg_breakwater_morning"
	if not art_base.is_empty() and ArtSlot.has_art(art_base):
		_base_tex = load(ArtSlot.ART_DIR + art_base + ".png")
	if not art_blend.is_empty() and ArtSlot.has_art(art_blend):
		_blend_tex = load(ArtSlot.ART_DIR + art_blend + ".png")


func has_art() -> bool:
	return _base_tex != null


## 화면을 꽉 채우도록 비율을 유지해 늘린 영역
func _cover_rect(tex: Texture2D) -> Rect2:
	var ts := tex.get_size()
	var k := maxf(size.x / ts.x, size.y / ts.y)
	var ds := ts * k
	return Rect2((size - ds) / 2.0, ds)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func horizon_y() -> float:
	return size.y * HORIZON


## 방파제 윗면의 y 좌표. 캐릭터를 세울 때 쓴다.
func breakwater_top_y(x: float) -> float:
	var hy := horizon_y()
	var x0 := size.x * WALL_START
	var k := clampf((x - x0) / (size.x - x0), 0.0, 1.0)
	return lerpf(hy + size.y * 0.03, hy, k)


func _palette() -> Dictionary:
	match mode:
		Mode.NIGHT:
			return _NIGHT
		Mode.DAWN:
			var out := {}
			var b := clampf(brightness, 0.0, 1.0)
			for k in _DAWN_DARK:
				out[k] = (_DAWN_DARK[k] as Color).lerp(_MORNING[k], b)
			return out
	return _DUSK


func _draw() -> void:
	if _base_tex:
		draw_texture_rect(_base_tex, _cover_rect(_base_tex), false)
		if _blend_tex and brightness > 0.0:
			draw_texture_rect(_blend_tex, _cover_rect(_blend_tex), false, Color(1, 1, 1, clampf(brightness, 0.0, 1.0)))
		return
	var w := size.x
	var h := size.y
	var hy := horizon_y()
	var p := _palette()

	_vertical_gradient(Rect2(0, 0, w, hy), p.sky_top, p.sky_bottom, 48)

	# 별 (새벽 초반과 밤)
	var star_alpha := 0.0
	if mode == Mode.NIGHT:
		star_alpha = 0.8
	elif mode == Mode.DAWN:
		star_alpha = clampf(0.8 - brightness * 1.6, 0.0, 0.8)
	if star_alpha > 0.0:
		var srng := RandomNumberGenerator.new()
		srng.seed = 7
		for i in 45:
			var sp := Vector2(srng.randf() * w, srng.randf() * hy * 0.7)
			var tw := 0.6 + 0.4 * sin(_t * 2.0 + i)
			draw_circle(sp, 1.0 + srng.randf() * 1.2, Color(1, 1, 1, star_alpha * tw))

	# 해 (새벽에는 수평선 아래에서 떠오른다)
	var sun_pos := Vector2(w * 0.3, hy - h * 0.06)
	if mode == Mode.DAWN:
		sun_pos = Vector2(w * 0.32, lerpf(hy + h * 0.06, hy - h * 0.13, brightness))
	draw_circle(sun_pos, h * 0.11, Color(p.sun, 0.18))
	draw_circle(sun_pos, h * 0.07, p.sun)

	# 먼 산
	var hills := PackedVector2Array([Vector2(0, hy)])
	for i in 13:
		var x := w * i / 12.0
		hills.append(Vector2(x, hy - h * (0.05 + 0.035 * sin(i * 1.7) + 0.02 * cos(i * 0.6))))
	hills.append(Vector2(w, hy))
	draw_colored_polygon(hills, Color(p.hill, 0.9))

	_vertical_gradient(Rect2(0, hy, w, h - hy), p.sea_top, p.sea_bottom, 32)

	# 해 반사광
	if sun_pos.y < hy + h * 0.02:
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

	_draw_breakwater_and_lighthouse(w, h, hy, p)


func _draw_breakwater_and_lighthouse(w: float, h: float, hy: float, p: Dictionary) -> void:
	var wall := PackedVector2Array([
		Vector2(w * WALL_START, hy + h * 0.03), Vector2(w, hy),
		Vector2(w, hy + h * 0.06), Vector2(w * (WALL_START - 0.02), hy + h * 0.06),
	])
	draw_colored_polygon(wall, p.stone)

	var base := Vector2(w * 0.86, breakwater_top_y(w * 0.86) + 2)
	var tower_h := h * 0.26
	var bw := h * 0.045
	var tw := h * 0.03
	var tower := PackedVector2Array([
		base + Vector2(-bw, 0), base + Vector2(bw, 0),
		base + Vector2(tw, -tower_h), base + Vector2(-tw, -tower_h),
	])
	draw_colored_polygon(tower, p.red)
	for k in 2:
		var y1 := tower_h * (0.3 + k * 0.32)
		var y2 := y1 + tower_h * 0.08
		var a := lerpf(bw, tw, y1 / tower_h)
		var b := lerpf(bw, tw, y2 / tower_h)
		draw_colored_polygon(PackedVector2Array([
			base + Vector2(-a, -y1), base + Vector2(a, -y1),
			base + Vector2(b, -y2), base + Vector2(-b, -y2),
		]), Color("f3eee4"))
	var top := base + Vector2(0, -tower_h)
	draw_rect(Rect2(top.x - tw * 1.1, top.y - h * 0.035, tw * 2.2, h * 0.035), Color("2b2a28"))
	draw_circle(top + Vector2(0, -h * 0.018), h * 0.012, Color(1, 0.92, 0.6, 0.9))

	# 어두울 때 등대 불빛
	var dark := 1.0 if mode == Mode.NIGHT else (clampf(1.0 - brightness * 1.5, 0.0, 1.0) if mode == Mode.DAWN else 0.0)
	if dark > 0.0:
		var glow := 0.6 + 0.4 * sin(_t * 2.0)
		draw_circle(top + Vector2(0, -h * 0.018), h * 0.05, Color(1, 0.9, 0.55, 0.18 * glow * dark))


func _vertical_gradient(rect: Rect2, top: Color, bottom: Color, steps: int) -> void:
	var step_h := rect.size.y / steps
	for i in steps:
		var c := top.lerp(bottom, float(i) / (steps - 1))
		draw_rect(Rect2(rect.position.x, rect.position.y + i * step_h, rect.size.x, step_h + 1), c)
