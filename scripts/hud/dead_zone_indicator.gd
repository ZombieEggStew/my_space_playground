extends Node2D

var aim_dead_zone_px := 64.0
var width := 1.0

# 增加机头指示器相关变量
var _nose_pos_2d := Vector2.ZERO
var _is_on_screen := true

func setup(aim_dead_zone:float) -> void:
	aim_dead_zone_px = aim_dead_zone

func _process(_delta: float) -> void:
	var player = GameManager.get_current_player()
	if not player:
		return
		
	var cam = GameManager.get_current_player().get_main_camera()
	if not cam:
		return

	# 1. 计算机头正前方的 3D 点
	# 如果你的模型初始旋转了 180 度，说明模型的 Z 正方向才是真正的机头方向。
	# 我们使用 global_transform.basis.z 产生的点（不带负号）
	var forward_point_3d = player.global_position + player.global_transform.basis.z * 1000.0
	
	# 2. 检查是否在相机后方
	_is_on_screen = not cam.is_position_behind(forward_point_3d)
	
	if _is_on_screen:
		# 3. 投影到屏幕 2D 坐标
		_nose_pos_2d = cam.unproject_position(forward_point_3d)

		
	queue_redraw()

func is_on_screen() -> bool:
	return _is_on_screen

func get_nose_screen_pos() -> Vector2:
	return _nose_pos_2d

func update_indicator(aim_dead_zone:float) -> void:
	aim_dead_zone_px = aim_dead_zone
	queue_redraw()

func _ready() -> void:
	queue_redraw()

func _draw() -> void:
	# # 绘制原本的死区圆圈
	# draw_arc(Vector2.ZERO, aim_dead_zone_px, 0, TAU, 64, Color.WHITE, width, true)
	
	# 绘制机头指示器
	if _is_on_screen:
		var draw_pos = _nose_pos_2d - position
		var indicator_color = Color.CYAN
		indicator_color.a = 0.7

		draw_arc(draw_pos, aim_dead_zone_px, 0, TAU, 64, Color.WHITE, width, true)
