extends Node

# Buff 脚本所在的目录
const BUFF_SCRIPT_DIR = "res://scripts/buff/"

# 辅助函数，应用指定名称的 Buff 给目标
func apply_buff_by_name(target: Node, source: Node, buff_id: String, duration: float = 0.0) -> void:
	var script_path = BUFF_SCRIPT_DIR + "buff_" + buff_id + ".gd"
	
	if not FileAccess.file_exists(script_path):
		printerr("Buff Manager: Cannot find buff script at: ", script_path)
		return
	
	var buff_script = load(script_path)
	if not buff_script:
		printerr("Buff Manager: Failed to load buff script: ", script_path)
		return
		
	var buff = buff_script.new() as Buff
	if not buff:
		printerr("Buff Manager: Script at ", script_path, " is not a valid Buff class")
		return
	
	# 自动设置 Buff 属性
	buff.buff_name = buff_id
	buff.icon_path = "res://textures/icon/icon_buff_" + buff_id + ".png"
	
	# 通用组件查找：要求目标在自身挂载一个 BuffComponent
	var component = get_buff_component(target)
	if component:
		component.add_buff(buff, source, duration)
	else:
		printerr("Buff Manager: Target ", target.name, " has no BuffComponent")

# 帮助查找目标身上的 BuffComponent 组件
func get_buff_component(target: Node) -> Node:
	# 检查目标的所有子节点是否有 BuffComponent 类型
	for child in target.get_children():
		if child is BuffComponent:
			return child
	return null

# 获取活动 Buff 信息，用于 UI 显示
func get_all_active_buffs(target: Node) -> Array[Buff]:
	var comp = get_buff_component(target)
	if comp:
		return comp.active_buffs.values()
	return []
