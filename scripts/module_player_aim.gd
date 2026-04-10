#TO DO : 目标太远断开锁定

extends Module
class_name BasicAimModule
var cam_main: Camera3D
var use_occlusion_check := true

var hovered_target: AbleToBeLocked
var locked_target: AbleToBeLocked
@export var crosshair_container : CanvasLayer

@export var crosshair_2: Node2D #绿色 二级锁定
@export var crosshair_3: Node2D #绿色 十字准心


@export var indicator_margin := 32.0


var aim_ray_length := 5000.0 #非锁定时使用，预测射击点

# 机炮最大转向角度
var aim_dead_zone_px := 64.0

var crosshair_2_detect_radius := 128.0

func _ready() -> void:
	SignalBus.on_lockable_target_init.connect(init_crosshair_1)

	cam_main = root.get_main_camera()

func _process(_delta: float) -> void:
	handle_targets()
	handle_hover()
	handle_cross_hair_2()
	handle_cross_hair_3()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		if hovered_target != null:
			locked_target = hovered_target

		# else:
		# 	locked_target = null

func init_crosshair_1(crosshair:Node) -> void:
	crosshair_container.add_child(crosshair)

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
		[self, cam_main]
	)
	var hit := space_state.intersect_ray(query)
	if hit.is_empty():
		return true

	var collider := hit.get("collider") as Node
	if collider == null:
		return false
	return collider == target or target.is_ancestor_of(collider)

func handle_targets():
	for target in LockManager.targetable_objects:
		var target_node := target.target_node3d
		target.world_pos = target_node.global_transform.origin + target.get_pivot_offset() as Vector3
		target.distance_to_player = root.global_position.distance_to(target.world_pos)
		var is_visible := _is_enemy_visible_from_camera(target_node)
		target.is_visible = is_visible

		if is_visible:
			target.screen_pos = cam_main.unproject_position(target.world_pos)

func handle_hover():
	if locked_target != null:
		hovered_target = null
		return

	var mouse_pos = get_viewport().get_mouse_position()

	var min_dist = crosshair_2_detect_radius
	
	for target in LockManager.targetable_objects:
		if not target.is_visible:
			continue
		
		var dist = mouse_pos.distance_to(target.screen_pos)
		if dist < min_dist:
			min_dist = dist

			hovered_target = target

		else:
			hovered_target = null

func handle_locked_target():
	if locked_target == null:
		return

	var world_pos := locked_target.world_pos

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
	
func handle_hoverd_target():
	if locked_target != null:
		return
	if hovered_target != null:
		crosshair_2.set_target_pos(hovered_target.screen_pos)
	else:
		crosshair_2.reset()

func handle_cross_hair_2():
	handle_locked_target()
	handle_hoverd_target()

func handle_cross_hair_3():
	if crosshair_3 == null:
		return
	
	var mouse_pos = get_viewport().get_mouse_position()
	crosshair_3.update_from_mouse(mouse_pos, aim_dead_zone_px, true)
	
func _get_crosshair3_screen_pos() -> Vector2:
	if crosshair_3 and crosshair_3.visible:
		return crosshair_3.position  
	else:
		return get_viewport().get_mouse_position()

func get_aim_direction_from_crosshair() -> Vector3:
	if locked_target:
		aim_ray_length = locked_target.distance_to_player

	var aim_screen_pos := _get_crosshair3_screen_pos()
	var ray_origin := cam_main.project_ray_origin(aim_screen_pos)
	var ray_dir := cam_main.project_ray_normal(aim_screen_pos).normalized()
	var aim_point := ray_origin + ray_dir * aim_ray_length
	return (aim_point - root.global_transform.origin).normalized()
