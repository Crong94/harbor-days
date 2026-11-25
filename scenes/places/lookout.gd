extends PlaceScene
## 뒷산 전망대: 하루 한 번 망원경으로 내일과 모레 바다를 본다 (Places.forecast)


func _ready() -> void:
	setup("lookout", "{player}")
	say("여기서 보니 마을이 생각보다 작네. 그래도 내 가게 지붕은 보인다.")
	_fill()


func _fill() -> void:
	clear_body()
	heading("낡은 망원경")
	if not Places.done_today(GameState, "lookout"):
		if not Places.is_open(GameState, "lookout", GameState.time_minutes):
			para("어두워서 아무것도 안 보여요. 저녁 7시 전에 와요")
			return
		para("먼바다 물빛과 구름을 보면 내일과 모레 바다를 짐작할 수 있어요")
		big_button("망원경 들여다보기 (30분)", "primary", _look)
		return
	for f in Places.forecast(GameState.day):
		_body.add_child(UiKit.text(f.title, "title", UiKit.CORAL_DEEP))
		for l in f.lines:
			para(l, UiKit.NOTE_INK)
		_body.add_child(UiKit.gap(6))


func _look() -> void:
	Places.mark(GameState, "lookout")
	Sound.play_sfx("newfish")
	var f: Array = Places.forecast(GameState.day)
	GameState.note("전망대에서 내일 바다를 미리 봤다. %s" % f[0].lines[0], 1)
	say("저 물빛이면 내일은 나가 볼 만하겠는데." if SeaDay.of(GameState.day + 1).tide_good else "물이 순하네. 내일은 욕심내지 말아야겠다.", "smile")
	_fill()
