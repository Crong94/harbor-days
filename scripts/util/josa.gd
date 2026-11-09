class_name Josa
extends RefCounted
## 한국어 조사 자동 처리.
## 대사 템플릿 예시: "{player|이/가} 왔다" → "준이 왔다" / "한바다가 왔다"

const HANGUL_START := 0xAC00
const HANGUL_END := 0xD7A3
const RIEUL_JONG := 8 # 종성 ㄹ 인덱스

static var _pattern: RegEx


## 마지막 글자에 받침이 있는지. 한글이 아니면 받침 없음으로 본다.
static func has_batchim(word: String) -> bool:
	if word.is_empty():
		return false
	var c := word.unicode_at(word.length() - 1)
	if c < HANGUL_START or c > HANGUL_END:
		return false
	return (c - HANGUL_START) % 28 != 0


static func _ends_with_rieul(word: String) -> bool:
	if word.is_empty():
		return false
	var c := word.unicode_at(word.length() - 1)
	if c < HANGUL_START or c > HANGUL_END:
		return false
	return (c - HANGUL_START) % 28 == RIEUL_JONG


## 단어에 조사를 붙인다. pair는 "받침 있을 때/받침 없을 때" 형식. 예: "이/가", "은/는", "으로/로"
static func attach(word: String, pair: String) -> String:
	var parts := pair.split("/")
	if parts.size() != 2:
		return word + pair
	var with_batchim := parts[0]
	var without_batchim := parts[1]
	# ㄹ 받침 뒤의 '으로'는 '로'를 쓴다. (예: 갯마을로)
	if with_batchim == "으로" and _ends_with_rieul(word):
		return word + without_batchim
	return word + (with_batchim if has_batchim(word) else without_batchim)


## 템플릿 안의 {키} 또는 {키|이/가}를 값으로 바꾼다.
static func format(template: String, values: Dictionary) -> String:
	if _pattern == null:
		_pattern = RegEx.new()
		_pattern.compile("\\{([a-zA-Z_][a-zA-Z0-9_]*)(?:\\|([^}]+))?\\}")
	var result := ""
	var cursor := 0
	for m in _pattern.search_all(template):
		result += template.substr(cursor, m.get_start() - cursor)
		var key := m.get_string(1)
		var value := str(values.get(key, "{" + key + "}"))
		var pair := m.get_string(2)
		result += attach(value, pair) if not pair.is_empty() else value
		cursor = m.get_end()
	result += template.substr(cursor)
	return result
