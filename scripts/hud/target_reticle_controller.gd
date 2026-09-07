extends Node
class_name TargetReticleController

## 目标 UI 控制器:监听目标生成/销毁,按目标 spawn/回收 [code]TargetReticle[/code](见 .memo/.CURRENT.md P3)。
##
## 挂在 HUD_Manager 下(随 HUD 层生存,为 P4 玩家重生重建 HUD 打底)。
## 玩法模块不再造 UI:本控制器从 SignalBus 拿目标事件,构建并管理目标 UI 簇。
##
## 职责边界:
## - 只做"目标 ↔ TargetReticle"的映射与生命周期调度,不含玩法逻辑。
## - 悬停/锁定判定仍在玩法模块;本控制器只负责 UI 的生成与回收。

@export var target_selector_scene: PackedScene
@export var hp_bar_scene: PackedScene

# target -> TargetReticle
var _reticles: Dictionary = {}

func _ready() -> void:
	SignalBus.on_lockable_target_spawned.connect(_on_target_spawned)
	SignalBus.on_lockable_target_died.connect(_on_target_died)

func _on_target_spawned(target: AbleToBeLocked) -> void:
	if target in _reticles:
		return
	var player := GameManager.get_current_player()
	if player == null:
		return
	var cam := player.get_main_camera()
	if cam == null:
		return

	var reticle := TargetReticle.new()
	reticle.name = "TargetReticle_" + target.name
	add_child(reticle)
	reticle.setup(target, player, cam, target_selector_scene, hp_bar_scene)
	_reticles[target] = reticle

func _on_target_died(target: AbleToBeLocked) -> void:
	# 只做簿记:实际的整簇回收由 TargetReticle 监听 target.tree_exited 触发
	_reticles.erase(target)
