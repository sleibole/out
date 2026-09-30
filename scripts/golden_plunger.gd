extends Area2D

var _time := 0.0
var _taken := false

@onready var _rig: Node2D = $Rig
@onready var _glint: Node2D = $Rig/Glint


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_time += delta
	if not _taken:
		_rig.position.y = sin(_time * 2.2) * 6.0
		_rig.rotation = sin(_time * 1.4) * 0.08
	var cycle := fmod(_time, 1.8)
	_glint.scale = Vector2.ONE * (sin(cycle / 0.45 * PI) if cycle < 0.45 else 0.0)
	_glint.rotation += delta * 2.0


func _on_body_entered(body: Node2D) -> void:
	if _taken or not body.is_in_group("player"):
		return
	_taken = true
	Game.collect_plunger()
	Game.play_sfx("chime", 0.0)
	Game.burst(global_position, Color("#FFE27A"), 28, 150, 400, Vector2.UP, 180, Vector2(0, 300), 0.4, 0.9)
	var tween := create_tween()
	tween.tween_property(_rig, "scale", Vector2(1.6, 1.6), 0.25)
	tween.parallel().tween_property(_rig, "position:y", -90.0, 0.4)
	tween.tween_property(_rig, "modulate:a", 0.0, 0.25)
	tween.tween_callback(queue_free)
