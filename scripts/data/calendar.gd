class_name Calendar
extends RefCounted
## 게임 날짜. 1일차는 2027년 3월 1일 (기획서: 2월 말 퇴사, 봄에 물빛울포 도착).
## 날짜는 진짜 달력을 따른다 (3월은 31일, 4월은 30일).

const START := {"year": 2027, "month": 3, "day": 1}
const WEEKDAYS := ["일", "월", "화", "수", "목", "금", "토"]
const SEASONS := ["겨울", "겨울", "봄", "봄", "봄", "여름", "여름", "여름", "가을", "가을", "가을", "겨울"]


## day일차의 날짜 {year, month, day, weekday(0=일)}
static func date(day: int) -> Dictionary:
	var base := Time.get_unix_time_from_datetime_dict({"year": START.year, "month": START.month, "day": START.day, "hour": 12})
	var d := Time.get_datetime_dict_from_unix_time(base + (day - 1) * 86400)
	return {"year": d.year, "month": d.month, "day": d.day, "weekday": d.weekday}


## 예: "3월 1일 (월)"
static func text(day: int) -> String:
	var d := date(day)
	return "%d월 %d일 (%s)" % [d.month, d.day, WEEKDAYS[d.weekday]]


## 짧게. 예: "3월 1일"
static func short_text(day: int) -> String:
	var d := date(day)
	return "%d월 %d일" % [d.month, d.day]


static func season(day: int) -> String:
	return SEASONS[date(day).month - 1]


## 그달 1일인가 (상환일)
static func is_month_start(day: int) -> bool:
	return date(day).day == 1


## 다음 달 1일이 몇 일차인지
static func next_month_start(day: int) -> int:
	var d := day + 1
	while not is_month_start(d):
		d += 1
	return d
