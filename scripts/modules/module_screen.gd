extends Module
class_name ScreenModule


@export var hud_container: Control
@onready var rotation_effect : UIRotationEffect = $UI_Layer/EffectManager/UI_RotationEffect
@onready var boost_offset_effect : UIBoostOffsetEffect = $UI_Layer/EffectManager/UI_BoostOffsetEffect

func add_hud(hud: CanvasLayer) -> void:
	# 这里的逻辑只负责“把 UI 塞进容器”
	# 具体的动态效果由子节点在各自的 _process 中处理
	for child in hud.get_children():
		if child is Control:
			print("Adding HUD element: " + child.name)
			child.reparent(hud_container)
			rotation_effect.setup(child)
			boost_offset_effect.setup(child)







