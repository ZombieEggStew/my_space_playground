extends Node2D

@export var half_size := 32.0
@export var line_width := 2.0
@export var line_color := Color(0.2, 1.0, 0.2, 0.95)


var _line_h: Line2D
var _line_v: Line2D
var _indicator_line: Line2D


func _ready() -> void:
	_line_h = _create_line()
	_line_v = _create_line()
	_update_lines()
	reset()


func _create_line() -> Line2D:
	var line := Line2D.new()
	line.width = line_width
	line.default_color = line_color
	line.antialiased = true
	line.z_index = 10
	line.points = PackedVector2Array([Vector2.ZERO, Vector2.ZERO])
	add_child(line)
	return line



func _update_lines() -> void:
	if _line_h == null or _line_v == null:
		return
	_line_h.points = PackedVector2Array([
		Vector2(-half_size, 0.0),
		Vector2(half_size, 0.0)
	])
	_line_v.points = PackedVector2Array([
		Vector2(0.0, -half_size),
		Vector2(0.0, half_size)
	])


func set_target_pos(target_pos: Vector2) -> void:
	position = target_pos
	visible = true


func update_from_mouse(mouse_pos: Vector2, dead_zone_px: float, dead_zone_enabled: bool = true) -> void:
	if not dead_zone_enabled:
		set_target_pos(mouse_pos)
		if _indicator_line:
			_indicator_line.visible = false
		return

	var viewport_size := get_viewport().get_visible_rect().size
	var center := viewport_size * 0.5
	var to_mouse := mouse_pos - center
	var radius := max(dead_zone_px, 0.0) as float

	if to_mouse.length() <= radius:
		set_target_pos(mouse_pos)
		if _indicator_line:
			_indicator_line.visible = false
		return

	var dir := to_mouse.normalized()
	var clamped_pos := center + dir * radius
	set_target_pos(clamped_pos)

	if _indicator_line:
		_indicator_line.visible = true
		_indicator_line.points = PackedVector2Array([
			Vector2.ZERO,
			mouse_pos - clamped_pos
		])


func reset() -> void:
	position = get_viewport().get_visible_rect().size / 2.0
	visible = true
	if _indicator_line:
		_indicator_line.visible = false
