extends VisibleOnScreenNotifier3D
class_name AbleToBeLocked

signal on_locked(enabled: bool)


@onready var target_node3d: = get_parent() as Node3D
var team_id : int = TeamID.NEUTRAL

var distance_to_player := 0.0

var is_locked := false

func set_locked(locked: bool) -> void:
	is_locked = locked
	on_locked.emit(is_locked)

func _ready() -> void:
	if target_node3d.has_method("get_team_id"):
		team_id = target_node3d.get_team_id()

	# 使用 call_deferred 确保父节点的 _ready 已经执行完毕
	call_deferred("_register_to_signal_bus")

func _register_to_signal_bus() -> void:
	SignalBus.on_lockable_target_spawned.emit(self)

func get_team_id() -> int:
	return team_id
	

func _exit_tree() -> void:
	SignalBus.on_lockable_target_died.emit(self)
