extends Node2D

var aim_dead_zone_px := 64.0
var width := 1.0

func _ready() -> void:
	aim_dead_zone_px = get_parent().get_parent().aim_dead_zone_px
	position = get_viewport().get_visible_rect().size / 2.0
	queue_redraw()

func _draw() -> void:
	draw_arc(Vector2.ZERO, aim_dead_zone_px, 0, TAU, 64, Color.WHITE, 1.0, true)
