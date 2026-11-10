class_name Loan
extends RefCounted
## 매달 나가는 돈 (기획서 10.1): 대출 원리금, 식당 월세, 공과금. 장면이 아닌 규칙만 담아 헤드리스로 시험한다.
##
## - 매달 1일 아침에 한꺼번에 통장에서 빠진다. 첫 달은 4월 1일 (1일차가 3월 1일)
## - 공과금은 계절마다 다르다 (여름 에어컨, 겨울 난방)
## - 돈이 모자라면 빼지 않고 연체로 남긴다. 다음 달 1일에 밀린 돈까지 같이 빠진다
## - 연체해도 바로 게임이 끝나지 않는다 (기획서: 독촉 전화, 이웃의 도움 같은 이야기로 완충. 이야기는 아직 없다)
## - 이자는 아직 따로 셈하지 않고 갚은 만큼 대출 잔액이 준다. 대출을 다 갚아도 월세와 공과금은 계속 나간다

## 1일이 이만큼 남았을 때부터 헤더에 알린다
const WARN_DAYS := 7
const RENT := 200_000
const UTILITIES := {"봄": 50_000, "여름": 80_000, "가을": 50_000, "겨울": 100_000}


## 그 달 1일에 나가는 월세와 공과금
static func bills(day: int) -> int:
	return RENT + int(UTILITIES.get(Calendar.season(day), 50_000))


## 그 달 1일에 낼 돈 전부 (대출 + 월세 + 공과금 + 밀린 돈)
static func due(day: int, monthly: int, arrears: int, debt: int) -> int:
	return mini(monthly, maxi(debt, 0)) + bills(day) + arrears


## 오늘(day)이 1일이면 결과, 아니면 빈 Dictionary.
## 돌려주는 값: {"due": 낼 돈, "loan": 그중 대출, "bills": 그중 월세와 공과금, "paid": 낸 돈(0이면 연체),
##   "arrears": 남은 연체 금액, "debt": 남은 대출}
static func settle(day: int, money: int, debt: int, monthly: int, arrears: int) -> Dictionary:
	if day <= 1 or not Calendar.is_month_start(day):
		return {}
	var loan := mini(monthly, maxi(debt, 0))
	var b := bills(day)
	var total := loan + b + arrears
	if money >= total:
		return {"due": total, "loan": loan, "bills": b, "paid": total, "arrears": 0, "debt": debt - loan}
	return {"due": total, "loan": loan, "bills": b, "paid": 0, "arrears": total, "debt": debt}


## 다음 1일까지 남은 날
static func days_left(day: int) -> int:
	return Calendar.next_month_start(day) - day


## 결과 안내 한 줄
static func notice(r: Dictionary) -> String:
	if r.is_empty():
		return ""
	if r.paid > 0:
		var parts := "월세와 공과금 %s" % _won(r.bills)
		if r.loan > 0:
			parts = "대출 %s, %s" % [_won(r.loan), parts]
		return "이번 달 고정비 %s을 냈어요 (%s). 남은 대출 %s" % [_won(r.paid), parts, _won(r.debt)]
	return "통장이 모자라 이번 달 %s을 못 냈어요. 다음 달에 같이 내야 해요" % _won(r.due)


## 헤더 작은 안내. 1일이 가까울 때만. 예: "1일 D-3 · 80만"
static func header_text(day: int, monthly: int, arrears: int, debt: int) -> String:
	var left := days_left(day)
	if left > WARN_DAYS and arrears <= 0:
		return ""
	return "고정비 D-%d · %d만" % [left, int((due(Calendar.next_month_start(day), monthly, arrears, debt) + 9999) / 10000)]


static func _won(n: int) -> String:
	var s := str(n)
	var out := ""
	while s.length() > 3:
		out = "," + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return s + out + "원"
