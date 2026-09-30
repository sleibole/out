extends Node
## Plays level_0 with scripted inputs and reports whether the exit and plunger were reached.
##
##   Godot --headless --path . res://tools/bot.tscn -- --route=main|plunger|fall
## "fall" walks into the first gap, then into the rat, to exercise respawn and bump.

## [x to jump at, only when standing at or above this y]
const MAIN_JUMPS := [[700.0, 800.0], [1150.0, 800.0], [2170.0, 800.0], [2930.0, 800.0]]
const PLUNGER_JUMPS := [[700.0, 800.0], [1150.0, 800.0], [1640.0, 800.0], [1950.0, 600.0],
	[2190.0, 420.0], [2170.0, 800.0], [2930.0, 800.0]]

var _player: CharacterBody2D
var _rat: Node2D
var _jumps: Array
var _jump_release := 0.0
var _time := 0.0
var _splashes := 0
var _bumps := 0
var _was_in_water := false
var _was_invulnerable := false
var _avoid_rat := true


func _ready() -> void:
	var route := "main"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--route="):
			route = a.get_slice("=", 1)
	match route:
		"plunger": _jumps = PLUNGER_JUMPS.duplicate(true)
		"fall": _jumps = []
		_: _jumps = MAIN_JUMPS.duplicate(true)
	_avoid_rat = route != "fall"
	var level: Node2D = load("res://scenes/levels/level_0.tscn").instantiate()
	add_child(level)
	_player = level.get_node("Player")
	_rat = level.get_node("Rat")
	Input.action_press("move_right")
	print("route: ", route)


func _physics_process(delta: float) -> void:
	_time += delta
	var pos := _player.global_position
	if _jump_release > 0.0:
		_jump_release -= delta
		if _jump_release <= 0.0:
			Input.action_release("jump")
	elif _player.is_on_floor():
		for j in _jumps:
			if pos.x >= j[0] and pos.x < j[0] + 120.0 and pos.y <= j[1]:
				_press_jump()
				_jumps.erase(j)
				break
		var to_rat := _rat.global_position.x - pos.x
		if _avoid_rat and _jump_release <= 0.0 and to_rat > 0.0 and to_rat < 170.0 and absf(_rat.global_position.y - pos.y) < 40.0:
			_press_jump()

	var in_water: bool = _player.get("_in_water")
	if in_water and not _was_in_water:
		_splashes += 1
		print("  %.1fs splash at x=%d" % [_time, pos.x])
	_was_in_water = in_water
	var invulnerable: bool = _player.get("_invulnerable") > 0.0 and not in_water
	if invulnerable and not _was_invulnerable and not _was_in_water:
		_bumps += 1
		print("  %.1fs bumped at x=%d" % [_time, pos.x])
	_was_invulnerable = invulnerable

	if _splashes == 1 and not _avoid_rat and _time > 3.0 and _time < 3.1:
		_player.global_position = Vector2(1500, 600)
		_player.respawn_position = Vector2(1500, 600)
	if Game.finished or _time > (8.0 if not _avoid_rat else 40.0):
		print("finished=%s time=%.1fs plungers=%d splashes=%d bumps=%d" % [Game.finished, _time, Game.plungers, _splashes, _bumps])
		set_physics_process(false)
		if DisplayServer.get_name() != "headless":
			await get_tree().create_timer(2.2).timeout
			await RenderingServer.frame_post_draw
			var path := ProjectSettings.globalize_path("res://.captures/end_card.png")
			get_viewport().get_texture().get_image().save_png(path)
			print("saved ", path)
		get_tree().quit()


func _press_jump() -> void:
	Input.action_press("jump")
	_jump_release = 0.35
