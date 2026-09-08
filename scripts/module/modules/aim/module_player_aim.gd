#TO DO : 目标太远断开锁定

extends Module
class_name BasicAimModule

@export var aim_view: AimView

var cam_main: Camera3D
var use_occlusion_check := true

var hovered_target: AbleToBeLocked 
var locked_target: AbleToBeLocked

var aim_ray_length := 5000.0 #非锁定时使用，预测射击点


func _ready() -> void:
	SignalBus.on_player_try_lock.connect(_handle_lock_action)
	# P3:悬停事件经 SignalBus 从 TargetReticle 转发,本模块不再直接持有/生成目标 UI
	SignalBus.on_target_hovered.connect(_on_mouse_enter_target)
	SignalBus.on_target_unhovered.connect(_on_mouse_exit_target)
	# Bug 4:目标死亡/离开场景树时清掉悬挂引用
	SignalBus.on_lockable_target_died.connect(_on_target_died)

	cam_main = root.get_main_camera()
	if cam_main == null:
		Log.log_missing_component(self,"main camera")
		queue_free()


func _handle_lock_action():
	if hovered_target != null:
		set_locked_target(hovered_target)
		print("Locked target: %s" % hovered_target.name)
	else:
		set_locked_target(null)

func _on_mouse_enter_target(target: AbleToBeLocked) -> void:
	hovered_target = target
	if aim_view:
		aim_view.set_hovered_target(target)

func _on_mouse_exit_target() -> void:
	hovered_target = null
	if aim_view:
		aim_view.set_hovered_target(null)

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
	SignalBus.on_player_lock_target.emit(target)

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
