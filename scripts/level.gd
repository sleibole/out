extends Node2D


func _ready() -> void:
	Game.reset()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart"):
		restart()


func restart() -> void:
	Game.reset()
	get_tree().reload_current_scene()
