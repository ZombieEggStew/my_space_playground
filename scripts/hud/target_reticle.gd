extends Node
class_name TargetReticle

## 单个可锁定目标的目标 UI 簇(白色选择框 + 目标血条)统一生命周期组件(见 .memo/.CURRENT.md P3)。
##
## 由 [code]TargetReticleController[/code] 按目标 spawn;setup 里经 register_hud 注册两个静态元素,
## 并把选择框的悬停事件转发到 SignalBus;目标销毁/离开场景树时整簇一起回收,不散落在各元素脚本里。
##
## 职责边界:
## - 只负责"一个目标的目标 UI 簇"的组装与生命周期,不含锁定判定(判定在 BasicAimModule)。
## - 元素自身的 tree_exited→queue_free 作为兜底自毁保留(双重保险,queue_free 幂等)。
## - 悬停状态经 SignalBus.on_target_hovered / on_target_unhovered 发布,玩法侧订阅。

var target: AbleToBeLocked

var _selector: HUD_TargetSelector
var _hp_bar: HUD_TargetHPBar

func setup(_target: AbleToBeLocked, player: PlayerShip, cam: Camera3D, selector_scene: PackedScene, hp_bar_scene: PackedScene) -> void:
	target = _target

	_selector = GameManager.hud_manager.register_hud(selector_scene).node as HUD_TargetSelector
	_selector.mouse_entered.connect(_on_selector_mouse_entered)
	_selector.mouse_exited.connect(_on_selector_mouse_exited)
	_selector.setup(target, player, cam)

	_hp_bar = GameManager.hud_manager.register_hud(hp_bar_scene).node as HUD_TargetHPBar
	_hp_bar.setup(target, cam)

	# 目标销毁/离开场景树 → 整簇回收
	if not target.tree_exited.is_connected(_cleanup):
		target.tree_exited.connect(_cleanup)

func _on_selector_mouse_entered(t: AbleToBeLocked) -> void:
	SignalBus.on_target_hovered.emit(t)

func _on_selector_mouse_exited() -> void:
	SignalBus.on_target_unhovered.emit()

## 整簇回收(目标死亡/离开场景树时由 tree_exited 触发;controller 也可调用)
func _cleanup() -> void:
	if is_instance_valid(_selector):
		_selector.queue_free()
	if is_instance_valid(_hp_bar):
		_hp_bar.queue_free()
	queue_free()
