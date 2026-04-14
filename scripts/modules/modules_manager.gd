extends Node
class_name ModulesManager

# basic modules
var movement_module: Module
var third_camera_module: Module
var player_aim_module: BasicAimModule
var screen_module: ScreenModule
var rader_module: RadarModule

# var main_weapon_module: WeaponModule
# var main_weapon_predict_aim_module: PredictAimModule

func install_module(module_scene:PackedScene) -> Module:
	var module = module_scene.instantiate()

	if module is MoveModule:
		movement_module = module
	if module is BasicAimModule:
		player_aim_module = module
	if module is ThirdCameraModule:
		third_camera_module = module
	if module is ScreenModule:
		screen_module = module
	if module is RadarModule:
		rader_module = module

	add_child(module)
	return module

func get_camera_module() -> ThirdCameraModule:
	return third_camera_module

func get_aim_module() -> BasicAimModule:
	return player_aim_module

func get_move_module() -> MoveModule:
	return movement_module

func get_screen_module() -> ScreenModule:
	return screen_module

func get_radar_module() -> RadarModule:
	return rader_module