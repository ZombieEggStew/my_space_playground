extends Node
class_name UIBoostShakeEffect

var shake_intensity := 2.0
var shake_speed := 20.0
var groups: Array[Control] = []

func setup(group: Control) -> void:
	if group not in groups:
		groups.append(group)

func _process(_delta: float) -> void:
	_update_shake(_delta)

func _update_shake(_delta: float) -> void:
	var is_boosting: bool = get_parent().is_boosting if "is_boosting" in get_parent() else false
	
	for group in groups:
		var target_offset := Vector2.ZERO
		if is_boosting:
			target_offset = Vector2(
				randf_range(-shake_intensity, shake_intensity),
				randf_range(-shake_intensity, shake_intensity)
			)
		
		# # 平滑插值应用偏移
		# group.position = group.position.lerp(target_offset, _delta * shake_speed)
		group.position += target_offset
