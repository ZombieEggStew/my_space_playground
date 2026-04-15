extends Node
class_name ModuleComponent

@export var hud_container: Node

var main_module: Module

func _enter_tree() -> void:
    main_module = get_parent() as Module
