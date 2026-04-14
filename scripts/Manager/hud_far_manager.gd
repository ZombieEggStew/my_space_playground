extends Node
class_name HUDFarManager

var player:PlayerShip
var cam:Camera3D
# 增加机头指示器相关变量
var nose_pos_2d := Vector2.ZERO
var is_on_screen := true
var mouse_pos := Vector2.ZERO 
func _ready():
	SignalBus.on_player_registered.connect(_on_player_registered)

func _on_player_registered(_player:PlayerShip):
	player = _player
	cam = player.get_main_camera()

func _process(_delta):
	mouse_pos = get_viewport().get_mouse_position()

	# 1. 计算机头正前方的 3D 点
	# 如果你的模型初始旋转了 180 度，说明模型的 Z 正方向才是真正的机头方向。
	# 我们使用 global_transform.basis.z 产生的点（不带负号）
	var forward_point_3d = player.global_position + player.global_transform.basis.z * 1000.0
	
	# 2. 检查是否在相机后方
	is_on_screen = not cam.is_position_behind(forward_point_3d)
	
	if is_on_screen:
		
		# 3. 投影到屏幕 2D 坐标
		nose_pos_2d = cam.unproject_position(forward_point_3d)