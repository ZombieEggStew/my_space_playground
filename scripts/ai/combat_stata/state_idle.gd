extends State
class_name StateIdle

func physics_update(_delta: float) -> void:
	if player == null or ship == null: 
		return
	
	# 检测玩家是否在机头方向一定范围内 (例如 30 度角内，且距离 800m 内)
	var to_player = (player.global_position - ship.global_position).normalized()
	var forward = -ship.global_basis.z
	var dist = ship.global_position.distance_to(player.global_position)
	
	# dot > 0.86 约为 30 度
	if forward.dot(to_player) > 0.86 and dist < 800.0:
		parent_sm.transition_to(CombatSM.ATTACK)