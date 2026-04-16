extends StateBase
class_name StateAttack


@export var fire_angle := 0.95
@export var stop_attack_dist := 150.0

func enter(_prev: StringName = &"") -> void:
    super.enter(_prev)
    # 可以在这里开启武器系统

func physics_update(delta: float) -> void:
    if player == null or ship == null: 
        parent_sm.transition_to(&"chase")
        return
    
    var to_player = player.global_position - ship.global_position
    var dist = to_player.length()
    var forward = -ship.global_basis.z
    var dot = forward.dot(to_player.normalized())
    
    # 攻击时微调指向（前导预测）
    var prediction_time = dist / 50.0 # 假设子弹速度
    var target_pos = player.global_position + player.velocity * prediction_time
    parent_sm.rotate_towards(target_pos, delta, 1.0)
    parent_sm.move_forward(parent_sm.max_speed * 0.6, delta) # 攻击时略微减速以增加窗口期
    
    # 执行射击逻辑 (假设 ship 有 shoot 方法)
    if dot > fire_angle:
        if ship.has_method("shoot"):
            ship.shoot()
            
    # 切换条件
    if dot < 0.7 or dist < 30.0:
        parent_sm.transition_to(&"evade")
    elif dist > stop_attack_dist:
        parent_sm.transition_to(&"chase")
