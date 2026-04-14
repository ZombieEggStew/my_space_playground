extends CanvasLayer
class_name HUDManager


@export var hud_container: Node
@export var hud_static: Node
@export var hud_3: Node

@export var hud_3_viewport: SubViewport

@export var flow_effect : UIFlowEffect
@export var rotation_effect : UIRotationEffect 
@export var boost_offset_effect : UIBoostOffsetEffect

func register_hud_group(group: Control) -> MyHUD:
	print("HUDManager: Registering HUD element: " + group.name)

	group.reparent(hud_container)
	return MyHUD.new(group)
	

	
func register_hud_static(scene: PackedScene) -> Node:
	var item = scene.instantiate()
	print("HUDManager: Registering HUD static element: " + item.name)
	hud_static.add_child(item)
	return item

func regisger_hud_3(scene: PackedScene) -> Node:
	var item = scene.instantiate()
	print("HUDManager: Registering HUD_3 element: " + item.name)
	hud_3.add_child(item)
	return item

func get_hud_3_viewport() -> SubViewport:
	return hud_3_viewport
