class_name Loan
extends RefCounted
## 귀촌 창업 대출 상환 규칙 (기획서 10.1). 장면이 아닌 규칙만 담아 헤드리스로 시험한다.
##
## - 매달 1일 아침에 원리금(GameState.monthly_repayment)이 통장에서 빠진다. 첫 상환은 4월 1일 (1일차가 3월 1일)
## - 돈이 모자라면 빼지 않고 연체로 남긴다. 다음 상환일에 밀린 돈까지 같이 빠진다
## - 연체해도 바로 게임이 끝나지 않는다 (기획서: 독촉 전화, 이웃의 도움 같은 이야기로 완충. 이야기는 아직 없다)
## - 이자는 아직 따로 셈하지 않고 갚은 만큼 대출 잔액이 준다

## 상환일이 이만큼 남았을 때부터 헤더에 알린다
const WARN_DAYS := 7


## 오늘(day)이 상환일이면 상환 결과, 아니면 빈 Dictionary.
## 돌려주는 값: {"due": 낼 돈, "paid": 낸 돈(0이면 연체), "arrears": 남은 연체 금액, "debt": 남은 대출}
static func settle(day: int, money: int, debt: int, monthly: int, arrears: int) -> Dictionary:
	if day <= 1 or not Calendar.is_month_start(day) or debt <= 0:
		return {}
	var due := mini(monthly + arrears, debt)
	if money >= due:
		return {"due": due, "paid": due, "arrears": 0, "debt": debt - due}
	return {"due": due, "paid": 0, "arrears": due, "debt": debt}


## 다음 상환일까지 남은 날
static func days_left(day: int) -> int:
	return Calendar.next_month_start(day) - day


## 상환 결과 안내 한 줄
static func notice(r: Dictionary) -> String:
	if r.is_empty():
		return ""
	if r.paid > 0:
		return "대출 %s을 갚았어요. 남은 대출 %s" % [_won(r.paid), _won(r.debt)]
	return "통장이 모자라 대출 %s을 못 갚았어요. 다음 달에 같이 내야 해요" % _won(r.due)


## 헤더 작은 안내. 상환일이 가까울 때만. 예: "상환 D-3 · 55만"
static func header_text(day: int, monthly: int, arrears: int, debt: int) -> String:
	if debt <= 0:
		return ""
	var left := days_left(day)
	if left > WARN_DAYS and arrears <= 0:
		return ""
	return "상환 D-%d · %d만" % [left, int((mini(monthly + arrears, debt) + 9999) / 10000)]


static func _won(n: int) -> String:
	var s := str(n)
	var out := ""
	while s.length() > 3:
		out = "," + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return s + out + "원"
