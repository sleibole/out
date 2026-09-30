@tool
extends Node2D
## Animated sewage water. Its origin is the resting surface line; a child Area2D
## named "Hazard" sends the player back to their checkpoint.

@export var width := 3840.0
@export var depth := 260.0
@export var color := Color("#5FD4A8")
@export var deep_color := Color("#3FA886")
@export var surface_color := Color("#B8F2DC")

var _time := 0.0


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	$Hazard.body_entered.connect(_on_hazard_body_entered)


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _wave(x: float) -> float:
	return sin(x * 0.018 + _time * 2.0) * 4.0 + sin(x * 0.041 - _time * 1.3) * 2.0


func _draw() -> void:
	var surface := PackedVector2Array()
	var x := 0.0
	while x <= width:
		surface.append(Vector2(x, _wave(x)))
		x += 32.0
	surface.append(Vector2(width, _wave(width)))
	var body := surface.duplicate()
	body.append(Vector2(width, depth))
	body.append(Vector2(0, depth))
	draw_colored_polygon(body, color)
	draw_rect(Rect2(0, 70, width, depth - 70), deep_color)
	draw_polyline(surface, surface_color, 5.0, true)

	var highlight := Color(surface_color, 0.55)
	for i in int(width / 170.0):
		var drift := _time * 22.0 * (1.0 if i % 2 == 0 else -1.0)
		var hx := fposmod(i * 170.0 + drift, width)
		var hy := 22.0 + (i % 3) * 14.0
		draw_line(Vector2(hx, hy), Vector2(hx + 46.0, hy), highlight, 4.0, true)


func _on_hazard_body_entered(body: Node2D) -> void:
	if body.has_method("fall_in_water"):
		body.fall_in_water(global_position.y)
