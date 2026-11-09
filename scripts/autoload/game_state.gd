extends Node
## 게임 전체에서 공유하는 상태. 오토로드 이름: GameState

const DEFAULT_PLAYER_NAME := "한바다"
const DEFAULT_SHOP_NAME := "오늘의 식탁"
const PLAYER_NAME_MAX := 6
const SHOP_NAME_MAX := 10

const RANDOM_PLAYER_NAMES := ["하늘", "준", "도윤", "서진", "민호", "태오", "지안", "한결"]
const RANDOM_SHOP_NAMES := ["한 접시", "물빛식당", "갯내음", "등대 밥집", "파도 식탁", "오늘 잡은 집", "바닷가 부엌"]

## 기획서 2.2 금지어 목록. 실제 출시 전에 더 보강한다.
const BANNED_WORDS := ["시발", "씨발", "병신", "개새", "좆", "fuck", "shit"]

var player_name := DEFAULT_PLAYER_NAME
var shop_name := DEFAULT_SHOP_NAME
var pet_name := "고등어"

var money := 180_000
var debt := 30_000_000
var monthly_repayment := 550_000
var day := 1

## 낚시 기록. 항목 형식: {"id": "bolak", "size": 18.3}
var caught_today: Array = []
var inventory: Array = []
## 어종 도감: 어종 id → 가장 큰 기록(cm)
var dex := {}

var _player_regex := RegEx.create_from_string("^[가-힣a-zA-Z0-9]+$")
var _shop_regex := RegEx.create_from_string("^[가-힣a-zA-Z0-9 ]+$")


## 대사 템플릿에 현재 이름들을 넣는다. 예: line("{shop|이/가}라...")
func line(template: String) -> String:
	return Josa.format(template, {
		"player": player_name,
		"shop": shop_name,
		"pet": pet_name,
	})


## 이름 검사. 문제가 없으면 빈 문자열, 있으면 안내 문구를 돌려준다.
func validate_player_name(text: String) -> String:
	return _validate(text, PLAYER_NAME_MAX, _player_regex, "한글, 영문, 숫자만 쓸 수 있어요.")


func validate_shop_name(text: String) -> String:
	return _validate(text, SHOP_NAME_MAX, _shop_regex, "한글, 영문, 숫자, 띄어쓰기만 쓸 수 있어요.")


func _validate(text: String, max_len: int, regex: RegEx, char_message: String) -> String:
	var t := text.strip_edges()
	if t.is_empty():
		return ""  # 빈 값은 기본값으로 처리하므로 통과
	if t.length() > max_len:
		return "%d자까지 쓸 수 있어요." % max_len
	if regex.search(t) == null:
		return char_message
	var lower := t.to_lower().replace(" ", "")
	for w in BANNED_WORDS:
		if lower.contains(w):
			return "다른 이름을 써 주세요."
	return ""


func random_player_name() -> String:
	return RANDOM_PLAYER_NAMES.pick_random()


func random_shop_name() -> String:
	return RANDOM_SHOP_NAMES.pick_random()


func format_won(amount: int) -> String:
	var s := str(abs(amount))
	var out := ""
	while s.length() > 3:
		out = "," + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return ("-" if amount < 0 else "") + s + out + "원"
