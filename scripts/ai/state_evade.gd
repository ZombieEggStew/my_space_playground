class_name StateEvade
extends StateBase

# 规避状态：远离玩家或进行不规则机动
var evade_timer := 0.0
var evade_direction := Vector3.ZERO

func enter(_prev: StringName = &"") -> void:
    super.enter(_prev)
    evade_timer = randf_range(1.5, 3.0)
    # 随机选择一个躲避方向（侧向或上方）
    var side = ship.global_basis.x * (1 if randf() > 0.5 else -1)
    var up = ship.global_basis.y * (1 if randf() > 0.5 else -1)
    evade_direction = (side + up + ship.global_basis.z).normalized() # 混合后方和侧向

func physics_update(delta: float) -> void:
    evade_timer -= delta
    
    # 转向躲避方向
    var target_pos = ship.global_position + evade_direction * 50.0
    parent_sm.rotate_towards(target_pos, delta, 1.5)
    parent_sm.move_forward(parent_sm.max_speed * 1.2, delta) # 加速逃离
    
    if evade_timer <= 0:
        parent_sm.transition_to(&"chase")
