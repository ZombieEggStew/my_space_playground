class_name StateEvade
extends State

# 规避状态：被射击后的紧急滚转与急转机动
@export var evade_duration := 1.2
@export var turn_intensity := 2.5

var timer := 0.0
var roll_speed := 10.0
var evade_target_pos := Vector3.ZERO

func enter(_prev: int = MoveSM.CHASE) -> void:
    super.enter(_prev)
    timer = evade_duration
    
    # 随机选择一个急转方向 (左/右/上/下)
    var random_side = ship.global_basis.x * randf_range(-1.0, 1.0)
    var random_up = ship.global_basis.y * randf_range(-0.5, 1.5) # 倾向于向上拉升
    var evade_vector = (random_side + random_up).normalized()
    
    # 目标点设在侧前方，强制进行急转弯
    evade_target_pos = ship.global_position + (-ship.global_basis.z * 20.0) + (evade_vector * 40.0)

func physics_update(delta: float) -> void:
    if ship == null: return
    
    timer -= delta
    
    # 1. 紧急滚转机动 (视觉与物理规避结合)
    ship.rotate_object_local(Vector3.FORWARD, roll_speed * delta)
    
    # 2. 急转弯转向
    parent_sm.rotate_towards(evade_target_pos, delta, turn_intensity)
    
    # 3. 维持高速逃离模式
    parent_sm.set_target_speed(parent_sm.max_speed * 1.3)
    
    # --- 逻辑切换 ---
    if timer <= 0:
        parent_sm.transition_to(MoveSM.ORBIT)
