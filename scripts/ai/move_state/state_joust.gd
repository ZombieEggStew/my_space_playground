extends State
class_name StateJoust

# 对冲状态：正对着玩家俯冲
func enter(_prev: int = MoveSM.ORBIT) -> void:
	super.enter(_prev)

func physics_update(delta: float) -> void:
	if player == null or ship == null: return
	
	var dist = ship.global_position.distance_to(player.global_position)
	var prediction_time = dist / parent_sm.max_speed
	var target_pos = player.global_position + (player.velocity * prediction_time)
	
	# 向着对冲点转向
	parent_sm.rotate_towards(target_pos, delta)
	# 全速对冲
	parent_sm.set_target_speed(parent_sm.max_speed)
	
	# 状态切换
	if dist < 100.0:
		parent_sm.transition_to(MoveSM.DISENGAGE)
	
	var ai_forward = -ship.global_basis.z
	var player_v_dir = player.velocity.normalized()
	if ai_forward.dot(player_v_dir) > -0.8:
		parent_sm.transition_to(MoveSM.ORBIT)
