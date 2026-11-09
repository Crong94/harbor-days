class_name CookingLogic
extends RefCounted
## 생선구이 규칙. 화면과 분리해서 헤드리스로 테스트할 수 있다.
##
## 흐름: SEASON(간 맞추기) → GRILL(굽기) → DONE
## - 간 맞추기: 누르고 있는 동안 소금이 뿌려지고, 떼면 그 양으로 정해진다. 레시피의 target에 가까울수록 좋다
## - 굽기: 시간이 지나며 익는다. 노릇한 구간에서 누르면 불에서 내린다. 늦으면 탄다
## 맛 단계는 레시피 JSON(바다 한 접시)의 steps[{flavor, target}]을 쓴다. 생선구이는 짠맛 한 단계다.

enum Phase { SEASON, GRILL, DONE }

const SEASON_SPEED := 0.45 # 누르고 있을 때 1초에 오르는 간
const GOOD_RANGE := 0.09 # target과 이만큼 차이 안이면 간이 딱 맞음
const GRILL_SPEED := 0.16 # 1초에 익는 정도
const GRILL_GOOD := Vector2(0.62, 0.86) # 노릇하게 익은 구간
const DEFAULT_TARGET := 0.58

var phase := Phase.SEASON
var target := DEFAULT_TARGET
var flavor := "salty"
var amount := 0.0 # 뿌린 간 0~1
var doneness := 0.0 # 익은 정도 0~1 (1이면 완전히 탐)
var seasoning := "" # good / bland / strong
var cooking := "" # good / raw / burnt

var _seasoning_started := false


## 레시피의 첫 맛 단계로 목표를 정한다.
func setup(recipe: Dictionary) -> void:
	var steps: Array = recipe.get("steps", [])
	if not steps.is_empty():
		flavor = steps[0].get("flavor", "salty")
		target = float(steps[0].get("target", DEFAULT_TARGET))


func press() -> void:
	match phase:
		Phase.SEASON:
			_seasoning_started = true
		Phase.GRILL:
			cooking = judge_grill(doneness)
			phase = Phase.DONE


func release() -> void:
	if phase == Phase.SEASON and _seasoning_started:
		seasoning = judge_season(amount, target)
		phase = Phase.GRILL


func update(dt: float, held: bool) -> void:
	match phase:
		Phase.SEASON:
			if held and _seasoning_started:
				amount = minf(amount + SEASON_SPEED * dt, 1.0)
				if amount >= 1.0:
					release()
		Phase.GRILL:
			doneness = minf(doneness + GRILL_SPEED * dt, 1.0)
			if doneness >= 1.0:
				cooking = "burnt"
				phase = Phase.DONE


static func judge_season(value: float, goal: float) -> String:
	if absf(value - goal) <= GOOD_RANGE:
		return "good"
	return "bland" if value < goal else "strong"


static func judge_grill(value: float) -> String:
	if value < GRILL_GOOD.x:
		return "raw"
	if value > GRILL_GOOD.y:
		return "burnt"
	return "good"


## 별 1~3개. 간과 굽기가 모두 좋으면 3개
func stars() -> int:
	return 1 + int(seasoning == "good") + int(cooking == "good")


## 손님 평 (바다 한 접시 맛 데이터의 review: [딱 맞음, 모자람, 지나침])
func flavor_review() -> String:
	var r: Array = Catalog.flavor(flavor).get("review", [])
	if r.size() < 3:
		return ""
	match seasoning:
		"good":
			return r[0]
		"bland":
			return r[1]
	return r[2]
