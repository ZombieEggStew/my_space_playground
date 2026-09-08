extends Node
class_name RadarView

## 雷达模块的 2D 呈现层(玩家侧,决策 #24):负责"目标 UI 簇"(选择框+血条)的
## 组装与生命周期,随 radar 模块一起装卸。radar 身体只算 3D、不碰相机。
## 敌人复用 radar 时若无相机(非 PlayerShip),本 view 自动禁用,不影响雷达身体。
##
## 职责边界:
## - 只做"目标 ↔ 目标 UI 簇"的映射与生命周期调度,不含雷达侦测/半径过滤(在身体)。
## - 悬停/锁定判定仍在 aim 模块;本 view 只负责渲染与回收(决策 #21 的渲染侧)。

@export var target_selector_scene: PackedScene
@export var hp_bar_scene: PackedScene

var _radar_module: RadarModule
var _root: Node

# target -> TargetReticle
var _reticles: Dictionary = {}

func _enter_tree() -> void:
	_radar_module = get_parent() as RadarModule
	if _radar_module:
		_root = _radar_module.root

func _ready() -> void:
	# 只有带相机的船(玩家)需要 2D 呈现;敌人雷达无相机 → 禁用
	if _root == null or not _root.has_method("get_main_camera"):
		set_process(false)
		return
	SignalBus.on_lockable_target_spawned.connect(_on_target_spawned)
	SignalBus.on_lockable_target_died.connect(_on_target_died)

func _on_target_spawned(target: AbleToBeLocked) -> void:
	if target in _reticles:
		return
	# 用自己所属的船(_root,由 radar 模块注入),不绕全局 GameManager;
	# 敌人雷达(无相机)在 _ready 已禁用,不会走到这里。
	if _root == null or not _root.has_method("get_main_camera"):
		return
	var cam: Camera3D = _root.get_main_camera()
	if cam == null:
		return

	var reticle := TargetReticle.new()
	reticle.name = "TargetReticle_" + target.name
	add_child(reticle)
	reticle.setup(target, _root as PlayerShip, cam, target_selector_scene, hp_bar_scene)
	_reticles[target] = reticle

func _on_target_died(target: AbleToBeLocked) -> void:
	# 只做簿记:实际的整簇回收由 TargetReticle 监听 target.tree_exited 触发
	_reticles.erase(target)

## 兜底清理(§4.2-5):断开 SignalBus + 回收全部目标 UI 簇(幂等)
func _exit_tree() -> void:
	if _root != null and _root.has_method("get_main_camera"):
		if SignalBus.on_lockable_target_spawned.is_connected(_on_target_spawned):
			SignalBus.on_lockable_target_spawned.disconnect(_on_target_spawned)
		if SignalBus.on_lockable_target_died.is_connected(_on_target_died):
			SignalBus.on_lockable_target_died.disconnect(_on_target_died)
	for reticle in _reticles.values():
		if is_instance_valid(reticle):
			reticle.cleanup()
	_reticles.clear()
