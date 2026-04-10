extends Node
class_name AbleToBeLocked

@export var team_id := 2
@export var piovot_offset := Vector3.ZERO

var target_node3d: Node3D

var is_visible := false

var crosshair_1: Node

var world_pos: Vector3

var screen_pos: Vector2

var distance_to_player := 0.0


func _ready() -> void:
    target_node3d = get_parent()
    crosshair_1 = Global.crosshair_1.instantiate()
    SignalBus.on_lockable_target_init.emit(crosshair_1)

func _process(_delta: float) -> void:
    if is_visible:
        crosshair_1.update_from_target(screen_pos, distance_to_player)
    else:
        crosshair_1.set_active(false)
        

func get_team_id() -> int:
    return team_id
    
func get_pivot_offset() -> Vector3:
    return piovot_offset

func _enter_tree() -> void:
    LockManager.register_target(self)

func _exit_tree() -> void:
    LockManager.unregister_target(self)