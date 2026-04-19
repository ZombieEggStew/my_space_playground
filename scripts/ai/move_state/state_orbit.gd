extends State
class_name StateOrbit

@export var chase_speed := 25.0
@export var attack_range := 600.0
@export var min_dist := 40.0

func enter(_prev: int = MoveSM.CHASE) -> void:
	super.enter(_prev)


func physics_update(delta: float) -> void:
	if player == null or ship == null: return
	
	# 获取玩家的攻击追踪点 (玩家速度的反方向)
	var player_velocity := Vector3.ZERO
	if player.get("velocity") != null:
		player_velocity = player.velocity
	
	var back_dir := player.global_basis.z
	if player_velocity.length() > 0.1:
		back_dir = -player_velocity.normalized()

	var player_back_pos := player.global_position + back_dir * 10.0 # 目标点在玩家运动轨迹后方 50 米
	
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
	
	# 逻辑切换：判断是否处于玩家速度轨迹的后方区域
	# 计算从玩家指向 AI 的向量
	var from_player = (ship.global_position - player.global_position).normalized()
	
	# 如果在目标点方向的 45 度锥角内 (dot > 0.7)，且距离在 600m 内，进入追逐(咬尾)模式
	var alignment = from_player.dot(back_dir)
	
	if alignment > 0.7 and dist < 600.0:
		parent_sm.transition_to(MoveSM.CHASE)

	# 逻辑切换：判断是否处于对冲状态 (JOUST) 或 侧方拦截状态 (INTERCEPT)
	var ai_forward = -ship.global_basis.z
	var player_v_dir = player.velocity.normalized()
	var to_player_dir = (to_player).normalized()
	
	if player.velocity.length() > 1.0 and dist < 800.0:
		# 1. 对冲判断 (JOUST): AI 面向与玩家速度反向对齐
		if ai_forward.dot(player_v_dir) < -0.8:
			parent_sm.transition_to(MoveSM.JOUST)
			return

		# 2. 侧方拦截判断 (INTERCEPT): AI 在玩家侧向，且玩家有一定的速度
		# 如果 AI 的朝向和到玩家的向量夹角较大，且玩家正在横向通过
		var side_dot = to_player_dir.dot(player_v_dir) # 玩家是否在横向运动
		if abs(side_dot) < 0.5: # 玩家相对于 AI 是侧向运动
			parent_sm.transition_to(MoveSM.INTERCEPT)
			return

