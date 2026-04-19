extends Node

var player_ship: PlayerShip
var move : MoveControllerModule

var is_engine_on = false
@export var test_mesh : MeshInstance3D
@export var test : MeshInstance3D
func _process(_delta):
	if not player_ship:
		player_ship = GameManager.get_current_player()
		if not move and player_ship.modules_manager and player_ship.modules_manager.get_move_module():
			move = player_ship.modules_manager.get_move_module()

	is_engine_on = move.is_engine_on
	test.visible = is_engine_on
	var player_velocity = player_ship.velocity

	if test_mesh:
		# 我们的目标是计算 velocity 相对于飞船朝向的“偏差”
		# 1. 获取从“世界坐标系”转换到“飞船本地坐标系”的四元数（或基矩阵）
		# 飞船的 global_transform.basis 描述了从本地到世界的变换
		# 我们使用它的逆 (inverse) 即可将世界向量转为本地向量
		var local_velocity = player_ship.global_transform.basis.inverse() * player_velocity
		
		# 2. 如果速度极小，默认朝向前方 (0, 0, -1)
		if local_velocity.length() < 0.1:
			test_mesh.rotation = Vector3.ZERO
		else:
			# 3. 让 test_mesh 在本地坐标系下指向 local_velocity
			# 假设 test_mesh 的初始朝向也是 Vector3.FORWARD (0, 0, -1)
			# 我们直接使用它的 look_at 指向本地速度
			var mesh_target = local_velocity.normalized()
			# 在本地空间内使用 look_at (相对于父节点)
			test_mesh.look_at(test_mesh.position + mesh_target, Vector3.UP)

	# print(player_face_direction)
	
