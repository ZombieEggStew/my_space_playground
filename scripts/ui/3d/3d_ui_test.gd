extends Node

var player_ship: PlayerShip
var move : MoveControllerModule
var cam_pivot : Node3D
var is_engine_on = false
@export var test_mesh : MeshInstance3D
@export var test : MeshInstance3D
func _process(_delta):
	if not player_ship:
		player_ship = GameManager.get_current_player()
		
		if not move and player_ship.modules_manager:
			move = player_ship.modules_manager.get_move_module()
			cam_pivot = player_ship.modules_manager.get_camera_module().get_cam_pivot()


	is_engine_on = move.is_engine_on
	test.visible = is_engine_on
	var player_velocity = player_ship.velocity

	if test_mesh:
		# 我们的目标是计算 velocity 相对于相机视角下的“偏差”
		# 1. 获取从“世界坐标系”转换到“相机的本地坐标系”的基矩阵
		# 如果没有 cam_pivot，回退使用飞船的基矩阵
		var view_basis = cam_pivot.global_transform.basis
		var local_velocity = view_basis.inverse() * player_velocity
		
		# 2. 如果速度极小，默认朝向前方 (0, 0, -1)
		if local_velocity.length() < 0.1:
			test_mesh.rotation = Vector3.ZERO
		else:
			# 3. 让 test_mesh 在当前节点空间内指向相对于相机视角的本地速度
			var mesh_target = local_velocity.normalized()
			# 使用 look_at 指向目标位置，相对于其父节点（或者是自身的 position）
			test_mesh.look_at(test_mesh.position + mesh_target, view_basis.y)
			# 消除 Z 轴旋转（Roll）
			test_mesh.rotation.z = 0

	# print(player_face_direction)
	
