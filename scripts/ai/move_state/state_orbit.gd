extends State
class_name StateOrbit

@export var chase_speed := 25.0
@export var attack_range := 600.0
@export var min_dist := 40.0

func enter(_prev: int = MoveSM.CHASE) -> void:
	super.enter(_prev)


func physics_update(delta: float) -> void:
	if player == null or ship == null: return
	
	# 获取玩家的后方位置 (玩家 basis.z 指向其后方)

	var player_back_pos := player.global_position + player.global_basis.z * 50.0 # 目标点在玩家后方 50 米
	
	var to_player := player.global_position - ship.global_position
	var dist := to_player.length()

	# 环绕/切入逻辑：
	# 1. 如果离得远，直接切向玩家后方
	# 2. 如果接近并已经试图咬尾，计算一个环绕向量
	var target_pos: Vector3
	
	if dist > 600.0:
		# 远距离：直接飞向玩家后方的预判点
		target_pos = player_back_pos
	else:
		# 近距离：试图绕到六点钟。
		# 计算一个侧向偏移，防止直勾勾撞上去，形成螺旋靠近的效果
		var side_dir = to_player.cross(Vector3.UP).normalized()
		var orbit_offset = side_dir * (dist * 0.5) # 距离越近偏移越小
		target_pos = player_back_pos + orbit_offset

	# 执行转向
	parent_sm.rotate_towards(target_pos, delta)

	# 环绕状态维持基础速度
	parent_sm.set_target_speed(parent_sm.max_speed * 0.8)
	
	# 逻辑切换：判断是否处于玩家 6 点钟方向
	# 计算从玩家指向 AI 的向量
	var from_player = (ship.global_position - player.global_position).normalized()
	# 玩家的后方是 player.global_basis.z
	var alignment = from_player.dot(player.global_basis.z)
	
	# 如果在玩家后方 45 度锥角内 (dot > 0.7)，且距离在 600m 内，进入追逐(咬尾)模式
	if alignment > 0.7 and dist < 600.0:
		parent_sm.transition_to(MoveSM.CHASE)

