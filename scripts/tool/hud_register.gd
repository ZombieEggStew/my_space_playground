extends Control
class_name HUDRegister

func _ready():
	print("HUDRegister ready, registering with GameManager...")
	GameManager.hud_manager.register_hud_group(self)
