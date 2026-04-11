extends UIModule

@export var hp_label: Label
@export var hp_bar: TextureProgressBar

@export var speed_label: Label

@export var items_container: Control

var my_hp_ref: FloatStat

func _ready() -> void:

	my_hp_ref = root.get_health_stat() 
	
	# 依然建议连接信号以更新显示，否则你需要每帧去读 my_hp_ref.value
	my_hp_ref.changed.connect(_update_hp_ui)
	_update_hp_ui(my_hp_ref.value)
	_apply_dynamic_rotation()

func _apply_dynamic_rotation() -> void:
	# 获取屏幕中心点
	var viewport_size = get_viewport().get_visible_rect().size
	var screen_center = viewport_size / 2.0
	
	# 旋转强度系数（可以根据需要调整）
	var rotation_intensity = 0.005 

	for child in items_container.get_children():
		if child is Control:
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

func _process(_delta):
	_updata_speed_ui()	


func _update_hp_ui(val: float) -> void:
	hp_label.text = "%s/%s" % [val, my_hp_ref.max_value]
	hp_bar.value = val / my_hp_ref.max_value * 100.0

 
func _updata_speed_ui() -> void:
	speed_label.text = root.get_speed_string()
