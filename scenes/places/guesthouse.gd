extends PlaceScene
## 등대민박: 하루 한 번 조식 생선을 낸다 (Places.inn_deliver). 다음 날 저녁 민박 손님이 한 명 더 온다


func _ready() -> void:
	var m := GameState.time_minutes
	setup("guesthouse", "서지우" if m >= 14 * 60 and m < 19 * 60 else "윤미자")
	if host == "서지우":
		say(["평상에서 그리면 바람이 물감을 말려 줘요.", "오늘은 등대를 그렸어요. 어제보다 조금 빨개요.", "한 달이 이렇게 짧은 줄 몰랐어요."][GameState.day % 3])
	else:
		say(["어머 {shop} 사장님! 커피 한잔 하고 가.", "우리 덕배 씨는 지붕 위에 있어. 부르지 마 안 내려와.", "방 하나 더 치웠어. 창고가 자꾸 방이 되네."][GameState.day % 3], "smile")
	_fill()


func _fill() -> void:
	clear_body()
	heading("내일 조식 생선")
	if not GameState.has_flag("inn_open"):
		para("아직 부탁받은 일이 없어요")
		return
	if Places.done_today(GameState, "guesthouse"):
		para("오늘 몫은 냈어요. 내일 저녁에 민박 손님이 한 명 더 와요", UiKit.CORAL_DEEP)
		return
	var need := Places.inn_count(GameState.day)
	var list := Places.inn_fish(GameState)
	para("구울 생선 %d마리. 사례금을 받고 내일 저녁에 민박 손님이 한 명 더 와요" % need)
	for e in list:
		_body.add_child(FishLine.make(e, GameState.day, "값 " + GameState.format_won(FishDB.value_of(e.id, e.size)), "", Control.new()))
	if list.size() < need:
		para("낼 생선이 %d마리 모자라요. 비싼 생선은 안 받아요" % (need - list.size()), UiKit.CORAL_DEEP)
	var ok := list.size() >= need and Places.is_open(GameState, "guesthouse", GameState.time_minutes)
	big_button("%d마리 내기 · %s" % [need, GameState.format_won(Places.inn_pay(list))] if list.size() >= need else "생선이 모자라요", "primary", _deliver, ok)


func _deliver() -> void:
	var got := Places.inn_deliver(GameState)
	if got <= 0:
		return
	Sound.play_sfx("coin")
	Haptics.play("tap")
	GameState.note("등대민박에 조식 생선을 냈다. 사례로 %s 받았다." % Josa.attach(GameState.format_won(got), "을/를"), 2)
	set_host("윤미자")
	say("싱싱하다 싱싱해! 손님들 저녁은 {shop|으로/로} 보낼게.", "smile")
	_fill()
