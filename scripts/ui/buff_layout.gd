extends HFlowContainer
class_name BuffLayout

@export var buff_icon_scene: PackedScene = preload("res://scenes/ui/buff_icon.tscn")

var buff_component: BuffComponent

func _ready() -> void:
	# 延迟查找以确保目标已加载
	call_deferred("_setup_listener")

func _setup_listener() -> void:
	var target = GameManager.get_current_player() # 这里假设是玩家角色，实际项目中可能需要更灵活的目标指定
	
	
	buff_component = BuffManager.get_buff_component(target)
	if buff_component:
		# 连接现有 Buff
		for buff in buff_component.active_buffs.values():
			_add_buff_icon(buff)
		
		# 监听后续变化
		buff_component.buff_added.connect(_add_buff_icon)

func _add_buff_icon(buff: Buff) -> void:
	# 检查是否已有该 Buff 的图标（防止重复）
	for child in get_children():
		if child is BuffIcon and child.buff == buff:
			return
			
	var icon_instance = buff_icon_scene.instantiate() as BuffIcon
	add_child(icon_instance)
	icon_instance.setup(buff)
