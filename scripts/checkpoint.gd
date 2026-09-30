extends Area2D
## The player respawns at this node's position after falling in the water.


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.respawn_position = global_position
