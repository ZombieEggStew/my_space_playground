extends State
class_name StateIntercept

# 拦截状态：在玩家侧方时，计算射击预判点，并利用惯性掠过
@export var bullet_speed := 500.0

func enter(_prev: int = MoveSM.ORBIT) -> void:
    super.enter(_prev)

func physics_update(delta: float) -> void:
    if player == null or ship == null: return
    
    var pos_diff = player.global_position - ship.global_position
    var dist = pos_diff.length()
    
    # 简单的拦截预判计算：根据子弹速度 (500) 进行前置量计算
    var time_to_hit = dist / bullet_speed
    var lead_target_pos = player.global_position + (player.velocity * time_to_hit)
    
    # 1. 将机头瞄准预判点 (准备射击姿势)
    parent_sm.rotate_towards(lead_target_pos, delta)
    
    # 2. 设置保持高速，利用惯性掠过 (不减速)
    parent_sm.set_target_speed(parent_sm.max_speed * .8)
    

    # --- 逻辑切换 ---
    # 状态有效性检测：如果玩家不再处于侧方横穿状态，或者截击角变得太差，则返回 ORBIT
    var player_v_dir = player.velocity.normalized()
    var side_dot = (ship.global_position - player.global_position).normalized().dot(player_v_dir)
    if player.velocity.length() < 1.0 or abs(side_dot) > 0.8:
        parent_sm.transition_to(MoveSM.ORBIT)
        return

    # 如果将要掠过玩家或距离过近
    if dist < 100.0:
        parent_sm.transition_to(MoveSM.DISENGAGE)
        return
        
    var to_intercept_pos = (lead_target_pos - ship.global_position).normalized()
    var ai_forward = -ship.global_basis.z
    if ai_forward.dot(to_intercept_pos) < 0.2:
        parent_sm.transition_to(MoveSM.DISENGAGE)
