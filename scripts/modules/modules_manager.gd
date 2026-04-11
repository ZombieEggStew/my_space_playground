extends Node
class_name ModulesManager

var movement_module: Module
var third_camera_module: Module
var player_aim_module: BasicAimModule

# var main_weapon_module: WeaponModule
# var main_weapon_predict_aim_module: PredictAimModule

func install_module(module_scene:PackedScene) -> Module:
	var module = module_scene.instantiate()

	if module is BasicMoveModule:
		movement_module = module
	if module is BasicAimModule:
		player_aim_module = module
	if module is ThirdCameraModule:
		third_camera_module = module
	

	add_child(module)
	return module

func get_aim_module() -> BasicAimModule:
	return player_aim_module

func get_move_module() -> BasicMoveModule:
	return movement_module

