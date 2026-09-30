extends Node
## Saves screenshots of level_0 with the player placed at several points.
##
##   Godot --path . res://tools/capture.tscn -- --out=/tmp/shots [--x=320,1500] [--size=1920x1080]
## Needs a window, so it cannot run headless.

func _ready() -> void:
	var args := _args()
	var out: String = args.get("out", "res://.captures")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	var xs: Array = []
	for s in String(args.get("x", "320,1100,1800,2464,3500")).split(","):
		xs.append(float(s))

	var level: Node2D = load("res://scenes/levels/level_0.tscn").instantiate()
	add_child(level)
	var player: CharacterBody2D = level.get_node("Player")
	var camera: Camera2D = level.get_node("Camera")
	var zoom := float(args.get("zoom", "1"))
	camera.zoom = Vector2(zoom, zoom)
	if zoom > 1.0:
		camera.set("vertical_offset", -90.0)
	for x in xs:
		var on_plunger_pipe := absf(x - 2464.0) < 1.0
		player.global_position = Vector2(x, 250.0 if on_plunger_pipe else 300.0)
		player.velocity = Vector2.ZERO
		for i in 50:
			await get_tree().physics_frame
		camera.reset_smoothing()
		var pose: String = args.get("pose", "idle")
		if pose != "idle":
			Input.action_press("move_right")
			if pose == "jump":
				Input.action_press("jump")
			for i in 14:
				await get_tree().physics_frame
			Input.action_release("move_right")
			Input.action_release("jump")
		for i in 2:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var img := get_viewport().get_texture().get_image()
		var path := "%s/shot_%04d.png" % [out, int(x)]
		img.save_png(ProjectSettings.globalize_path(path))
		print("saved ", path, " ", img.get_size())
	get_tree().quit()


func _args() -> Dictionary:
	var result := {}
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--") and "=" in a:
			var kv := a.substr(2).split("=", true, 1)
			result[kv[0]] = kv[1]
	return result
