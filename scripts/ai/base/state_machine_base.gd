extends Node
class_name StateMachine

# 共享变量，供各个状态访问
var target: CharacterBody3D = null
var controlled_ship: CharacterBody3D = null

var initial_state: int = 0

var current_state: State = null

func setup(_target:PlayerShip , _controlled_ship :CharacterBody3D) -> void:
    target = _target
    controlled_ship = _controlled_ship
    for state in get_children():
        state.setup(_target, _controlled_ship)

func transition_to(new_state: int) -> void:
    if current_state:
        current_state.exit(new_state)
    
    current_state = get_child(new_state) as State
    if current_state:
        current_state.enter()


func physics_process(delta: float) -> void:
    if target == null:
        target = GameManager.get_current_player()
        return
    if current_state and current_state.has_method("physics_update"):
        current_state.physics_update(delta)