extends Node
class_name Module

var root : CharacterBody3D
var modules_manager : ModulesManager
@export var hud_container: Node


func _enter_tree() -> void:
    modules_manager = get_parent()
    root = modules_manager.get_parent()


func log_error(message: String) -> void:
    print("[ERROE] ", self.name, ": ", message)

func log_missing_component(module : String) -> void:
    log_error("Missing component: %s" % module)