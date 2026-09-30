extends CanvasLayer

const INK := Color("#1E1A22")
const GOLD := Color("#F2A81C")
const CREAM := Color("#FFF5D0")

var _hint: Label
var _counter: Label
var _end_panel: PanelContainer
var _end_count: Label


func _ready() -> void:
	_hint = _make_label("←  →  move        Space  jump", 34, CREAM)
	_hint.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_hint.position.y -= 70
	_hint.grow_horizontal = Control.GROW_DIRECTION_BOTH
	add_child(_hint)
	var fade := create_tween()
	fade.tween_interval(7.0)
	fade.tween_property(_hint, "modulate:a", 0.0, 1.0)

	_counter = _make_label("", 36, GOLD)
	_counter.position = Vector2(40, 30)
	_counter.visible = false
	add_child(_counter)

	_build_end_panel()
	Game.plunger_collected.connect(_on_plunger_collected)
	Game.level_finished.connect(_on_level_finished)


func _unhandled_input(event: InputEvent) -> void:
	if _end_panel.visible and event.is_action_pressed("jump"):
		get_tree().current_scene.restart()


func _on_plunger_collected(count: int) -> void:
	_counter.text = "Golden plungers  %d / %d" % [count, Game.PLUNGERS_TOTAL]
	_counter.visible = true
	_counter.pivot_offset = _counter.size * 0.5
	_counter.scale = Vector2(1.4, 1.4)
	create_tween().tween_property(_counter, "scale", Vector2.ONE, 0.3)


func _on_level_finished() -> void:
	_end_count.text = "Golden plungers  %d / %d" % [Game.plungers, Game.PLUNGERS_TOTAL]
	await get_tree().create_timer(1.3).timeout
	_end_panel.visible = true
	_end_panel.modulate.a = 0.0
	create_tween().tween_property(_end_panel, "modulate:a", 1.0, 0.4)


func _build_end_panel() -> void:
	_end_panel = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#3F3B45")
	style.border_color = INK
	style.set_border_width_all(8)
	style.set_corner_radius_all(28)
	style.set_content_margin_all(48)
	_end_panel.add_theme_stylebox_override("panel", style)
	_end_panel.visible = false

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 24)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	_end_panel.add_child(box)
	box.add_child(_make_label("You escaped the first pipe!", 64, CREAM))
	_end_count = _make_label("", 44, GOLD)
	box.add_child(_end_count)
	box.add_child(_make_label("Press Jump to play again", 34, CREAM))

	add_child(_end_panel)
	_end_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_end_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_end_panel.grow_vertical = Control.GROW_DIRECTION_BOTH


func _make_label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var settings := LabelSettings.new()
	settings.font_size = size
	settings.font_color = color
	settings.outline_size = 12
	settings.outline_color = INK
	label.label_settings = settings
	return label
