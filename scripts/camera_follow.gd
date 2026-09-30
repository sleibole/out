extends Camera2D

@export var target_path: NodePath
@export var look_ahead := 120.0
@export var look_ahead_speed := 3.0
@export var vertical_offset := -120.0

var _ahead := 0.0

@onready var _target: Node2D = get_node(target_path)


func _ready() -> void:
	global_position = _target.global_position + Vector2(0, vertical_offset)
	reset_smoothing()


func _process(delta: float) -> void:
	var facing: float = _target.get("facing")
	_ahead = lerpf(_ahead, facing * look_ahead, 1.0 - exp(-look_ahead_speed * delta))
	global_position = _target.global_position + Vector2(_ahead, vertical_offset)
