extends Node
class_name AIBrain

var target: CharacterBody3D = null
var controlled_ship: CharacterBody3D = null

var combat_sm: CombatSM = null
var move_sm: MoveSM = null

var is_enable := false

func _ready():
    target = GameManager.get_current_player()
    controlled_ship = get_parent() as CharacterBody3D 

    for sm in get_children():
        if sm is CombatSM:
            combat_sm = sm as CombatSM
        elif sm is MoveSM:
            move_sm = sm as MoveSM
            
        sm.setup(target, controlled_ship)


func _physics_process(delta: float) -> void:
    if not is_enable:
        return
    combat_sm.physics_process(delta)
    move_sm.physics_process(delta)