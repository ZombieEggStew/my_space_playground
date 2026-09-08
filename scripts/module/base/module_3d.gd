extends Node3D
class_name Module3D

var root : CharacterBody3D
var modules_manager : ModulesManager
@export var hud_container: Node


func _enter_tree() -> void:
    modules_manager = get_parent()
    root = modules_manager.get_parent()

