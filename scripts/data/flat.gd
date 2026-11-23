class_name Flat
extends RefCounted
## 갯벌 채집 (2026-11-19 사용자: 낚시만 하니 심심하다 → 낮에 할 거리)
##
## - 복자 할머니가 알려 준 뒤에 열린다 (Story bokja_flat → flags.flat_open, 지도 "flat")
## - 물이 빠졌을 때(간조 앞뒤, Spots.rocks_windows)이면서 낮(OPEN~CLOSE)에만 들어간다. 물이 들어오면 나와야 한다
## - 판은 COLS x ROWS 칸. 어떤 칸에는 조개나 게, 낙지가 숨어 있다. 숨구멍(작은 구멍)이 보이는 칸이 수상하다.
##   진짜 숨구멍 말고 그냥 구멍(DECOY)도 있다. 한 번 파는 데 DIG_MIN분이 들고 한 번 들어가면 DIGS번까지 판다
## - 캔 것은 GameState.seafood {id: 개수}. 새 메뉴 재료(Menu), 선물(Friends)로 쓴다. 이틀 뒤 밤에 상하지 않는다(조개는 해감해 둔다)
## 장면이 아닌 규칙만 담아 헤드리스로 시험한다.

const OPEN := 9 * 60
const CLOSE := 18 * 60
const COLS := 4
const ROWS := 5
const DIG_MIN := 10
const DIGS := 10
const DECOY := 0.12

## id: 이름, 무게(나오는 정도), 값(시장 값 기준, 선물과 메뉴 계산용)
const ITEMS := {
	"bajirak": {"name": "바지락", "weight": 5.0, "value": 600},
	"dongjuk": {"name": "동죽", "weight": 3.0, "value": 500},
	"gul": {"name": "굴", "weight": 2.0, "value": 900},
	"ge": {"name": "칠게", "weight": 2.5, "value": 300},
	"nakji": {"name": "낙지", "weight": 0.6, "value": 4000},
}
const ITEM_CHANCE := 0.45


static func item(id: String) -> Dictionary:
	return ITEMS.get(id, {})


static func name_of(id: String) -> String:
	return str(item(id).get("name", id))


## 오늘 갯벌에 들어갈 수 있는 때 [[시작, 끝]...]
static func open_times(day: int) -> Array:
	var out := []
	for w in Spots.rocks_windows(day):
		var a := maxi(int(w[0]), OPEN)
		var b := mini(int(w[1]), CLOSE)
		if b - a >= 30:
			out.append([a, b])
	return out


## 지금 들어갈 수 있으면 물이 들어오는 시각, 아니면 -1
static func open_until(day: int, minutes: int) -> int:
	for t in open_times(day):
		if minutes >= int(t[0]) and minutes < int(t[1]):
			return int(t[1])
	return -1


## 그날 판. 칸마다 {"item": id 또는 "", "hole": 숨구멍이 보이나}. visit: 그날 몇 번째로 들어왔나
static func board(day: int, visit := 0) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("갯벌-%d-%d" % [day, visit])
	var total := 0.0
	for id in ITEMS:
		total += float(ITEMS[id].weight)
	var out := []
	for i in COLS * ROWS:
		var it := ""
		if rng.randf() < ITEM_CHANCE:
			var r := rng.randf() * total
			for id in ITEMS:
				r -= float(ITEMS[id].weight)
				if r <= 0.0:
					it = id
					break
		# 숨은 것이 있으면 대개 숨구멍이 보인다. 없어도 가끔 그냥 구멍이 있다
		var hole := (rng.randf() < 0.85) if it != "" else (rng.randf() < DECOY)
		out.append({"item": it, "hole": hole, "dug": false})
	return out


## 한 칸을 판다: 나온 것 id(없으면 ""). 이미 판 칸이면 null 대신 "dug"
static func dig(b: Array, i: int) -> String:
	if i < 0 or i >= b.size() or b[i].dug:
		return "dug"
	b[i].dug = true
	return str(b[i].item)


## 캔 것을 GameState에 넣는다
static func keep(gs: Object, id: String) -> void:
	if id.is_empty() or not ITEMS.has(id):
		return
	gs.seafood[id] = int(gs.seafood.get(id, 0)) + 1
