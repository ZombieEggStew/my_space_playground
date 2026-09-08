#TO DO : 目标太远断开锁定

extends Module
class_name BasicAimModule

@export var aim_view: AimView

var cam_main: Camera3D
var use_occlusion_check := true

var hovered_target: AbleToBeLocked 
var locked_target: AbleToBeLocked

var aim_ray_length := 5000.0 #非锁定时使用，预测射击点

## 决策 #27:hover 几何数据源(radar_view 缓存 screen_rect),install 顺序保证 radar 先于 aim。
var _radar_view: RadarView


func _ready() -> void:
	ship_bus.on_player_try_lock.connect(_handle_lock_action)
	# 决策 #27:hover 由本模块(selection)自判:每帧拉 radar_view 缓存 rects 做命中测试,
	# 不再订阅全局/转发信号;无 radar 时 _radar_view 为 null → selection 降级(§4.2-2)。
	# Bug 4:目标死亡/离开场景树时清掉悬挂引用
	SignalBus.on_lockable_target_died.connect(_on_target_died)

	cam_main = root.get_main_camera()
	if cam_main == null:
		Log.log_missing_component(self,"main camera")
		queue_free()


func _process(_delta: float) -> void:
	_update_hover()

## 决策 #27:每帧拉 radar_view 缓存的 screen_rect 命中测试鼠标位置;
## 命中多个按遍历序尾者胜;离屏/未知目标不在 rects 中 → 自动 unhover。
func _update_hover() -> void:
	var hovered: AbleToBeLocked = null
	# 每帧取(而非 _ready 缓存):支持 radar 动态装卸后 selection 自动恢复/降级
	_radar_view = modules_manager.get_radar_view() if modules_manager else null
	if _radar_view != null and is_instance_valid(_radar_view):
		var mouse_pos := get_viewport().get_mouse_position()
		for target: AbleToBeLocked in _radar_view.get_screen_rects():
			if _radar_view.get_screen_rect(target).has_point(mouse_pos):
				hovered = target
	_set_hovered(hovered)

## hover 状态变化才动作(本地状态驱动 aim_view;变化脉冲经 ② 发布供 radar_view 高亮)
func _set_hovered(target: AbleToBeLocked) -> void:
	if target == hovered_target:
		return
	hovered_target = target
	if aim_view:
		aim_view.set_hovered_target(target)
	if ship_bus:
		if target != null:
			ship_bus.on_target_hovered.emit(target)
		else:
			ship_bus.on_target_unhovered.emit()


func _handle_lock_action():
	if hovered_target != null:
		set_locked_target(hovered_target)
		print("Locked target: %s" % hovered_target.name)
	else:
		set_locked_target(null)

# Bug 4:目标死亡/离开场景树时清掉悬挂引用,避免 _process 里访问已释放目标
func _on_target_died(target: AbleToBeLocked) -> void:
	if locked_target == target:
		locked_target = null
	if hovered_target == target:
		hovered_target = null
	if aim_view:
		aim_view.set_locked_target(locked_target)
		aim_view.set_hovered_target(hovered_target)

func set_locked_target(target: AbleToBeLocked) -> void:
	if target:
		target.set_locked(true)
	else:
		if locked_target:
			locked_target.set_locked(false)

	locked_target = target
	if aim_view:
		aim_view.set_locked_target(target)
	ship_bus.on_player_lock_target.emit(target)

func _is_enemy_visible_from_camera(target: Node3D) -> bool:
	if cam_main == null:
		return false

	var world_pos := target.global_transform.origin
	if cam_main.is_position_behind(world_pos):
		return false

	var screen_pos := cam_main.unproject_position(world_pos)
	var viewport_rect := get_viewport().get_visible_rect()
	if not viewport_rect.has_point(screen_pos):
		return false

	if not use_occlusion_check:
		return true

	var space_state := root.get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(
		cam_main.global_transform.origin,
		world_pos,
		0xFFFFFFFF,
		[root, cam_main]
	)
	var hit := space_state.intersect_ray(query)
	if hit.is_empty():
		return true

	var collider := hit.get("collider") as Node
	if collider == null:
		return false
	return collider == target or target.is_ancestor_of(collider)


func get_aim_direction_from_crosshair(aim_screen_pos:Vector2) -> Vector3:
	if is_instance_valid(locked_target):
		aim_ray_length = locked_target.global_position.distance_to(root.global_position) 

	var ray_origin := cam_main.project_ray_origin(aim_screen_pos)
	var ray_dir := cam_main.project_ray_normal(aim_screen_pos).normalized()
	var aim_point := ray_origin + ray_dir * aim_ray_length
	return (aim_point - root.global_transform.origin).normalized()
