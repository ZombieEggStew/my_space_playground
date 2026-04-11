extends Node
class_name AbleToBeLocked

@export var team_id := 2
@export var piovot_offset := Vector3.ZERO

var target_node3d: Node3D

var is_visible := false

var world_pos: Vector3

var distance_to_player := 0.0


func _ready() -> void:
    target_node3d = get_parent()
    LockManager.register_target(self)
    SignalBus.on_lockable_target_spawned.emit(self)
        

func get_team_id() -> int:
    return team_id
    
func get_pivot_offset() -> Vector3:
    return piovot_offset

func _exit_tree() -> void:
    LockManager.unregister_target(self)