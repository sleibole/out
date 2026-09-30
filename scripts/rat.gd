extends CharacterBody2D

@export var speed := 90.0
## Distance the rat walks either side of where it was placed.
@export var patrol_distance := 200.0
@export var gravity := 2400.0
@export var rig_scale := 1.25

const LEG_PHASES := [0.0, PI, PI, 0.0]

var _home_x := 0.0
var _dir := 1.0
var _pause := 0.0
var _startle := 0.0
var _phase := 0.0
var _time := 0.0
var _tail_base: PackedVector2Array
var _head_base := Vector2.ZERO

@onready var _rig: Node2D = $Rig
@onready var _body: Node2D = $Rig/Body
@onready var _head: Node2D = $Rig/Head
@onready var _eyes: Node2D = $Rig/Head/Eyes
@onready var _startle_marks: Node2D = $Rig/Head/Startle
@onready var _tail: Line2D = $Rig/Tail
@onready var _tail_outline: Line2D = $Rig/TailOutline
@onready var _legs: Array[Node2D] = [$Rig/FarBackLeg, $Rig/FarFrontLeg, $Rig/NearBackLeg, $Rig/NearFrontLeg]
@onready var _hurtbox: Area2D = $Hurtbox


func _ready() -> void:
	_home_x = global_position.x
	_tail_base = _tail.points
	_head_base = _head.position


func _physics_process(delta: float) -> void:
	velocity.y += gravity * delta
	if _pause > 0.0:
		_pause -= delta
		velocity.x = 0.0
	else:
		velocity.x = _dir * speed
		var past_right := _dir > 0.0 and global_position.x > _home_x + patrol_distance
		var past_left := _dir < 0.0 and global_position.x < _home_x - patrol_distance
		if past_right or past_left:
			_dir = -_dir
			_pause = 0.4
	move_and_slide()
	if is_on_wall():
		_dir = -_dir

	for body in _hurtbox.get_overlapping_bodies():
		if body.has_method("bump") and body.bump(global_position.x):
			_startle = 0.8
			_pause = 0.8
			if is_on_floor():
				velocity.y = -380.0


func _process(delta: float) -> void:
	_time += delta
	_startle = maxf(_startle - delta, 0.0)
	_rig.scale = Vector2(_dir, 1.0) * rig_scale

	var moving := absf(velocity.x) > 5.0
	if moving:
		_phase += delta * 14.0
	for i in _legs.size():
		var target := sin(_phase + LEG_PHASES[i]) * 0.5 if moving else 0.0
		_legs[i].rotation = lerp_angle(_legs[i].rotation, target, 1.0 - exp(-20.0 * delta))
	var bob := -absf(sin(_phase)) * 3.0 if moving else 0.0
	_body.position.y = bob
	_head.position = _head_base + Vector2(0, bob)

	_startle_marks.visible = _startle > 0.0
	_eyes.scale = Vector2.ONE * (1.35 if _startle > 0.0 else 1.0)

	var wag_speed := 14.0 if _startle > 0.0 else 6.0
	var points := PackedVector2Array()
	for i in _tail_base.size():
		points.append(_tail_base[i] + Vector2(0, sin(_time * wag_speed - i * 0.8) * i * 2.0))
	_tail.points = points
	_tail_outline.points = points
