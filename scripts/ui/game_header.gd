class_name GameHeader
extends Control
## 화면 맨 위 공통 헤더. 날짜와 시각, 오늘의 바다(날씨, 물때), 돈, 메뉴 버튼.
## 메뉴 버튼을 누르면 아래에서 메뉴 시트(GameMenu)가 올라온다.
##
## 쓰는 법: var h := GameHeader.new(); add_child(h)
##   - 시각: 장면이 시간을 직접 굴리면 set_minutes(분), 아니면 GameState.time_minutes를 보여 준다
##   - set_badge("3마리"): 돈 옆 작은 배지 (빈 문자열이면 숨김)
##   - refresh(): 돈이나 날짜가 바뀌었을 때
##   - is_menu_open(): 메뉴가 열려 있는 동안 장면 입력과 시간을 멈출 때 쓴다
## 이 노드는 화면 전체를 덮지만 클릭은 막지 않는다. 메뉴는 CanvasLayer로 맨 위에 뜬다.

signal menu_toggled(open: bool)
signal gear_changed

## 휴대폰 위쪽 노치와 상태 표시줄을 피하는 여백
const TOP_PAD := 26.0
const BAR_H := 70.0
## 헤더 아래 끝 y. 헤더 밑에 놓을 것들은 이 아래부터
const BOTTOM := TOP_PAD + BAR_H

var _bar: PanelContainer
var _date: Label
var _clock: Label
var _sea: Label
var _money: Label
var _badge: PanelContainer
var _menu: GameMenu
var _minutes := -1.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_bar = PanelContainer.new()
	var s := UiKit.chunky(UiKit.PAPER, UiKit.RADIUS_LG, 0, 4)
	s.content_margin_left = 18
	s.content_margin_right = 10
	s.content_margin_top = 6
	s.content_margin_bottom = 10
	_bar.add_theme_stylebox_override("panel", s)
	_bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_bar.offset_left = 14
	_bar.offset_right = -14
	_bar.offset_top = TOP_PAD
	_bar.offset_bottom = BOTTOM
	_bar.mouse_filter = Control.MOUSE_FILTER_STOP # 헤더를 눌러도 뒤 장면(낚시)으로 입력이 새지 않게
	add_child(_bar)

	var h := UiKit.hbox(UiKit.SPACE_SM)
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bar.add_child(h)

	# 왼쪽: 날짜와 시각 / 날씨와 물때
	var left := UiKit.vbox(-2)
	left.alignment = BoxContainer.ALIGNMENT_CENTER
	left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(left)
	var row1 := UiKit.hbox(6)
	row1.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left.add_child(row1)
	_date = UiKit.text("", "label", UiKit.CORAL_DEEP)
	row1.add_child(_date)
	_clock = UiKit.text("", "number", UiKit.INK)
	_clock.add_theme_font_size_override("font_size", 25)
	row1.add_child(_clock)
	_sea = UiKit.text("", "caption", UiKit.INK_SOFT)
	_sea.add_theme_font_override("font", UiKit.font("medium"))
	_sea.add_theme_font_size_override("font_size", 16)
	left.add_child(_sea)

	h.add_child(UiKit.spacer())

	# 오른쪽: 배지, 돈, 메뉴
	_badge = UiKit.badge("", UiKit.SEA, UiKit.INK)
	_badge.hide()
	h.add_child(_badge)
	_money = UiKit.text("", "number", UiKit.INK)
	_money.add_theme_font_size_override("font_size", 23)
	h.add_child(_money)
	h.add_child(UiKit.gap(2))
	var menu_btn := UiKit.action("메뉴", "sun", true)
	menu_btn.custom_minimum_size = Vector2(84, 46)
	menu_btn.pressed.connect(open_menu)
	h.add_child(menu_btn)

	_menu = GameMenu.new()
	_menu.closed.connect(func(): menu_toggled.emit(false))
	_menu.gear_changed.connect(func():
		gear_changed.emit()
		refresh())
	add_child(_menu)
	refresh()


func _process(_delta: float) -> void:
	_clock.text = HudText.clock_text(_minutes if _minutes >= 0.0 else float(GameState.time_minutes))


## 장면이 굴리는 시각(자정부터 분)
func set_minutes(m: float) -> void:
	_minutes = m


func set_badge(t: String) -> void:
	(_badge.get_child(0) as Label).text = t
	_badge.visible = not t.is_empty()


func refresh() -> void:
	_date.text = HudText.date_text(GameState.day)
	_sea.text = HudText.sea_text(SeaDay.of(GameState.day))
	# 상환일이 가까우면 작게 알린다
	var loan := Loan.header_text(GameState.day, GameState.monthly_repayment, GameState.arrears, GameState.debt)
	if not loan.is_empty():
		_sea.text += "  ·  " + loan
	_money.text = GameState.format_won(GameState.money)


func open_menu() -> void:
	Sound.play_sfx("tap")
	_menu.open()
	menu_toggled.emit(true)


func is_menu_open() -> bool:
	return _menu != null and _menu.is_open()


## 헤더 판을 보이거나 숨긴다 (낚시 줄다리기 중에는 숨긴다). 메뉴는 그대로
func show_bar(on: bool) -> void:
	_bar.visible = on
