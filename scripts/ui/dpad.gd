class_name DPad
extends Control
## 콘솔 십자키 (2026-11-11 사용자 요청: 키보드 화살표 대신 요즘 콘솔 방향키 모양, 손 떼면 투명).
## 한 덩어리 십자 모양. 누른 채 손가락을 미끄러뜨리면 방향이 바뀌고 대각선도 된다.
## 안 누를 때는 거의 투명, 누르는 동안 또렷해지고 누른 쪽 팔이 눌려 들어간다.
## dir: 지금 방향 (-1~1, 대각선은 길이 1로 줄인 값)

signal changed(dir: Vector2)

const ARM := 0.36 # 십자 팔 굵기 (지름 대비)
const DEAD := 0.18 # 가운데 이만큼은 방향 없음 (반지름 대비)
const IDLE_ALPHA := 0.28

var dir := Vector2.ZERO
var _touch := -2 # 누르고 있는 손가락 (-1은 마우스, -2는 없음)
var _alpha := IDLE_ALPHA


## 십자 가운데에서 본 손가락 위치 → 방향 (8방향)
static func dir_from(offset: Vector2, radius: float) -> Vector2:
	if offset.length() < radius * DEAD:
		return Vector2.ZERO
	var a := snappedf(offset.angle(), PI / 4.0)
	var d := Vector2.from_angle(a)
	return Vector2(roundf(d.x), roundf(d.y)).normalized()


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
	var d := dir_from(p - size / 2.0, _radius())
	if d != dir:
		if d != Vector2.ZERO:
			Haptics.play("tick")
		dir = d
		changed.emit(dir)


func _release() -> void:
	_touch = -2
	if dir != Vector2.ZERO:
		dir = Vector2.ZERO
		changed.emit(dir)


func _process(delta: float) -> void:
	var target := 1.0 if _touch != -2 else IDLE_ALPHA
	_alpha = move_toward(_alpha, target, delta * (8.0 if target > _alpha else 2.5))
	modulate.a = _alpha
	queue_redraw()


func _draw() -> void:
	var c := size / 2.0
	var r := _radius()
	var w := r * 2.0 * ARM
	var face := UiKit.TEAL_BTN
	var lip := 6.0
	# 십자 한 덩어리: 외곽선, 아래 턱, 윗면 순서
	for layer in 3:
		var grow := 3.0 if layer == 0 else 0.0
		var off := Vector2(0, lip) if layer < 2 else Vector2.ZERO
		var col: Color = [UiKit.OUTLINE, face.darkened(0.3), face][layer]
		var rad := int(w * 0.28)
		draw_style_box(UiKit.box(col, rad, Color.TRANSPARENT, 0, 0), Rect2(c + off - Vector2(w / 2.0 + grow, r + grow), Vector2(w + grow * 2.0, r * 2.0 + grow * 2.0)))
		draw_style_box(UiKit.box(col, rad, Color.TRANSPARENT, 0, 0), Rect2(c + off - Vector2(r + grow, w / 2.0 + grow), Vector2(r * 2.0 + grow * 2.0, w + grow * 2.0)))
	# 누른 쪽 팔은 눌려 들어가 어둡게
	if dir != Vector2.ZERO:
		for axis in [Vector2(dir.x, 0), Vector2(0, dir.y)]:
			if axis == Vector2.ZERO:
				continue
			var mid: Vector2 = c + axis * r * 0.62 + Vector2(0, lip * 0.6)
			var ext := Vector2(r * 0.68, w) if axis.y == 0.0 else Vector2(w, r * 0.68)
			draw_style_box(UiKit.box(face.darkened(0.16), int(w * 0.28), Color.TRANSPARENT, 0, 0), Rect2(mid - ext / 2.0, ext))
	# 팔 끝 작은 세모와 가운데 오목한 원
	for d in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
		var tip: Vector2 = c + d * r * 0.72
		var side := Vector2(-d.y, d.x)
		var pressed: bool = (d.x != 0.0 and signf(dir.x) == d.x) or (d.y != 0.0 and signf(dir.y) == d.y)
		var o := Vector2(0, lip * 0.6) if pressed else Vector2.ZERO
		draw_colored_polygon(PackedVector2Array([tip + o + d * 9.0, tip + o - d * 6.0 + side * 10.0, tip + o - d * 6.0 - side * 10.0]), Color(1, 1, 1, 0.85))
	draw_circle(c, w * 0.26, face.darkened(0.12))
