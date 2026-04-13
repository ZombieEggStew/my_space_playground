extends Node

@export var active: bool = false
@export var hud_container: Control
@export var viewport: SubViewportContainer

var shake_intensity := 5.0

func _process(_delta: float) -> void:
	if not active: return
	_update_shake(_delta)

func _update_shake(_delta: float) -> void:
	if get_parent().is_boosting:
		var shake_offset = Vector2(
			randf_range(-shake_intensity, shake_intensity),
			randf_range(-shake_intensity, shake_intensity)
		)
		# 同时抖动 UI 容器和 3D Viewport 容器
		hud_container.position += shake_offset
		if viewport:
			viewport.position += shake_offset
	else:
		# 停止加速时，UI 容器由于已经有 _update_ui_float 的 lerp 逻辑，会自动归位
		# 3D Viewport 需要手动归位（假设初始位置是 Vector2.ZERO）
		if viewport:
			viewport.position = viewport.position.lerp(Vector2.ZERO, _delta * 10.0)