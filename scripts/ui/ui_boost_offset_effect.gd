extends Node
class_name UIBoostOffsetEffect
@export var active: bool = false
@export var hud_container: Control

# Boost 时的 UI 扩散强度
var boost_offset_intensity = 100.0

var smooth : float = 8.0

func setup(child: Control) -> void:
	# 记录原始位置，用于 Boost 效果恢复
	child.set_meta("original_pos", child.position)

func _process(delta):

	if not active: return
	
	_update_boost_effect(delta)

func _update_boost_effect(delta: float) -> void:
	# 遍历所有 UI 子节点
	for child in hud_container.get_children():
		if child is Control:
			# 计算目标 Boost 偏移量
			var target_boost_pos = Vector2.ZERO
			
			if get_parent().is_boosting:
				smooth = 8.0
				# 核心逻辑：根据自身的旋转角度（弧度）向“前方”偏移
				# 这里假设 rotation 指向的是 UI 的发散方向
				var angle = child.rotation
				var boost_dir = Vector2(cos(angle), sin(angle)).normalized()
				
				# 为了让上下两排 UI 向屏幕边缘张开，这里需要根据其位置调整方向
				# 如果已经在 rotation 逻辑中计算好了方向，可以直接使用
				target_boost_pos = boost_dir * boost_offset_intensity
			else :
				smooth = 2.0
			
			# 平滑插值应用偏移 (注意：这里修改的是节点的 position 偏移)
			# 如果该节点原本需要居中，建议操作其 offset 属性或在一个包装容器内移动
			# 这里为了演示，假设使用一个简单的向外推力
			if child.has_meta("original_pos"):
				var base_pos = child.get_meta("original_pos")
				child.position = child.position.lerp(base_pos + target_boost_pos, delta * smooth)



