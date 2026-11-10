class_name FishLine
extends RefCounted
## 공책 위 생선 한 줄 (여울 수첩 보관 탭 FishLine): 그림 · 이름과 크기, 값 · 신선도 단계와 막대 · 오른쪽 단추.
## 수산시장과 메뉴 가방에서 같이 쓴다.

## 신선도 단계: 잡은 날이면 "오늘 잡음"(초록, 막대 가득), 하루 지나면 "오늘 밤 상함"(금빛, 막대 반)
static func stage(entry: Dictionary, today: int) -> Dictionary:
	var age := today - int(entry.get("day", today))
	if age <= 0:
		return {"name": "오늘 잡음", "color": UiKit.GREEN_FRESH, "fill": 1.0}
	return {"name": "오늘 밤 상함", "color": UiKit.GOLD, "fill": 0.45}


## sub: 값 줄 글자 (예: "6,200원"). note: 그 옆 작은 강조 (예: "시장이 나아요"). right: 오른쪽 단추나 상태 표시
static func make(entry: Dictionary, today: int, sub: String, note := "", right: Control = null) -> PanelContainer:
	var row := UiKit.note_row()
	var h: HBoxContainer = row.get_child(0)
	var icon := UiKit.icon_rect("fish_" + entry.id, 50)
	if icon:
		icon.custom_minimum_size = Vector2(84, 50)
		h.add_child(icon)
	var text := UiKit.vbox(-2)
	text.alignment = BoxContainer.ALIGNMENT_CENTER
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var title := UiKit.text("%s %.1fcm" % [FishDB.get_fish(entry.id).name, entry.size], "title", UiKit.NOTE_INK)
	title.add_theme_font_size_override("font_size", 23)
	text.add_child(title)
	var line := UiKit.hbox(8)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var val := UiKit.text(sub, "body", UiKit.NOTE_INK_SOFT)
	val.add_theme_font_size_override("font_size", 18)
	line.add_child(val)
	if not note.is_empty():
		var n := UiKit.text(note, "body", UiKit.TEAL_BTN)
		n.add_theme_font_override("font", UiKit.font("bold"))
		n.add_theme_font_size_override("font_size", 16)
		line.add_child(n)
	text.add_child(line)
	h.add_child(text)
	var st := stage(entry, today)
	var fresh := UiKit.vbox(4)
	fresh.alignment = BoxContainer.ALIGNMENT_CENTER
	fresh.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fresh.add_child(UiKit.stage_chip(st.name, st.color, UiKit.NOTE_INK))
	fresh.add_child(UiKit.fresh_bar(st.fill, st.color))
	h.add_child(fresh)
	if right:
		h.add_child(right)
	return row
