extends Node3D
class_name Module

var root : CharacterBody3D
var modules_manager : ModulesManager
@export var hud_container: Node


## 进入场景树时兜底解析依赖:正常情况下 install_module 已显式注入
## root/modules_manager(见 ModulesManager._inject_module_deps);这里只在
## 未注入时按旧约定推算(兼容手拖进场景 / 遗漏注入的情况)。
## 覆盖此方法的子类必须调用 super._enter_tree()。
func _enter_tree() -> void:
    if modules_manager == null:
        modules_manager = get_parent() as ModulesManager
    if root == null and modules_manager != null:
        root = modules_manager.get_parent() as CharacterBody3D

## 卸载钩子(§4.2-5):子类覆写,清理 reparent 出去的 2D 节点、断开手动连接。
## 由 ModulesManager.uninstall_module 显式调用,并在 _exit_tree 再兜底一次。
## 必须是幂等的:重复调用不得报错/重复释放。
func on_uninstall() -> void:
    pass

## 兜底:即使模块被外部直接 queue_free/移除场景树,也能触发一次清理。
func _exit_tree() -> void:
    on_uninstall()

