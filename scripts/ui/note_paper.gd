class_name NotePaper
extends PanelContainer
## 공책 종이 (여울 수첩 NotePaper). 크림 종이에 가로줄과 왼쪽 빨간 여백 줄을 긋는다.
## 판 모양은 UiKit.note_paper()가 정한다. 줄은 판정 요소가 아닌 종이 무늬라 그림 대신 선으로 긋는다 (여울과 같은 방식)

const LINE_GAP := 43.0
const LINE_FROM := 80.0


func _ready() -> void:
	resized.connect(queue_redraw)


func _draw() -> void:
	var line := Color(UiKit.NOTE_DARK, 0.55)
	var y := LINE_FROM
	while y < size.y - 20.0:
		draw_line(Vector2(16, y), Vector2(size.x - 16, y), line, 1.5)
		y += LINE_GAP
	draw_line(Vector2(17, 14), Vector2(17, size.y - 18), UiKit.NOTE_RED, 2.0)
