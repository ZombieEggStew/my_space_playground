extends Node
class_name ModulesManager

@export var movement_module: Module
@export var camera_control_module: Module
@export var player_aim_module: BasicAimModule

@export var main_weapon_module: WeaponModule
@export var main_weapon_predict_aim_module: PredictAimModule

func _ready() -> void:
	init_modules()

func get_aim_module() -> BasicAimModule:
	return player_aim_module

func init_modules() -> void:
	var predicted_aim_module = Global.predict_aim_module_scene.instantiate()
	var laser_gun_module = Global.laser_gun_module_scene.instantiate()

	add_child(predicted_aim_module)
	add_child(laser_gun_module)