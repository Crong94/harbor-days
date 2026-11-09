extends Control
## 타이틀 화면.

const NEXT_SCENE := "res://scenes/prologue/resignation.tscn"


func _ready() -> void:
	var bg := SeaBackdrop.new()
	bg.mode = SeaBackdrop.Mode.DUSK
	add_child(bg)

	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.alignment = BoxContainer.ALIGNMENT_BEGIN
	add_child(root)

	var top_space := Control.new()
	top_space.custom_minimum_size.y = 110
	root.add_child(top_space)

	var title := UiKit.shadowed(UiKit.label("오늘의 바다", UiKit.SIZE_TITLE, UiKit.CREAM, HORIZONTAL_ALIGNMENT_CENTER), Color(UiKit.NAVY_DEEP, 0.55), 4)
	root.add_child(title)

	var subtitle := UiKit.shadowed(UiKit.label("물때 맞춰 삽니다", 28, UiKit.CREAM, HORIZONTAL_ALIGNMENT_CENTER), Color(UiKit.NAVY_DEEP, 0.5), 2)
	root.add_child(subtitle)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(spacer)

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 16)
	root.add_child(buttons)

	var start := UiKit.button("새로 시작")
	start.pressed.connect(func(): UiKit.go_to(self, NEXT_SCENE))
	buttons.add_child(start)

	var footer := UiKit.label("오늘 잡은 물고기로 내일을 살아간다", UiKit.SIZE_SMALL, Color(UiKit.CREAM, 0.75), HORIZONTAL_ALIGNMENT_CENTER)
	var footer_margin := MarginContainer.new()
	footer_margin.add_theme_constant_override("margin_top", 24)
	footer_margin.add_theme_constant_override("margin_bottom", 36)
	footer_margin.add_child(footer)
	root.add_child(footer_margin)

	start.grab_focus()
	UiKit.fade_in(self, 1.0)
