extends Node2D

@export var circle_diameter := 16.0
@export var line_width := 2.0
@export var circle_color := Color(0.2, 1.0, 0.2, .5)

var distance_to_target := 0.0

func _ready() -> void:
	visible = false
	queue_redraw()


func _draw() -> void:
	var radius := get_radius_for_distance(distance_to_target)
	# print("drawing crosshair at distance: ", distance_to_target)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 32, circle_color, line_width, true)

# 根据采样数据进行曲线拟合或插值
# 100m -> 48px
# 200m -> 16px
# 600m -> 12px
func get_radius_for_distance(dist: float) -> float:
	if dist <= 100:
		return 48.0
	elif dist <= 200:
		# 在 100m 和 200m 之间线性插值 (48 -> 16)
		return remap(dist, 100, 200, 48, 16)
	elif dist <= 600:
		# 在 200m 和 600m 之间线性插值 (16 -> 12)
		return remap(dist, 200, 600, 16, 12)
	else:
		# 远于 600m 保持最小半径
		return 12.0

# y = -0.072 x + 55
func set_target_pos(aim_data : Dictionary) -> void:
	
	position = aim_data.get("screen_pos", Vector2.ZERO)
	distance_to_target = aim_data.get("distance", 0.0)
	visible = true
	queue_redraw()	

func reset() -> void:
	visible = false


