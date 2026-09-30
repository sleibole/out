extends Area2D


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if Game.finished or not body.is_in_group("player"):
		return
	body.celebrate()
	Game.play_sfx("flush", 0.0)
	Game.finish()
