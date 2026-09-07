extends Node
class_name UIFlowEffect


# 获取屏幕中心点
@onready var viewport_size := get_viewport().get_visible_rect().size
@onready var screen_center := viewport_size / 2.0 

# group -> 当前平滑后的视差偏移。
# 不再直接写 position,只写 meta 里的 hud_flow_offset 通道,
# 由 HUDManager 统一合成,避免与其他特效(如抖动)互相抢占 position。
var _offsets: Dictionary = {}

func setup(_group: Control, index: ControlGroup.Index) -> void:
	if _group not in _offsets:
		_offsets[_group] = Vector2.ZERO
	_group.set_meta("hud_flow_index", index)
	if not _group.has_meta("hud_flow_offset"):
		_group.set_meta("hud_flow_offset", Vector2.ZERO)

func _process(delta):
	_update_ui_float_effect(delta)

func _update_ui_float_effect(delta: float) -> void:
	# 这里可以根据需要调整插值速度和强度
	var mouse_pos := get_viewport().get_mouse_position()
	var mouse_offset := mouse_pos - screen_center

	for group in _offsets.keys():
		if not is_instance_valid(group):
			_offsets.erase(group)
			continue

		# 不同组不同强度
		var index: ControlGroup.Index = group.get_meta("hud_flow_index", ControlGroup.Index.GROUP_1)
		var intensity := 0.02 + index * 0.02
		var target_offset := mouse_offset * intensity

		# 平滑插值 (Lerp) 增加顺滑感,结果写入独立 offset 通道
		var current: Vector2 = _offsets[group]
		_offsets[group] = current.lerp(target_offset, delta * 5.0)
		group.set_meta("hud_flow_offset", _offsets[group])
