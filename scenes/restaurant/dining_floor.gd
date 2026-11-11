class_name DiningFloor
extends Control
## 저녁 영업 판 (규칙은 DiningLogic). 식당 정면 단면 배경 위에 손님이 앉고, 주인공이 접시를 들고 걷는다.
##   완성 접시(내놓는 자리)를 누르면 주인공 손에 들린다 → 조이스틱(또는 방향키)으로 그 손님 곁까지 걸어가면 내려놓는다
##   손님 머리 위: 주문한 요리 그림과 기다림 고리(초록 → 노랑 → 빨강)
## 배치 (2026-11-11 사용자): 세로로 긴 식당. 위 주방, 양옆 세로 바 카운터에 손님이 벽 쪽에 앉아 가운데를 보고, 주인공은 가운데 통로를 오간다
## 그림: 배경 bg_shop_inside_night (그림 세션이 받는 중), 손님 SD sd_guest/<id>_react.png, 요리 dish/<recipe>.png
## 이름 없는 손님 SD가 오기 전까지는 주민 SD가 대신 앉는다 (TEMP_FACES).
## 끝나면 finished(결과)를 보낸다. 결과 모양은 예전 DayFlow.serve_regulars와 같다 (장부가 그대로 쓴다).

signal finished(result: Dictionary)

## 이름 없는 손님 그림이 오기 전 임시 얼굴 (사용자 결정 2026-11-11: 이름 없는 손님 SD를 먼저 요청)
const TEMP_FACES := ["bokja", "junho", "gyeongja", "mansu", "sundeok"]
const GUEST_H := 150.0
const PLAYER_H := 210.0
const DISH := 58.0
const PAD_SIZE := 210.0 # 조이스틱 원판 지름

var logic := DiningLogic.new()
var _guests := {} # guest index → GuestSD
var _faces := {} # 손님 이름 → 그림 id
var _player_tex: Texture2D
var _staff_tex := {} # 역할 → {stand, walk[]} (알바 그림)
const STAFF_H := 170.0
var _player_back: Texture2D
var _player_face_left := false
var _player_up := false
var _dish_tex := {} # guest index → Texture2D
var _key_move := Vector2.ZERO
var _btn_move := Vector2.ZERO
var _pops: Array = [] # {t, p, text, color, heart}
var _t := 0.0
var _done := false
var _draw_layer: Control
var _decor_layer: Control # 의자, 바 위 장식, 벽 장식, 화분 (손님 뒤)
var _decor := [] # [{pos, tex, kind}]
var _pad: Joystick


func start(day: int, inventory: Array) -> void:
	logic.setup(day, inventory, DayFlow.GUESTS)
	logic.seat_bonus = ShopDecor.seat_comfort(GameState.shop_decor)
	logic.helper_serve = StaffDB.in_role(GameState.staff, "serve") != ""
	logic.helper_kitchen = StaffDB.in_role(GameState.staff, "kitchen") != ""
	_staff_tex.clear()
	for role in GameState.staff:
		var st := StaffDB.get_staff(GameState.staff[role])
		var walk := []
		for a in st.get("walk", []):
			walk.append(_load_art(a))
		_staff_tex[role] = {"stand": _load_art(st.get("art", "")), "walk": walk}
	logic.pantry = GameState.produce # 곁들임은 GameState에서 바로 빠진다
	logic.reserve = Sides.reserve_for(GameState)
	_load_decor()
	var names := {}
	for s in logic.schedule:
		names[s.name] = true
	var i := 0
	for n in names:
		_faces[n] = TEMP_FACES[(hash(n) + i) % TEMP_FACES.size()]
		i += 1
	show()


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_player_tex = _load_art("sd/front_02")
	_player_back = _load_art("sd/back_02")
	_decor_layer = Control.new()
	_decor_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_decor_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_decor_layer.draw.connect(_draw_decor)
	add_child(_decor_layer)
	_draw_layer = Control.new()
	_draw_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_draw_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_draw_layer.draw.connect(_draw_floor)
	add_child(_draw_layer)
	_build_pad()
	hide()


## 상점에서 산 가구를 슬롯마다 불러 둔다 (그림이 없는 물건은 그리지 않는다)
func _load_decor() -> void:
	_decor.clear()
	for sl in ShopDecor.slots():
		var art := ShopDecor.art_of(ShopDecor.item_in(GameState.shop_decor, sl.id))
		var tex := _load_art(art) if not art.is_empty() else null
		if tex:
			_decor.append({"pos": sl.pos, "tex": tex, "kind": sl.kind})
	_decor_layer.queue_redraw()


## 가구 그리기: 그림 아래 가운데를 자리에 맞춘다. 종류마다 화면 높이
const DECOR_H := {"chair": 120.0, "bar": 70.0, "wall": 110.0, "plant": 130.0}


func _draw_decor() -> void:
	for d in _decor:
		var tex: Texture2D = d.tex
		var h: float = DECOR_H.get(d.kind, 100.0)
		var w := h * tex.get_width() / float(tex.get_height())
		var at := to_screen(d.pos)
		_decor_layer.draw_texture_rect(tex, Rect2(at.x - w / 2.0, at.y - h, w, h), false)


func _load_art(id: String) -> Texture2D:
	return load(ArtSlot.art_path(id)) if ArtSlot.has_art(id) else null


## 배경 그림 비율 → 화면 좌표
## 좌표 기준 = 화면에 꽉 채워 깐 식당 배경 그림 자리 (cover: 비율 그대로 화면을 덮고 넘치는 쪽은 가운데 기준으로 잘림)
const BG_SIZE := Vector2(941, 1671)


func floor_rect() -> Rect2:
	var k := maxf(size.x / BG_SIZE.x, size.y / BG_SIZE.y)
	var s := BG_SIZE * k
	return Rect2((size - s) / 2.0, s)


func to_screen(p: Vector2) -> Vector2:
	var r := floor_rect()
	return r.position + p * r.size


# ─── 십자키 ─────────────────────────────────────────

## 투명 조이스틱 하나 (아래 가운데). 손 떼면 옅어진다 (Joystick)
func _build_pad() -> void:
	var d := Joystick.new()
	d.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	d.size = Vector2(PAD_SIZE, PAD_SIZE)
	d.position = Vector2(-PAD_SIZE / 2.0, -PAD_SIZE - 30.0)
	d.changed.connect(func(v): _btn_move = v)
	add_child(d)
	_pad = d


func _unhandled_input(event: InputEvent) -> void:
	if not visible or _done:
		return
	if event is InputEventKey and event.keycode in [KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN, KEY_A, KEY_D, KEY_W, KEY_S]:
		get_viewport().set_input_as_handled()
		_key_move = Vector2(
			float(Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A)),
			float(Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S)) - float(Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W)))
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var i := _pass_at(event.position)
		if i >= 0:
			get_viewport().set_input_as_handled()
			logic.take(i)


## 내놓는 자리 접시 화면 위치
func _pass_pos(i: int) -> Vector2:
	var n := maxi(1, logic.pass_dishes.size())
	return to_screen(DiningLogic.PASS) + Vector2((i - (n - 1) / 2.0) * (DISH + 10.0), 0)


func _pass_at(p: Vector2) -> int:
	for i in logic.pass_dishes.size():
		if p.distance_to(_pass_pos(i)) <= DISH * 0.75:
			return i
	return -1


# ─── 진행 ───────────────────────────────────────────

func _process(delta: float) -> void:
	if not visible:
		return
	_t += delta
	if not _done:
		logic.move = (_key_move + _btn_move).limit_length(1.0)
		if logic.move.x != 0.0:
			_player_face_left = logic.move.x < 0.0
		if logic.move.y != 0.0:
			_player_up = logic.move.y < 0.0
		logic.update(delta)
		_handle_events()
		if logic.is_over():
			_done = true
			_pad.hide()
			finished.emit({"served": logic.served, "missed": logic.missed + logic.angry, "sales": logic.sales, "side_sales": logic.side_sales, "sides": logic.served.filter(func(e): return e.side != "").size(), "angry": logic.angry, "hearts": logic.served.filter(func(e): return e.heart).size()})
	for p in _pops:
		p.t += delta
	_pops = _pops.filter(func(p): return p.t < 1.4)
	_place_guests()
	_decor_layer.queue_redraw()
	_draw_layer.queue_redraw()


## 문 닫기까지 흐른 게임 시각 (18:00~21:00)
func clock_minutes() -> float:
	return DayFlow.SHOP_OPEN + (DayFlow.SHOP_CLOSE - DayFlow.SHOP_OPEN) * clampf(logic.time / DiningLogic.OPEN_SECONDS, 0.0, 1.0)


func _handle_events() -> void:
	for e in logic.events:
		match e.type:
			"order":
				Sound.play_sfx("door", 0.05, -6.0)
				var gi: int = e.guest
				var g: Dictionary = logic.guests[gi]
				var sd := GuestSD.new()
				sd.guest_id = _faces.get(g.name, TEMP_FACES[0])
				sd.size = Vector2(GUEST_H * 0.75, GUEST_H)
				add_child(sd)
				move_child(sd, _draw_layer.get_index()) # 말풍선과 주인공 뒤
				_guests[gi] = sd
				UiKit.fade_in(sd, 0.3)
				var art := Catalog.dish_art(FishDB.get_fish(g.fish).get("grill", "bollak-gui"))
				_dish_tex[gi] = _load_art(art)
			"ready":
				Sound.play_sfx("tick", 0.05)
			"take":
				Sound.play_sfx("tap", 0.05, -4.0)
				Haptics.play("tap")
			"served":
				var gi: int = e.guest
				Sound.play_sfx("coin", 0.08)
				Haptics.play("catch" if e.heart else "tap")
				if _guests.has(gi):
					_guests[gi].set_pose("happy" if e.heart else "stand")
				_pop(_bubble_pos(gi) + Vector2(0, -50), "+" + GameState.format_won(e.price), UiKit.SUN, e.heart)
				if e.side != "":
					_pop(_bubble_pos(gi) + Vector2(0, -16), Sides.name_of(e.side) + " 곁들임", UiKit.LEAF, false)
			"angry":
				var gi: int = e.guest
				Sound.play_sfx("bad", 0.0, -6.0)
				Haptics.play("lost")
				if _guests.has(gi):
					_guests[gi].set_pose("sad")
				_pop(_bubble_pos(gi) + Vector2(0, -50), "너무 늦어요", UiKit.PINK, false)
				_leave(gi, 0.9)
			"left":
				_leave(e.guest, 0.0)
			"missed":
				Sound.play_sfx("bad", 0.0, -10.0)
				_pop(to_screen(Vector2(0.5, 0.2)), "생선이 떨어졌어요", UiKit.PINK, false)
	logic.events.clear()


func _leave(gi: int, delay: float) -> void:
	if not _guests.has(gi):
		return
	var sd: GuestSD = _guests[gi]
	_guests.erase(gi)
	var tw := sd.create_tween()
	tw.tween_interval(delay)
	tw.tween_property(sd, "modulate:a", 0.0, 0.35)
	tw.tween_callback(sd.queue_free)


func _pop(at: Vector2, text: String, col: Color, heart: bool) -> void:
	_pops.append({"t": 0.0, "p": at, "text": text, "color": col, "heart": heart})


func _seat_screen(gi: int) -> Vector2:
	return to_screen(DiningLogic.SEATS[logic.guests[gi].seat])


## 주문 말풍선 자리: 손님 옆 통로 쪽 (세로 바라서 위아래 손님과 겹치지 않게)
func _bubble_pos(gi: int) -> Vector2:
	var seat: Vector2 = DiningLogic.SEATS[logic.guests[gi].seat]
	var side := 1.0 if seat.x < 0.5 else -1.0
	return _seat_screen(gi) + Vector2(side * (GUEST_H * 0.42 + 40.0), -GUEST_H * 0.55)


func _place_guests() -> void:
	for gi in _guests:
		var sd: GuestSD = _guests[gi]
		var feet := _seat_screen(gi)
		sd.position = feet - Vector2(sd.size.x / 2.0, sd.size.y)


# ─── 그리기 ─────────────────────────────────────────
# 기다림 고리, 내놓는 자리 표시, 화로 진행 고리는 판정을 보여 주는 요소라 코드로 그린다.

func _draw_floor() -> void:
	var ci := _draw_layer
	var font := UiKit.font("cute")
	# 빈자리: 옅은 고리 (손님이 앉을 수 있는 곳)
	var taken := {}
	for g in logic.guests:
		if g.state != DiningLogic.GuestState.LEFT:
			taken[g.seat] = true
	for i in DiningLogic.SEATS.size():
		if not taken.has(i):
			_ellipse(ci, to_screen(DiningLogic.SEATS[i]), 34.0, Color(UiKit.FOAM, 0.25), 3.0)
	# 화로: 굽는 중인 접시마다 진행 고리
	var stove := to_screen(DiningLogic.PASS) + Vector2(DISH * 0.5, -DISH - 20.0)
	for k in logic.cooking.size():
		var c: Dictionary = logic.cooking[k]
		var p := stove + Vector2(k * (DISH + 10.0), 0)
		var done: float = 1.0 - float(c.left) / maxf(float(c.total), 0.01)
		ci.draw_circle(p, DISH * 0.42, Color(UiKit.NIGHT_DEEP, 0.75))
		var lit := logic.cooking_now()
		ci.draw_arc(p, DISH * 0.42, -PI / 2.0, -PI / 2.0 + TAU * clampf(done, 0.0, 1.0), 40, UiKit.SUN if lit else Color(UiKit.FOAM, 0.35), 6.0, true)
		_dish(ci, c.guest, p, DISH * 0.55, 0.55)
	# 주방에 아무도 없으면 화로가 멈춘다: 짧게 알려 준다
	if not logic.cooking.is_empty() and not logic.cooking_now():
		var kt := "주방에 서 있어야 구워져요"
		var kw := font.get_string_size(kt, HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x
		var kp := stove + Vector2(-kw / 2.0, -DISH * 0.6)
		ci.draw_string_outline(font, kp, kt, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, 8, UiKit.OUTLINE)
		ci.draw_string(font, kp, kt, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, UiKit.FOAM)
	# 서빙 자리: 지금 든 접시의 손님 앞 통로에 옅은 고리
	if logic.holding >= 0:
		_ellipse(ci, to_screen(DiningLogic.serve_spot(logic.guests[logic.holding].seat)), 30.0 + sin(_t * 6.0) * 3.0, Color(UiKit.SUN, 0.7), 3.0)
	# 내놓는 자리: 완성 접시 (누르면 집는다)
	for i in logic.pass_dishes.size():
		var p := _pass_pos(i)
		var bob := sin(_t * 5.0 + i) * 3.0
		ci.draw_circle(p + Vector2(0, bob), DISH * 0.6, Color(UiKit.OUTLINE, 0.55))
		ci.draw_circle(p + Vector2(0, bob), DISH * 0.55, Color(UiKit.PAPER, 0.95))
		_dish(ci, logic.pass_dishes[i], p + Vector2(0, bob), DISH, 1.0)
	# 손님 머리 위: 주문 그림과 기다림 고리. 지금 든 접시의 손님은 금색 테
	for gi in logic.guests.size():
		var g: Dictionary = logic.guests[gi]
		if g.state != DiningLogic.GuestState.SEATED:
			continue
		var p := _bubble_pos(gi)
		var left: float = 1.0 - float(g.wait) / logic.patience_of(g.seat)
		var col := UiKit.LEAF if left > 0.5 else (UiKit.SUN if left > 0.2 else UiKit.DANGER)
		var r := 34.0
		if gi == logic.holding:
			ci.draw_circle(p, r + 9.0 + sin(_t * 8.0) * 2.0, Color(UiKit.SUN, 0.55))
		ci.draw_circle(p, r + 3.0, UiKit.OUTLINE)
		ci.draw_circle(p, r, UiKit.PAPER)
		ci.draw_arc(p, r + 6.0, -PI / 2.0, -PI / 2.0 + TAU * clampf(left, 0.0, 1.0), 40, col, 6.0, true)
		_dish(ci, gi, p, r * 1.5, 1.0)
	_draw_staff(ci)
	# 주인공 (앞모습, 위로 걸을 땐 뒷모습). 든 접시는 머리 위에
	var pp := to_screen(logic.player)
	var tex := _player_back if _player_up and _player_back else _player_tex
	if tex:
		var h := PLAYER_H
		var w := h * tex.get_width() / float(tex.get_height())
		var step := absf(sin(_t * 12.0)) * 6.0 if logic.move != Vector2.ZERO else 0.0
		ci.draw_set_transform(pp + Vector2(0, -step), 0.0, Vector2(-1.0 if _player_face_left else 1.0, 1.0))
		ci.draw_texture_rect(tex, Rect2(-w / 2.0, -h, w, h), false)
		ci.draw_set_transform_matrix(Transform2D.IDENTITY)
	if logic.holding >= 0:
		var hp := pp + Vector2(0, -PLAYER_H - 10.0)
		ci.draw_circle(hp, DISH * 0.55, Color(UiKit.OUTLINE, 0.5))
		ci.draw_circle(hp, DISH * 0.5, Color(UiKit.PAPER, 0.95))
		_dish(ci, logic.holding, hp, DISH * 0.9, 1.0)
	# 튀어 오르는 글자 (값, 하트)
	for p in _pops:
		var k: float = p.t / 1.4
		var at: Vector2 = p.p + Vector2(0, -40.0 * k)
		var a := 1.0 - maxf(0.0, k - 0.6) / 0.4
		var w := font.get_string_size(p.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 30).x
		var x := at.x - w / 2.0 + (16.0 if p.heart else 0.0)
		ci.draw_string_outline(font, Vector2(x, at.y), p.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 30, 9, Color(UiKit.OUTLINE, a))
		ci.draw_string(font, Vector2(x, at.y), p.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color(p.color, a))
		if p.heart:
			_heart(ci, Vector2(x - 22.0, at.y - 10.0), 13.0, Color(UiKit.CORAL, a))
	# 남은 손님이 없으면 마감 안내
	if logic.time_left() <= 0.0 and not _done:
		var t := "마감! 남은 손님만 받아요"
		var tw := font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, 26).x
		ci.draw_string_outline(font, Vector2(size.x / 2.0 - tw / 2.0, floor_rect().position.y + 20.0), t, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, 9, UiKit.OUTLINE)
		ci.draw_string(font, Vector2(size.x / 2.0 - tw / 2.0, floor_rect().position.y + 20.0), t, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, UiKit.FOAM)


## 알바: 주방 알바는 화로 옆에 서 있고, 서빙 알바는 접시를 들고 주방에서 손님 앞까지 걸어간다
func _draw_staff(ci: Control) -> void:
	if _staff_tex.has("kitchen"):
		_draw_sprite(ci, _staff_tex.kitchen.stand, to_screen(DiningLogic.PASS) + Vector2(-120.0, 6.0), false)
	if _staff_tex.has("serve"):
		var home := to_screen(Vector2(DiningLogic.AISLE.y, DiningLogic.FLOOR_MIN.y))
		var at := home
		var walk: Array = _staff_tex.serve.walk
		var tex: Texture2D = _staff_tex.serve.stand
		var flip := false
		if logic.helper_dish >= 0 and logic.helper_dish < logic.guests.size():
			var goal := to_screen(DiningLogic.serve_spot(logic.guests[logic.helper_dish].seat))
			var k := 1.0 - clampf(logic.helper_left / DiningLogic.HELPER_TRIP, 0.0, 1.0)
			at = home.lerp(goal, minf(1.0, k * 1.6)) # 가서 잠깐 서 있다가 낸다
			flip = goal.x < home.x
			if k < 0.62 and not walk.is_empty():
				tex = walk[int(_t * 6.0) % walk.size()]
		_draw_sprite(ci, tex, at, flip)
		if logic.helper_dish >= 0:
			var hp := at + Vector2(0, -STAFF_H - 8.0)
			ci.draw_circle(hp, DISH * 0.45, Color(UiKit.PAPER, 0.95))
			_dish(ci, logic.helper_dish, hp, DISH * 0.8, 1.0)


func _draw_sprite(ci: Control, tex: Texture2D, feet: Vector2, flip: bool) -> void:
	if tex == null:
		return
	var h := STAFF_H
	var w := h * tex.get_width() / float(tex.get_height())
	ci.draw_set_transform(feet, 0.0, Vector2(-1.0 if flip else 1.0, 1.0))
	ci.draw_texture_rect(tex, Rect2(-w / 2.0, -h, w, h), false)
	ci.draw_set_transform_matrix(Transform2D.IDENTITY)


func _dish(ci: Control, gi: int, c: Vector2, w: float, alpha: float) -> void:
	var tex: Texture2D = _dish_tex.get(gi)
	if tex == null:
		ci.draw_circle(c, w * 0.3, Color(UiKit.CORAL, alpha))
		return
	var h := w * tex.get_height() / float(tex.get_width())
	ci.draw_texture_rect(tex, Rect2(c.x - w / 2.0, c.y - h / 2.0, w, h), false, Color(1, 1, 1, alpha))


func _ellipse(ci: Control, c: Vector2, r: float, col: Color, width: float) -> void:
	ci.draw_set_transform(c, 0.0, Vector2(1.0, 0.4))
	ci.draw_arc(Vector2.ZERO, r, 0.0, TAU, 32, col, width / 0.4 * 0.5, true)
	ci.draw_set_transform_matrix(Transform2D.IDENTITY)


## 하트 (만족 표시)
func _heart(ci: Control, c: Vector2, r: float, col: Color) -> void:
	ci.draw_circle(c + Vector2(-r * 0.5, 0), r * 0.55, col)
	ci.draw_circle(c + Vector2(r * 0.5, 0), r * 0.55, col)
	ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-r * 1.02, r * 0.15), c + Vector2(r * 1.02, r * 0.15), c + Vector2(0, r * 1.25)]), col)
