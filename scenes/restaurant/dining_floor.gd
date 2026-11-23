class_name DiningFloor
extends Control
## 저녁 영업 판 (규칙은 DiningLogic). 2026-11-16 다시 짬.
## 사용자: "한 사람은 주방에서 계속 요리하고 다른 한 사람은 서빙만", "주인공은 낚시, 서빙. 요리는 다른 인물이 전담".
##   주방: 요리사 세라가 조리대 뒤에서 굽는다. 요리사 양옆 동그라미가 화구 두 개의 익은 정도다.
##   홀: 완성 접시가 조리대 끝에 놓이면 눌러서 주인공이 갖다준다. 서빙 알바 여울이 있으면 여울도 맨 앞 접시부터 나른다.
##   조이스틱 없이 누르기만 하고, 사람은 정해진 길로만 걷는다.
## 그림: 식당 4안 (2026-11-18, Shop4). 빈 바탕 shop4/bg_night 위에 주방 장비, 카운터, 스툴, 테이블, 소품을 낱장으로 얹는다. 손님 SD sd_guest/<id>_*.png
##   (앉은 그림 seat_back, seat_side, seat_front), 주인공 sd/walk·serve_walk, 알바 staff/*, 요리 dish/<recipe>.png, 생선 fish_<id>.png
## 물건과 손님은 한 층(_people)에서 key 순서로 그린다 (Shop4Prop). 뒷모습 손님이 앉은 스툴 아랫부분과 칸막이 테이블 아랫부분은 손님 위에 한 번 더 덮는다.
## 가게 꾸미기(ShopDecor)는 4안 빈자리에 간판, 줄전구, 바 위 소품, 벽 장식, 화분을 얹는다 (의자는 편안함만).
## 끝나면 finished(결과)를 보낸다 (장부가 그대로 쓴다).

signal finished(result: Dictionary)

const BG := "shop4/bg_night"
const BG_SIZE := Vector2(982, 1602)
## 사람 키 (화면 px, 서 있는 키). 슬롯 설계 7차: SD 1.3배
const CHAR_H := 195.0
const GUEST_H := CHAR_H
## 걷기 시트는 칸 위 여백이 커서 이만큼 키워 그린다 (GuestSD.WALK_SCALE과 같은 값)
const SHEET_WALK_SCALE := 1.2
## 주인공 걷기 시트 한 칸 높이. 시트 안 몸이 칸의 66%라 여울, 세라(몸 키 약 195px)와 같은 키가 되게 크게 그린다
const PLAYER_H := CHAR_H * 1.5
## 주인공 서기 시트 3칸 (걷기 시트와 같은 칸 높이, 발 높이). 없으면 걷기 시트의 STAND_CELL
const STAND_SHEET := "sd/stand"
## 서 있을 때 쓰는 걷기 시트 칸. 0번은 앞으로 한 발을 든 칸이라 늘 한 발을 들고 서 있는 것처럼 보였다 (11-19 사용자). 1번은 두 발이 땅에 닿는다
const STAND_CELL := 1
## 앉은 시트 px → 배경 px (그림 세션 확인 그림의 K. 바른 자세 시트를 이 배율로 놓으면 의자 크기와 맞는다)
const SEAT_K := 0.44
const SEAT_LIFT := 30.0 # 앉은 그림이 없어 서 있는 그림으로 대신할 때 발을 자리보다 이만큼 위에
const DISH := 50.0
const NIGHT_DIM := Color(0.85, 0.85, 0.85)
## 화구 고리 (오른쪽 벽 옆모습 화구 둘 위, 누르는 자리)
## 화구 위 조리 도구 (바다 한 접시 cook_tool 그림). 요리 갈래(SpecialGuest.style_of)마다 하나
const COOK_TOOLS := {"grill": "cook_tool/grill", "fry": "cook_tool/fryer", "soup": "cook_tool/stockpot", "braise": "cook_tool/wok", "raw": "cook_tool/knife"}
const COOK_TOOL_W := 72.0
const COOK_TOOL_SINK := 14.0 # 도구 바닥을 화구 자리보다 이만큼 아래에
var _tool_cache := {}


func _tool_tex(style: String) -> Texture2D:
	if not _tool_cache.has(style):
		_tool_cache[style] = _load_art(COOK_TOOLS.get(style, COOK_TOOLS.grill))
	return _tool_cache[style]


## 굽는 중 말풍선 (요리사 머리 위, 한 줄에 생선 하나와 익는 막대)
const BUBBLE_W := 176.0
const BUBBLE_ROW_H := 46.0
const BUBBLE_GAP := 6.0
## 쟁반 자리 (시트에서 쟁반의 회색 금속 부분을 찾아 잰 값). 칸마다 [가로: 칸 가운데에서 칸 폭 비율, 쟁반 윗면: 칸 높이 비율, 쟁반 폭: 칸 폭 비율].
## 빈 배열은 쟁반이 몸에 가려 안 보이는 칸(뒷모습)
const TRAY := {
	"sd/serve_walk": [[0.037, 0.562, 0.41], [0.039, 0.562, 0.41], [], [], [0.268, 0.537, 0.43], [0.231, 0.537, 0.47], [0.245, 0.537, 0.47], [0.247, 0.54, 0.43]],
	"staff/yeoul_sd_walk": [[0.059, 0.537, 0.55], [0.051, 0.536, 0.55], [], [], [0.331, 0.537, 0.33], [0.327, 0.537, 0.34], [0.352, 0.532, 0.29], [0.264, 0.539, 0.39]],
	"staff/yeoul_sd_react": [[], [0.12, 0.558, 0.5], []],
	"sd/stand": [[], [0.0, 0.545, 0.38], []],
}

var logic := DiningLogic.new()
var _guests := {} # guest index → GuestSD
var _faces := {} # 손님 이름 → 그림 id
var _staff := {} # 역할 → StaffDB 정보
var _dish_tex := {} # guest index → Texture2D
var _fish_tex := {} # fish id → Texture2D
var _pops: Array = [] # {t, p, text, color, heart}
var _t := 0.0
var _done := false
var _bg_tex: Texture2D
var _decor_layer: Control # 바, 의자, 장식 (손님 뒤)
var _people: Control # 손님과 가구 덮개 (y 순서로 그린다)
var _props: Array = [] # 4안 물건과 덮개 (Shop4Prop)
var night := true # 저녁 영업. 밤 바탕과 밤 색
var _draw_layer: Control # 사람, 화구, 접시, 말풍선 (손님 앞)
var _decor := [] # [{pos, tex, kind}]
var _taught_plate := false # 처음 노릇할 때 "지금 눌러요" 안내
var _taught_take := false
var _taught_clear := false
var _seat_dish := {} # 자리 → 먹고 간 요리 그림 (빈 그릇 표시)
const PLATES := ["decor/plate_dirty_fish", "decor/plate_dirty", "decor/plate_dirty_rice"]
var _plates := {}


## 빈 그릇 자리: 그 손님 앞 바, 선반, 테이블 위. 화면 좌표, 그릇 아래쪽 근처
func _plate_pos(seat: int) -> Vector2:
	return to_screen(DiningLogic.PLATE_SPOTS[seat])


## 빈 그릇 그림 (자리마다 정해진 하나)
func _plate_tex(seat: int) -> Texture2D:
	var id: String = PLATES[seat % PLATES.size()]
	if not _plates.has(id):
		_plates[id] = _load_art(id)
	return _plates[id]
var _helper_bow := 0.0 # 서빙 알바가 접시를 내려놓고 인사하는 시간
## 요리사 세라: 접시를 담으면 주방 바 쪽(SERA_PASS)으로 몇 걸음 가서 내놓고 돌아온다 (보이기만 하는 움직임, 규칙은 그대로).
## 노릇노릇이면 엄지 척, 타면 곤란한 얼굴 (반응 시트)
const SERA_PASS := Vector2(445 / 982.0, 515 / 1602.0)
## 세라 걷기 시트는 칸 위아래 여백이 커서(인물 471/724, 발 아래 여백 107) 조리 시트(인물 832/887)와 키를 맞춰 크게 그린다
const SERA_WALK_H := CHAR_H * 1.51
const SERA_SPEED := 0.22
const SERA_REACT_T := 0.9
var _sera_pos := DiningLogic.COOK_SPOT
var _sera_path: Array = []
var _sera_dir := Vector2.DOWN
var _sera_react := 0.0
var _sera_react_cell := 0
var _sera_react_next := -1 # 조리대로 돌아오면 보일 반응 칸 (-1이면 없음. 바 쪽은 화구 고리에 얼굴이 가려서 돌아와서)
var _started := false # start 전(prepare)에는 시간이 흐르지 않는다


## 문 열기 전 (대사가 나오는 동안): 바, 의자, 요리사만 보인다
func prepare() -> void:
	logic.helper_serve = StaffDB.in_role(GameState.staff, "serve") != ""
	logic.helper_kitchen = true
	logic.place_staff()
	_staff.clear()
	for role in GameState.staff:
		_staff[role] = StaffDB.get_staff(GameState.staff[role])
	_load_decor()
	show()


func start(day: int, inventory: Array) -> void:
	logic.helper_serve = StaffDB.in_role(GameState.staff, "serve") != ""
	logic.helper_kitchen = true # 요리는 세라가 늘 맡는다
	logic.fry = GameState.flags.has("recipe_fish_fry")
	logic.menu = Menu.menu_list(GameState.flags)
	logic.seafood = GameState.seafood # 새 메뉴 재료는 GameState에서 바로 빠진다
	logic.today = GameState.day
	# 영업 전 메뉴판 (ServicePlan): 값 수준, 생선마다 요리, 오늘 올 단골
	var plan := ServicePlan.plan_of(GameState)
	var pr := ServicePlan.price(plan.price)
	logic.plan = plan
	logic.flags = GameState.flags
	logic.price_mult = float(pr.mult)
	logic.patience_mult = float(pr.patience)
	logic.extra_guests = int(pr.guests)
	logic.regular_names = ServicePlan.regulars(GameState)
	logic.setup(day, inventory, DayFlow.GUESTS, Bus.visitors(GameState.reputation, day))
	logic.place_staff()
	logic.seat_bonus = ShopDecor.seat_comfort(GameState.shop_decor)
	_staff.clear()
	for role in GameState.staff:
		_staff[role] = StaffDB.get_staff(GameState.staff[role])
	logic.pantry = GameState.produce # 곁들임은 GameState에서 바로 빠진다
	logic.reserve = Sides.reserve_for(GameState)
	_load_decor()
	_started = true
	var names := {}
	for s in logic.schedule:
		names[s.name] = true
	var i := 0
	for n in names:
		_faces[n] = GuestSD.face_for(n, i)
		i += 1
	show()


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ArtSlot.has_art(BG):
		_bg_tex = load(ArtSlot.art_path(BG))
	_decor_layer = Control.new()
	_decor_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_decor_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_decor_layer.draw.connect(_draw_decor)
	add_child(_decor_layer)
	_people = Control.new()
	_people.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_people.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_people)
	if _bg_tex:
		_build_shop4()
	_draw_layer = Control.new()
	_draw_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_draw_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_draw_layer.draw.connect(_draw_floor)
	add_child(_draw_layer)
	hide()


## 4안 물건을 모두 놓는다 (Shop4). 손님과 함께 _place_guests가 key 순서로 줄 세운다
func _build_shop4() -> void:
	var dim := Shop4.NIGHT_TINT if night else Color.WHITE
	for it in Shop4.ITEMS:
		var tex := _load_art(Shop4.path(it[0], night, it[7]))
		if tex:
			_add_prop(tex, Shop4.rect_of(it, tex.get_size()), it[4], Color.WHITE if it[6] else dim)
	var stools := []
	for st in Shop4.STOOLS:
		var tex := _load_art(Shop4.DIR + "hall_old_stool_" + st[0])
		stools.append(tex)
		if tex:
			_add_prop(tex, Shop4.stool_rect(st), st[3], dim)
	# 뒷모습 손님 앞에 스툴 아랫부분을 다시 덮는다
	for seat in Shop4.SEAT_STOOL.size():
		var si: int = Shop4.SEAT_STOOL[seat]
		if si >= 0 and stools[si]:
			_add_prop(stools[si], Shop4.stool_rect(Shop4.STOOLS[si]), Shop4.SEAT_KEY[seat] + 0.01, dim, Shop4.stool_cover(Shop4.STOOLS[si]))
	# 칸막이 손님 앞에 2인 테이블 아랫부분
	for it in Shop4.ITEMS:
		if it[0] == "hall_table_2":
			var tex := _load_art(Shop4.path(it[0], night, false))
			if tex:
				var r := Shop4.rect_of(it, tex.get_size())
				_add_prop(tex, r, Shop4.SEAT_KEY[14] + 0.01, dim, [PackedVector2Array([Vector2(r.position.x, Shop4.BOOTH_CUT),
					Vector2(r.end.x, Shop4.BOOTH_CUT), r.end, Vector2(r.position.x, r.end.y)])])
	# 앞벽 들보 (아래쪽 스툴 다리가 들보 뒤로)
	var bm := Shop4.BEAM
	_add_prop(_bg_tex, Rect2(Vector2.ZERO, Shop4.SIZE), Shop4.BEAM_KEY, Color.WHITE,
		[PackedVector2Array([bm.position, Vector2(bm.end.x, bm.position.y), bm.end, Vector2(bm.position.x, bm.end.y)])])


## 4안 꾸미기: 간판, 줄전구, 바 위 소품, 벽 장식, 화분을 4안 빈자리에 얹는다 (ShopDecor.EXTRA_SLOTS의 key 순서로 손님과 함께)
var _decor_props: Array = []
func _load_decor4() -> void:
	for p in _decor_props:
		_props.erase(p)
		p.queue_free()
	_decor_props.clear()
	var dim := Shop4.NIGHT_TINT if night else Color.WHITE
	for sl in ShopDecor.slots():
		if not ShopDecor.DRAWN_KINDS.has(sl.kind) or not sl.has("key"):
			continue
		var art := ShopDecor.art_of(ShopDecor.item_in(GameState.shop_decor, sl.id))
		var tex := _load_art(art) if not art.is_empty() else null
		if tex == null:
			continue
		var glow: bool = ShopDecor.DRAW.get(sl.kind, {}).get("glow", false)
		_add_prop(tex, ShopDecor.draw_rect(sl, tex.get_size()), sl.key, Color.WHITE if glow else dim)
		_decor_props.append(_props[-1])


func _add_prop(tex: Texture2D, r: Rect2, key: float, tint: Color, polys: Array = []) -> void:
	var p := Shop4Prop.new()
	p.dining = self
	p.tex = tex
	p.rect = r
	p.key = key
	p.tint = tint
	p.polys = polys
	_people.add_child(p)
	_props.append(p)


func _load_art(id: String) -> Texture2D:
	return load(ArtSlot.art_path(id)) if ArtSlot.has_art(id) else null


## 배경 그림 비율 → 화면 좌표. 배경은 비율 그대로 화면 안에 다 들어오게(폭에 맞춤) 가운데 놓는다.
## 예전엔 화면을 덮게 키워서 세로가 긴 폰에서 양옆 자리와 화구가 잘렸다 (11-19 사용자). 남는 위아래는 어두운 바탕
func floor_rect() -> Rect2:
	var k := minf(size.x / BG_SIZE.x, size.y / BG_SIZE.y)
	var s := BG_SIZE * k
	return Rect2((size - s) / 2.0, s)


func to_screen(p: Vector2) -> Vector2:
	var r := floor_rect()
	return r.position + p * r.size


## 배경 그림 px → 화면 px
func bg_px(v: float) -> float:
	return v * floor_rect().size.x / BG_SIZE.x


# ─── 가구 ───────────────────────────────────────────

func _load_decor() -> void:
	_decor.clear()
	if not _props.is_empty():
		_load_decor4()
		_decor_layer.queue_redraw()
		return
	for sl in ShopDecor.slots():
		if not ShopDecor.DRAWN_KINDS.has(sl.kind):
			continue # 3안 바탕에 이미 그려진 가구
		var art := ShopDecor.art_of(ShopDecor.item_in(GameState.shop_decor, sl.id))
		var tex := _load_art(art) if not art.is_empty() else null
		if tex:
			_decor.append({"pos": sl.pos, "tex": tex, "kind": sl.kind, "slot": sl,
				"native": ShopDecor.item(ShopDecor.item_in(GameState.shop_decor, sl.id)).get("native", false)})
	_decor_layer.queue_redraw()


## 바, 의자, 장식. 바는 배경 크기 캔버스라 그대로 덮는다. 불빛 말고는 밤 밝기로 조금 누른다
func _draw_decor() -> void:
	_draw_decor_items(_decor_layer, false)


## 가구 그리기. front면 화구, 도구처럼 조리대 위에 놓이는 것만 (요리사 앞)
func _draw_decor_items(ci: Control, front: bool) -> void:
	for d in _decor:
		var tex: Texture2D = d.tex
		var spec: Dictionary = ShopDecor.DRAW.get(d.kind, {"h": 100.0})
		if spec.get("front", false) != front:
			continue
		var col := Color.WHITE if spec.get("glow", false) else NIGHT_DIM
		if spec.get("canvas", false):
			ci.draw_texture_rect(tex, floor_rect(), false, col)
			continue
		var w: float
		var h: float
		var sl: Dictionary = d.slot
		if d.native:
			w = bg_px(tex.get_width())
			h = bg_px(tex.get_height())
		elif sl.has("box"):
			var k := minf(sl.box.x / tex.get_width(), sl.box.y / tex.get_height())
			w = bg_px(tex.get_width() * k)
			h = bg_px(tex.get_height() * k)
		elif sl.has("lamp_h"):
			h = bg_px(sl.lamp_h)
			w = h * tex.get_width() / float(tex.get_height())
		elif spec.has("w"):
			w = bg_px(spec.w)
			h = w * tex.get_height() / float(tex.get_width())
		else:
			h = bg_px(spec.get("h", 100.0))
			w = h * tex.get_width() / float(tex.get_height())
		var at := to_screen(d.pos)
		if spec.get("center", false):
			at.y += h / 2.0
		ci.draw_texture_rect(tex, Rect2(at.x - w / 2.0, at.y - h, w, h), false, col)


# ─── 누르기 ─────────────────────────────────────────

func _gui_input_pos(p: Vector2) -> bool:
	# 화구: 주인공이 굽는 판(helper_kitchen false)에서만 누른다
	for b in (DiningLogic.STOVES if not logic.helper_kitchen else 0):
		var br := _burner_rect(b)
		if br.has_area() and br.grow(8.0).has_point(p):
			var r := logic.plate(b)
			match r:
				"perfect", "good":
					_taught_plate = true
				"early":
					_pop(br.get_center() + Vector2(0, -BUBBLE_ROW_H), "아직 덜 익었어요", UiKit.FOAM, false)
				"full":
					_pop(br.get_center() + Vector2(0, -BUBBLE_ROW_H), "내놓을 자리가 없어요", UiKit.PINK, false)
				"away":
					_pop(br.get_center() + Vector2(0, -BUBBLE_ROW_H), "주방에 아무도 없어요", UiKit.PINK, false)
			return true
	# 내놓는 자리 접시: 가장 가까운 것을 고른다 (다시 누르면 내려놓는다)
	var best := -1
	for i in logic.pass_dishes.size():
		var d := p.distance_to(_pass_pos(i))
		if d <= DISH * 0.9 and (best < 0 or d < p.distance_to(_pass_pos(best))):
			best = i
	if best >= 0:
		if not logic.select(best):
			_pop(_pass_pos(best) + Vector2(0, -DISH), "벌써 나가는 접시예요", UiKit.FOAM, false)
		return true
	# 손님: 고른 접시가 있으면 갖다주고, 빈 그릇 자리면 치운다
	var gi := _guest_at(p)
	if gi >= 0 and logic.selected >= 0:
		match logic.deliver_to(gi):
			"ok":
				_taught_take = true
			"wrong":
				_pop(_bubble_pos(gi) + Vector2(0, -30), "다른 요리를 시켰어요", UiKit.PINK, false)
			"full":
				_pop(_bubble_pos(gi) + Vector2(0, -30), "할 일이 꽉 찼어요", UiKit.PINK, false)
		return true
	var seat := _dirty_at(p)
	if seat >= 0:
		if logic.clear_seat(seat):
			_taught_clear = true
		elif not logic._seat_reserved(seat):
			_pop(_seat_bubble(seat) + Vector2(0, -30), "할 일이 꽉 찼어요", UiKit.PINK, false)
		return true
	if gi >= 0:
		_pop(_bubble_pos(gi) + Vector2(0, -30), "먼저 완성 접시를 골라요", UiKit.FOAM, false)
		return true
	return false


## 누른 곳의 앉은 손님 (말풍선이나 몸)
func _guest_at(p: Vector2) -> int:
	var best := -1
	var best_d := 70.0
	for gi in logic.guests.size():
		if logic.guests[gi].state != DiningLogic.GuestState.SEATED:
			continue
		var body := _seat_screen(gi) - Vector2(0, _head_h(gi) * 0.5)
		var d := minf(p.distance_to(_bubble_pos(gi)) * 0.8, p.distance_to(body))
		if d < best_d:
			best_d = d
			best = gi
	return best


## 누른 곳의 빈 그릇 자리
func _dirty_at(p: Vector2) -> int:
	for seat in logic.dirty:
		if p.distance_to(_plate_pos(seat)) <= 50.0 or p.distance_to(to_screen(DiningLogic.SEATS[seat]) - Vector2(0, 50)) <= 60.0:
			return seat
	return -1


func _unhandled_input(event: InputEvent) -> void:
	if not visible or _done or not _started:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		# 터치는 마우스 눌림으로도 들어와서 이것만 받는다 (두 번 눌리지 않게)
		if _gui_input_pos(event.position):
			get_viewport().set_input_as_handled()


## 내놓는 자리 i번 접시 화면 위치 (주방 바 왼쪽 날개 위)
func _pass_pos(i: int) -> Vector2:
	return to_screen(DiningLogic.PASS_SPOTS[i])


# ─── 진행 ───────────────────────────────────────────

func _process(delta: float) -> void:
	if not visible:
		return
	_t += delta
	_helper_bow = maxf(0.0, _helper_bow - delta)
	_update_sera(delta)
	if _started and not _done:
		logic.update(delta)
		_handle_events()
		if logic.is_over():
			_done = true
			finished.emit({"served": logic.served, "missed": logic.missed + logic.angry, "sales": logic.sales,
				"side_sales": logic.side_sales, "sides": logic.served.filter(func(e): return e.side != "").size(),
				"angry": logic.angry, "sold_out": logic.turned_away, "hearts": logic.served.filter(func(e): return e.heart).size(),
				"burnt": logic.burnt, "perfect": logic.perfect, "angry_list": logic.angry_list})
	for p in _pops:
		p.t += delta
	_pops = _pops.filter(func(p): return p.t < 1.4)
	_place_guests()
	_draw_layer.queue_redraw()


## 문 닫기까지 흐른 게임 시각 (18:00~21:00)
func clock_minutes() -> float:
	return DayFlow.SHOP_OPEN + (DayFlow.SHOP_CLOSE - DayFlow.SHOP_OPEN) * clampf(logic.time / DiningLogic.OPEN_SECONDS, 0.0, 1.0)


func _handle_events() -> void:
	for e in logic.events:
		match e.type:
			"arrive":
				Sound.play_sfx("door", 0.05, -6.0)
				var gi: int = e.guest
				var g: Dictionary = logic.guests[gi]
				var sd := GuestSD.new()
				sd.guest_id = _faces.get(g.name, GuestSD.TEMP_FACES[0])
				sd.size = Vector2(GUEST_H * 0.75, GUEST_H)
				sd.walk = "back"
				sd.flip = false
				if night:
					sd.modulate = Shop4.NIGHT_TINT # 4안 확인 그림처럼 밤에는 손님도 물건과 같은 색
				_people.add_child(sd) # 4안 물건과 함께 key 순서로 (사람과 말풍선 뒤)
				_guests[gi] = sd
				UiKit.fade_in(sd, 0.3)
				_dish_tex[gi] = _load_art(Catalog.dish_art(DiningLogic.dish_art_id(g.fish, g.get("dish", "grill"))))
				if not _fish_tex.has(g.fish):
					_fish_tex[g.fish] = _load_art("fish_" + g.fish)
			"order":
				var gi: int = e.guest
				if _guests.has(gi):
					var sd: GuestSD = _guests[gi]
					var seat_i: int = logic.guests[gi].seat
					sd.walk = ""
					sd.seat = DiningLogic.SEAT_VIEW[seat_i]
					sd.flip = DiningLogic.SEAT_FLIP[seat_i]
					sd.seat_k = bg_px(SEAT_K)
					sd.set_pose("stand")
				Sound.play_sfx("tap", 0.05, -10.0)
			"cook":
				Sound.play_sfx("sizzle", 0.05, -12.0)
			"ready":
				Sound.play_sfx("tick", 0.05)
			"plated":
				var at := _bubble_anchor() + Vector2(-BUBBLE_W / 2.0 - 18.0, -BUBBLE_ROW_H * 1.6)
				if logic.helper_kitchen:
					sera_plated(e.quality)
				match e.quality:
					"perfect":
						Sound.play_sfx("good", 0.05, -4.0)
						Haptics.play("catch")
						_pop(at, "노릇노릇!", UiKit.SUN, false)
					"good":
						Sound.play_sfx("okay", 0.05, -6.0)
						_pop(at, "좋아요", UiKit.FOAM, false)
					"burnt":
						Sound.play_sfx("bad", 0.0, -6.0)
						Haptics.play("lost")
						_pop(at, "탔어요", UiKit.PINK, false)
			"early":
				Sound.play_sfx("tap", 0.05, -10.0)
			"take", "helper_take", "priority":
				Sound.play_sfx("tap", 0.05, -4.0)
				Haptics.play("tap")
			"served":
				var gi: int = e.guest
				Sound.play_sfx("coin", 0.08)
				Haptics.play("catch" if e.heart else "tap")
				if e.helper:
					_helper_bow = 0.6
				if _guests.has(gi):
					var sd2: GuestSD = _guests[gi]
					sd2.set_pose("happy" if e.heart else "eat")
					if e.heart:
						get_tree().create_timer(1.0).timeout.connect(func():
							if is_instance_valid(sd2):
								sd2.set_pose("eat"))
				_pop(_bubble_pos(gi) + Vector2(0, -30), "+" + GameState.format_won(e.price), UiKit.SUN, e.heart)
				if e.side != "":
					_pop(_bubble_pos(gi) + Vector2(0, 4), Sides.name_of(e.side) + " 곁들임", UiKit.LEAF, false)
			"angry":
				var gi: int = e.guest
				Sound.play_sfx("bad", 0.0, -6.0)
				Haptics.play("lost")
				if _guests.has(gi):
					_guests[gi].set_pose("sad")
				# 왜 화났는지 보여 준다: 접시가 나와 있었는데 안 날랐는지, 아직 굽는 중이었는지
				var why := "접시가 나와 있었는데..." if e.get("reason", "") == "pass" else "너무 오래 걸려요"
				_pop(_bubble_pos(gi) + Vector2(0, -30), why, UiKit.PINK, false)
				_leave(gi, 0.9)
			"left":
				_seat_dish[logic.guests[e.guest].seat] = _dish_tex.get(e.guest)
				_leave(e.guest, 0.0)
			"cleared":
				Sound.play_sfx("tap", 0.05, -6.0)
			"wrong":
				Sound.play_sfx("bad", 0.0, -12.0)
			"select", "queued", "queued_clear":
				Sound.play_sfx("tap", 0.05, -8.0)
			"sold_out":
				Sound.play_sfx("okay", 0.0, -6.0)
				_pop(Vector2(size.x / 2.0, to_screen(Vector2(0.5, 0.24)).y), "재료 소진! 오늘은 여기까지", UiKit.SUN, false)
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


## 앉은 손님 엉덩이 자리에서 머리 꼭대기까지 (화면 px). 그림을 모르면 보통 키
func _head_h(gi: int) -> float:
	if _guests.has(gi):
		var top: float = _guests[gi].seated_top()
		if top > 0.0:
			return top
	return bg_px(140.0)


## 말풍선 놓는 쪽: 0 머리 위, -1 왼쪽, 1 오른쪽. 테이블 손님은 머리 위에 두면 맞은편 손님 얼굴을 가려서 옆으로
const BUBBLE_SIDE := [0, 0, 0, 0, 0, 0, -1, 1, -1, 1, -1, 1, -1, 1, 0, 0]


## 주문 말풍선 자리
func _bubble_pos(gi: int) -> Vector2:
	return _bubble_at(logic.guests[gi].seat, _head_h(gi))


func _seat_bubble(seat_i: int) -> Vector2:
	return _bubble_at(seat_i, bg_px(140.0))


func _bubble_at(seat_i: int, head: float) -> Vector2:
	var at := to_screen(DiningLogic.SEATS[seat_i])
	var side: int = BUBBLE_SIDE[seat_i]
	if side == 0:
		return at - Vector2(0, head + 30.0)
	return at + Vector2(side * bg_px(72.0), -head * 0.72)


## 손님을 자리에 놓고, 손님과 가구 덮개를 위에서 아래 순서로 다시 줄 세운다
func _place_guests() -> void:
	var order := []
	for pr in _props:
		order.append([pr.key, pr])
	for gi in _guests:
		var sd: GuestSD = _guests[gi]
		var g: Dictionary = logic.guests[gi]
		if g.state == DiningLogic.GuestState.WALKING:
			var dir: Vector2 = g.dir
			if absf(dir.x) >= absf(dir.y):
				sd.walk = "side"
				sd.flip = dir.x < 0.0
			else:
				sd.walk = "back" if dir.y < 0.0 else "front"
				sd.flip = false
			sd.position = to_screen(g.pos) - Vector2(sd.size.x / 2.0, sd.size.y)
			order.append([float(g.pos.y) * Shop4.SIZE.y, sd])
			continue
		var seat_i: int = g.seat
		var at := _seat_screen(gi)
		if sd.seated() and sd.seat_k > 0.0:
			sd.position = at # 원점이 엉덩이 자리
		else:
			sd.position = at - Vector2(sd.size.x / 2.0, sd.size.y + SEAT_LIFT)
		order.append([float(Shop4.SEAT_KEY[seat_i]), sd])
	order.sort_custom(func(a, b): return a[0] < b[0])
	for i in order.size():
		if order[i][1].get_index() != i:
			_people.move_child(order[i][1], i)


# ─── 그리기 ─────────────────────────────────────────
# 화구 고리, 기다림 고리는 판정을 보여 주는 요소라 코드로 그린다. 그림은 모두 받은 그림이다.

func _draw_floor() -> void:
	var ci := _draw_layer
	var font := UiKit.font("cute")
	_draw_cook(ci)
	_draw_decor_items(ci, true) # 화구, 도구
	# 화구 위 조리 도구: 요리법마다 맞는 도구 (구이 석쇠, 튀김 튀김솥, 국물 들통, 조림 웍, 회 칼).
	# 구이만 석쇠 위에 생선이 보이고 익는 색이 든다. 나머지는 도구만 살짝 흔들리고, 익는 정도는 옆 말풍선이 알려 준다
	for c in logic.cooking:
		var bp := to_screen(DiningLogic.BURNERS[c.burner])
		var g: Dictionary = logic.guests[c.guest]
		var style := SpecialGuest.style_of(g.get("dish", "grill"))
		var tool: Texture2D = _tool_tex(style)
		var jig := sin(_t * (14.0 if style != "soup" else 6.0) + c.burner) * (1.2 if style != "braise" else 2.4)
		var tint := Color(1, 1, 1).lerp(Color(0.85, 0.6, 0.35), clampf(DiningLogic.doneness(c), 0.0, 1.0))
		if float(c.t) - float(c.total) > DiningLogic.GOLD:
			tint = tint.lerp(Color(0.35, 0.25, 0.2), clampf((float(c.t) - float(c.total) - DiningLogic.GOLD) / (DiningLogic.BURN - DiningLogic.GOLD), 0.0, 1.0))
		var top := bp.y
		if tool:
			var tw := COOK_TOOL_W
			var th := tw * tool.get_height() / float(tool.get_width())
			var tr := Rect2(bp.x - tw / 2.0, bp.y + COOK_TOOL_SINK - th + (jig if style != "grill" else 0.0), tw, th)
			ci.draw_texture_rect(tool, tr, false)
			top = tr.position.y + th * 0.18 # 석쇠 윗면
		if style == "grill" or tool == null:
			var ft: Texture2D = _fish_tex.get(g.fish)
			if ft:
				var w := 46.0
				var h := w * ft.get_height() / float(ft.get_width())
				ci.draw_texture_rect(ft, Rect2(bp.x - w / 2.0, top - h * 0.55 + jig, w, h), false, tint)
	_draw_burner_ui(ci, font)
	# 처음 한 번씩 화면 아래에 짧게 알려 준다
	var hint_at := Vector2(size.x / 2.0, to_screen(Vector2(0.5, 0.975)).y)
	_bottom_hint = _started and not _done and ((not logic.pass_dishes.is_empty() or logic.selected >= 0) and not _taught_take or not logic.dirty.is_empty() and not _taught_clear)
	if _done or not _started:
		pass
	elif not logic.pass_dishes.is_empty() and not _taught_take and logic.selected < 0:
		_caption(ci, font, hint_at, "픽업대에 나온 접시를 눌러요")
	elif logic.selected >= 0 and not _taught_take:
		_caption(ci, font, hint_at, "반짝이는 손님을 누르면 갖다줘요")
	elif not logic.dirty.is_empty() and not _taught_clear:
		_caption(ci, font, hint_at, "빈 그릇을 눌러서 치워요. 치워야 손님이 앉아요")
	# 빈 그릇 (다 먹고 간 자리)
	# 그림: decor/plate_dirty*.png (그림 세션 11-16). 자리마다 셋 중 하나, 아래 가운데를 바 위에. 치우러 가는 중이면 흐리게
	for seat in logic.dirty:
		var bp := _plate_pos(seat)
		var faded := logic._seat_reserved(seat)
		var tex: Texture2D = _plate_tex(seat)
		if tex == null:
			tex = _seat_dish.get(seat)
		if tex == null:
			continue
		var w := 60.0
		var h := w * tex.get_height() / float(tex.get_width())
		if not faded:
			_ellipse(ci, bp + Vector2(0, h * 0.35), 34.0 + sin(_t * 4.0) * 2.0, Color(UiKit.FOAM, 0.35), 3.0)
		ci.draw_texture_rect(tex, Rect2(bp.x - w / 2.0, bp.y + h * 0.4 - h, w, h), false, Color(1, 1, 1, 0.45 if faded else 1.0))
	# 손님 말풍선: 주문한 요리와 기다림 고리
	for gi in logic.guests.size():
		var g: Dictionary = logic.guests[gi]
		if g.state != DiningLogic.GuestState.SEATED:
			continue
		var p := _bubble_pos(gi)
		var left: float = 1.0 - float(g.wait) / float(g.get("patience", logic.patience_of(g.seat)))
		# 손님 종류 이름표 (급해요, 미식가, 단골 이름)
		var tag: String = ServicePlan.KINDS.get(g.get("kind", "normal"), {}).get("tag", "")
		if g.get("kind", "") == "regular":
			tag = Friends.person(g.name).get("call", g.name)
		if not tag.is_empty():
			_caption_small(ci, font, p + Vector2(0, -44.0), tag, UiKit.SUN if g.get("kind", "") == "regular" else UiKit.FOAM)
		var col := UiKit.LEAF if left > 0.5 else (UiKit.SUN if left > 0.2 else UiKit.DANGER)
		var r := 26.0
		var carried := gi == logic.holding or gi == logic.helper_dish or logic._dish_reserved(gi)
		var can_take: bool = logic.selected >= 0 and not carried and logic.same_order(gi, logic.selected) and logic._waiting_dish(gi)
		if can_take:
			ci.draw_circle(p, r + 11.0 + sin(_t * 9.0) * 3.0, Color(UiKit.SUN, 0.6))
		elif carried:
			ci.draw_circle(p, r + 9.0 + sin(_t * 8.0) * 2.0, Color(UiKit.SUN, 0.5))
		ci.draw_circle(p, r + 3.0, UiKit.OUTLINE)
		ci.draw_circle(p, r, UiKit.PAPER)
		ci.draw_arc(p, r + 5.0, -PI / 2.0, -PI / 2.0 + TAU * clampf(left, 0.0, 1.0), 36, col, 5.0, true)
		_dish(ci, gi, p, r * 1.55, 1.0)
	_draw_hall(ci)
	# 픽업대: 완성 접시 (눌러서 갖다준다). 4안은 홀 자리 바로 위라 주인공보다 나중에 그려야 보인다
	for i in logic.pass_dishes.size():
		var gi_d: int = logic.pass_dishes[i]
		var lift := -22.0 if gi_d == logic.selected else 0.0
		var p := _pass_pos(i) + Vector2(0, -8.0 + lift + sin(_t * 5.0 + i) * 2.0)
		var going := logic._dish_reserved(gi_d)
		if gi_d == logic.selected:
			ci.draw_circle(p, DISH * 0.62, Color(UiKit.SUN, 0.45 + 0.2 * sin(_t * 8.0)))
		_dish(ci, gi_d, p, DISH, 0.55 if going else 1.0)
	# 튀어 오르는 글자
	for p in _pops:
		var k: float = p.t / 1.4
		var at: Vector2 = p.p + Vector2(0, -40.0 * k)
		var a := 1.0 - maxf(0.0, k - 0.6) / 0.4
		var w := font.get_string_size(p.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 28).x
		var x := clampf(at.x - w / 2.0 + (16.0 if p.heart else 0.0), 8.0, size.x - w - 8.0)
		ci.draw_string_outline(font, Vector2(x, at.y), p.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 28, 9, Color(UiKit.OUTLINE, a))
		ci.draw_string(font, Vector2(x, at.y), p.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color(p.color, a))
		if p.heart:
			_heart(ci, Vector2(x - 22.0, at.y - 10.0), 12.0, Color(UiKit.CORAL, a))
	if logic.time_left() <= 0.0 and not _done:
		_caption(ci, font, Vector2(size.x / 2.0, to_screen(Vector2(0.5, 0.24)).y), "마감! 남은 손님만 받아요")
	elif _started and not _done and not _bottom_hint:
		# 지금 할 일 한 줄 (처음 배우는 아래 안내가 떠 있을 때는 겹치지 않게 숨긴다) (흐름이 헷갈리지 않게)
		_caption(ci, font, Vector2(size.x / 2.0, to_screen(Vector2(0.5, 0.0)).y + 150.0), ServicePlan.hint(logic))


## 세라가 접시를 담았다: 바 쪽으로 갔다 돌아오고, 돌아오면 결과에 따라 반응
func sera_plated(quality: String) -> void:
	_sera_path = [SERA_PASS, DiningLogic.COOK_SPOT]
	_sera_react_next = {"perfect": 1, "burnt": 2}.get(quality, -1)


func _update_sera(delta: float) -> void:
	if _sera_react > 0.0:
		_sera_react = maxf(0.0, _sera_react - delta)
		return
	if _sera_path.is_empty():
		return
	var target: Vector2 = _sera_path[0]
	var d := target - _sera_pos
	var step := SERA_SPEED * delta
	if d.length() <= step:
		_sera_pos = target
		_sera_path.pop_front()
		if _sera_path.is_empty() and _sera_react_next >= 0:
			_sera_react_cell = _sera_react_next
			_sera_react = SERA_REACT_T
			_sera_react_next = -1
	else:
		_sera_dir = d.normalized()
		_sera_pos += _sera_dir * step


func sera_moving() -> bool:
	return not _sera_path.is_empty() and _sera_react <= 0.0


## 요리사: 주방 알바가 있으면 세라, 없으면 주인공 (조리대 뒤에 서서 손님 쪽을 본다)
func _draw_cook(ci: Control) -> void:
	var at := to_screen(DiningLogic.COOK_SPOT)
	if logic.helper_kitchen:
		var cook: String = StaffDB.COOK.sd_cook
		var walk: String = StaffDB.COOK.get("sd_walk", "")
		var react: String = StaffDB.COOK.get("sd_react", "")
		if _sera_react > 0.0 and react != "" and _has_sheet(react):
			_draw_cell(ci, react, 3, _sera_react_cell, to_screen(_sera_pos), CHAR_H * 1.05, false)
			return
		var grid: bool = StaffDB.COOK.get("grid", false)
		if sera_moving() and walk != "" and _has_sheet(walk):
			var wc := GuestSD.walk_cell(_sera_dir, _t)
			if grid:
				_draw_grid(ci, walk, wc, to_screen(_sera_pos), SERA_BODY_H, wc >= 4 and _sera_dir.x < 0.0)
				return
			var feet := to_screen(_sera_pos) + Vector2(0, SERA_WALK_H * 107.0 / 724.0 - CHAR_H * 1.05 * 27.0 / 887.0)
			_draw_cell(ci, walk, 8, wc, feet, SERA_WALK_H, wc >= 4 and _sera_dir.x < 0.0)
			return
		if cook != "" and _has_sheet(cook):
			if grid:
				_draw_grid(ci, cook, _sera_cook_cell(), at, SERA_BODY_H, false)
				return
			var cell := (1 + int(_t * 4.0) % 2) if not logic.cooking.is_empty() else 0
			_draw_cell(ci, cook, 4, cell, at, CHAR_H * 1.05, false)
		return
	if logic.at_stove() or logic.player.distance_to(DiningLogic.COOK_SPOT) < 0.01:
		# 주인공이 조리대 뒤에 서 있다. 굽는 중이면 살짝 들썩인다
		var bob := absf(sin(_t * 6.0)) * 2.0 if not logic.cooking.is_empty() else 0.0
		if _has_sheet(STAND_SHEET):
			_draw_cell(ci, STAND_SHEET, 3, 0, at + Vector2(0, -bob), PLAYER_H, false)
		elif _has_sheet("sd/walk"):
			_draw_cell(ci, "sd/walk", 8, STAND_CELL, at + Vector2(0, -bob), PLAYER_H, false)


## 화구 고리: 굽는 중(하늘색 차오름) → 노릇노릇(금빛, 지금 누르기) → 지나감(주황) → 타기 직전(빨강)
func _draw_burner_ui(ci: Control, font: Font) -> void:
	var rows := _cook_rows()
	if rows.is_empty():
		return
	var tip := _bubble_anchor()
	var r0 := _row_rect(0, rows.size())
	var mid := (r0.position.y + _row_rect(rows.size() - 1, rows.size()).end.y) / 2.0
	# 말풍선 꼬리 (오른쪽 요리사 쪽)
	var tail := PackedVector2Array([Vector2(r0.end.x - 4.0, mid - 10.0), Vector2(r0.end.x - 4.0, mid + 10.0), Vector2(tip.x, tip.y)])
	ci.draw_colored_polygon(tail, UiKit.PAPER)
	ci.draw_polyline(PackedVector2Array([tail[0], tail[2], tail[1]]), UiKit.OUTLINE, 3.0, true)
	for k in rows.size():
		var c: Dictionary = rows[k]
		var r := _row_rect(k, rows.size())
		var d := DiningLogic.doneness(c)
		var over := float(c.t) - float(c.total)
		var col := UiKit.SKY
		var frac := clampf(d, 0.0, 1.0)
		var bg := UiKit.PAPER
		if over >= 0.0:
			frac = 1.0
			if over <= DiningLogic.GOLD:
				col = UiKit.SUN
				bg = UiKit.GOLD_SOFT
				var pulse := 0.5 + 0.5 * sin(_t * 10.0)
				ci.draw_style_box(UiKit.box(Color(UiKit.SUN, 0.35 + 0.25 * pulse), 20), r.grow(4.0 + pulse * 3.0))
			elif over <= DiningLogic.BURN - 1.5:
				col = UiKit.CORAL
			else:
				col = UiKit.DANGER
		ci.draw_style_box(UiKit.chunky(bg, 16, 0, 3), r)
		var ft: Texture2D = _fish_tex.get(logic.guests[c.guest].fish)
		if ft:
			var w := 36.0
			var h := w * ft.get_height() / float(ft.get_width())
			ci.draw_texture_rect(ft, Rect2(r.position.x + 10.0, r.position.y + (r.size.y - 3.0 - h) / 2.0, w, h), false)
		var bar := Rect2(r.position.x + 54.0, r.position.y + (r.size.y - 3.0) / 2.0 - 6.0, r.size.x - 68.0, 12.0)
		ci.draw_style_box(UiKit.box(Color(UiKit.INK, 0.15), 6), bar)
		if frac > 0.0:
			ci.draw_style_box(UiKit.box(col, 6), Rect2(bar.position, Vector2(maxf(bar.size.x * frac, 12.0), bar.size.y)))
		if over >= 0.0 and over <= DiningLogic.GOLD and logic.at_stove() and not _taught_plate:
			_caption(ci, font, Vector2(r.get_center().x, _row_rect(rows.size() - 1, rows.size()).end.y + 30.0), "지금 눌러요!")


## 굽는 중인 것만 화구 순서대로
func _cook_rows() -> Array:
	var out := []
	for b in DiningLogic.STOVES:
		for x in logic.cooking:
			if int(x.burner) == b:
				out.append(x)
	return out


## 말풍선 꼬리 끝: 요리사 가슴 왼쪽
func _bubble_anchor() -> Vector2:
	var at := to_screen(DiningLogic.COOK_SPOT)
	var body := SERA_BODY_H if logic.helper_kitchen else PLAYER_H * 0.67
	return Vector2(at.x - body * 0.28, at.y - body * 0.6)


## 말풍선 k번째 줄 (n줄 중). 요리사 왼쪽 주방 바닥에 세로로 쌓는다
func _row_rect(k: int, n: int) -> Rect2:
	var tip := _bubble_anchor()
	var fr := floor_rect()
	var x := maxf(tip.x - 18.0 - BUBBLE_W, fr.position.x + 8.0)
	var h := n * BUBBLE_ROW_H + (n - 1) * BUBBLE_GAP
	var top := tip.y - h / 2.0
	return Rect2(x, top + k * (BUBBLE_ROW_H + BUBBLE_GAP), BUBBLE_W, BUBBLE_ROW_H)


## 화구 b가 말풍선에서 차지하는 줄 (굽는 중이 아니면 빈 상자)
func _burner_rect(b: int) -> Rect2:
	var rows := _cook_rows()
	for k in rows.size():
		if int(rows[k].burner) == b:
			return _row_rect(k, rows.size())
	return Rect2()

## 홀: 서빙 알바와 (홀에 나와 있으면) 주인공. y 순서로 그린다
func _draw_hall(ci: Control) -> void:
	var people := []
	if logic.helper_serve and _staff.has("serve"):
		people.append({"who": "helper", "y": logic.helper.y})
	var player_in_kitchen := not logic.helper_kitchen and logic.player.distance_to(DiningLogic.COOK_SPOT) < 0.01
	if not player_in_kitchen:
		people.append({"who": "player", "y": logic.player.y})
	people.sort_custom(func(a, b): return a.y < b.y)
	for p in people:
		if p.who == "helper":
			_draw_helper(ci)
		else:
			_draw_player_walk(ci)


func _draw_player_walk(ci: Control) -> void:
	var pp := to_screen(logic.player)
	var moving := not logic.player_path.is_empty()
	var sheet := "sd/serve_walk" if logic.holding >= 0 or logic.carrying_dirty else "sd/walk"
	if not _has_sheet(sheet):
		return
	if not moving and _has_sheet(STAND_SHEET):
		# 서기 시트: 0 빈손 대기, 1 빈 쟁반 들기, 2 숨쉬기 (0과 번갈아)
		var sc := 1 if logic.holding >= 0 or logic.carrying_dirty else (2 if fmod(_t, 2.4) > 1.8 else 0)
		_draw_cell(ci, STAND_SHEET, 3, sc, pp, PLAYER_H, false)
		if logic.holding >= 0:
			_dish_on_tray(ci, logic.holding, STAND_SHEET, 3, sc, pp, PLAYER_H, false)
		return
	var cell := GuestSD.walk_cell(logic.player_dir, _t) if moving else STAND_CELL
	var flip := cell >= 4 and logic.player_dir.x < 0.0
	_draw_cell(ci, sheet, 8, cell, pp, PLAYER_H, flip)
	if logic.holding >= 0:
		_dish_on_tray(ci, logic.holding, sheet, 8, cell, pp, PLAYER_H, flip)


func _draw_helper(ci: Control) -> void:
	var st: Dictionary = _staff.serve
	var at := to_screen(logic.helper)
	var walk_sheet: String = st.get("sd_walk", "")
	var react: String = st.get("sd_react", "")
	var moving := not logic.helper_path.is_empty()
	if moving and walk_sheet != "" and _has_sheet(walk_sheet):
		var cell := GuestSD.walk_cell(logic.helper_dir, _t)
		var flip := cell >= 4 and logic.helper_dir.x < 0.0
		_draw_cell(ci, walk_sheet, 8, cell, at, CHAR_H * SHEET_WALK_SCALE, flip)
		if logic.helper_dish >= 0:
			_dish_on_tray(ci, logic.helper_dish, walk_sheet, 8, cell, at, CHAR_H * SHEET_WALK_SCALE, flip)
	elif react != "" and _has_sheet(react):
		# 서 있을 때: 대기(쟁반 옆구리), 막 내려놓았으면 꾸벅 인사
		_draw_cell(ci, react, 3, 2 if _helper_bow > 0.0 else 0, at, CHAR_H * 1.05, false)


func _caption(ci: Control, font: Font, at: Vector2, t: String) -> void:
	var w := font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x
	var x := clampf(at.x - w / 2.0, 26.0, size.x - w - 26.0)
	var y := at.y + sin(_t * 4.0) * 2.0
	# 지붕, 바닥 그림 위에서도 읽히게 반투명 둥근 띠를 깐다
	var asc := font.get_ascent(24)
	ci.draw_style_box(UiKit.box(Color(UiKit.NIGHT_DEEP, 0.72), 22), Rect2(x - 18.0, y - asc - 10.0, w + 36.0, asc + font.get_descent(24) + 20.0))
	ci.draw_string_outline(font, Vector2(x, y), t, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, 9, UiKit.OUTLINE)
	ci.draw_string(font, Vector2(x, y), t, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, UiKit.FOAM)


## 든 접시를 그 칸의 쟁반 위에 (TRAY). 뒷모습 칸은 쟁반이 가려서 그리지 않는다
func _dish_on_tray(ci: Control, gi: int, path: String, n: int, i: int, feet: Vector2, cell_h: float, flip: bool) -> void:
	if not TRAY.has(path):
		return
	var tr: Array = TRAY[path][i]
	if tr.is_empty():
		return
	var w := _cell_w(path, n, i, cell_h)
	var x := feet.x + float(tr[0]) * w * (-1.0 if flip else 1.0)
	var top := feet.y - cell_h + float(tr[1]) * cell_h
	var dw := maxf(float(tr[2]) * w, 34.0)
	var tex: Texture2D = _dish_tex.get(gi)
	var dh := dw * (tex.get_height() / float(tex.get_width()) if tex else 0.6)
	_dish(ci, gi, Vector2(x, top - dh * 0.28), dw, 1.0)


func _cell_w(path: String, n: int, i: int, cell_h: float) -> float:
	var e := _sheet(path, n)
	return cell_h * (e.cuts[i + 1] - e.cuts[i]) / float(e.tex.get_height())


## 한 줄 시트 (assets/art/<path>.png, n칸). 칸 경계는 가장 빈 열에서 찾는다 (GuestSD.find_cuts_n)
static var _sheet_cache := {}


static func _has_sheet(path: String) -> bool:
	return ResourceLoader.exists("res://assets/art/%s.png" % path)


static func _sheet(path: String, n: int) -> Dictionary:
	var key := "%s/%d" % [path, n]
	if _sheet_cache.has(key):
		return _sheet_cache[key]
	var tex: Texture2D = load("res://assets/art/%s.png" % path)
	var img := tex.get_image()
	if img.is_compressed():
		img.decompress()
	var cols := PackedFloat32Array()
	cols.resize(img.get_width())
	for x in img.get_width():
		var s := 0.0
		for y in range(0, img.get_height(), 6):
			s += img.get_pixel(x, y).a
		cols[x] = s
	var e := {"tex": tex, "cuts": GuestSD.find_cuts_n(cols, n)}
	_sheet_cache[key] = e
	return e


## 시트의 한 칸을 발이 feet에 오게 그린다. 칸 전체 높이를 cell_h로
func _draw_cell(ci: Control, path: String, n: int, i: int, feet: Vector2, cell_h: float, flip: bool) -> void:
	var e := _sheet(path, n)
	var tex: Texture2D = e.tex
	var src := Rect2(e.cuts[i], 0, e.cuts[i + 1] - e.cuts[i], tex.get_height())
	var w := cell_h * src.size.x / src.size.y
	ci.draw_set_transform(feet, 0.0, Vector2(-1.0 if flip else 1.0, 1.0))
	ci.draw_texture_rect_region(tex, Rect2(-w / 2.0, -cell_h, w, cell_h), src)
	ci.draw_set_transform_matrix(Transform2D.IDENTITY)


func _dish(ci: Control, gi: int, c: Vector2, w: float, alpha: float) -> void:
	var tex: Texture2D = _dish_tex.get(gi)
	if tex == null:
		ci.draw_circle(c, w * 0.3, Color(UiKit.CORAL, alpha))
		return
	var h := w * tex.get_height() / float(tex.get_width())
	ci.draw_texture_rect(tex, Rect2(c.x - w / 2.0, c.y - h / 2.0, w, h), false, Color(1, 1, 1, alpha))


func _heart(ci: Control, c: Vector2, r: float, col: Color) -> void:
	ci.draw_circle(c + Vector2(-r * 0.5, 0), r * 0.55, col)
	ci.draw_circle(c + Vector2(r * 0.5, 0), r * 0.55, col)
	ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-r * 1.02, r * 0.15), c + Vector2(r * 1.02, r * 0.15), c + Vector2(0, r * 1.25)]), col)


## 바닥에 눕힌 고리 (빈 그릇 자리 표시)
func _ellipse(ci: Control, c: Vector2, r: float, col: Color, width: float) -> void:
	ci.draw_set_transform(c, 0.0, Vector2(1.0, 0.4))
	ci.draw_arc(Vector2.ZERO, r, 0.0, TAU, 32, col, width / 0.4 * 0.5, true)
	ci.draw_set_transform_matrix(Transform2D.IDENTITY)


var _bottom_hint := false


## 작은 이름표 글자 (손님 종류)
func _caption_small(ci: Control, font: Font, at: Vector2, t: String, col: Color) -> void:
	var w := font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x
	var x := clampf(at.x - w / 2.0, 6.0, size.x - w - 6.0)
	ci.draw_string_outline(font, Vector2(x, at.y), t, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, 7, UiKit.OUTLINE)
	ci.draw_string(font, Vector2(x, at.y), t, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, col)


# ─── 세라 v2 격자 시트 (11-19) ─────────────────────────

## 세라 몸 높이 (발끝에서 머리끝까지 화면 px). 예전 시트와 같은 키
const SERA_BODY_H := CHAR_H * 1.05 * 0.946
## 조리 칸 차례: 굽는 동안 올리기 → 뒤집기 → 흔들기 둘 → 소금 → 흔들기 둘. 다 익은 접시가 있으면 담기 → 내밀기. 쉴 땐 기다리기
const SERA_COOK_LOOP := [0, 1, 2, 3, 2, 3, 4, 2, 3]


func _sera_cook_cell() -> int:
	if logic.cooking.is_empty():
		return 7
	for c in logic.cooking:
		if DiningLogic.doneness(c) >= 1.0:
			return 5 if int(_t * 2.0) % 2 == 0 else 6
	return SERA_COOK_LOOP[int(_t * 2.5) % SERA_COOK_LOOP.size()]


static var _grid_cache := {}


## 격자 시트(4열 2줄) 칸마다 그림이 차지하는 영역 (알파로 잰다)
static func _grid_info(path: String) -> Dictionary:
	if _grid_cache.has(path):
		return _grid_cache[path]
	var tex: Texture2D = load("res://assets/art/%s.png" % path)
	var img := tex.get_image()
	if img.is_compressed():
		img.decompress()
	var cw := img.get_width() / 4
	var chh := img.get_height() / 2
	var boxes := []
	var tallest := 1.0
	for i in 8:
		var r := Rect2i((i % 4) * cw, (i / 4) * chh, cw, chh)
		var u := img.get_region(r).get_used_rect()
		boxes.append(Rect2(r.position + u.position, u.size))
		tallest = maxf(tallest, float(u.size.y))
	var e := {"tex": tex, "boxes": boxes, "tallest": tallest}
	_grid_cache[path] = e
	return e


## 격자 칸 i의 그림을 발끝이 feet에 오게 그린다. body_h: 가장 큰 칸의 키가 이 높이가 되게 줄인다
func _draw_grid(ci: Control, path: String, i: int, feet: Vector2, body_h: float, flip: bool) -> void:
	var e := _grid_info(path)
	var box: Rect2 = e.boxes[clampi(i, 0, 7)]
	var k: float = body_h / float(e.tallest)
	var w := box.size.x * k
	var h := box.size.y * k
	ci.draw_set_transform(feet, 0.0, Vector2(-1.0 if flip else 1.0, 1.0))
	ci.draw_texture_rect_region(e.tex, Rect2(-w / 2.0, -h, w, h), box)
	ci.draw_set_transform_matrix(Transform2D.IDENTITY)
