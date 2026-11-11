extends SceneTree
## 줄다리기 난이도 재기 (사람이 직접 하기 전에 숫자로 먼저 본다).
## 실행: godot --headless --path . --script res://tools/fight_balance.gd
##
## "평범하게 잘하는 사람"을 흉내 낸다: 장력이 HOLD_UNTIL을 넘으면 손을 떼고 RESUME_AT 아래로 내려오면 다시 감는다.
## 장력도, 옆으로 차고 나가는 것도 REACT초 늦게 알아챈다 (사람 반응 속도). 바늘털이 중에는 손을 떼지 않는다.
## 어종마다, 기본 장비와 2단계 장비로 잡힌 비율과 걸린 시간, 실패 까닭을 적는다.

const TRIES := 200
const HOLD_UNTIL := 0.7
const RESUME_AT := 0.45
const REACT := 0.35


func _init() -> void:
	for gear in [["rod_1", "reel_1"], ["rod_2", "reel_2"]]:
		print("── 장비 %s + %s" % gear)
		for id in FishDB.FISH:
			var ok := 0
			var secs := 0.0
			var why := {}
			for i in TRIES:
				var r := _fight(id, gear, 1000 + i)
				if r.ok:
					ok += 1
					secs += r.t
				else:
					why[r.why] = int(why.get(r.why, 0)) + 1
			print("  %-12s 성공 %3d%%  평균 %4.1f초  실패 %s" % [FishDB.get_fish(id).name, ok * 100 / TRIES, secs / maxf(ok, 1), why])
	# 감성돔은 장비 10단계 전부 (낚싯대와 릴 같은 단계)
	print("── 감성돔 장비 단계별")
	for tier in range(1, 11):
		var ok := 0
		for i in TRIES:
			if _fight("gamseongdom", ["rod_%d" % tier, "reel_%d" % tier], 1000 + i).ok:
				ok += 1
		print("  %2d단계  성공 %3d%%" % [tier, ok * 100 / TRIES])
	quit()


func _fight(id: String, gear: Array, seed_value: int) -> Dictionary:
	var l := FishingLogic.new()
	l.rng.seed = seed_value
	l.forgiving = false
	l.catch_count = 1
	GearDB.apply(l, gear[0], gear[1])
	l.force_first_fish = id
	l.catch_count = 0 # 첫 고기 고정을 써서 어종을 정한다
	l.state = FishingLogic.State.BITE
	# 장비마다 PERFECT 폭이 달라 같은 순간에 눌러도 판정이 갈린다. 공정하게 늘 PERFECT 가운데에서 챈다
	var z := l.perfect_zone()
	l.bite_depth = (z.x + z.y) / 2.0
	l._timer = 1.0
	l.cast_power = 0.6
	l.press()
	l.forgiving = false
	var held := true
	var t := 0.0
	var seen_run := 0.0
	var past: Array = [] # 사람은 REACT초 전 장력을 보고 손을 움직인다
	while l.state == FishingLogic.State.REELING and t < 60.0:
		past.append(l.tension)
		var seen: float = past[maxi(0, past.size() - 1 - int(REACT * 60.0))]
		if seen >= HOLD_UNTIL:
			held = false
		elif seen <= RESUME_AT:
			held = true
		if l.jump_t > 0.0:
			held = true
		if l.run_dir != 0:
			seen_run += 1.0 / 60.0
		else:
			seen_run = 0.0
		l.steer = -l.run_dir if seen_run >= REACT else 0.0
		l.update(1.0 / 60.0, held or (l.run_dir != 0 and seen_run >= REACT))
		t += 1.0 / 60.0
	return {"ok": l.state == FishingLogic.State.CAUGHT, "t": t, "why": l.fail_reason if l.state != FishingLogic.State.CAUGHT else ""}
