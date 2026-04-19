class_name StateChase
extends State

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


	# 1. 始终对准玩家 6 点钟方向
	parent_sm.rotate_towards(player_back_pos, delta)

	# 2. 调整速度保持 200m-500m 距离
	var target_speed :float= parent_sm.max_speed
	
	# 获取玩家当前速度作为参考（假设 player 有 velocity 属性）
	var p_speed := player.velocity.length()
	
	if dist < 100.0:
		# 太近了，减速或匹配玩家速度
		target_speed = p_speed * 0.8
	elif dist > 200.0:
		# 太远了，全速冲刺
		target_speed = parent_sm.max_speed * 1.2
	else:
		# 在理想区间内，匹配速度并微调
		target_speed = p_speed
	
	# 只设置目标速度，不再调用 move_forward
	parent_sm.set_target_speed(target_speed)

	# 逻辑切换：如果脱离了 6 点钟方向，回到环绕模式
	var from_player = (ship.global_position - player.global_position).normalized()
	var alignment = from_player.dot(back_dir)
	if alignment < 0.5: # 角度变大，咬丢了
		parent_sm.transition_to(MoveSM.ORBIT)
