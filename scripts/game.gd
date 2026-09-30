extends Node

signal plunger_collected(count: int)
signal level_finished

const PLUNGERS_TOTAL := 1
const SFX_NAMES := ["jump", "land", "plop", "splash", "squeak", "chime", "flush"]

var plungers := 0
var finished := false

var _sfx := {}
var _players: Array[AudioStreamPlayer] = []
var _disc: Texture2D


func _ready() -> void:
	for sfx_name in SFX_NAMES:
		_sfx[sfx_name] = load("res://audio/sfx/%s.wav" % sfx_name)
	for i in 8:
		var player := AudioStreamPlayer.new()
		add_child(player)
		_players.append(player)
	_disc = _make_disc()


func reset() -> void:
	plungers = 0
	finished = false


func collect_plunger() -> void:
	plungers += 1
	plunger_collected.emit(plungers)


func finish() -> void:
	if finished:
		return
	finished = true
	level_finished.emit()


func play_sfx(sfx_name: String, pitch_jitter := 0.06, volume_db := 0.0) -> void:
	for player in _players:
		if not player.playing:
			player.stream = _sfx[sfx_name]
			player.pitch_scale = randf_range(1.0 - pitch_jitter, 1.0 + pitch_jitter)
			player.volume_db = volume_db
			player.play()
			return


## One-shot particle burst in the current scene, used for dust, splashes and sparkles.
func burst(pos: Vector2, color: Color, amount: int, speed_min: float, speed_max: float,
		direction := Vector2.UP, spread := 60.0, gravity := Vector2(0, 900),
		size := 0.5, lifetime := 0.6) -> void:
	var particles := CPUParticles2D.new()
	particles.texture = _disc
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.amount = amount
	particles.lifetime = lifetime
	particles.direction = direction
	particles.spread = spread
	particles.initial_velocity_min = speed_min
	particles.initial_velocity_max = speed_max
	particles.gravity = gravity
	particles.scale_amount_min = size * 0.6
	particles.scale_amount_max = size
	particles.color = color
	var fade := Gradient.new()
	fade.set_color(0, Color.WHITE)
	fade.set_color(1, Color(1, 1, 1, 0))
	particles.color_ramp = fade
	particles.z_index = 15
	get_tree().current_scene.add_child(particles)
	particles.global_position = pos
	particles.emitting = true
	particles.finished.connect(particles.queue_free)


func _make_disc() -> Texture2D:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.85, 1.0])
	gradient.colors = PackedColorArray([Color.WHITE, Color.WHITE, Color(1, 1, 1, 0)])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(0.5, 0.0)
	texture.width = 32
	texture.height = 32
	return texture
