class_name StateOrbit
extends StateBase

# 盘旋状态：绕着目标侧向飞行
@export var orbit_radius := 50.0
@export var orbit_side := 1.0 # 1 or -1

func enter(_prev: StringName = &"") -> void:
    super.enter(_prev)
    orbit_side = 1.0 if randf() > 0.5 else -1.0

func physics_update(delta: float) -> void:
    if player == null: return
    
    var to_player = player.global_position - ship.global_position
    var dist = to_player.length()
    
    # 计算切向向量
    var up = Vector3.UP
    var tangent = to_player.cross(up).normalized() * orbit_side
    
    # 结合向心和切向运动
    var desired_dir = (tangent + to_player.normalized() * (dist - orbit_radius) * 0.05).normalized()
    var target_pos = ship.global_position + desired_dir * 10.0
    
    parent_sm.rotate_towards(target_pos, delta, 0.8)
    parent_sm.move_forward(parent_sm.max_speed * 0.7, delta)
    
    # 状态切换：如果玩家拉开距离，重新追逐
    if dist > orbit_radius * 2.0:
        parent_sm.transition_to(&"chase")
    # 攻击机会
    elif ship.global_transform.basis.z.dot(-to_player.normalized()) > 0.8:
        # 如果大致对着玩家，尝试切到攻击
        pass
