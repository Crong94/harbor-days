extends Node
## 폰 뒤로가기 (PC는 Esc). 오토로드 이름: BackButton. 예전엔 한 번만 눌러도 게임이 꺼졌다 (11-24 사용자).
##   1. 글자 입력 중이면 입력을 마친다
##   2. 열린 메뉴를 닫는다
##   3. 장면에 on_back()이 있고 true를 돌려주면 끝 (지도: 서랍, 창 닫기)
##   4. 보이는 "닫기" 단추, 없으면 "나가기" 단추를 누른다
##   5. 더 닫을 것이 없으면 안내를 띄우고 QUIT_SEC 안에 한 번 더 눌러야 꺼진다
## project.godot의 quit_on_go_back을 꺼 두어야 한다

const QUIT_SEC := 2.5
const EXIT_TEXTS := ["닫기", "나가기"]

var _armed := 0.0
var _layer: CanvasLayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(delta: float) -> void:
	if _armed > 0.0:
		_armed -= delta
		if _armed <= 0.0 and _layer:
			_layer.hide()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		press(true)


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not OS.has_feature("mobile"):
		press(false)


## can_quit: 폰에서만 두 번 누르면 끈다
func press(can_quit: bool) -> void:
	if _close_one():
		_armed = 0.0
		if _layer:
			_layer.hide()
		return
	if not can_quit:
		return
	if _armed > 0.0:
		get_tree().quit()
		return
	_armed = QUIT_SEC
	_show_hint()


## 무언가 하나 닫았으면 true
func _close_one() -> bool:
	var focus := get_viewport().gui_get_focus_owner()
	if focus is LineEdit:
		focus.release_focus()
		return true
	var scene := get_tree().current_scene
	if scene == null:
		return false
	for n in scene.find_children("*", "Control", true, false):
		if n is GameHeader and n.is_menu_open():
			n.close_menu()
			return true
	if scene.has_method("on_back") and scene.on_back():
		return true
	for t in EXIT_TEXTS:
		var b := find_button(scene, t)
		if b:
			b.pressed.emit()
			return true
	return false


## 보이고 눌리는 그 글자의 단추 가운데 가장 위(나중에 그려지는 것)
static func find_button(root: Node, text: String) -> Button:
	var found: Button = null
	for n in root.find_children("*", "Button", true, false):
		var b: Button = n
		if b.text == text and not b.disabled and b.is_visible_in_tree():
			found = b
	return found


func _show_hint() -> void:
	if _layer == null:
		_layer = CanvasLayer.new()
		_layer.layer = 100
		add_child(_layer)
		var holder := CenterContainer.new()
		holder.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
		holder.offset_top = -190
		holder.offset_bottom = -120
		holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_layer.add_child(holder)
		var panel := UiKit.glass_panel(22, UiKit.RADIUS_PILL, true)
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.add_child(panel)
		panel.add_child(UiKit.text("한 번 더 누르면 게임을 꺼요", "label", UiKit.FOAM, HORIZONTAL_ALIGNMENT_CENTER))
	_layer.show()
