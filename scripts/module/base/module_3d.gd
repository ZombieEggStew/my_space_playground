extends Node3D
class_name Module3D

var root : CharacterBody3D
var modules_manager : ModulesManager
@export var hud_container: Node


func _enter_tree() -> void:
    modules_manager = get_parent()
    root = modules_manager.get_parent()

## 卸载钩子(§4.2-5):子类覆写,清理 reparent 出去的 2D 节点、断开手动连接。
## 由 ModulesManager.uninstall_module_3d 显式调用,并在 _exit_tree 再兜底一次。
## 必须是幂等的:重复调用不得报错/重复释放。
func on_uninstall() -> void:
    pass

## 兜底:即使模块被外部直接 queue_free/移除场景树,也能触发一次清理。
func _exit_tree() -> void:
    on_uninstall()

