extends Node
class_name UIFlowEffect


# 获取屏幕中心点
@onready var viewport_size := get_viewport().get_visible_rect().size
@onready var screen_center := viewport_size / 2.0 

var groups: Array[ControlGroup] = []

func _init() -> void:
	# 初始化 3 个默认组，防止 index 越界
	for index in ControlGroup.Index.values():
		groups.append(ControlGroup.new())

func setup(_group: Control , index:ControlGroup.Index) -> void:
	if _group not in groups[index].value:
		groups[index].value.append(_group)

func _process(delta):
	_update_ui_float_effect(delta)

func _update_ui_float_effect(delta: float) -> void:
	# 这里可以根据需要调整插值速度和强度
	var mouse_pos := get_viewport().get_mouse_position()
	var mouse_offset := mouse_pos - screen_center
	
	# 目标偏移量（反向偏移增加深度感）
	var target_offset := Vector2.ZERO
	
	# 平滑插值 (Lerp) 增加顺滑感
	for index in ControlGroup.Index.values():
		for control in groups[index].value:
			var intensity = 0.02 + index * 0.02 # 不同组不同强度
			target_offset = mouse_offset * intensity
			control.position = control.position.lerp(target_offset, delta * 5.0)
