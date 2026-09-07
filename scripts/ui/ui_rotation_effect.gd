extends Node
class_name UIRotationEffect

# 旋转强度系数（可以根据需要调整）
var rotation_intensity = 0.01

# 已注册的 HUD 组。每帧重算旋转(控件移动/屏幕尺寸变化后不再失效),
# 并做 is_instance_valid 反注册,避免控件释放后报 "previously freed"(与 flow/shake 防护一致)。
var _groups: Array[Control] = []

func setup(group: Control) -> void:
	if group not in _groups:
		_groups.append(group)

func _process(_delta: float) -> void:
	_update_rotation()

func _update_rotation() -> void:
	# 每帧读取屏幕中心,窗口尺寸变化后旋转基准自动跟随
	var screen_center: Vector2 = get_viewport().get_visible_rect().size / 2.0

	var i := 0
	while i < _groups.size():
		var group: Control = _groups[i]
		if not is_instance_valid(group):
			_groups.remove_at(i)
			continue
		for child in group.get_children():
			if not is_instance_valid(child):
				continue

			# 1. 设置中心轴点 (50%, 50%)
			child.pivot_offset_ratio = Vector2(0.5, 0.5)

			# 2. 计算节点相对于屏幕中心的位置
			var global_pos: Vector2 = child.global_position + child.size * 0.5
			var offset: Vector2 = global_pos - screen_center

			# 3. 根据象限确定旋转方向
			var direction: float = signf(offset.x * offset.y)

			# 4. 离屏幕中心高度越远旋转角度越大(使用 y 方向的偏离长度作为强度)
			var vertical_distance: float = absf(offset.y)

			# 应用旋转 (角度)
			child.rotation_degrees = direction * vertical_distance * rotation_intensity
		i += 1
