extends Node
class_name UIRotationEffect

@export var active: bool = false

# 获取屏幕中心点
@onready var viewport_size = get_viewport().get_visible_rect().size
@onready var screen_center = viewport_size / 2.0




# 旋转强度系数（可以根据需要调整）
var rotation_intensity = 0.01 

func setup(child:Control) -> void:
    if not active:
        return

    # 1. 设置中心轴点 (50%, 50%)
    child.pivot_offset_ratio =  Vector2(0.5, 0.5)
    
    # 2. 计算节点相对于屏幕中心的位置
    var global_pos = child.global_position + child.size * 0.5
    var offset = global_pos - screen_center
    
    # 3. 根据象限确定旋转方向
    var direction = sign(offset.x * offset.y)
    
    # 4. 离屏幕中心高度越远旋转角度越大
    # 使用 y 方向的偏离长度作为强度
    var vertical_distance = abs(offset.y)
    
    # 应用旋转 (角度或弧度)
    # 这里假设使用 degree，乘以系数控制幅度
    child.rotation_degrees = direction * vertical_distance * rotation_intensity
