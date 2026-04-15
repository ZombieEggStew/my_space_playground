extends Node
class_name Module

var root : CharacterBody3D
var modules_manager : ModulesManager
@export var hud_container: Node


func _enter_tree() -> void:
    modules_manager = get_parent()
    root = modules_manager.get_parent()


