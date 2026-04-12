extends Module
class_name ScreenModule

# 获取屏幕中心点
@onready var viewport_size = get_viewport().get_visible_rect().size
@onready var screen_center = viewport_size / 2.0

# 旋转强度系数（可以根据需要调整）
var rotation_intensity = 0.005 

@export var hud_container: Control

func add_hud(hud: CanvasLayer) -> void:
	for child in hud.get_children():
		if child is Control:
			child.reparent(hud_container)
			# 1. 设置中心轴点 (0.5, 0.5)
			# 注意：pivot_offset 需要根据 size 来计算，或者直接设置 pivot_offset = size * 0.5
			child.pivot_offset = child.size * 0.5
			
			# 2. 计算节点相对于屏幕中心的位置
			var global_pos = child.global_position + child.size * 0.5
			var offset = global_pos - screen_center
			
			# 3. 根据象限确定旋转方向
			var direction = sign(offset.x * offset.y)
			
			# 4. 离中心越远旋转角度越大
			# 使用偏移向量的长度作为强度
			var distance = offset.length()
			
			# 应用旋转 (角度或弧度)
			# 这里假设使用 degree，乘以系数控制幅度
			child.rotation_degrees = direction * distance * rotation_intensity

