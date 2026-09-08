extends Node3D
class_name Module

var root : CharacterBody3D
var modules_manager : ModulesManager
## ② 飞船级事件总线(install 时由 ModulesManager 显式注入;决策 #25/#27)
var ship_bus : ShipBus
@export var hud_container: Node

## 决策 #32:跨模块引用统一"事件驱动获取"——声明关心的模块类型,装卸事件触发时
## 自动调 _resolve_module_refs()(重装模块立即更新,无需轮询/重启)。
## 传给子类覆写的 _resolve_module_refs() 的是"重取引用 + 幂等 + 缺模块降级"。
var _watched_module_types: Array = []


## 进入场景树时兜底解析依赖:正常情况下 install_module 已显式注入
## root/modules_manager/ship_bus(见 ModulesManager._inject_module_deps);这里只在
## 未注入时按旧约定推算(兼容手拖进场景 / 遗漏注入的情况)。
## 覆盖此方法的子类必须调用 super._enter_tree()。
func _enter_tree() -> void:
    if modules_manager == null:
        modules_manager = get_parent() as ModulesManager
    if root == null and modules_manager != null:
        root = modules_manager.get_parent() as CharacterBody3D
    if ship_bus == null and root != null and "ship_bus" in root:
        ship_bus = root.get("ship_bus")

## 声明本模块关心的其他模块类型(基类即可,如 EngineModule 匹配 MoveControllerModule)。
## 之后这些模块安装/卸载都会触发 _resolve_module_refs()。须在 _ready 调用(且只调一次)。
func watch_modules(module_types: Array) -> void:
    _watched_module_types = module_types
    if modules_manager == null:
        return
    if not modules_manager.module_installed.is_connected(_on_watched_module_installed):
        modules_manager.module_installed.connect(_on_watched_module_installed)
    if not modules_manager.module_uninstalled.is_connected(_on_watched_module_uninstalled):
        modules_manager.module_uninstalled.connect(_on_watched_module_uninstalled)

func _on_watched_module_installed(module: Module) -> void:
    if _is_watched(module):
        _resolve_module_refs()

func _on_watched_module_uninstalled(module: Module) -> void:
    if _is_watched(module):
        _resolve_module_refs()

func _is_watched(module: Module) -> bool:
    for t in _watched_module_types:
        if is_instance_of(module, t):
            return true
    return false

## 子类覆写:重取关心的模块引用(装卸事件触发时调用)。必须幂等;
## 某模块缺失时把对应引用置 null(消费方按 null 降级,不硬崩)。
func _resolve_module_refs() -> void:
    pass

func _unwatch_modules() -> void:
    if modules_manager != null and is_instance_valid(modules_manager):
        if modules_manager.module_installed.is_connected(_on_watched_module_installed):
            modules_manager.module_installed.disconnect(_on_watched_module_installed)
        if modules_manager.module_uninstalled.is_connected(_on_watched_module_uninstalled):
            modules_manager.module_uninstalled.disconnect(_on_watched_module_uninstalled)

## 卸载钩子(§4.2-5):子类覆写,清理 reparent 出去的 2D 节点、断开手动连接。
## 由 ModulesManager.uninstall_module 显式调用,并在 _exit_tree 再兜底一次。
## 必须是幂等的:重复调用不得报错/重复释放。
func on_uninstall() -> void:
    pass

## 兜底:即使模块被外部直接 queue_free/移除场景树,也能触发一次清理。
func _exit_tree() -> void:
    on_uninstall()
    _unwatch_modules()

