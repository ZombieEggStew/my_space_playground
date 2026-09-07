extends CanvasLayer
class_name HUDManager

@export var hud_container: Node
@export var hud_static: Node
@export var hud_far : Node



@export var flow_effect : UIFlowEffect
@export var rotation_effect : UIRotationEffect 
@export var boost_offset_effect : UIBoostOffsetEffect
@export var boost_shake_effect : UIBoostShakeEffect

# 动态 HUD 组:特效只写独立的 offset 通道,由这里统一合成,避免互相抢占 position
var _dynamic_groups: Array[Control] = []


func register_hud_group(group: Control) -> MyHUD:
	print("HUDManager: Registering HUD element: " + group.name)

	group.reparent(hud_container)
	_init_dynamic_group(group)
	return MyHUD.new(group)
	
func register_hud_static(scene: PackedScene) -> Node:
	var item = scene.instantiate()
	print("HUDManager: Registering HUD static element: " + item.name)
	hud_static.add_child(item)
	return item

func register_hud_far(scene: PackedScene) -> Node:
	var item = scene.instantiate()
	print("HUDManager: Registering HUD far element: " + item.name)
	hud_far.add_child(item)
	return item

func register_hud_far_node(node: Node2D) -> Node:
	print("HUDManager: Registering HUD far element: " + node.name)
	node.reparent(hud_far)
	return node


# 捕获作者好的布局基准位置,并初始化各特效的 offset 通道
func _init_dynamic_group(group: Control) -> void:
	if group in _dynamic_groups:
		return
	group.set_meta("hud_base_pos", group.position)
	group.set_meta("hud_flow_offset", Vector2.ZERO)
	group.set_meta("hud_shake_offset", Vector2.ZERO)
	_dynamic_groups.append(group)


func _process(_delta: float) -> void:
	_compose_dynamic_groups()


# 特效各自只写 meta 里的 offset 通道,这里统一合成到 position(保留布局基准)
func _compose_dynamic_groups() -> void:
	var i := 0
	while i < _dynamic_groups.size():
		var group: Control = _dynamic_groups[i]
		if not is_instance_valid(group):
			_dynamic_groups.remove_at(i)
			continue
		var base: Vector2 = group.get_meta("hud_base_pos", Vector2.ZERO)
		var flow: Vector2 = group.get_meta("hud_flow_offset", Vector2.ZERO)
		var shake: Vector2 = group.get_meta("hud_shake_offset", Vector2.ZERO)
		group.position = base + flow + shake
		i += 1
