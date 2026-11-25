extends PlaceScene
## 물빛분교: 하루 한 번 해솔이와 물고기 이름 맞히기 세 문제 (Places.quiz)

var _quiz: Array = []
var _at := -1
var _right := 0


func _ready() -> void:
	var m := GameState.time_minutes
	var open := Places.is_open(GameState, "school", m)
	var teacher: bool = GameState.has_flag("met_minhyuk") and m >= 9 * 60 and m < 14 * 60
	setup("school", "김해솔" if open else ("정민혁" if teacher else ""))
	if open:
		say("내일은 더 어려운 거 낼 거예요!" if Places.done_today(GameState, "school") else "아저씨 왔다! 오늘도 물고기 공부해요. 제가 문제 낼게요!", "smile")
	elif teacher:
		say("지금은 수업 중이에요. 학생은 하나지만 시간표는 다 있답니다. 두 시에 끝나요.", "smile")
	else:
		say("운동장에 그네 하나가 바람에 흔들린다.")
	_fill()


func _fill() -> void:
	clear_body()
	heading("물고기 이름 맞히기")
	if Places.done_today(GameState, "school"):
		para("오늘 수업은 끝났어요. 내일 오후에 또 해요")
	elif not Places.is_open(GameState, "school", GameState.time_minutes):
		para("해솔이는 학교가 끝난 오후 2시부터 7시까지 있어요")
	else:
		para("해솔이가 내는 문제 세 개. 다 맞히면 학교 텃밭에서 난 걸 하나 줘요")
		big_button("문제 풀기 (1시간)", "primary", _start)


func _start() -> void:
	_quiz = Places.quiz(GameState.day)
	_at = 0
	_right = 0
	_ask()


func _ask() -> void:
	clear_body()
	var q: Dictionary = _quiz[_at]
	heading("문제 %d / %d" % [_at + 1, _quiz.size()])
	if q.kind == "art":
		para("이 물고기 이름은 뭘까요?", UiKit.NOTE_INK)
		_body.add_child(ArtSlot.make("fish_" + q.fish, "물고기", Vector2(560, 220)))
	else:
		para("저는 누구일까요?", UiKit.NOTE_INK)
		para(Places.quiz_fact(q.fish), UiKit.NOTE_INK, 21)
	for c in q.choices:
		big_button(FishDB.get_fish(c).name, "secondary", _answer.bind(c))


func _answer(c: String) -> void:
	var f: String = _quiz[_at].fish
	var fname: String = FishDB.get_fish(f).name
	if c == f:
		_right += 1
		Sound.play_sfx("good")
		say("딩동댕! %s 맞아요!" % fname, "smile")
	else:
		Sound.play_sfx("bad", 0.0, -8.0)
		say("땡! 정답은 %s. 아저씨 낚시꾼 맞아요?" % fname, "sad")
	_at += 1
	if _at < _quiz.size():
		_ask()
		return
	var gift := Places.finish_quiz(GameState, _right)
	clear_body()
	heading("%d개 맞혔어요" % _right)
	para("해솔이와 조금 더 친해졌어요" if _right > 0 else "내일은 꼭 맞혀요", UiKit.NOTE_INK)
	if not gift.is_empty():
		Sound.play_sfx("newfish")
		para("학교 텃밭에서 난 %s 하나를 받았어요" % Pantry.name_of(gift), UiKit.CORAL_DEEP)
		GameState.note("해솔이 물고기 문제를 다 맞혔다. 상으로 %s 하나를 받았다." % Pantry.name_of(gift), 2)
	big_button("나가기", "primary", leave)
