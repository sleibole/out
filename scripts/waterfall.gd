@tool
extends Node2D
## Decorative sewage waterfall. Its origin is the top center of the fall.

@export var height := 560.0
@export var width := 64.0
@export var color := Color("#7FE3BC")
@export var streak_color := Color("#C8F7E4")
@export var foam_color := Color("#E8FFF6")

var _time := 0.0


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var half := width * 0.5
	draw_rect(Rect2(-half, 0, width, height), color)
	for lane in 3:
		var lx := -half + width * (0.22 + lane * 0.28)
		var offset := fposmod(_time * 380.0 + lane * 90.0, 140.0)
		var y := offset - 140.0
		while y < height:
			var top := maxf(y, 0.0)
			var bottom := minf(y + 60.0, height)
			if bottom > top:
				draw_line(Vector2(lx, top), Vector2(lx, bottom), streak_color, 5.0, true)
			y += 140.0
	for i in 6:
		var fx := -half - 18.0 + i * (width + 36.0) / 5.0
		var r := 16.0 + sin(_time * 5.0 + i * 1.7) * 4.0
		draw_circle(Vector2(fx, height - 6.0 + sin(_time * 3.0 + i) * 3.0), r, foam_color)
