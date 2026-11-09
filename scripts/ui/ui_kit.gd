class_name UiKit
extends RefCounted
## 오늘의 바다 디자인 시스템. 모든 화면은 여기 있는 토큰과 컴포넌트만 쓴다.
##
## 방향: 물빛 유리 + 종이 혼합 (docs/UI_디자인_시스템.md)
## - 그림 위에 뜨는 것(HUD, 대사창, 지도 핀, 토스트)은 반투명 남색 유리
## - 읽을 게 많은 창(메뉴, 상점, 카드, 장부)은 따뜻한 크림색 종이
## - 주요 행동은 산호색, 새것과 강조는 햇살 금색, 정보는 청록
## 글꼴: 제목은 고운바탕, 나머지는 Pretendard

# ─── 색 ─────────────────────────────────────────────

## 글자 (종이 위)
const INK := Color("17243a")
const INK_SOFT := Color("566176")
const INK_MUTED := Color("8b93a2")
## 종이
const PAPER := Color("fbf6ec")
const PAPER_DEEP := Color("f2e9d8") # 종이 안쪽 칸, 입력창
const PAPER_LINE := Color("e3d8c3") # 종이 테두리, 구분선
## 유리 (그림 위)
const GLASS := Color(0.055, 0.105, 0.18, 0.66)
const GLASS_STRONG := Color(0.045, 0.085, 0.15, 0.84)
const GLASS_EDGE := Color(1, 1, 1, 0.16)
const FOAM := Color("f8f4ea") # 유리 위 글자
const FOAM_SOFT := Color(0.97, 0.95, 0.92, 0.72)
## 포인트
const CORAL := Color("ff7a59")
const CORAL_DEEP := Color("e85d3d")
const SEA := Color("2a9d97")
const SUN := Color("f3b843")
const DANGER := Color("e5484d")
const SCRIM := Color(0.02, 0.05, 0.1, 0.5) # 모달 뒤 어둡게
const SHADOW := Color(0.04, 0.07, 0.12, 0.28)

## 예전 이름 (기존 코드 호환). 새 코드에서는 위 이름을 쓴다
const CREAM := FOAM
const NAVY := INK
const NAVY_DEEP := Color("0e1828")
const MUSTARD := SUN
const TEAL := SEA
const WOOD := Color("8a5a3a")
const WOOD_DARK := Color("3a2a20")
const ERROR := DANGER

# ─── 글자 ───────────────────────────────────────────

const FONT_DIR := "res://assets/fonts/"
const FONTS := {
	"regular": "Pretendard-Regular.otf",
	"medium": "Pretendard-Medium.otf",
	"semibold": "Pretendard-SemiBold.otf",
	"bold": "Pretendard-Bold.otf",
	"extrabold": "Pretendard-ExtraBold.otf",
	"serif": "GowunBatang-Regular.ttf",
	"serif_bold": "GowunBatang-Bold.ttf",
}

## 글자 단계: [글꼴, 크기]
const TYPE := {
	"display": ["serif_bold", 92], # 게임 제목
	"h1": ["serif_bold", 44], # 장면 제목, 간판
	"h2": ["bold", 30], # 창 제목
	"title": ["semibold", 23], # 목록 항목 이름, 대사 이름표
	"body": ["medium", 21], # 대사, 설명
	"label": ["semibold", 17], # 버튼 작은 것, 칩
	"caption": ["regular", 15], # 도움말, 보조 정보
}

## 예전 크기 이름 (호환)
const SIZE_TITLE := 92
const SIZE_HEADING := 30
const SIZE_BODY := 21
const SIZE_SMALL := 16

# ─── 모양 ───────────────────────────────────────────

const RADIUS_SM := 10
const RADIUS_MD := 16
const RADIUS_LG := 24
const RADIUS_PILL := 999

const SPACE_XS := 4
const SPACE_SM := 8
const SPACE_MD := 12
const SPACE_LG := 20
const SPACE_XL := 32

## 움직임 (초)
const MOTION_FAST := 0.14
const MOTION_BASE := 0.24
const MOTION_SLOW := 0.45

const BUTTON_H := 54
const BUTTON_H_SM := 42

static var _font_cache := {}


static func font(weight: String) -> Font:
	if not _font_cache.has(weight):
		_font_cache[weight] = load(FONT_DIR + FONTS.get(weight, FONTS.regular))
	return _font_cache[weight]


# ─── 스타일박스 ─────────────────────────────────────

## 기본 상자. 예전 코드 호환용 인자 순서를 유지한다.
static func box(bg: Color, radius := RADIUS_MD, border := Color.TRANSPARENT, border_w := 0, pad := 20) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(radius)
	s.corner_detail = 10
	s.anti_aliasing = true
	if border_w > 0:
		s.border_color = border
		s.set_border_width_all(border_w)
	s.set_content_margin_all(pad)
	return s


## 그림자 높이 1(살짝 뜬 것) 2(창) 3(모달)
static func elevate(s: StyleBoxFlat, level := 2) -> StyleBoxFlat:
	s.shadow_color = Color(SHADOW, [0.0, 0.16, 0.26, 0.36][clampi(level, 0, 3)])
	s.shadow_size = [0, 6, 16, 28][clampi(level, 0, 3)]
	s.shadow_offset = Vector2(0, [0, 2, 6, 10][clampi(level, 0, 3)])
	return s


static func paper_box(pad := SPACE_LG, radius := RADIUS_LG, level := 2) -> StyleBoxFlat:
	return elevate(box(PAPER, radius, PAPER_LINE, 1, pad), level)


static func glass_box(pad := SPACE_LG, radius := RADIUS_LG, strong := false) -> StyleBoxFlat:
	return elevate(box(GLASS_STRONG if strong else GLASS, radius, GLASS_EDGE, 1, pad), 1)


## 종이 안쪽 칸 (목록 한 줄, 정보 묶음)
static func inset_box(pad := SPACE_MD, radius := RADIUS_MD) -> StyleBoxFlat:
	return box(PAPER_DEEP, radius, Color.TRANSPARENT, 0, pad)


# ─── 패널 ───────────────────────────────────────────

static func paper_panel(pad := SPACE_XL, radius := RADIUS_LG) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", paper_box(pad, radius))
	return p


static func glass_panel(pad := SPACE_LG, radius := RADIUS_LG, strong := false) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", glass_box(pad, radius, strong))
	return p


## 세로 쌓기 상자
static func vbox(gap := SPACE_MD) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", gap)
	return v


static func hbox(gap := SPACE_MD, align := BoxContainer.ALIGNMENT_BEGIN) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", gap)
	h.alignment = align
	return h


static func gap(px: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(px, px)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


## 가로로 남는 자리를 채우는 빈칸
static func spacer() -> Control:
	var c := Control.new()
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


## 얇은 구분선
static func divider(color := PAPER_LINE) -> ColorRect:
	var r := ColorRect.new()
	r.color = color
	r.custom_minimum_size.y = 1
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


# ─── 글자 ───────────────────────────────────────────

## 글자 단계로 라벨을 만든다. style: display, h1, h2, title, body, label, caption
static func text(t: String, style := "body", color := INK, align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var spec: Array = TYPE.get(style, TYPE.body)
	var l := Label.new()
	l.text = t
	l.horizontal_alignment = align
	l.add_theme_font_override("font", font(spec[0]))
	l.add_theme_font_size_override("font_size", spec[1])
	l.add_theme_color_override("font_color", color)
	if style in ["body", "caption"]:
		l.add_theme_constant_override("line_spacing", 6)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


## 예전 방식 라벨 (호환). 크기에 맞는 굵기를 고른다
static func label(t: String, size := SIZE_BODY, color := INK, align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := text(t, "body", color, align)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_font_override("font", font("bold" if size >= 28 else ("medium" if size >= 19 else "regular")))
	return l


## 그림 위 글자에 은은한 그림자
static func shadowed(l: Label, shadow := Color(0, 0, 0, 0.45), offset := 2) -> Label:
	l.add_theme_color_override("font_shadow_color", shadow)
	l.add_theme_constant_override("shadow_offset_x", 0)
	l.add_theme_constant_override("shadow_offset_y", offset)
	l.add_theme_constant_override("shadow_outline_size", 6)
	return l


## 줄바꿈 되는 본문
static func paragraph(t: String, style := "body", color := INK, width := 0.0, align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := text(t, style, color, align)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if width > 0.0:
		l.custom_minimum_size.x = width
	return l


# ─── 버튼 ───────────────────────────────────────────

## kind: "primary" 산호, "secondary" 종이, "glass" 유리(그림 위), "ghost" 글자만
static func action(t: String, kind := "primary", small := false) -> Button:
	var b := Button.new()
	b.text = t
	b.focus_mode = Control.FOCUS_ALL
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.custom_minimum_size = Vector2(120 if small else 168, BUTTON_H_SM if small else BUTTON_H)
	b.add_theme_font_override("font", font("bold" if not small else "semibold"))
	b.add_theme_font_size_override("font_size", 17 if small else 20)
	var pad := 18 if small else 26
	var bg: Color
	var fg: Color
	var edge := Color.TRANSPARENT
	match kind:
		"secondary":
			bg = PAPER
			fg = INK
			edge = PAPER_LINE
		"glass":
			bg = GLASS
			fg = FOAM
			edge = GLASS_EDGE
		"ghost":
			bg = Color(INK, 0.0)
			fg = INK_SOFT
		_:
			bg = CORAL
			fg = Color.WHITE
	var normal := box(bg, RADIUS_PILL, edge, 1 if edge.a > 0 else 0, pad)
	normal.content_margin_top = 0
	normal.content_margin_bottom = 0
	if kind == "primary":
		elevate(normal, 1)
		normal.shadow_color = Color(CORAL_DEEP, 0.35)
	var hover := normal.duplicate()
	hover.bg_color = bg.lightened(0.08) if kind != "ghost" else Color(INK, 0.06)
	var pressed := normal.duplicate()
	pressed.bg_color = (CORAL_DEEP if kind == "primary" else bg.darkened(0.08)) if kind != "ghost" else Color(INK, 0.1)
	pressed.shadow_size = 0
	var disabled := normal.duplicate()
	disabled.bg_color = Color(bg, bg.a * 0.45) if kind != "primary" else Color(INK_MUTED, 0.35)
	disabled.shadow_size = 0
	var focus := box(Color.TRANSPARENT, RADIUS_PILL, SUN, 3, 0)
	focus.set_expand_margin_all(3)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", pressed)
	b.add_theme_stylebox_override("disabled", disabled)
	b.add_theme_stylebox_override("focus", focus)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(state, fg)
	b.add_theme_color_override("font_disabled_color", Color(fg, 0.45) if kind != "primary" else Color(1, 1, 1, 0.75))
	_add_press_motion(b)
	return b


## 예전 방식 버튼 (호환). primary면 산호, 아니면 종이
static func button(t: String, primary := true) -> Button:
	return action(t, "primary" if primary else "secondary")


## 마우스를 올리면 살짝 커지고 누르면 살짝 눌린다
static func _add_press_motion(c: Control) -> void:
	var set_pivot := func(): c.pivot_offset = c.size / 2.0
	c.resized.connect(set_pivot)
	var to := func(s: float):
		if c.is_inside_tree():
			c.create_tween().tween_property(c, "scale", Vector2(s, s), MOTION_FAST).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	c.mouse_entered.connect(func(): if not (c is BaseButton and c.disabled): to.call(1.035))
	c.mouse_exited.connect(func(): to.call(1.0))
	if c is BaseButton:
		c.button_down.connect(func(): to.call(0.97))
		c.button_up.connect(func(): to.call(1.035 if c.is_hovered() else 1.0))


# ─── 칩, 배지 ───────────────────────────────────────

## HUD 칩: 유리 알약 안에 작은 이름과 값. icon은 assets/art/<id>.png가 있을 때만 보인다
static func chip(caption: String, value := "", icon := "", on_glass := true) -> PanelContainer:
	var p := PanelContainer.new()
	var s := glass_box(0, RADIUS_PILL) if on_glass else box(PAPER_DEEP, RADIUS_PILL, Color.TRANSPARENT, 0, 0)
	s.content_margin_left = 16
	s.content_margin_right = 18
	s.content_margin_top = 8
	s.content_margin_bottom = 8
	p.add_theme_stylebox_override("panel", s)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var h := hbox(SPACE_SM)
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	p.add_child(h)
	var ic := icon_rect(icon, 22)
	if ic:
		h.add_child(ic)
	if not caption.is_empty():
		h.add_child(text(caption, "caption", FOAM_SOFT if on_glass else INK_SOFT))
	var v := text(value, "label", FOAM if on_glass else INK)
	v.name = "Value"
	v.add_theme_font_size_override("font_size", 18)
	h.add_child(v)
	return p


## 칩 값 바꾸기
static func set_chip(c: PanelContainer, value: String) -> void:
	var v := c.find_child("Value", true, false) as Label
	if v:
		v.text = value


## 작은 배지 (NEW, 사용 중 같은 표시)
static func badge(t: String, bg := SUN, fg := INK) -> PanelContainer:
	var p := PanelContainer.new()
	var s := box(bg, RADIUS_PILL, Color.TRANSPARENT, 0, 0)
	s.content_margin_left = 12
	s.content_margin_right = 12
	s.content_margin_top = 3
	s.content_margin_bottom = 4
	p.add_theme_stylebox_override("panel", s)
	p.add_child(text(t, "label", fg, HORIZONTAL_ALIGNMENT_CENTER))
	p.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return p


## 아이콘 그림 (assets/art/<id>.png). 그림이 아직 없으면 null을 돌려줘 자리를 차지하지 않는다
static func icon_rect(id: String, px := 24) -> TextureRect:
	if id.is_empty() or not ArtSlot.has_art(id):
		return null
	var r := TextureRect.new()
	r.texture = load(ArtSlot.art_path(id))
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.custom_minimum_size = Vector2(px, px)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


# ─── 입력 ───────────────────────────────────────────

## 채워진 입력창. on_glass면 유리 위, 아니면 종이 위
static func line_edit(placeholder: String, size := 30, color := INK, max_len := 0, on_glass := false) -> LineEdit:
	var e := LineEdit.new()
	e.placeholder_text = placeholder
	e.max_length = max_len
	e.alignment = HORIZONTAL_ALIGNMENT_CENTER
	e.add_theme_font_override("font", font("semibold"))
	e.add_theme_font_size_override("font_size", size)
	e.add_theme_color_override("font_color", color)
	e.add_theme_color_override("font_placeholder_color", Color(color, 0.32))
	e.add_theme_color_override("caret_color", CORAL)
	e.add_theme_color_override("selection_color", Color(CORAL, 0.3))
	e.add_theme_constant_override("caret_width", 2)
	var bg := Color(1, 1, 1, 0.08) if on_glass else PAPER_DEEP
	var normal := box(bg, RADIUS_MD, Color.TRANSPARENT, 2, 14)
	normal.border_color = Color(1, 1, 1, 0.14) if on_glass else PAPER_LINE
	normal.content_margin_left = 20
	normal.content_margin_right = 20
	var focused := normal.duplicate()
	focused.border_color = CORAL
	focused.bg_color = Color(1, 1, 1, 0.14) if on_glass else Color.WHITE
	e.add_theme_stylebox_override("normal", normal)
	e.add_theme_stylebox_override("focus", focused)
	return e


# ─── 게이지 ─────────────────────────────────────────

## 둥근 막대 게이지를 그린다. zone은 (시작, 끝) 비율로 칠할 표시 구간 (없으면 Vector2.ZERO)
static func draw_bar(ci: CanvasItem, r: Rect2, value: float, fill: Color, on_glass := true, zone := Vector2.ZERO, zone_color := Color(SUN, 0.45)) -> void:
	var rad := int(r.size.y / 2.0)
	var track := box(Color(0, 0, 0, 0.35) if on_glass else Color(INK, 0.08), rad, Color(1, 1, 1, 0.18) if on_glass else Color.TRANSPARENT, 1 if on_glass else 0, 0)
	ci.draw_style_box(track, r)
	if zone != Vector2.ZERO:
		var zr := Rect2(r.position + Vector2(r.size.x * zone.x, 2), Vector2(r.size.x * (zone.y - zone.x), r.size.y - 4))
		ci.draw_style_box(box(zone_color, int(zr.size.y / 2.0), Color.TRANSPARENT, 0, 0), zr)
	var w := r.size.x * clampf(value, 0.0, 1.0)
	if w >= 2.0:
		var inner := Rect2(r.position + Vector2(2, 2), Vector2(maxf(w - 4.0, r.size.y - 4.0), r.size.y - 4))
		ci.draw_style_box(box(fill, int(inner.size.y / 2.0), Color.TRANSPARENT, 0, 0), inner)


# ─── 화면 도우미 ───────────────────────────────────

## 화면 전체를 덮는 어두운 막 (모달 뒤). 클릭을 막는다
static func scrim(alpha := 0.5) -> ColorRect:
	var r := ColorRect.new()
	r.color = Color(SCRIM, alpha)
	r.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_STOP
	return r


## 배경 그림을 화면 가득 (비율 유지, 잘라서 채움). 그림이 없으면 null
static func cover_art(id: String) -> TextureRect:
	if not ArtSlot.has_art(id):
		return null
	var r := TextureRect.new()
	r.texture = load(ArtSlot.art_path(id))
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	r.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


## 위아래로 어두워지는 막 (그림 위 글자를 읽기 쉽게). stops: [[위치 0~1, 투명도], ...]
static func shade(stops: Array, color := NAVY_DEEP) -> TextureRect:
	var g := Gradient.new()
	g.remove_point(1)
	g.set_offset(0, stops[0][0])
	g.set_color(0, Color(color, stops[0][1]))
	for i in range(1, stops.size()):
		g.add_point(stops[i][0], Color(color, stops[i][1]))
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill_from = Vector2(0, 0)
	tex.fill_to = Vector2(0, 1)
	tex.width = 4
	tex.height = 256
	var r := TextureRect.new()
	r.texture = tex
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_SCALE
	r.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


## 장면이 열릴 때 부드럽게 나타나게 한다.
static func fade_in(node: CanvasItem, duration := 0.6) -> void:
	node.modulate.a = 0.0
	node.create_tween().tween_property(node, "modulate:a", 1.0, duration).set_trans(Tween.TRANS_SINE)


## 아래에서 살짝 떠오르며 나타난다 (창, 카드)
static func rise_in(c: Control, delay := 0.0, distance := 18.0) -> void:
	c.modulate.a = 0.0
	var tw := c.create_tween()
	tw.tween_interval(delay)
	tw.tween_callback(func():
		if c.get_parent() is Container:
			# 컨테이너 안에서는 위치가 다시 정해지므로 흐릿하게 나타나기만 한다
			c.create_tween().tween_property(c, "modulate:a", 1.0, MOTION_SLOW).set_trans(Tween.TRANS_SINE)
			return
		c.position.y += distance
		var t2 := c.create_tween().set_parallel()
		t2.tween_property(c, "modulate:a", 1.0, MOTION_SLOW).set_trans(Tween.TRANS_SINE)
		t2.tween_property(c, "position:y", c.position.y - distance, MOTION_SLOW).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT))


## 튕기며 나타난다 (잡은 물고기 카드, 완성 접시)
static func pop_in(c: Control) -> void:
	c.pivot_offset = c.size / 2.0
	c.scale = Vector2(0.86, 0.86)
	c.modulate.a = 0.0
	var tw := c.create_tween().set_parallel()
	tw.tween_property(c, "scale", Vector2.ONE, 0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(c, "modulate:a", 1.0, 0.2)


## 화면을 어둡게 한 뒤 다음 장면으로 넘어간다.
static func go_to(from: Node, scene_path: String, duration := 0.5) -> void:
	var tw := from.create_tween()
	tw.tween_property(from, "modulate:a", 0.0, duration).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(func(): from.get_tree().change_scene_to_file(scene_path))


# ─── 전역 테마 ─────────────────────────────────────

## 게임 전체 기본 모양 (기본 글꼴, 스크롤바, 툴팁). GameState가 시작할 때 루트에 건다
static func build_theme() -> Theme:
	var t := Theme.new()
	t.default_font = font("regular")
	t.default_font_size = 20
	t.set_color("font_color", "Label", INK)
	# 스크롤바: 얇은 알약
	for kind in ["VScrollBar", "HScrollBar"]:
		var track := box(Color(INK, 0.06), RADIUS_PILL, Color.TRANSPARENT, 0, 0)
		track.content_margin_left = 3
		track.content_margin_right = 3
		var grab := box(Color(INK, 0.28), RADIUS_PILL, Color.TRANSPARENT, 0, 0)
		grab.content_margin_left = 3
		grab.content_margin_right = 3
		t.set_stylebox("scroll", kind, track)
		t.set_stylebox("grabber", kind, grab)
		var grab_hi := grab.duplicate()
		grab_hi.bg_color = Color(INK, 0.45)
		t.set_stylebox("grabber_highlight", kind, grab_hi)
		t.set_stylebox("grabber_pressed", kind, grab_hi)
	# 툴팁: 유리
	var tip := glass_box(10, RADIUS_SM, true)
	tip.content_margin_left = 14
	tip.content_margin_right = 14
	t.set_stylebox("panel", "TooltipPanel", tip)
	t.set_color("font_color", "TooltipLabel", FOAM)
	t.set_font("font", "TooltipLabel", font("medium"))
	t.set_font_size("font_size", "TooltipLabel", 16)
	return t
