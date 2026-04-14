extends Node
class_name MyHUD

var group: Control

var manager: HUDManager

func _init(node:Control) -> void:
	group = node
	manager = GameManager.hud_manager

	
func set_flow_effect(index:ControlGroup.Index = ControlGroup.Index.GROUP_1) -> MyHUD:
	manager.flow_effect.setup(group , index)
	return self

func set_rotation_effect() -> MyHUD:
	manager.rotation_effect.setup(group)
	return self

func set_boost_offset_effect() -> MyHUD:
	manager.boost_offset_effect.setup(group)
	return self

func set_boost_shake_effect() -> MyHUD:
	manager.boost_shake_effect.setup(group)
	return self