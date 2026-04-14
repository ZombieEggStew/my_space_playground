extends Node3D
class_name ModulesManager

# basic modules
var movement_module: MoveControllerModule
var third_camera_module: ThirdCameraModule
var player_aim_module: BasicAimModule
var screen_module: ScreenModule
var rader_module: RadarModule

func install_module(module_scene:PackedScene) -> Module:
	var module = module_scene.instantiate()

	if module is BasicAimModule:
		player_aim_module = module

	if module is ScreenModule:
		screen_module = module
	if module is RadarModule:
		rader_module = module

	add_child(module)
	return module

func install_module_3d(module_scene:PackedScene) -> Module3D:
	var module = module_scene.instantiate()

	if module is EngineModule:
		movement_module = module
	if module is ThirdCameraModule:
		third_camera_module = module

	add_child(module)
	return module

func get_camera_module() -> ThirdCameraModule:
	return third_camera_module

func get_aim_module() -> BasicAimModule:
	return player_aim_module

func get_move_module() -> EngineModule:
	return movement_module

func get_screen_module() -> ScreenModule:
	return screen_module

func get_radar_module() -> RadarModule:
	return rader_module
