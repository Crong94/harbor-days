class_name Loan
extends RefCounted
## 매주 나가는 돈 (2026-11-24 사용자: 한 달보다 일주일 단위가 더 재밌겠다. 예전엔 매달 1일).
##
## - 월요일 아침에 대출 원리금, 식당 월세, 공과금을 한꺼번에 낸다. 첫 주는 8일차 (1일차가 월요일)
## - 한 주 몫 = 한 달 몫 × 12 ÷ 52. 공과금은 계절마다 다르다 (여름 에어컨, 겨울 난방)
## - 모자라면 빼지 않고 밀린 돈으로 남긴다. 다음 월요일에 같이 빠진다. 게임이 끝나지는 않는다
## - 제때 낸 주가 이어지면(streak) CREDIT_EVERY주마다 은행이 대출을 CREDIT만큼 깎아 준다
## - 집에서 대출을 더 갚을 수 있다 (extra). 다 갚아도 월세와 공과금은 나간다

const WEEK := 7
## 이만큼 남았을 때부터 헤더에 알린다
const WARN_DAYS := 3
const RENT := 46_000
const UTILITIES := {"봄": 12_000, "여름": 18_000, "가을": 12_000, "겨울": 23_000}
const CREDIT_EVERY := 4
const CREDIT := 50_000
const EXTRA := 100_000


## 월요일 (내는 날)인가
static func is_pay_day(day: int) -> bool:
	return day > 1 and (day - 1) % WEEK == 0


static func next_pay_day(day: int) -> int:
	return day + WEEK - (day - 1) % WEEK


## 한 달 대출금 → 한 주 대출금 (천 원 단위)
static func weekly(monthly: int) -> int:
	return int(roundf(monthly * 12.0 / 52.0 / 1000.0)) * 1000


static func bills(day: int) -> int:
	return RENT + int(UTILITIES.get(Calendar.season(day), 12_000))


## 그날 낼 돈 전부 (대출 + 월세 + 공과금 + 밀린 돈)
static func due(day: int, monthly: int, arrears: int, debt: int) -> int:
	return mini(weekly(monthly), maxi(debt, 0)) + bills(day) + arrears


## 오늘(day)이 내는 날이면 결과, 아니면 빈 Dictionary.
## {"due": 낼 돈, "loan": 그중 대출, "bills": 월세와 공과금, "paid": 낸 돈(0이면 밀림), "arrears": 밀린 돈, "debt": 남은 대출,
##   "streak": 이어서 제때 낸 주, "credit": 깎아 준 대출}
static func settle(day: int, money: int, debt: int, monthly: int, arrears: int, streak := 0) -> Dictionary:
	if not is_pay_day(day):
		return {}
	var loan := mini(weekly(monthly), maxi(debt, 0))
	var b := bills(day)
	var total := loan + b + arrears
	if money < total:
		return {"due": total, "loan": loan, "bills": b, "paid": 0, "arrears": total, "debt": debt, "streak": 0, "credit": 0}
	# 밀린 돈에는 지난주 대출 몫도 들어 있다. 다 갚으면 대출 잔액에서 그만큼도 준다
	var late := clampi(arrears - int(arrears / maxi(1, loan + b)) * b, 0, maxi(0, debt - loan)) if arrears > 0 and loan > 0 else 0
	var left := debt - loan - late
	var s := streak + 1
	var credit := mini(CREDIT, left) if s % CREDIT_EVERY == 0 else 0
	return {"due": total, "loan": loan, "bills": b, "paid": total, "arrears": 0, "debt": left - credit, "streak": s, "credit": credit}


## 다음 내는 날까지 남은 날
static func days_left(day: int) -> int:
	return next_pay_day(day) - day


## 집에서 더 갚기: 실제로 갚을 돈 (모자라거나 빚이 없으면 0)
static func extra_amount(money: int, debt: int) -> int:
	var n := mini(EXTRA, debt)
	return n if n > 0 and money >= n else 0


static func notice(r: Dictionary) -> String:
	if r.is_empty():
		return ""
	if r.paid > 0:
		var parts := "월세와 공과금 %s" % _won(r.bills)
		if r.loan > 0:
			parts = "대출 %s, %s" % [_won(r.loan), parts]
		var t := "이번 주 고정비 %s을 냈어요 (%s). 남은 대출 %s" % [_won(r.paid), parts, _won(r.debt)]
		if int(r.credit) > 0:
			t += ". %d주 연속 제때 내서 은행이 %s을 깎아 줬어요" % [r.streak, _won(r.credit)]
		return t
	return "통장이 모자라 이번 주 %s을 못 냈어요. 다음 월요일에 같이 내야 해요" % _won(r.due)


## 헤더 작은 안내. 내는 날이 가까울 때만. 예: "고정비 D-3 · 19만"
static func header_text(day: int, monthly: int, arrears: int, debt: int) -> String:
	var left := days_left(day)
	if left > WARN_DAYS and arrears <= 0:
		return ""
	return "고정비 D-%d · %d만" % [left, int((due(next_pay_day(day), monthly, arrears, debt) + 9999) / 10000)]


static func _won(n: int) -> String:
	var s := str(n)
	var out := ""
	while s.length() > 3:
		out = "," + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return s + out + "원"
