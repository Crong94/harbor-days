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
## 그림에서 화면에 보일 부분 (그림 크기 대비 0~1). 예: Rect2(0.1, 0, 0.8, 0.8)이면 아래쪽 20%를 잘라 내고 확대한다
var art_view := Rect2(0, 0, 1, 1)
var _blend_tex: Texture2D

## 시간표: [시각(분), 그림 id]를 시각 순서로. 있으면 art_base, art_blend 대신 쓴다.
## 이웃한 두 그림 사이를 시각에 따라 서서히 겹쳐 바꾼다 (자정을 넘어 이어진다).
var art_schedule: Array = []
var _sched_tex: Array = [] # [시각, Texture2D]

## 낚시 화면 시간표 (북쪽 방파제, 동쪽 바다). 같은 시각이 두 번 나오면 그 사이는 한 그림으로 머문다
const FISHING_SCHEDULE := [
	[0, "bg_fishing_night_v"], [4 * 60, "bg_fishing_night_v"],
	[5 * 60, "bg_fishing_dawn_v"], [5 * 60 + 45, "bg_fishing_dawn_v"],
	[7 * 60 + 15, "bg_fishing_morning_v"], [16 * 60 + 30, "bg_fishing_morning_v"],
	[18 * 60, "bg_fishing_evening_v"], [19 * 60, "bg_fishing_evening_v"],
	[20 * 60, "bg_fishing_night_v"],
]


## 시각에 따른 두 그림과 섞는 정도: [앞 그림 번호, 뒤 그림 번호, 0~1]
static func schedule_mix(sched: Array, m: float) -> Array:
	m = fposmod(m, 24.0 * 60.0)
	var n := sched.size()
	for i in n:
		var a: Array = sched[i]
		var b: Array = sched[(i + 1) % n]
		var t0: float = a[0]
		var t1: float = b[0] if i + 1 < n else b[0] + 24.0 * 60.0
		if m >= t0 and m < t1:
			var k := 0.0 if t1 <= t0 else (m - t0) / (t1 - t0)
			return [i, (i + 1) % n, k if a[1] != b[1] else 0.0]
	return [0, 0, 0.0]


## 해: 배경과 따로 받은 해 그림(sun.png)을 시각(minutes)에 따라 움직인다.
## 새벽에는 산 바로 위에서 서서히 나타나며(투명도) 떠오르고, 저녁에는 서서히 사라지며 진다. 잘린 해는 보이지 않는다.
## 좌표는 배경 그림 크기 대비 비율. sun_art가 비어 있으면 해를 그리지 않는다.
var sun_art := ""
var minutes := -1.0
var sun_size := 0.17 # 해 그림(빛무리 포함) 크기, 화면 가로 대비
var _sun_tex: Texture2D
var _sun_node: Control # 해는 물결 셰이더가 안 먹게 자식 노드에 그린다

## 물결: 배경 그림의 바다 부분(그림 세로 비율 x 위 ~ y 아래)을 셰이더로 일렁이게 한다. ZERO면 끈다
var water_band := Vector2.ZERO
const WATER_SHADER := "res://scripts/ui/sea_water.gdshader"


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if mode == Mode.DAWN and art_base.is_empty():
		art_base = "bg_breakwater_dawn"
		art_blend = "bg_breakwater_morning"
	if not art_base.is_empty() and ArtSlot.has_art(art_base):
		_base_tex = load(ArtSlot.art_path(art_base))
	if not art_blend.is_empty() and ArtSlot.has_art(art_blend):
		_blend_tex = load(ArtSlot.art_path(art_blend))
	for e in art_schedule:
		if ArtSlot.has_art(e[1]):
			_sched_tex.append([e[0], load(ArtSlot.art_path(e[1]))])
	if not _sched_tex.is_empty() and _base_tex == null:
		_base_tex = _sched_tex[0][1] # 크기 계산(art_point)과 물결 셰이더 켜기에 쓴다
	if not sun_art.is_empty() and ArtSlot.has_art(sun_art):
		_sun_tex = load(ArtSlot.art_path(sun_art))
		_sun_node = Control.new()
		_sun_node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_sun_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_sun_node.draw.connect(_draw_sun)
		add_child(_sun_node)
	if _base_tex and water_band != Vector2.ZERO:
		var mat := ShaderMaterial.new()
		mat.shader = load(WATER_SHADER)
		mat.set_shader_parameter("water_top", water_band.x)
		mat.set_shader_parameter("water_bottom", water_band.y)
		material = mat


## 시각(자정부터 분)에 따른 해 위치 (배경 그림 비율). z는 0이면 산 아래로 완전히 숨음.
## 05:00 산 뒤에서 떠올라 11:00 오른쪽 위 높이까지 오르고, 17:30부터 오른쪽 끝으로 내려가 19:30에 진다.
static func sun_path(m: float) -> Vector3:
	# 방향: 북쪽 방파제 끝에서 동쪽 바다를 본다. 화면 왼쪽이 북쪽, 오른쪽이 남쪽, 등 뒤가 서쪽.
	# 해는 정면(동쪽) 수평선 바로 위에서 서서히 나타나 떠오르고, 남쪽(오른쪽 위)으로 높이 올라가다
	# 정오 무렵 머리 위를 지나 등 뒤(서쪽)로 넘어가며 화면 위로 사라진다. 저녁 해넘이는 등 뒤라 보이지 않는다.
	m = fposmod(m, 24.0 * 60.0)
	var low := Vector2(0.55, 0.285) # 산 바로 위 (해가 처음 나타나는 자리)
	var gone := Vector2(0.92, -0.06) # 화면 위로 넘어간 자리
	var start := 5 * 60 + 15.0
	var end := 13 * 60.0
	if m < start:
		return Vector3(low.x, low.y, 0.0)
	if m >= end:
		return Vector3(gone.x, gone.y, 0.0)
	var k := (m - start) / (end - start)
	var e := 1.0 - pow(1.0 - k, 1.6) # 처음엔 빠르게 떠오르고 점점 느리게
	var fade_in := clampf((m - start) / 30.0, 0.0, 1.0)
	var fade_out := clampf((end - m) / 50.0, 0.0, 1.0)
	return Vector3(lerpf(low.x, gone.x, k), lerpf(low.y, gone.y, e), minf(fade_in, fade_out))


func has_art() -> bool:
	return _base_tex != null


## 배경 그림 위의 비율 위치(0~1)를 화면 좌표로 바꾼다. 그림이 없으면 화면 비율 그대로.
func art_point(norm: Vector2) -> Vector2:
	if not _base_tex:
		return norm * size
	var r := _cover_rect(_base_tex)
	return r.position + norm * r.size


## 화면을 꽉 채우도록 비율을 유지해 늘린 그림 전체의 영역. art_view 부분이 화면 가운데에 꽉 찬다
func _cover_rect(tex: Texture2D) -> Rect2:
	var ts := tex.get_size()
	var vs := ts * art_view.size
	var k := maxf(size.x / vs.x, size.y / vs.y)
	var view_pos := (size - vs * k) / 2.0
	return Rect2(view_pos - art_view.position * ts * k, ts * k)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()
	if _sun_node:
		_sun_node.queue_redraw()


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
	if not _sched_tex.is_empty() and minutes >= 0.0:
		var mix := schedule_mix(_sched_tex, minutes)
		var ta: Texture2D = _sched_tex[mix[0]][1]
		var tb: Texture2D = _sched_tex[mix[1]][1]
		draw_texture_rect(ta, _cover_rect(ta), false)
		if mix[2] > 0.0 and tb != ta:
			draw_texture_rect(tb, _cover_rect(tb), false, Color(1, 1, 1, mix[2]))
		return
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


## 해 그림을 산 위쪽만 보이게 잘라 그린다. 새벽에는 주황빛, 밝아지면 흰빛
func _draw_sun() -> void:
	if _sun_tex == null or minutes < 0.0:
		return
	var p := sun_path(minutes)
	if p.z <= 0.0:
		return
	var c := art_point(Vector2(p.x, p.y))
	var sz := size.x * sun_size
	var tint := Color(1.0, 0.72, 0.5).lerp(Color.WHITE, clampf(brightness, 0.0, 1.0))
	tint.a = p.z
	_sun_node.draw_texture_rect(_sun_tex, Rect2(c - Vector2(sz, sz) / 2.0, Vector2(sz, sz)), false, tint)


func _vertical_gradient(rect: Rect2, top: Color, bottom: Color, steps: int) -> void:
	var step_h := rect.size.y / steps
	for i in steps:
		var c := top.lerp(bottom, float(i) / (steps - 1))
		draw_rect(Rect2(rect.position.x, rect.position.y + i * step_h, rect.size.x, step_h + 1), c)
