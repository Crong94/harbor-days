class_name KeyboardLift
extends Node
## 폰 자판이 올라와 입력 칸을 가리면 화면을 그만큼 위로 민다. 자판이 내려가면 제자리로.
## 쓰는 법: add_child(KeyboardLift.make(self, 입력칸))

const GAP := 110.0 # 입력 칸 아래 안내 글까지 보이게

var screen: Control
var edit: LineEdit


static func make(s: Control, e: LineEdit) -> KeyboardLift:
	var k := KeyboardLift.new()
	k.screen = s
	k.edit = e
	return k


## 입력 칸 아래 끝 bottom이 자판(높이 kb) 위로 올라오게 밀 거리
static func lift(bottom: float, view_h: float, kb: float) -> float:
	return 0.0 if kb <= 0.0 else maxf(0.0, bottom + GAP - (view_h - kb))


func _process(delta: float) -> void:
	if not is_instance_valid(edit) or not DisplayServer.has_feature(DisplayServer.FEATURE_VIRTUAL_KEYBOARD):
		return
	var view_h := screen.get_viewport_rect().size.y
	var win_h := maxf(1.0, float(DisplayServer.window_get_size().y))
	var kb := DisplayServer.virtual_keyboard_get_height() * view_h / win_h if edit.has_focus() else 0.0
	var bottom := edit.get_global_rect().end.y - screen.position.y
	screen.position.y = lerpf(screen.position.y, -lift(bottom, view_h, kb), minf(1.0, delta * 14.0))
