extends Module
class_name RadarModule

signal on_target_found(target: AbleToBeLocked)

var targets : Array[AbleToBeLocked] = []

func _enter_tree() -> void:
	SignalBus.on_lockable_target_spawned.connect(_on_target_found)
	SignalBus.on_lockable_target_died.connect(_on_target_died)

# 处理重复
func _on_target_found(target: AbleToBeLocked) -> void:
	print("Radar found target: %s" % target.name)
	on_target_found.emit(target)
	targets.append(target)

func get_targets_found() -> Array[AbleToBeLocked]:
	return targets

func _on_target_died(target: AbleToBeLocked) -> void:
	if target in targets:
		targets.erase(target)
