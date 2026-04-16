class_name CombatStateMachine
extends StateMachine

# 共享变量，供各个状态访问
var target: CharacterBody3D = null
var turn_speed: float = 2.0
var max_speed: float = 30.0
var acceleration: float = 15.0

func _ready() -> void:
    # 确保在初始化时有玩家引用
    if GameManager.player_instance:
        target = GameManager.player_instance
    
    # 初始化状态列表（假设子节点已在编辑器中添加或在此动态添加）
    # 设置初始状态为追逐
    initial_state = &"chase"
    super._ready()

func _physics_process(delta: float) -> void:
    if target == null:
        target = GameManager.player_instance
        return
    
    if current_state and current_state.has_method("physics_update"):
        current_state.physics_update(delta)

# 辅助方法：处理基础飞行转向
func rotate_towards(target_pos: Vector3, delta: float, speed_mult: float = 1.0) -> void:
    if controlled_ship == null: return
    
    var to_target = target_pos - controlled_ship.global_position
    if to_target.is_zero_approx(): return
    
    var look_basis = Basis.looking_at(to_target, Vector3.UP)
    controlled_ship.global_basis = controlled_ship.global_basis.slerp(look_basis, turn_speed * speed_mult * delta)

# 辅助方法：前进移动
func move_forward(speed: float, delta: float) -> void:
    if controlled_ship == null: return
    var forward = -controlled_ship.global_basis.z
    controlled_ship.velocity = controlled_ship.velocity.move_toward(forward * speed, acceleration * delta)
    controlled_ship.move_and_slide()
