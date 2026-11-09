extends Control
## 타이틀 화면. 세로 화면 위쪽에 제목, 아래쪽에 시작 버튼.
## 배경: bg_title (사용자에게 받음). 없으면 방파제 밤 그림(bg_fishing_night)을 쓴다.

const NEXT_SCENE := "res://scenes/prologue/resignation.tscn"
const VERSION := "v0.3"

var _bg: TextureRect


func _ready() -> void:
	var art := "bg_title" if ArtSlot.has_art("bg_title") else "bg_fishing_night"
	_bg = UiKit.cover_art(art)
	if _bg:
		add_child(_bg)
		_slow_zoom()
	add_child(UiKit.shade([[0.0, 0.7], [0.36, 0.0], [0.62, 0.0], [1.0, 0.92]]))

	# 위: 제목
	var top := UiKit.vbox(UiKit.SPACE_SM)
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top.offset_top = 150
	top.offset_bottom = 420
	add_child(top)
	var kicker := UiKit.text("물빛울포 이야기", "label", UiKit.SUN, HORIZONTAL_ALIGNMENT_CENTER)
	kicker.add_theme_constant_override("outline_size", 0)
	top.add_child(UiKit.shadowed(kicker, Color(0, 0, 0, 0.4), 1))
	var title := UiKit.shadowed(UiKit.text("오늘의 바다", "display", Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER), Color(UiKit.NAVY_DEEP, 0.6), 4)
	top.add_child(title)
	var sub := UiKit.shadowed(UiKit.text("물때 맞춰 삽니다", "h1", UiKit.FOAM_SOFT, HORIZONTAL_ALIGNMENT_CENTER), Color(0, 0, 0, 0.4), 2)
	sub.add_theme_font_override("font", UiKit.font("serif"))
	sub.add_theme_font_size_override("font_size", 26)
	top.add_child(sub)

	# 아래: 시작
	var bottom := UiKit.vbox(UiKit.SPACE_LG)
	bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_top = -330
	bottom.offset_bottom = -56
	bottom.alignment = BoxContainer.ALIGNMENT_END
	add_child(bottom)
	var start := UiKit.action("새로 시작")
	start.custom_minimum_size = Vector2(420, 64)
	start.add_theme_font_size_override("font_size", 22)
	start.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	start.pressed.connect(func():
		Sound.play_sfx("tap")
		UiKit.go_to(self, NEXT_SCENE))
	bottom.add_child(start)
	bottom.add_child(UiKit.gap(8))
	bottom.add_child(UiKit.text("오늘 잡은 물고기로 내일을 살아간다", "caption", UiKit.FOAM_SOFT, HORIZONTAL_ALIGNMENT_CENTER))
	bottom.add_child(UiKit.text(VERSION, "caption", Color(UiKit.FOAM, 0.4), HORIZONTAL_ALIGNMENT_CENTER))

	start.grab_focus()
	Sound.play_bgm("title")
	UiKit.fade_in(self, 1.0)
	UiKit.rise_in(top, 0.3, 24.0)
	UiKit.rise_in(bottom, 0.8, 24.0)


## 배경이 아주 천천히 다가왔다 멀어진다
func _slow_zoom() -> void:
	_bg.resized.connect(func(): _bg.pivot_offset = _bg.size / 2.0)
	var tw := create_tween().set_loops()
	tw.tween_property(_bg, "scale", Vector2(1.06, 1.06), 18.0).set_trans(Tween.TRANS_SINE)
	tw.tween_property(_bg, "scale", Vector2.ONE, 18.0).set_trans(Tween.TRANS_SINE)
