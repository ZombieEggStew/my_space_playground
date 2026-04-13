class_name StatePatrol
extends StateBase

var patrol_speed := 8.0
var min_change_interval := 1.0
var max_change_interval := 2.5

var detect_range := 80.0
var detect_fov_deg := 90.0
var eye_height := 1.0
@export_flags_3d_physics var visibility_collision_mask := 0xFFFFFFFF
@export var debug_draw_enabled := false
@export var debug_color := Color(0.1, 1.0, 0.2, 0.2)
 
@export_range(6, 128, 1) var debug_segments := 28 # 扇形 细分

var _current_dir := Vector3.FORWARD
var _change_timer := 0.0

var _debug_root: Node3D = null
var _debug_mesh_instance: MeshInstance3D = null
var _debug_material: StandardMaterial3D = null

func _ready() -> void:
	super()
	name = State.patrol_state_name

	randomize()

	_pick_next_direction()
	_update_debug_visual(true)


func enter(_prev_state_name: StringName = StringName("")) -> void:
	super(_prev_state_name) 
	_pick_next_direction()


func exit(_next_state_name: StringName = StringName("")) -> void:
	super(_next_state_name)
	parent_sm.set_desired_velocity(Vector3.ZERO)

func _process(delta: float) -> void:
	super(delta)
	_update_debug_visual(false)


func physics_update(delta: float) -> void:
	super(delta)

	if _can_see_player():
		print("Player detected, switching to chase state")
		parent_sm.transition_to(State.chase_state_name)
		return

	_change_timer -= delta
	if _change_timer <= 0.0:
		_pick_next_direction()

	var desired := _current_dir * patrol_speed
	desired.y = 0.0

	parent_sm.set_desired_velocity(desired)
	


func _can_see_player() -> bool:
	#距离
	var eye_pos := ship.global_position + Vector3.UP * eye_height
	var target_pos := player.global_position
	var to_target := target_pos - eye_pos

	if to_target.length_squared() > detect_range * detect_range:
		return false

	#视野
	# var forward := (_ship.global_transform.basis.z).normalized()
	# var dir_to_target := to_target.normalized()
	# var min_dot := cos(deg_to_rad(detect_fov_deg * 0.5))
	# if forward.dot(dir_to_target) < min_dot:
	# 	return false

	#遮挡物
	var query := PhysicsRayQueryParameters3D.create(eye_pos, target_pos)
	query.exclude = [ship]
	query.collision_mask = visibility_collision_mask
	var hit := ship.get_world_3d().direct_space_state.intersect_ray(query)

	if hit.is_empty():
		return true

	var collider := hit.get("collider") as Node
	if collider == null:
		return false

	return collider == player or player.is_ancestor_of(collider)


func _pick_next_direction() -> void:
	_change_timer = randf_range(min_change_interval, max_change_interval)
	var x := randf_range(-1.0, 1.0)
	var z := randf_range(-1.0, 1.0)
	var next_dir := Vector3(x, 0.0, z)
	if next_dir.length() < 0.01:
		next_dir = Vector3.FORWARD
	_current_dir = next_dir.normalized()


func _should_show_debug() -> bool:
	return debug_draw_enabled




func _ensure_debug_nodes(ship_node: Node3D) -> void:
	if ship_node == null:
		return

	if not is_instance_valid(_debug_root) or _debug_root.get_parent() != ship_node:
		if is_instance_valid(_debug_root):
			_debug_root.queue_free()

		_debug_root = Node3D.new()
		_debug_root.name = "DetectionDebug"
		ship_node.add_child(_debug_root)

	if not is_instance_valid(_debug_mesh_instance):
		_debug_mesh_instance = MeshInstance3D.new()
		_debug_mesh_instance.name = "DetectionCone"
		_debug_root.add_child(_debug_mesh_instance)

	if _debug_material == null:
		_debug_material = StandardMaterial3D.new()
		_debug_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_debug_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_debug_material.cull_mode = BaseMaterial3D.CULL_DISABLED
		_debug_material.albedo_color = debug_color


func _hide_debug_nodes() -> void:
	if is_instance_valid(_debug_root):
		_debug_root.visible = false


func _update_debug_visual(force_rebuild: bool) -> void:
	if not _should_show_debug():
		_hide_debug_nodes()
		return


	_ensure_debug_nodes(ship)
	if not is_instance_valid(_debug_root) or not is_instance_valid(_debug_mesh_instance):
		return

	_debug_root.visible = true
	_debug_root.position = Vector3(0.0, eye_height, 0.0)

	if _debug_material:
		_debug_material.albedo_color = debug_color

	if force_rebuild or _debug_mesh_instance.mesh == null:
		_debug_mesh_instance.mesh = _build_detection_mesh()
	else:
		_debug_mesh_instance.mesh = _build_detection_mesh()

	if _debug_mesh_instance.material_override == null and _debug_material:
		_debug_mesh_instance.material_override = _debug_material


func _build_detection_mesh() -> Mesh:
	var mesh := ImmediateMesh.new()
	var half_fov := deg_to_rad(detect_fov_deg * 0.5)
	var seg_count := maxi(debug_segments, 6)
	var step := (half_fov * 2.0) / float(seg_count)

	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES, _debug_material)
	for i in range(seg_count):
		var a0 := -half_fov + step * float(i)
		var a1 := a0 + step
		var p0 := Vector3(sin(a0), 0.0, cos(a0)) * detect_range
		var p1 := Vector3(sin(a1), 0.0, cos(a1)) * detect_range
		mesh.surface_add_vertex(Vector3.ZERO)
		mesh.surface_add_vertex(p0)
		mesh.surface_add_vertex(p1)
	mesh.surface_end()

	return mesh
