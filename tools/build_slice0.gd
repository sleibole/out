extends Node
## Generates the Slice 0 scenes: shape-built character rigs, the tile set, and level_0.
## Runs as a scene rather than with --script so the Game autoload exists when
## gameplay scripts are compiled.
##
##   Godot --headless --path . res://tools/build_slice0.tscn
##
## Rerunning overwrites every generated scene, including edits made in the editor.
## Once a scene is being hand-edited, remove its build step from _init().

const INK := Color("#1E1A22")
const TILE := 64
const LEVEL_COLS := 60
const LEVEL_ROWS := 17
const WATER_Y := 860.0

const C := {
	"skin": Color("#F6CFB0"), "skin_shadow": Color("#E0AE8C"),
	"hair": Color("#8A4B2A"), "hair_shadow": Color("#6A361C"),
	"hoodie": Color("#557F48"), "hoodie_shadow": Color("#3E6135"),
	"boot": Color("#F2C230"), "boot_shadow": Color("#C99A1C"),
	"mouth": Color("#7A2E2E"), "tongue": Color("#E0707A"), "blush": Color("#F2A0A0"),
	"rat": Color("#6E6878"), "rat_shadow": Color("#524D5B"), "rat_belly": Color("#9A94A4"),
	"rat_pink": Color("#E89AA8"), "rat_pink_shadow": Color("#C87888"),
	"gold": Color("#F2A81C"), "gold_shadow": Color("#C47F0E"), "gold_light": Color("#FFE27A"),
	"pipe": Color("#5A5560"), "pipe_light": Color("#8A8590"), "pipe_shadow": Color("#3F3B45"),
	"sky_top": Color("#A7D3CB"), "sky_bottom": Color("#6FA39E"), "light": Color("#F2D57A"),
	"bg_pipe": Color("#6A9F9A"), "bg_pipe_dark": Color("#5E918C"), "bg_blob": Color("#5E9591"),
	"mid_pipe": Color("#4F817E"), "mid_pipe_dark": Color("#436F6C"),
	"brick": Color("#6E5A55"), "brick_light": Color("#82695F"),
	"wood": Color("#8A5A3A"), "board": Color("#C9955E"),
}

var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = 7
	_add_input_map()
	_save(_build_player_rig(), "res://scenes/player/player_rig.tscn")
	_save(_build_rat_rig(), "res://scenes/enemies/rat_rig.tscn")
	_save(_build_plunger_rig(), "res://scenes/objects/golden_plunger_rig.tscn")
	_save(_build_player(), "res://scenes/player/player.tscn")
	_save(_build_rat(), "res://scenes/enemies/rat.tscn")
	_save(_build_plunger(), "res://scenes/objects/golden_plunger.tscn")
	_save(_build_checkpoint(), "res://scenes/objects/checkpoint.tscn")
	var tileset := _build_tileset()
	ResourceSaver.save(tileset, "res://art/tiles/sewer_tileset.tres")
	_save(_build_level(load("res://art/tiles/sewer_tileset.tres")), "res://scenes/levels/level_0.tscn")
	print("Slice 0 build complete")
	get_tree().quit()


# --- Input ------------------------------------------------------------------

func _key(code: Key) -> InputEventKey:
	var e := InputEventKey.new()
	e.physical_keycode = code
	return e


func _pad_button(button: JoyButton) -> InputEventJoypadButton:
	var e := InputEventJoypadButton.new()
	e.button_index = button
	return e


func _pad_axis(axis: JoyAxis, value: float) -> InputEventJoypadMotion:
	var e := InputEventJoypadMotion.new()
	e.axis = axis
	e.axis_value = value
	return e


func _add_input_map() -> void:
	var actions := {
		"move_left": [_key(KEY_A), _key(KEY_LEFT), _pad_button(JOY_BUTTON_DPAD_LEFT), _pad_axis(JOY_AXIS_LEFT_X, -1.0)],
		"move_right": [_key(KEY_D), _key(KEY_RIGHT), _pad_button(JOY_BUTTON_DPAD_RIGHT), _pad_axis(JOY_AXIS_LEFT_X, 1.0)],
		"jump": [_key(KEY_SPACE), _key(KEY_W), _key(KEY_UP), _pad_button(JOY_BUTTON_A)],
		"restart": [_key(KEY_R), _pad_button(JOY_BUTTON_BACK)],
	}
	for action in actions:
		ProjectSettings.set_setting("input/" + action, {"deadzone": 0.3, "events": actions[action]})
	ProjectSettings.save()


# --- Geometry helpers -------------------------------------------------------

func ellipse(c: Vector2, rx: float, ry: float, n := 32) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n:
		var a := TAU * i / n
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return pts


func circle(c: Vector2, r: float, n := 32) -> PackedVector2Array:
	return ellipse(c, r, r, n)


func rect(r: Rect2) -> PackedVector2Array:
	return PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)])


func capsule(a: Vector2, b: Vector2, r: float) -> PackedVector2Array:
	return largest(Geometry2D.offset_polyline(PackedVector2Array([a, b]), r, Geometry2D.JOIN_ROUND, Geometry2D.END_ROUND))


func arc_stroke(pts: Array, r: float) -> PackedVector2Array:
	return largest(Geometry2D.offset_polyline(PackedVector2Array(pts), r, Geometry2D.JOIN_ROUND, Geometry2D.END_ROUND))


func rounded(pts: PackedVector2Array, r: float) -> PackedVector2Array:
	var inner := largest(Geometry2D.offset_polygon(pts, -r, Geometry2D.JOIN_MITER))
	return largest(Geometry2D.offset_polygon(inner, r, Geometry2D.JOIN_ROUND))


func rrect(r: Rect2, radius: float) -> PackedVector2Array:
	return rounded(rect(r), radius)


func shifted(pts: PackedVector2Array, offset: Vector2) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in pts:
		out.append(p + offset)
	return out


func merge(a: PackedVector2Array, b: PackedVector2Array) -> PackedVector2Array:
	return largest(Geometry2D.merge_polygons(a, b))


func inter(a: PackedVector2Array, b: PackedVector2Array) -> Array:
	return Geometry2D.intersect_polygons(a, b)


## The parts of `shape` not covered by `shape` moved by `light_offset`: a cel-shadow crescent.
func crescent(shape: PackedVector2Array, light_offset: Vector2) -> Array:
	return Geometry2D.clip_polygons(shape, shifted(shape, light_offset))


func largest(polys: Array) -> PackedVector2Array:
	var best := PackedVector2Array()
	var best_size := -1.0
	for p in polys:
		var size := _bounds(p).get_area()
		if size > best_size:
			best = p
			best_size = size
	return best


func _bounds(pts: PackedVector2Array) -> Rect2:
	var r := Rect2(pts[0], Vector2.ZERO)
	for p in pts:
		r = r.expand(p)
	return r


func star(c: Vector2, outer: float, inner_r: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 8:
		var a := TAU * i / 8.0 - PI / 2.0
		var r := outer if i % 2 == 0 else inner_r
		pts.append(c + Vector2(cos(a), sin(a)) * r)
	return pts


# --- Node helpers -----------------------------------------------------------

func node(parent: Node, node_name: String, pos := Vector2.ZERO) -> Node2D:
	var n := Node2D.new()
	n.name = node_name
	n.position = pos
	parent.add_child(n)
	return n


func poly(parent: Node, node_name: String, pts: PackedVector2Array, color: Color) -> Polygon2D:
	var p := Polygon2D.new()
	p.name = node_name
	p.polygon = pts
	p.color = color
	p.antialiased = true
	parent.add_child(p)
	return p


## A shape with an ink outline behind it and optional cel-shadow polygons on top.
func part(parent: Node, node_name: String, pts: PackedVector2Array, color: Color,
		shadows: Array = [], shadow_color := Color.BLACK, outline := 3.0) -> Node2D:
	var n := node(parent, node_name)
	if outline > 0.0:
		poly(n, "Outline", largest(Geometry2D.offset_polygon(pts, outline, Geometry2D.JOIN_ROUND)), INK)
	poly(n, "Fill", pts, color)
	for i in shadows.size():
		poly(n, "Shadow" if i == 0 else "Shadow%d" % (i + 1), shadows[i], shadow_color)
	return n


func line(parent: Node, node_name: String, pts: PackedVector2Array, color: Color, width: float) -> Line2D:
	var l := Line2D.new()
	l.name = node_name
	l.points = pts
	l.default_color = color
	l.width = width
	l.joint_mode = Line2D.LINE_JOINT_ROUND
	l.begin_cap_mode = Line2D.LINE_CAP_ROUND
	l.end_cap_mode = Line2D.LINE_CAP_ROUND
	l.antialiased = true
	parent.add_child(l)
	return l


func label(parent: Node, node_name: String, text: String, pos: Vector2, size: Vector2,
		font_size: int, color: Color, outline_color := Color(0, 0, 0, 0), outline := 0) -> Label:
	var l := Label.new()
	l.name = node_name
	l.text = text
	l.position = pos
	l.size = size
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var settings := LabelSettings.new()
	settings.font_size = font_size
	settings.font_color = color
	settings.outline_size = outline
	settings.outline_color = outline_color
	l.label_settings = settings
	parent.add_child(l)
	return l


func rect_shape(parent: Node, size: Vector2, pos := Vector2.ZERO) -> CollisionShape2D:
	var shape := RectangleShape2D.new()
	shape.size = size
	var cs := CollisionShape2D.new()
	cs.name = "CollisionShape2D"
	cs.shape = shape
	cs.position = pos
	parent.add_child(cs)
	return cs


func instance(parent: Node, path: String, node_name: String, pos := Vector2.ZERO) -> Node2D:
	var scene: PackedScene = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_REPLACE)
	var n: Node2D = scene.instantiate()
	n.name = node_name
	n.position = pos
	parent.add_child(n)
	return n


func _set_owner(n: Node, root: Node) -> void:
	for child in n.get_children():
		child.owner = root
		if child.scene_file_path.is_empty():
			_set_owner(child, root)


func _save(root: Node, path: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	_set_owner(root, root)
	var scene := PackedScene.new()
	var err := scene.pack(root)
	assert(err == OK, "pack failed: " + path)
	err = ResourceSaver.save(scene, path)
	assert(err == OK, "save failed: " + path)
	root.free()
	print("saved ", path)


# --- Player rig (hybrid pose: profile body, head turned a quarter to camera) --
# Faces right. Origin is between the feet. About 150 px tall.

func _build_player_rig() -> Node2D:
	var rig := Node2D.new()
	rig.name = "Rig"

	for side in ["Far", "Near"]:
		var far: bool = side == "Far"
		var leg := node(rig, side + "Leg", Vector2(7 if far else -3, -34))
		part(leg, "Leg", capsule(Vector2(0, 0), Vector2(0, 20), 6.0), C.skin_shadow if far else C.skin)
		var boot := merge(rrect(Rect2(-8, 12, 16, 18), 4), capsule(Vector2(-2, 27.5), Vector2(9, 27.5), 6.5))
		var boot_shadows := [] if far else inter(boot, rect(Rect2(-30, 28, 60, 20)))
		part(leg, "Boot", boot, C.boot_shadow if far else C.boot, boot_shadows, C.boot_shadow)

	var body := node(rig, "Body")

	var far_arm := node(body, "FarArm", Vector2(8, -78))
	part(far_arm, "Sleeve", capsule(Vector2.ZERO, Vector2(0, 24), 7.5), C.hoodie_shadow)
	part(far_arm, "Hand", circle(Vector2(0, 31), 6.0), C.skin_shadow)

	var torso := rounded(PackedVector2Array([
		Vector2(-19, -88), Vector2(17, -88), Vector2(25, -44), Vector2(29, -26),
		Vector2(-27, -26), Vector2(-23, -44)]), 7)
	var torso_shadow := inter(torso, PackedVector2Array([
		Vector2(-60, -100), Vector2(-7, -100), Vector2(-13, -20), Vector2(-60, -20)]))
	part(body, "Torso", torso, C.hoodie, torso_shadow, C.hoodie_shadow)
	part(body, "Pocket", capsule(Vector2(-4, -48), Vector2(16, -48), 1.6), INK, [], INK, 0)
	part(body, "Hood", ellipse(Vector2(-15, -90), 17, 11), C.hoodie_shadow)

	var head := node(body, "Head", Vector2(5, -114))
	var pigtail := ellipse(Vector2(-45, 6), 12, 17)
	part(head, "Pigtail", pigtail, C.hair, crescent(pigtail, Vector2(4, -4)), C.hair_shadow)
	part(head, "PigtailTie", circle(Vector2(-36, -4), 5), C.boot, [], C.boot, 2.5)

	var face := circle(Vector2.ZERO, 38, 40)
	part(head, "Face", face, C.skin, Geometry2D.clip_polygons(face, circle(Vector2(9, -7), 38, 40)), C.skin_shadow)
	var ear := part(head, "Ear", circle(Vector2(-13, 9), 8), C.skin, [], C.skin, 2.5)
	poly(ear, "Inner", ellipse(Vector2(-12, 10), 3.5, 4.5), C.skin_shadow)

	part(head, "Tuft", capsule(Vector2(2, -38), Vector2(11, -50), 4.5), C.hair)
	var hair_region := PackedVector2Array([
		Vector2(-60, -60), Vector2(60, -60), Vector2(46, -22), Vector2(32, -29), Vector2(17, -28),
		Vector2(4, -24), Vector2(-8, -18), Vector2(-19, -2), Vector2(-28, 30), Vector2(-60, 30)])
	var hair := largest(inter(circle(Vector2(0, -2), 41, 40), hair_region))
	part(head, "Hair", hair, C.hair, Geometry2D.clip_polygons(hair, circle(Vector2(8, -10), 40, 40)), C.hair_shadow)

	var eyes := node(head, "Eyes", Vector2(0, -2))
	var near_eye := part(eyes, "NearEye", ellipse(Vector2(9, 3), 7.5, 10), Color.WHITE, [], INK, 2.0)
	poly(near_eye, "Pupil", circle(Vector2(11.5, 4), 5.5), INK)
	poly(near_eye, "Highlight", circle(Vector2(13.3, 1), 1.9), Color.WHITE)
	var far_eye := part(eyes, "FarEye", ellipse(Vector2(29, 2), 5.5, 9.5), Color.WHITE, [], INK, 2.0)
	poly(far_eye, "Pupil", circle(Vector2(30.5, 3), 4.5), INK)
	poly(far_eye, "Highlight", circle(Vector2(31.9, 0.5), 1.5), Color.WHITE)

	part(head, "NearBrow", arc_stroke([Vector2(3, -14), Vector2(9, -18), Vector2(15, -15)], 1.8), INK, [], INK, 0)
	part(head, "FarBrow", arc_stroke([Vector2(25, -15), Vector2(29, -18), Vector2(33, -15)], 1.5), INK, [], INK, 0)
	part(head, "Nose", circle(Vector2(37, 7), 4.5), C.skin, [], C.skin, 2.0)
	poly(head, "Blush", ellipse(Vector2(5, 18), 7, 4.5), Color(C.blush, 0.55))

	var mouth := node(head, "Mouth")
	var smile := PackedVector2Array()
	for i in 17:
		var a := PI * i / 16.0
		smile.append(Vector2(22 + 9 * cos(a), 16 + 8 * sin(a)))
	part(mouth, "Smile", smile, C.mouth, inter(smile, ellipse(Vector2(22, 23), 6, 4)), C.tongue, 2.0)
	var oh_shape := ellipse(Vector2(23, 19), 5, 6.5)
	var oh := part(mouth, "Oh", oh_shape, C.mouth, inter(oh_shape, ellipse(Vector2(23, 24), 4, 3)), C.tongue, 2.0)
	oh.visible = false

	var near_arm := node(body, "NearArm", Vector2(-3, -77))
	var sleeve := capsule(Vector2.ZERO, Vector2(0, 24), 7.5)
	part(near_arm, "Sleeve", sleeve, C.hoodie, inter(sleeve, rect(Rect2(-20, -20, 17, 60))), C.hoodie_shadow)
	part(near_arm, "Hand", circle(Vector2(0, 31), 6.5), C.skin)
	return rig


# --- Rat rig ----------------------------------------------------------------
# Faces right. Origin between the feet. About 70 px tall.

func _build_rat_rig() -> Node2D:
	var rig := Node2D.new()
	rig.name = "Rig"
	var tail_pts := PackedVector2Array([
		Vector2(-28, -24), Vector2(-44, -30), Vector2(-56, -42), Vector2(-64, -56), Vector2(-78, -62)])
	line(rig, "TailOutline", tail_pts, INK, 10.0)
	line(rig, "Tail", tail_pts, C.rat_pink, 5.0)

	for spec in [["FarBackLeg", Vector2(-14, -12), true], ["FarFrontLeg", Vector2(20, -12), true]]:
		_rat_leg(rig, spec[0], spec[1], spec[2])

	var body := node(rig, "Body")
	var body_shape := ellipse(Vector2(0, -26), 34, 21)
	var body_part := part(body, "Torso", body_shape, C.rat, crescent(body_shape, Vector2(6, -6)), C.rat_shadow)
	for belly in inter(body_shape, ellipse(Vector2(8, -10), 24, 10)):
		poly(body_part, "Belly", belly, C.rat_belly)

	for spec in [["NearBackLeg", Vector2(-20, -10), false], ["NearFrontLeg", Vector2(14, -10), false]]:
		_rat_leg(rig, spec[0], spec[1], spec[2])

	var head := node(rig, "Head", Vector2(30, -38))
	var far_ear := part(head, "FarEar", circle(Vector2(4, -19), 10), C.rat_shadow)
	poly(far_ear, "Inner", circle(Vector2(4, -19), 6), C.rat_pink_shadow)
	var head_shape := merge(ellipse(Vector2.ZERO, 20, 17), capsule(Vector2(6, 2), Vector2(24, 6), 10))
	part(head, "Skull", head_shape, C.rat, crescent(head_shape, Vector2(4, -5)), C.rat_shadow)
	part(head, "Teeth", rrect(Rect2(21, 13, 10, 8), 2), Color.WHITE, [], INK, 2.0)
	poly(head, "ToothGap", rect(Rect2(25.6, 13, 1, 8)), INK)
	part(head, "Nose", circle(Vector2(34, 5), 5), C.rat_pink, [], INK, 2.0)
	var near_ear := part(head, "NearEar", circle(Vector2(-10, -17), 12.5), C.rat)
	poly(near_ear, "Inner", circle(Vector2(-9, -16), 7.5), C.rat_pink)

	var eyes := node(head, "Eyes", Vector2(10, -4))
	var e1 := part(eyes, "NearEye", ellipse(Vector2(-5, 0), 5.5, 7), Color.WHITE, [], INK, 2.0)
	poly(e1, "Pupil", circle(Vector2(-3.5, 1), 3.3), INK)
	var e2 := part(eyes, "FarEye", ellipse(Vector2(5, -1), 4.2, 6.5), Color.WHITE, [], INK, 2.0)
	poly(e2, "Pupil", circle(Vector2(6.3, 0), 2.8), INK)

	line(head, "Whisker1", PackedVector2Array([Vector2(30, 3), Vector2(46, -3)]), INK, 1.6)
	line(head, "Whisker2", PackedVector2Array([Vector2(31, 6), Vector2(49, 6)]), INK, 1.6)
	line(head, "Whisker3", PackedVector2Array([Vector2(30, 9), Vector2(45, 15)]), INK, 1.6)

	var startle := node(head, "Startle")
	for i in 3:
		var a: Vector2 = [Vector2(-4, -36), Vector2(8, -40), Vector2(20, -35)][i]
		var b: Vector2 = [Vector2(-9, -47), Vector2(9, -52), Vector2(27, -45)][i]
		line(startle, "Mark%d" % (i + 1), PackedVector2Array([a, b]), INK, 3.5)
	startle.visible = false
	return rig


func _rat_leg(rig: Node, leg_name: String, pos: Vector2, far: bool) -> void:
	var leg := node(rig, leg_name, pos)
	part(leg, "Leg", capsule(Vector2.ZERO, Vector2(0, 6), 4.0), C.rat_shadow if far else C.rat, [], INK, 2.0)
	part(leg, "Foot", ellipse(Vector2(4, 9), 7, 4), C.rat_pink_shadow if far else C.rat_pink, [], INK, 2.0)


# --- Golden plunger rig -----------------------------------------------------

func _build_plunger_rig() -> Node2D:
	var rig := Node2D.new()
	rig.name = "Rig"
	poly(rig, "Glow", circle(Vector2(0, -8), 52), Color(C.gold_light, 0.22))
	var handle := rrect(Rect2(-5, -38, 10, 48), 4)
	part(rig, "Handle", handle, C.gold, inter(handle, rect(Rect2(-10, -50, 8, 70))), C.gold_shadow)
	var knob := circle(Vector2(0, -40), 8)
	part(rig, "Knob", knob, C.gold, crescent(knob, Vector2(3, -3)), C.gold_shadow)
	var cup := largest(inter(ellipse(Vector2(0, 26), 24, 18), rect(Rect2(-40, 0, 80, 26))))
	part(rig, "Cup", cup, C.gold, crescent(cup, Vector2(5, -4)), C.gold_shadow)
	part(rig, "Rim", rrect(Rect2(-27, 23, 54, 8), 4), C.gold, [], INK, 3.0)
	poly(rig, "Shine", capsule(Vector2(1.5, -32), Vector2(1.5, -2), 1.6), Color(1, 1, 1, 0.75))
	var glint := node(rig, "Glint", Vector2(13, -26))
	poly(glint, "Star", star(Vector2.ZERO, 13, 3), Color.WHITE)
	return rig


# --- Gameplay scenes --------------------------------------------------------

func _build_player() -> Node2D:
	var player := CharacterBody2D.new()
	player.name = "Player"
	player.collision_layer = 1 << 1
	player.collision_mask = 1
	player.set_script(load("res://scripts/player.gd"))
	var shape := CapsuleShape2D.new()
	shape.radius = 26
	shape.height = 176
	var cs := CollisionShape2D.new()
	cs.name = "CollisionShape2D"
	cs.shape = shape
	cs.position = Vector2(0, -88)
	player.add_child(cs)
	instance(player, "res://scenes/player/player_rig.tscn", "Rig")
	return player


func _build_rat() -> Node2D:
	var rat := CharacterBody2D.new()
	rat.name = "Rat"
	rat.collision_layer = 1 << 2
	rat.collision_mask = 1
	rat.set_script(load("res://scripts/rat.gd"))
	rect_shape(rat, Vector2(76, 44), Vector2(0, -22))
	instance(rat, "res://scenes/enemies/rat_rig.tscn", "Rig")
	var hurtbox := Area2D.new()
	hurtbox.name = "Hurtbox"
	hurtbox.collision_layer = 0
	hurtbox.collision_mask = 1 << 1
	rat.add_child(hurtbox)
	rect_shape(hurtbox, Vector2(80, 54), Vector2(0, -32))
	return rat


func _build_plunger() -> Node2D:
	var plunger := Area2D.new()
	plunger.name = "GoldenPlunger"
	plunger.collision_layer = 1 << 3
	plunger.collision_mask = 1 << 1
	plunger.set_script(load("res://scripts/golden_plunger.gd"))
	var shape := CircleShape2D.new()
	shape.radius = 40
	var cs := CollisionShape2D.new()
	cs.name = "CollisionShape2D"
	cs.shape = shape
	plunger.add_child(cs)
	instance(plunger, "res://scenes/objects/golden_plunger_rig.tscn", "Rig")
	return plunger


func _build_checkpoint() -> Node2D:
	var cp := Area2D.new()
	cp.name = "Checkpoint"
	cp.collision_layer = 1 << 3
	cp.collision_mask = 1 << 1
	cp.set_script(load("res://scripts/checkpoint.gd"))
	rect_shape(cp, Vector2(64, 1000), Vector2(0, -400))
	return cp


# --- Tile set ---------------------------------------------------------------

const STONE_TOP := [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)]
const STONE_BODY := [Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)]
const PIPE := [Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2), Vector2i(3, 2)]


func _build_tileset() -> TileSet:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(TILE, TILE)
	ts.add_physics_layer()
	ts.set_physics_layer_collision_layer(0, 1)
	ts.set_physics_layer_collision_mask(0, 0)
	var src := TileSetAtlasSource.new()
	src.texture = load("res://art/tiles/sewer_tiles.svg")
	src.texture_region_size = Vector2i(TILE, TILE)
	ts.add_source(src, 0)
	var full := rect(Rect2(-32, -32, 64, 64))
	var pipe_top := rect(Rect2(-32, -26, 64, 34))
	for coords in STONE_TOP + STONE_BODY:
		src.create_tile(coords)
		var td := src.get_tile_data(coords, 0)
		td.add_collision_polygon(0)
		td.set_collision_polygon_points(0, 0, full)
	for coords in PIPE:
		src.create_tile(coords)
		var td := src.get_tile_data(coords, 0)
		td.add_collision_polygon(0)
		td.set_collision_polygon_points(0, 0, pipe_top)
		td.set_collision_polygon_one_way(0, 0, true)
	return ts


# --- Level ------------------------------------------------------------------

func _build_level(tileset: TileSet) -> Node2D:
	var level := Node2D.new()
	level.name = "Level0"
	level.set_script(load("res://scripts/level.gd"))

	_build_far_background(level)
	_build_mid_background(level)
	var decor := node(level, "Decor")
	decor.z_index = -5
	_build_entry_pipe(decor, Vector2(320, 0))
	_build_drain(decor, "DrainA", 832.0)
	_build_drain(decor, "DrainB", 3072.0)
	_build_exit_art(decor, Vector2(3700, 704))

	var tiles := TileMapLayer.new()
	tiles.name = "Tiles"
	tiles.tile_set = tileset
	level.add_child(tiles)
	# Main path platforms: [first column, last column, top row]. Gaps between them are water.
	for p in [[0, 11, 11], [14, 18, 11], [21, 34, 11], [37, 46, 10], [49, 59, 11]]:
		_paint_platform(tiles, p[0], p[1], p[2])
	# Optional route: one-way pipes rising toward the golden plunger.
	for p in [[27, 30, 8], [32, 34, 6], [37, 39, 4]]:
		_paint_pipe(tiles, p[0], p[1], p[2])

	var checkpoints := node(level, "Checkpoints")
	instance(checkpoints, "res://scenes/objects/checkpoint.tscn", "RatPlatform", Vector2(1376, 704))
	instance(checkpoints, "res://scenes/objects/checkpoint.tscn", "StepUp", Vector2(2400, 640))
	instance(checkpoints, "res://scenes/objects/checkpoint.tscn", "FinalPlatform", Vector2(3168, 704))

	var exit := Area2D.new()
	exit.name = "Exit"
	exit.position = Vector2(3690, 704)
	exit.collision_layer = 1 << 3
	exit.collision_mask = 1 << 1
	exit.set_script(load("res://scripts/exit.gd"))
	level.add_child(exit)
	rect_shape(exit, Vector2(80, 180), Vector2(0, -90))

	instance(level, "res://scenes/objects/golden_plunger.tscn", "GoldenPlunger", Vector2(2464, 196))
	var rat := instance(level, "res://scenes/enemies/rat.tscn", "Rat", Vector2(1824, 700))
	rat.set("patrol_distance", 200.0)
	var player := instance(level, "res://scenes/player/player.tscn", "Player", Vector2(320, 330))

	var water := Node2D.new()
	water.name = "Water"
	water.position = Vector2(0, WATER_Y)
	water.z_index = 10
	water.set_script(load("res://scripts/water.gd"))
	water.set("width", float(LEVEL_COLS * TILE))
	water.set("depth", 260.0)
	level.add_child(water)
	var hazard := Area2D.new()
	hazard.name = "Hazard"
	hazard.collision_layer = 1 << 4
	hazard.collision_mask = 1 << 1
	water.add_child(hazard)
	rect_shape(hazard, Vector2(LEVEL_COLS * TILE + 400, 300), Vector2(LEVEL_COLS * TILE / 2.0, 220))

	_build_foreground(level)

	var bounds := StaticBody2D.new()
	bounds.name = "Bounds"
	level.add_child(bounds)
	rect_shape(bounds, Vector2(64, 3000), Vector2(-32, 0))
	rect_shape(bounds, Vector2(64, 3000), Vector2(LEVEL_COLS * TILE + 32, 0))

	var camera := Camera2D.new()
	camera.name = "Camera"
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = LEVEL_COLS * TILE
	camera.limit_bottom = LEVEL_ROWS * TILE
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 6.0
	camera.set_script(load("res://scripts/camera_follow.gd"))
	level.add_child(camera)
	camera.set("target_path", NodePath("../Player"))

	var hud := CanvasLayer.new()
	hud.name = "HUD"
	hud.set_script(load("res://scripts/hud.gd"))
	level.add_child(hud)
	return level


func _paint_platform(tiles: TileMapLayer, x0: int, x1: int, top: int) -> void:
	for x in range(x0, x1 + 1):
		var column := 0 if x == x0 else (2 if x == x1 else 1)
		tiles.set_cell(Vector2i(x, top), 0, STONE_TOP[column])
		for y in range(top + 1, LEVEL_ROWS):
			tiles.set_cell(Vector2i(x, y), 0, STONE_BODY[column])


func _paint_pipe(tiles: TileMapLayer, x0: int, x1: int, row: int) -> void:
	var middle := (x0 + x1) / 2
	for x in range(x0, x1 + 1):
		var coords: Vector2i = PIPE[1]
		if x == x0:
			coords = PIPE[0]
		elif x == x1:
			coords = PIPE[2]
		elif x == middle and x1 - x0 >= 3:
			coords = PIPE[3]
		tiles.set_cell(Vector2i(x, row), 0, coords)


func _parallax(level: Node, layer_name: String, scroll: float, z: int) -> Parallax2D:
	var p := Parallax2D.new()
	p.name = layer_name
	p.scroll_scale = Vector2(scroll, 1.0)
	p.z_index = z
	level.add_child(p)
	return p


func _build_far_background(level: Node) -> void:
	var far := _parallax(level, "FarBackground", 0.25, -100)
	var sky := poly(far, "Sky", rect(Rect2(-200, -200, 3200, 1400)), Color.WHITE)
	sky.vertex_colors = PackedColorArray([C.sky_top, C.sky_top, C.sky_bottom, C.sky_bottom])
	var arches := node(far, "Arches")
	for spec in [[240, 380, 110], [1080, 300, 210], [1880, 420, 80], [2600, 320, 180]]:
		var x: float = spec[0]
		var w: float = spec[1]
		var top: float = spec[2]
		var shape := merge(rect(Rect2(x, top + w / 2.0, w, 1100)), circle(Vector2(x + w / 2.0, top + w / 2.0), w / 2.0, 48))
		poly(arches, "Arch%d" % arches.get_child_count(), shape, C.light)
	var pipes := node(far, "Pipes")
	for spec in [[120, 50], [700, 60], [980, 44], [1600, 56], [2250, 64], [2620, 48]]:
		poly(pipes, "V%d" % pipes.get_child_count(), rect(Rect2(spec[0], -200, spec[1], 1300)), C.bg_pipe)
		for y in [180, 520]:
			poly(pipes, "Collar%d" % pipes.get_child_count(), rect(Rect2(spec[0] - 6, y, spec[1] + 12, 22)), C.bg_pipe_dark)
	for spec in [[600, 300, 700], [1500, 470, 900], [2300, 250, 600]]:
		poly(pipes, "H%d" % pipes.get_child_count(), rect(Rect2(spec[0], spec[1], spec[2], 44)), C.bg_pipe)
	var blobs := node(far, "Blobs")
	var x := -100.0
	while x < 3000.0:
		var r := _rng.randf_range(70, 120)
		poly(blobs, "Blob%d" % blobs.get_child_count(), circle(Vector2(x, 820 + _rng.randf_range(-40, 30)), r), C.bg_blob)
		x += _rng.randf_range(90, 150)


func _build_mid_background(level: Node) -> void:
	var mid := _parallax(level, "MidBackground", 0.55, -50)
	for spec in [[300, 70, 150], [1150, 80, 0], [1700, 70, 260], [2500, 90, 100], [3200, 70, 200]]:
		var px: float = spec[0]
		var w: float = spec[1]
		var run: float = spec[2]
		var pipe := node(mid, "Pipe%d" % mid.get_child_count())
		poly(pipe, "Vertical", rect(Rect2(px, -100, w, 1300)), C.mid_pipe)
		poly(pipe, "Shade", rect(Rect2(px, -100, w * 0.3, 1300)), C.mid_pipe_dark)
		for y in [240, 600]:
			poly(pipe, "Collar%d" % y, rrect(Rect2(px - 8, y, w + 16, 26), 5), C.mid_pipe_dark)
		if run > 0.0:
			poly(pipe, "Branch", rect(Rect2(px + w, 400, run, 56)), C.mid_pipe)
			poly(pipe, "BranchShade", rect(Rect2(px + w, 440, run, 16)), C.mid_pipe_dark)

	var tk := node(mid, "TKMark", Vector2(1190, 250))
	poly(tk, "Ring", circle(Vector2.ZERO, 42), C.gold_shadow)
	poly(tk, "Plaque", circle(Vector2.ZERO, 35), C.pipe_shadow)
	poly(tk, "Crown", PackedVector2Array([
		Vector2(-18, -40), Vector2(-18, -58), Vector2(-9, -48), Vector2(0, -62),
		Vector2(9, -48), Vector2(18, -58), Vector2(18, -40)]), C.gold)
	label(tk, "Letters", "TK", Vector2(-40, -26), Vector2(80, 52), 36, C.gold)


func _build_entry_pipe(decor: Node, pos: Vector2) -> void:
	var pipe := node(decor, "EntryPipe", pos)
	var body := rect(Rect2(-46, -60, 92, 390))
	part(pipe, "Tube", body, C.pipe, inter(body, rect(Rect2(-46, -60, 24, 390))), C.pipe_shadow)
	for y in [80, 210]:
		part(pipe, "Collar%d" % y, rrect(Rect2(-54, y, 108, 24), 5), C.pipe_light)
	var lip := rrect(Rect2(-58, 304, 116, 32), 6)
	part(pipe, "Lip", lip, C.pipe_light, inter(lip, rect(Rect2(-60, 322, 120, 20))), C.pipe)
	poly(pipe, "Mouth", ellipse(Vector2(0, 336), 44, 7), INK)


func _build_drain(decor: Node, drain_name: String, x: float) -> void:
	var drain := node(decor, drain_name, Vector2(x, 0))
	var body := rect(Rect2(-40, -60, 80, 300))
	part(drain, "Tube", body, C.pipe, inter(body, rect(Rect2(-40, -60, 20, 300))), C.pipe_shadow)
	part(drain, "Lip", rrect(Rect2(-50, 228, 100, 28), 6), C.pipe_light)
	var fall := Node2D.new()
	fall.name = "Waterfall"
	fall.position = Vector2(0, 250)
	fall.set_script(load("res://scripts/waterfall.gd"))
	drain.add_child(fall)
	fall.set("height", WATER_Y - 250.0)
	fall.set("width", 62.0)


func _build_exit_art(decor: Node, pos: Vector2) -> void:
	var art := node(decor, "ExitArt", pos)
	var wall := rect(Rect2(-140, -800, 300, 800))
	part(art, "Wall", wall, C.brick)
	var bricks := node(art, "Bricks")
	for row in 22:
		var offset := 0.0 if row % 2 == 0 else 36.0
		var bx := -136.0 + offset
		while bx < 150.0:
			if _rng.randf() < 0.45:
				poly(bricks, "Brick%d" % bricks.get_child_count(), rrect(Rect2(bx, -796 + row * 36, 64, 28), 4), C.brick_light)
			bx += 72.0
	var center := Vector2(0, -122)
	part(art, "Ring", circle(center, 120, 48), C.pipe, crescent(circle(center, 120, 48), Vector2(8, -8)), C.pipe_shadow)
	poly(art, "Tunnel", circle(center, 98, 48), Color("#2A2530"))
	poly(art, "LightOuter", circle(center + Vector2(10, 0), 82, 48), C.light)
	poly(art, "LightMid", circle(center + Vector2(14, 0), 58, 48), Color("#F7E7A8"))
	poly(art, "LightInner", circle(center + Vector2(18, 0), 34, 48), Color("#FFF5D0"))

	var sign := node(art, "Sign", Vector2(-270, 0))
	part(sign, "Post", rect(Rect2(-7, -130, 14, 130)), C.wood)
	part(sign, "Board", rrect(Rect2(-100, -200, 200, 70), 10), C.board)
	label(sign, "Text", "THIS WAY UP?", Vector2(-100, -200), Vector2(200, 70), 26, INK)
	part(sign, "Arrow", PackedVector2Array([Vector2(104, -180), Vector2(128, -165), Vector2(104, -150)]), C.board)


func _build_foreground(level: Node) -> void:
	var fg := _parallax(level, "Foreground", 1.3, 20)
	var ink := Color(INK, 0.94)
	var x := -100.0
	var i := 0
	while x < 4800.0:
		var group := node(fg, "Clump%d" % i, Vector2(x, 1090))
		poly(group, "Mound", ellipse(Vector2.ZERO, _rng.randf_range(110, 170), _rng.randf_range(50, 75)), ink)
		for s in _rng.randi_range(2, 4):
			var sx := _rng.randf_range(-70, 70)
			var h := _rng.randf_range(90, 170)
			poly(group, "Stem%d" % s, rect(Rect2(sx - 3, -h, 6, h)), ink)
			poly(group, "Head%d" % s, capsule(Vector2(sx, -h - 4), Vector2(sx, -h + 30), 7), ink)
		if i % 3 == 1:
			poly(group, "PipeBend", largest(Geometry2D.offset_polyline(PackedVector2Array([
				Vector2(120, 20), Vector2(120, -100), Vector2(240, -100)]), 22, Geometry2D.JOIN_ROUND, Geometry2D.END_BUTT)), ink)
		x += _rng.randf_range(380, 560)
		i += 1
