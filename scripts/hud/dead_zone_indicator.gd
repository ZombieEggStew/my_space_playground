extends HUDFarBase

var aim_dead_zone_px := 64.0
var width := 1.0


func setup(aim_dead_zone:float) -> void:
	aim_dead_zone_px = aim_dead_zone

func _process(_delta: float) -> void:
	queue_redraw()

func update_indicator(aim_dead_zone:float) -> void:
	aim_dead_zone_px = aim_dead_zone
	queue_redraw()

func _ready() -> void:
	queue_redraw()

func _draw() -> void:

	# 绘制机头指示器
	if hud.is_on_screen:

		draw_arc(Vector2.ZERO, aim_dead_zone_px, 0, TAU, 64, Color.WHITE, width, true)
