extends Node
class_name UIFlowEffect



# 获取屏幕中心点
@onready var viewport_size = get_viewport().get_visible_rect().size
@onready var screen_center = viewport_size / 2.0


var groups: Array[Control] = []

# UI 浮动强度
var float_intensity = 0.05


func setup(_group: Control) -> void:
	if _group not in groups:
		groups.append(_group)

func _process(delta):
	_update_ui_float_effect(delta)

func _update_ui_float_effect(delta: float) -> void:
	# 这里可以根据需要调整插值速度和强度
	var mouse_pos = get_viewport().get_mouse_position()
	var mouse_offset = mouse_pos - screen_center
	
	# 目标偏移量（反向偏移增加深度感）
	var target_offset = mouse_offset * float_intensity
	
	# 平滑插值 (Lerp) 增加顺滑感
	for group in groups:
		group.position = group.position.lerp(target_offset, delta * 5.0)
