class_name Portraits
extends RefCounted
## 대화창 얼굴 일러스트. 말하는 사람 이름으로 그림을 찾는다.
## 그림: assets/art/portrait/<id>_<face>.png. face는 normal(평소), smile(웃음), sad(곤란, 생각)
## 원본은 여울 폴더의 세 표정 묶음 (docs/ref/인물/여울). 그림이 없는 사람은 얼굴 없이 이름표만 나온다.
## 대사 한 줄에 "face": "smile"처럼 적으면 그 표정을 쓴다. 없으면 normal.

const DIR := "res://assets/art/portrait/"
const FACES := ["normal", "smile", "sad"]

## 대사의 speaker 이름 → 그림 id
const SPEAKERS := {
	"순덕": "sundeok", "최순덕": "sundeok", "할머니": "sundeok",
	"만수": "mansu", "박만수": "mansu",
	"용팔": "yongpal", "오용팔": "yongpal",
	"복자": "bokja", "김복자": "bokja",
	"경자": "gyeongja", "문경자": "gyeongja",
	"준호": "junho", "이준호": "junho",
	"{player}": "player", "나": "player",
}


## 그 사람의 얼굴 그림 경로. 없으면 빈 문자열
static func path(speaker: String, face := "normal") -> String:
	var id: String = SPEAKERS.get(speaker, "")
	if id.is_empty():
		return ""
	if not face in FACES:
		face = "normal"
	var p := DIR + "%s_%s.png" % [id, face]
	if ResourceLoader.exists(p):
		return p
	p = DIR + "%s_normal.png" % id
	return p if ResourceLoader.exists(p) else ""
