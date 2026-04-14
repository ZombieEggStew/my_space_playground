extends VisibleOnScreenNotifier3D
class_name AbleToBeLocked


@onready var target_node3d: = get_parent() as Node3D
var team_id : int = TeamID.TEAM_NEUTRAL

var distance_to_player := 0.0


func _ready() -> void:
	if target_node3d.has_method("get_team_id"):
		team_id = target_node3d.get_team_id()

	SignalBus.on_lockable_target_spawned.emit(self)
	

func get_team_id() -> int:
	return team_id
	

func _exit_tree() -> void:
	SignalBus.on_lockable_target_died.emit(self)
