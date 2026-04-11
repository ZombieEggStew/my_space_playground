extends Node
class_name Module

var root : CharacterBody3D
var modules_manager : ModulesManager

func _enter_tree() -> void:
    modules_manager = get_parent()
    root = modules_manager.get_parent()

func log_error(message: String) -> void:
    print("Error in module ", self.name, ": ", message)

func log_missing_component() -> void:
    log_error("Missing required component !" )