extends CanvasLayer
class_name HUDManager

@export var hud_container: Node
@export var hud_static: Node
@export var hud_far : Node



@export var flow_effect : UIFlowEffect
@export var rotation_effect : UIRotationEffect 
@export var boost_offset_effect : UIBoostOffsetEffect
@export var boost_shake_effect : UIBoostShakeEffect



func register_hud_group(group: Control) -> MyHUD:
	print("HUDManager: Registering HUD element: " + group.name)

	group.reparent(hud_container)
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
