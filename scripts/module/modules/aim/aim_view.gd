extends Node
class_name AimView

## aim 模块的 2D 呈现层(决策 #20):持有锁定准星 crosshair_2,负责其注册与每帧驱动。
## 数据来源:aim 模块(selection)经 [method set_locked_target] / [method set_hovered_target]
## 传入目标身份;本 view 用相机投影渲染(投影原语后续收口到 camera,决策 #18)。
##
## 职责边界:
## - 只负责准星的显示/平滑/屏幕边缘指示,不含锁定/悬停判定(判定在 module_player_aim)。
## - 随 aim 模块一起装卸;卸载时清理经 register_hud 注册到 HUD 层的准星节点。

@export var scene_lock_reticle: PackedScene

var crosshair_2: HUD_LockReticle  # 绿色 二级锁定准星

var _locked_target: AbleToBeLocked
var _hovered_target: AbleToBeLocked

var cam_main: Camera3D
var indicator_margin := 32.0

func _ready() -> void:
	var aim_module := get_parent()
	if aim_module and aim_module.get("root") != null:
		cam_main = aim_module.root.get_main_camera()
	init_crosshair_2()

func init_crosshair_2() -> void:
	crosshair_2 = GameManager.hud_manager.register_hud(scene_lock_reticle).node as HUD_LockReticle

func set_locked_target(target: AbleToBeLocked) -> void:
	_locked_target = target

func set_hovered_target(target: AbleToBeLocked) -> void:
	_hovered_target = target

func _process(_delta: float) -> void:
	if cam_main == null:
		return
	if is_instance_valid(_locked_target):
		_handle_locked_target()
	elif is_instance_valid(_hovered_target):
		crosshair_2.set_target_pos(cam_main.unproject_position(_hovered_target.global_position))
	else:
		crosshair_2.reset()

func _handle_locked_target() -> void:
	if not is_instance_valid(_locked_target):
		_locked_target = null
		return

	var world_pos := _locked_target.global_position
	var viewport_size := get_viewport().get_visible_rect().size
	var center := viewport_size * 0.5
	var screen_pos := cam_main.unproject_position(world_pos)

	if cam_main.is_position_behind(world_pos):
		var to_enemy := world_pos - cam_main.global_transform.origin
		var right_component := cam_main.global_transform.basis.x.dot(to_enemy)
		var up_component := cam_main.global_transform.basis.y.dot(to_enemy)
		var dir_2d := Vector2(right_component, -up_component)
		if dir_2d.length() < 0.001:
			dir_2d = Vector2.UP
		screen_pos = center + dir_2d.normalized() * max(viewport_size.x, viewport_size.y)

	screen_pos = Vector2(
		clamp(screen_pos.x, indicator_margin, viewport_size.x - indicator_margin),
		clamp(screen_pos.y, indicator_margin, viewport_size.y - indicator_margin)
	)
	crosshair_2.set_target_pos(screen_pos)

## 兜底清理(§4.2-5):卸载时回收注册到 HUD 层的准星节点(幂等)
func _exit_tree() -> void:
	if is_instance_valid(crosshair_2):
		crosshair_2.queue_free()
	crosshair_2 = null
