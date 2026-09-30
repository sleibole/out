extends CharacterBody2D

## Draw scale of the shape rig; keep the collision capsule in player.tscn in step.
@export var rig_scale := 1.25

@export_group("Run")
@export var run_speed := 420.0
@export var ground_accel := 2400.0
@export var ground_decel := 3000.0
@export var air_control := 0.8

@export_group("Jump")
@export var jump_height := 224.0
@export var time_to_apex := 0.38
@export var fall_gravity_multiplier := 1.6
@export var jump_cut := 0.5
@export var max_fall_speed := 1100.0
@export var coyote_time := 0.12
@export var jump_buffer_time := 0.15
## How far the player is nudged up when a jump barely misses a ledge corner.
@export var ledge_assist := 16.0

@export_group("Bump and respawn")
@export var bump_velocity := Vector2(380, -520)
@export var bump_control_lock := 0.3
@export var invulnerable_time := 1.2
@export var respawn_delay := 0.9

var facing := 1.0
var respawn_position := Vector2.ZERO

var _coyote := 0.0
var _buffer := 0.0
var _jump_held := false
var _invulnerable := 0.0
var _control_lock := 0.0
var _in_water := false
var _frozen := false
var _fall_speed := 0.0
var _squash := Vector2.ONE
var _run_phase := 0.0
var _time := 0.0
var _blink_timer := 3.0
var _surprised := 0.0

@onready var _rig: Node2D = $Rig
@onready var _body: Node2D = $Rig/Body
@onready var _eyes: Node2D = $Rig/Body/Head/Eyes
@onready var _smile: Node2D = $Rig/Body/Head/Mouth/Smile
@onready var _oh: Node2D = $Rig/Body/Head/Mouth/Oh
@onready var _near_leg: Node2D = $Rig/NearLeg
@onready var _far_leg: Node2D = $Rig/FarLeg
@onready var _near_arm: Node2D = $Rig/Body/NearArm
@onready var _far_arm: Node2D = $Rig/Body/FarArm


func _ready() -> void:
	add_to_group("player")
	respawn_position = global_position
	floor_snap_length = 8.0


func _gravity() -> float:
	return 2.0 * jump_height / (time_to_apex * time_to_apex)


func _jump_velocity() -> float:
	return -2.0 * jump_height / time_to_apex


func _physics_process(delta: float) -> void:
	_time += delta
	_invulnerable = maxf(_invulnerable - delta, 0.0)
	_control_lock = maxf(_control_lock - delta, 0.0)

	if _in_water:
		velocity = velocity.move_toward(Vector2(0, 90), 2500.0 * delta)
		global_position += velocity * delta
		return

	if _frozen:
		velocity.x = move_toward(velocity.x, 0.0, ground_decel * delta)
		velocity.y = minf(velocity.y + _gravity() * delta, max_fall_speed)
		move_and_slide()
		return

	var dir := Input.get_axis("move_left", "move_right")
	if _control_lock > 0.0:
		dir = 0.0

	if is_on_floor():
		_coyote = coyote_time
	else:
		_coyote -= delta
	if Input.is_action_just_pressed("jump"):
		_buffer = jump_buffer_time
	else:
		_buffer -= delta
	if _buffer > 0.0 and _coyote > 0.0:
		_jump()

	if _jump_held and velocity.y < 0.0 and not Input.is_action_pressed("jump"):
		velocity.y *= jump_cut
		_jump_held = false
	if velocity.y >= 0.0:
		_jump_held = false

	var g := _gravity()
	if velocity.y > 0.0:
		g *= fall_gravity_multiplier
	velocity.y = minf(velocity.y + g * delta, max_fall_speed)

	var accel := ground_accel if dir != 0.0 else ground_decel
	if not is_on_floor():
		accel *= air_control
	velocity.x = move_toward(velocity.x, dir * run_speed, accel * delta)
	if dir != 0.0:
		facing = signf(dir)

	var was_on_floor := is_on_floor()
	_fall_speed = velocity.y
	move_and_slide()
	if dir != 0.0 and is_on_wall() and not is_on_floor():
		_ledge_assist(dir)
	if is_on_floor() and not was_on_floor:
		_land()


func _jump() -> void:
	velocity.y = _jump_velocity()
	_buffer = 0.0
	_coyote = 0.0
	_jump_held = true
	_squash = Vector2(0.8, 1.2)
	Game.play_sfx("jump")
	Game.burst(global_position, Color("#E8E2D8"), 6, 60, 140, Vector2.UP, 70, Vector2(0, 200), 0.45, 0.35)


func _land() -> void:
	if _fall_speed < 250.0:
		return
	_squash = Vector2(1.25, 0.78)
	Game.play_sfx("land", 0.1, -4.0)
	Game.burst(global_position, Color("#E8E2D8"), 8, 80, 180, Vector2.UP, 80, Vector2(0, 250), 0.5, 0.4)


func _ledge_assist(dir: float) -> void:
	for lift in range(4, int(ledge_assist) + 1, 4):
		var lifted := global_transform.translated(Vector2(0, -lift))
		if not test_move(global_transform, Vector2(0, -lift)) and not test_move(lifted, Vector2(dir * 4.0, 0)):
			global_position += Vector2(dir * 4.0, -lift)
			velocity.y = minf(velocity.y, 0.0)
			return


func fall_in_water(surface_y: float) -> void:
	if _in_water or _frozen:
		return
	_in_water = true
	velocity = Vector2(velocity.x * 0.2, minf(velocity.y, 300.0))
	_surprised = respawn_delay
	Game.play_sfx("splash")
	Game.burst(Vector2(global_position.x, surface_y), Color("#B8F2DC"), 22, 250, 520, Vector2.UP, 40, Vector2(0, 1400), 0.7, 0.8)
	await get_tree().create_timer(respawn_delay).timeout
	global_position = respawn_position
	velocity = Vector2.ZERO
	_in_water = false
	_invulnerable = 1.0
	_squash = Vector2(0.8, 1.2)
	Game.play_sfx("plop")


## Called by enemies on contact. Returns true if the bump happened.
func bump(from_x: float) -> bool:
	if _invulnerable > 0.0 or _in_water or _frozen:
		return false
	var away := signf(global_position.x - from_x)
	if away == 0.0:
		away = -facing
	velocity = Vector2(away * bump_velocity.x, bump_velocity.y)
	_control_lock = bump_control_lock
	_invulnerable = invulnerable_time
	_surprised = 0.6
	_jump_held = false
	_squash = Vector2(1.2, 0.85)
	Game.play_sfx("squeak")
	return true


func celebrate() -> void:
	_frozen = true
	_invulnerable = 0.0
	if is_on_floor():
		velocity.y = -450.0
	var tween := create_tween()
	tween.tween_interval(0.5)
	tween.tween_property(self, "modulate:a", 0.0, 0.6)


func _process(delta: float) -> void:
	_squash = _squash.lerp(Vector2.ONE, 1.0 - exp(-12.0 * delta))
	_rig.scale = Vector2(facing * _squash.x, _squash.y) * rig_scale
	var flashing := _invulnerable > 0.0 and fmod(_time, 0.16) < 0.08
	_rig.modulate.a = 0.35 if flashing else 1.0

	var t := 1.0 - exp(-14.0 * delta)
	var on_floor := is_on_floor() and not _in_water
	if on_floor and absf(velocity.x) > 30.0:
		_run_phase += delta * absf(velocity.x) / run_speed * 13.0
		var s := sin(_run_phase)
		_set_limbs(s * 0.75, -s * 0.75, -s * 0.9, s * 0.9, t)
		_body.position.y = -absf(cos(_run_phase)) * 5.0
		_body.rotation = lerp_angle(_body.rotation, 0.08, t)
	elif on_floor:
		_set_limbs(0.0, 0.0, 0.08, -0.05, t)
		_body.position.y = sin(_time * 2.5) * 1.5
		_body.rotation = lerp_angle(_body.rotation, 0.0, t)
	elif velocity.y < 0.0:
		_set_limbs(-0.6, 0.5, 1.1, -1.7, t)
		_body.position.y = lerpf(_body.position.y, 0.0, t)
		_body.rotation = lerp_angle(_body.rotation, 0.0, t)
	else:
		var flail := sin(_time * 22.0) * 0.25
		_set_limbs(-0.3, 0.3, 2.5 + flail, -2.6 - flail, t)
		_body.rotation = lerp_angle(_body.rotation, 0.0, t)

	_surprised = maxf(_surprised - delta, 0.0)
	var oh := _surprised > 0.0 or _in_water or (not on_floor and velocity.y > 700.0)
	_oh.visible = oh
	_smile.visible = not oh

	_blink_timer -= delta
	if _blink_timer <= 0.0:
		_blink_timer = randf_range(2.2, 4.5)
	_eyes.scale.y = 0.12 if _blink_timer < 0.12 else 1.0


func _set_limbs(near_leg: float, far_leg: float, near_arm: float, far_arm: float, t: float) -> void:
	_near_leg.rotation = lerp_angle(_near_leg.rotation, near_leg, t)
	_far_leg.rotation = lerp_angle(_far_leg.rotation, far_leg, t)
	_near_arm.rotation = lerp_angle(_near_arm.rotation, near_arm, t)
	_far_arm.rotation = lerp_angle(_far_arm.rotation, far_arm, t)
