extends Node
class_name TargetReticle

## 单个可锁定目标的目标 UI 簇(白色选择框 + 目标血条)统一生命周期组件(见 .memo/.CURRENT.md P3)。
##
## 由 [code]RadarView[/code](radar_view.gd)按目标 spawn;setup 里经 register_hud 注册两个静态元素,
## 并把 radar_view 算好的屏幕矩形喂给选择框(方案 A);目标销毁/离开场景树时整簇一起回收。
##
## 职责边界:
## - 只负责"一个目标的目标 UI 簇"的组装与生命周期,不含投影/尺寸计算(在 radar_view)
##   与悬停检测(在 aim/selection,决策 #27)。
## - 元素自身的 tree_exited→queue_free 作为兜底自毁保留(双重保险,queue_free 幂等)。
## - hover 高亮经 RadarView 订阅 ② 后调用 [method set_hovered] 转发(决策 #27)。

var target: AbleToBeLocked

var _selector: HUD_TargetSelector
var _hp_bar: HUD_TargetHPBar

func setup(_target: AbleToBeLocked, cam: Camera3D, selector_scene: PackedScene, hp_bar_scene: PackedScene) -> void:
	target = _target

	_selector = GameManager.hud_manager.register_hud(selector_scene).node as HUD_TargetSelector
	_selector.setup(target)

	_hp_bar = GameManager.hud_manager.register_hud(hp_bar_scene).node as HUD_TargetHPBar
	_hp_bar.setup(target, cam)

	# 目标销毁/离开场景树 → 整簇回收
	if not target.tree_exited.is_connected(_cleanup):
		target.tree_exited.connect(_cleanup)

## radar_view 每帧喂入选择框显示数据(方案 A):中心屏幕坐标 + 尺寸
func set_screen_rect(center: Vector2, size: Vector2) -> void:
	if is_instance_valid(_selector):
		_selector.set_target_pos(center, size)

## radar_view 控制选择框显隐(离屏时隐藏)
func set_on_screen(visible: bool) -> void:
	if is_instance_valid(_selector):
		_selector.set_active(visible)

## radar_view 订阅 ② hover 事件后转发高亮
func set_hovered(hovered: bool) -> void:
	if is_instance_valid(_selector):
		_selector.set_hovered(hovered)

## 整簇回收(目标死亡/离开场景树时由 tree_exited 触发;radar_view 卸载时也可显式调用)
func cleanup() -> void:
	_cleanup()

## 整簇回收(目标死亡/离开场景树时由 tree_exited 触发;controller 也可调用)
func _cleanup() -> void:
	if is_instance_valid(_selector):
		_selector.queue_free()
	if is_instance_valid(_hp_bar):
		_hp_bar.queue_free()
	queue_free()
