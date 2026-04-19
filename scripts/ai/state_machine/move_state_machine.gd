extends StateMachine
class_name MoveSM

enum {
    ORBIT,
    CHASE,
    INTERCEPT,
    EVADE,
    JOUST,
    DISENGAGE
}


var turn_speed: float = 2.0
var target_speed: float = 80.0
var max_speed: float = 100.0
var acceleration: float = 10.0


func _ready() -> void:
    initial_state = MoveSM.ORBIT
    transition_to(initial_state)

func physics_process(delta: float) -> void:
    super.physics_process(delta)

    
    move_forward(delta)

# 辅助方法：由状态调用来设置期望速度
func set_target_speed(speed: float) -> void:
    target_speed = speed


# 辅助方法：处理基础飞行转向
func rotate_towards(target_pos: Vector3, delta: float, speed_mult: float = 4.0) -> void:
    if controlled_ship == null: return
    
    var to_target = target_pos - controlled_ship.global_position
    if to_target.is_zero_approx(): return
    
    var look_basis = Basis.looking_at(to_target, Vector3.UP)
    controlled_ship.global_basis = controlled_ship.global_basis.slerp(look_basis, turn_speed * speed_mult * delta)

# 辅助方法：前进移动
func move_forward(delta: float) -> void:
    if controlled_ship == null: return
    var forward = -controlled_ship.global_basis.z
    controlled_ship.velocity = controlled_ship.velocity.move_toward(forward * target_speed, acceleration * delta)
    controlled_ship.move_and_slide()
