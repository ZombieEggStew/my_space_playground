extends Node2D

var aim_dead_zone_px := 64.0
var width := 1.0

func setup(aim_dead_zone:float) -> void:
	aim_dead_zone_px = aim_dead_zone

func update_indicator(aim_dead_zone:float) -> void:
	aim_dead_zone_px = aim_dead_zone
	queue_redraw()

func _ready() -> void:
	position = get_viewport().get_visible_rect().size / 2.0
	queue_redraw()

func _draw() -> void:
	draw_arc(Vector2.ZERO, aim_dead_zone_px, 0, TAU, 64, Color.WHITE, 1.0, true)
