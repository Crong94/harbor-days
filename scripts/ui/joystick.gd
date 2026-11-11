class_name Joystick
extends Control
## 투명 아날로그 조이스틱 (2026-11-11 사용자: 튀지 않게, 반투명 원판 위 흰 손잡이 하나).
## 원판 안을 누르고 밀면 손잡이가 손가락을 따라가고(원판 밖으로는 안 나감), 미는 쪽과 세기만큼 움직인다.
## 손을 떼면 손잡이가 가운데로 돌아가고 전체가 옅어진다. 판정을 보여 주는 조작 UI라 코드로 그린다.
## dir: 지금 방향과 세기 (길이 0~1)

signal changed(dir: Vector2)

const DEAD := 0.15 # 가운데 이만큼은 멈춤 (반지름 대비)
const KNOB := 0.36 # 손잡이 반지름 (원판 반지름 대비)
const IDLE_ALPHA := 0.45

var dir := Vector2.ZERO
var _touch := -2 # 누르고 있는 손가락 (-1은 마우스, -2는 없음)
var _knob := Vector2.ZERO # 가운데에서 손잡이까지 (화면 px)
var _alpha := IDLE_ALPHA


## 가운데에서 본 손가락 위치 → 방향과 세기 (원판 밖이면 길이 1, 가운데 DEAD 안은 0)
static func dir_from(offset: Vector2, radius: float) -> Vector2:
	var k := offset.length() / maxf(radius, 1.0)
	if k < DEAD:
		return Vector2.ZERO
	return offset.normalized() * minf(1.0, (k - DEAD) / (1.0 - DEAD))


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP


func _radius() -> float:
	return minf(size.x, size.y) / 2.0


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _touch == -2:
			_touch = event.index
			_aim(event.position)
		elif not event.pressed and event.index == _touch:
			_release()
		accept_event()
	elif event is InputEventScreenDrag and event.index == _touch:
		_aim(event.position)
		accept_event()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and _touch == -2:
			_touch = -1
			_aim(event.position)
		elif not event.pressed and _touch == -1:
			_release()
		accept_event()
	elif event is InputEventMouseMotion and _touch == -1:
		_aim(event.position)
		accept_event()


func _aim(p: Vector2) -> void:
	var r := _radius()
	var off := p - size / 2.0
	_knob = off.limit_length(r * (1.0 - KNOB * 0.6))
	var d := dir_from(off, r * (1.0 - KNOB * 0.6))
	if d != dir:
		dir = d
		changed.emit(dir)


func _release() -> void:
	_touch = -2
	if dir != Vector2.ZERO:
		dir = Vector2.ZERO
		changed.emit(dir)


func _process(delta: float) -> void:
	if _touch == -2:
		_knob = _knob.lerp(Vector2.ZERO, minf(1.0, delta * 14.0))
	var target := 0.85 if _touch != -2 else IDLE_ALPHA
	_alpha = move_toward(_alpha, target, delta * 3.0)
	modulate.a = _alpha
	queue_redraw()


func _draw() -> void:
	var c := size / 2.0
	var r := _radius()
	# 원판: 옅은 어두운 유리
	draw_circle(c, r, Color(0.08, 0.08, 0.14, 0.32))
	draw_arc(c, r - 1.5, 0.0, TAU, 64, Color(1, 1, 1, 0.22), 3.0, true)
	# 손잡이: 흰 동그라미, 아래 옅은 그림자, 가운데 작은 사방 표시
	var k := c + _knob
	var kr := r * KNOB
	draw_circle(k + Vector2(0, 4), kr, Color(0, 0, 0, 0.18))
	draw_circle(k, kr, Color(0.97, 0.97, 0.98))
	var mark := Color(0.45, 0.47, 0.55)
	var a := kr * 0.42
	for d in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
		var side := Vector2(-d.y, d.x)
		var tip: Vector2 = k + d * a
		draw_line(k + d * a * 0.25, tip, mark, 2.5, true)
		draw_colored_polygon(PackedVector2Array([tip + d * 4.0, tip - d * 3.0 + side * 5.0, tip - d * 3.0 - side * 5.0]), mark)
