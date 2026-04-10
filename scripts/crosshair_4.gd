extends Node2D

@export var circle_diameter := 32.0
@export var line_width := 2.0
@export var circle_color := Color(0.2, 1.0, 0.2, 1.0)


func _ready() -> void:
	_update_center_position()
	visible = false
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_SIZE_CHANGED:
		_update_center_position()
		queue_redraw()


func _draw() -> void:
	var radius := circle_diameter * 0.5
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 96, circle_color, line_width, true)


func set_target_pos(target_pos: Vector2) -> void:
	position = target_pos
	visible = true


func reset() -> void:
	visible = false
	_update_center_position()


func _update_center_position() -> void:
	position = get_viewport().get_visible_rect().size * 0.5
