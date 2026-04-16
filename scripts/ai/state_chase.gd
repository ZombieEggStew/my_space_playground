class_name StateChase
extends StateBase

@export var chase_speed := 25.0
@export var attack_range := 100.0
@export var min_dist := 40.0

func enter(_prev: StringName = &"") -> void:
    super.enter(_prev)

func physics_update(delta: float) -> void:
    if player == null or ship == null: return
    
    var to_player = player.global_position - ship.global_position
    var dist = to_player.length()
    
    # 基础追踪
    parent_sm.rotate_towards(player.global_position, delta)
    parent_sm.move_forward(chase_speed, delta)
    
    # 逻辑切换
    if dist > 250.0:
        parent_sm.transition_to(&"intercept")
    elif dist < min_dist:
        parent_sm.transition_to(&"evade")
    elif dist < attack_range:
        var forward = -ship.global_basis.z
        if forward.dot(to_player.normalized()) > 0.85:
            parent_sm.transition_to(&"attack")
        else:
            parent_sm.transition_to(&"orbit")
