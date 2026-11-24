class_name Shop4View
extends Control
## 식당 4안 정지 화면 (손님 없이 바탕과 물건만). 첫날 튜토리얼처럼 영업 판이 아닌 장면의 배경으로 쓴다.
## 바탕과 물건을 Shop4.ITEMS, STOOLS, 가게 꾸미기(ShopDecor) 순서 그대로 한 번에 그린다. 화면을 비율 그대로 덮고 넘치는 쪽은 가운데 기준으로 잘린다.
## 4안 그림이 없으면 아무것도 그리지 않는다 (has_art로 먼저 확인)

var night := false
var decor := {} # 가게 꾸미기 (GameState.shop_decor를 부르는 쪽이 넣는다. 여기서 GameState를 부르면 헤드리스 시험에서 못 읽는다)
var kitchen := {} # 주방 장비 단계 (GameState.kitchen)
var _layers: Array = [] # [key, tex, rect(바탕 px), tint, src(바탕 띠, 없으면 Rect2())]
var _bg: Texture2D


static func has_art(is_night := false) -> bool:
	return ArtSlot.has_art(Shop4.bg_id(is_night))


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build()
	resized.connect(queue_redraw)


func _tex(id: String) -> Texture2D:
	return load(ArtSlot.art_path(id)) if ArtSlot.has_art(id) else null


func _build() -> void:
	_layers.clear()
	_bg = _tex(Shop4.bg_id(night))
	if _bg == null:
		return
	var dim := Shop4.NIGHT_TINT if night else Color.WHITE
	for it in Shop4.ITEMS:
		var t := _tex(Shop4.path(it[0], night, it[7], kitchen))
		if t:
			_layers.append([float(it[4]), t, Shop4.rect_of(it, t.get_size()), Color.WHITE if it[6] else dim, Rect2()])
	for st in Shop4.STOOLS:
		var t := _tex(Shop4.DIR + "hall_old_stool_" + st[0])
		if t:
			_layers.append([float(st[3]), t, Shop4.stool_rect(st), dim, Rect2()])
	for sl in ShopDecor.slots():
		if not ShopDecor.DRAWN_KINDS.has(sl.kind) or not sl.has("key"):
			continue
		var art := ShopDecor.art_of(ShopDecor.item_in(decor, sl.id))
		var t := _tex(art) if not art.is_empty() else null
		if t:
			var glow: bool = ShopDecor.DRAW.get(sl.kind, {}).get("glow", false)
			_layers.append([float(sl.key), t, ShopDecor.draw_rect(sl, t.get_size()), Color.WHITE if glow else dim, Rect2()])
	# 앞벽 들보 (아래쪽 스툴 다리가 들보 뒤로)
	_layers.append([Shop4.BEAM_KEY, _bg, Shop4.BEAM, Color.WHITE, Shop4.BEAM])
	_layers.sort_custom(func(a, b): return a[0] < b[0])


## 바탕 비율 → 화면 영역 (DiningFloor.floor_rect와 같은 덮기)
func floor_rect() -> Rect2:
	var k := maxf(size.x / Shop4.SIZE.x, size.y / Shop4.SIZE.y)
	var s := Shop4.SIZE * k
	return Rect2((size - s) / 2.0, s)


func _draw() -> void:
	if _bg == null:
		return
	var fr := floor_rect()
	var k := fr.size.x / Shop4.SIZE.x
	draw_texture_rect(_bg, fr, false)
	for l in _layers:
		var r: Rect2 = l[2]
		var dst := Rect2(fr.position + r.position * k, r.size * k)
		var src: Rect2 = l[4]
		if src.has_area():
			draw_texture_rect_region(l[1], dst, src, l[3])
		else:
			draw_texture_rect(l[1], dst, false, l[3])
