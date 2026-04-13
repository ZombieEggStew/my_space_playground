extends Node2D
class_name Crosshair3


@export var half_size := 32.0
@export var line_width := 2.0
@export var line_color := Color(0.2, 1.0, 0.2, 0.95)


var _line_h: Line2D
var _line_v: Line2D

var aim_dead_zone_px := 64.0

func _ready() -> void:
	_line_h = _create_line()
	_line_v = _create_line()
	_update_lines()
	reset()

func setup(dead_zone:float) -> void:
	aim_dead_zone_px = dead_zone

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


func update_from_mouse(mouse_pos: Vector2) -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var center := viewport_size * 0.5
	var to_mouse := mouse_pos - center
	var radius := max(aim_dead_zone_px, 0.0) as float

	if to_mouse.length() <= radius:
		set_target_pos(mouse_pos)


	var dir := to_mouse.normalized()
	var clamped_pos := center + dir * radius
	set_target_pos(clamped_pos)

func reset() -> void:
	position = get_viewport().get_visible_rect().size / 2.0
	visible = true
