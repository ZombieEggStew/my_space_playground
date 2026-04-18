extends StateMachine
class_name CombatSM
enum {
    IDLE,
    ATTACK,
}

func _ready() -> void:
    
    # 初始化状态列表（假设子节点已在编辑器中添加或在此动态添加）
    # 设置初始状态为追逐
    initial_state = CombatSM.IDLE

    transition_to(initial_state)