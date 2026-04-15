#TO DO : 目标太远断开锁定

extends Module
class_name BasicAimModule


var cam_main: Camera3D
var use_occlusion_check := true

var hovered_target: AbleToBeLocked 
var locked_target: AbleToBeLocked

var crosshair_2: Node #绿色 二级锁定


var indicator_margin := 32.0

var rader_module: RadarModule




var aim_ray_length := 5000.0 #非锁定时使用，预测射击点


func _ready() -> void:
	init_crosshair_2()

	SignalBus.on_player_try_lock.connect(_handle_lock_action)
	cam_main = root.get_main_camera()

	if cam_main == null:
		Log.log_missing_component(self,"main camera")
		queue_free()

	rader_module = modules_manager.get_radar_module()

	if rader_module == null:
		Log.log_missing_component(self,"RadarModule")
		queue_free()
	
	rader_module.on_target_found.connect(_spawn_ui_for_target)

func init_crosshair_2() -> void:
	crosshair_2 = GameManager.hud_manager.register_hud_static(Scenes.crosshair_2)

func _spawn_ui_for_target(target:AbleToBeLocked) -> void:
	init_crosshair_1_for_target(target)

	init_locked_target_hp_bar(target)


func init_crosshair_1_for_target(target:AbleToBeLocked) -> void:
	var crosshair_1 = GameManager.hud_manager.register_hud_static(Scenes.crosshair_1)
	crosshair_1.mouse_entered.connect(_on_mouse_enter_target)
	crosshair_1.mouse_exited.connect(_on_mouse_exit_target)

	crosshair_1.setup(target, root , cam_main) # 完成绑定

func init_locked_target_hp_bar(target:AbleToBeLocked) -> void:
	var hp_bar_target = GameManager.hud_manager.register_hud_static(Scenes.hp_bar_target_scene)
	hp_bar_target.setup(target , cam_main)
	

func _process(_delta: float) -> void:
	# handle_targets()
	handle_cross_hair_2()


func _handle_lock_action():
	if hovered_target != null:
		set_locked_target(hovered_target)
		print("Locked target: %s" % hovered_target.name)
	else:
		set_locked_target(null)

func _on_mouse_enter_target(target: AbleToBeLocked) -> void:
	hovered_target = target

func _on_mouse_exit_target() -> void:
	hovered_target = null

func set_locked_target(target: AbleToBeLocked) -> void:
	if target:
		target.set_locked(true)
	else:
		if locked_target:
			locked_target.set_locked(false)

	locked_target = target
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

# func handle_targets():
# 	for target in targets_found:
# 		var target_node := target.target_node3d
# 		target.world_pos = target_node.global_transform.origin + target.get_pivot_offset() as Vector3
# 		target.distance_to_player = root.global_position.distance_to(target.world_pos)
# 		var is_visible := _is_enemy_visible_from_camera(target_node)
# 		target.is_visible = is_visible


func handle_locked_target():
	if locked_target == null:
		return

	var world_pos := locked_target.global_position

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
	
func handle_cross_hair_2():
	if locked_target:
		handle_locked_target()
	elif hovered_target:
		crosshair_2.set_target_pos(cam_main.unproject_position(hovered_target.global_position))
	else:
		crosshair_2.reset()


func get_aim_direction_from_crosshair(aim_screen_pos:Vector2) -> Vector3:
	if locked_target:
		aim_ray_length = locked_target.global_position.distance_to(root.global_position) 

	var ray_origin := cam_main.project_ray_origin(aim_screen_pos)
	var ray_dir := cam_main.project_ray_normal(aim_screen_pos).normalized()
	var aim_point := ray_origin + ray_dir * aim_ray_length
	return (aim_point - root.global_transform.origin).normalized()
