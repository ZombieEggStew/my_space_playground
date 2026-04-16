class_name StateIntercept
extends StateBase

# 切入状态：计算预测位置，快速截击
@export var intercept_dist := 150.0

func enter(_prev: StringName = &"") -> void:
    super.enter(_prev)
    print("AI: Entering Intercept mode")

func physics_update(delta: float) -> void:
    if player == null or ship == null: return
    
    # 计算预测位置 (简单预测：当前位置 + 速度 * 时间)
    var dist = ship.global_position.distance_to(player.global_position)
    var prediction_time = dist / parent_sm.max_speed
    var target_pos = player.global_position + (player.velocity * prediction_time)
    
    parent_sm.rotate_towards(target_pos, delta, 1.2) # 切入转向更快
    parent_sm.move_forward(parent_sm.max_speed, delta)
    
    # 状态切换逻辑
    if dist < 60.0:
        parent_sm.transition_to(&"chase")
    elif dist > 300.0:
        # 太远了继续切入
        pass
