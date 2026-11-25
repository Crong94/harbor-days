extends PlaceScene
## 해양생태 연구소: 하루 한 번 잡은 고기를 표본으로 기록한다 (Places.record). 고기는 돌려받는다


func _ready() -> void:
	setup("lab", "한서윤")
	say(["오늘은 뭐 잡았어요? 정확한 위치도요.", "수온이 어제보다 0.3도 올랐어요. 재미있죠? 저만 재미있군요.", "밥이요? 데이터가 밥이에요. 농담이에요. 먹었어요."][GameState.day % 3])
	_fill()


func _fill() -> void:
	clear_body()
	var n := GameState.specimens.size()
	heading("표본 기록 %d/%d" % [n, FishDB.FISH.size()])
	var nx := Places.STAGES.filter(func(s): return n < int(s[0]))
	if not nx.is_empty():
		para("%d가지를 채우면 추가 연구비 %s과 평판 +%d" % [nx[0][0], GameState.format_won(int(nx[0][1])), nx[0][2]])
	else:
		para("방파제 고기를 모두 기록했어요. 더 큰 고기를 보여 주면 기록을 고쳐 써요")
	if Places.done_today(GameState, "lab"):
		para("오늘 기록은 끝났어요. 내일 또 보여 주세요", UiKit.CORAL_DEEP)
	elif not Places.is_open(GameState, "lab", GameState.time_minutes):
		para("연구소는 9시부터 저녁 7시까지 열어요", UiKit.CORAL_DEEP)
	else:
		_add_choices()
	_body.add_child(UiKit.gap(6))
	_body.add_child(UiKit.text("지금까지 기록", "title", UiKit.NOTE_INK))
	for id in FishDB.FISH:
		var has := GameState.specimens.has(id)
		para("%s  %s" % [FishDB.get_fish(id).name, "%.0fcm" % float(GameState.specimens[id]) if has else "아직 없음"],
			UiKit.NOTE_INK if has else UiKit.NOTE_INK_SOFT, 18)


func _add_choices() -> void:
	var list := Places.specimen_choices(GameState)
	if list.is_empty():
		para("보여 줄 고기가 없어요. 아이스박스나 수조에 고기를 담아 와요", UiKit.CORAL_DEEP)
	for e in list:
		var pay := Places.specimen_pay(GameState, e)
		var b := UiKit.game_button(GameState.format_won(pay) if pay > 0 else "기록함", UiKit.CORAL_DEEP, Vector2(128, 52), 19)
		b.disabled = pay <= 0
		b.pressed.connect(_record.bind(e))
		var note := "기록 %.0fcm" % float(GameState.specimens[e.id]) if GameState.specimens.has(e.id) else "처음 보는 어종"
		_body.add_child(FishLine.make(e, GameState.day, note, "", b))


func _record(e: Dictionary) -> void:
	var r := Places.record(GameState, e)
	if r.is_empty():
		return
	Sound.play_sfx("newfish" if r.new else "coin")
	var fname: String = FishDB.get_fish(e.id).name
	if int(r.stage) > 0:
		say("%d가지째예요! 추가 연구비 %s 받아 왔어요. 보고서에 {player} 씨 이름도 넣을게요." % [r.stage, GameState.format_won(int(r.bonus))], "smile")
		GameState.note("연구소 표본이 %d가지가 됐다. 서윤 씨가 웃었다." % r.stage, 3)
	elif r.new:
		say("%s %.1fcm. 좋은 개체예요. 고기는 돌려드릴게요." % [fname, e.size], "smile")
		GameState.note("연구소에 %s 표본을 기록했다." % fname, 2)
	else:
		say("기록 갱신이네요. %.1fcm. 같은 어종도 커 가는 게 보이죠." % e.size, "smile")
	_fill()
