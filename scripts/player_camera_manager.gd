extends Module


@export var cam_spring_arm: SpringArm3D 
@export var cam_pivot: Node3D
@export var model_node: Node3D	
@export var collision_shape: CollisionShape3D

# 自动追踪参数
var auto_track_enabled := true
var max_yaw_speed := 3.0      # rad/s
var max_pitch_speed := 2.0    # rad/s
var target_yaw := 0.0
var target_pitch := 0.0
var _yaw_speed := 0.0
var _pitch_speed := 0.0

var _base_collision_shape_rotation := Vector3.ZERO

var smooth_factor := 10.0     # 越大越“跟手”

var mouse_sensitivity := 0.01
# 运镜
var is_cam_move := true
var is_ship_rolling := true


func _ready() -> void:
	_base_collision_shape_rotation = collision_shape.rotation
	SignalBus.on_player_boost.connect(on_player_boost)

func _input(event: InputEvent) -> void:
	handle_actions()
	handle_mouse_move(event)

func _process(_delta: float) -> void:
	pass


func _physics_process(delta: float) -> void:
	track_mouse(delta)

	var t := 1.0 - exp(-smooth_factor * delta)
	_yaw_speed = lerp(_yaw_speed, target_yaw, t)
	_pitch_speed = lerp(_pitch_speed, target_pitch, t)
	root.rotate_object_local(Vector3.UP, _yaw_speed * delta)
	root.rotate_object_local(Vector3.RIGHT, _pitch_speed * delta)


	if is_cam_move:
		cam_pivot.position.x = _yaw_speed * 2
		cam_pivot.position.z = _pitch_speed * 1
	if is_ship_rolling:
		model_node.rotation.z = -_yaw_speed * 0.3
		collision_shape.rotation.z = _base_collision_shape_rotation.z + model_node.rotation.z

		model_node.rotation.x = _pitch_speed * 0.1
		collision_shape.rotation.x = _base_collision_shape_rotation.x + model_node.rotation.x


func track_mouse(delta: float) -> void:
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		return
	if auto_track_enabled:
		var viewport_size = get_viewport().get_visible_rect().size
		var center = viewport_size * 0.5
		
		var mouse_pos = get_viewport().get_mouse_position()

		var offset = mouse_pos - center

		# 死区：鼠标接近中心时不转，避免抖动
		if offset.length() <= PlayerInfo.dead_zone_px:
			var t_stop = 1.0 - exp(-smooth_factor * delta)
			_yaw_speed = lerp(_yaw_speed, 0.0, t_stop)
			_pitch_speed = lerp(_pitch_speed, 0.0, t_stop)
		else:
			# 归一化到 [-1, 1]
			var nx = clamp(offset.x / max(center.x, 1.0), -1.0, 1.0)
			var ny = clamp(offset.y / max(center.y, 1.0), -1.0, 1.0)

			target_yaw = -nx * max_yaw_speed
			target_pitch = ny * max_pitch_speed


	else:
		target_pitch = 0.0
		target_yaw = 0.0

func handle_mouse_move(event: InputEvent) -> void:
	if event is not InputEventMouseMotion: return

	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED: return
		
	# 取消鼠标追踪后的校正
	var mouse_delta = event.relative
	root.rotate_object_local(Vector3.UP, -mouse_delta.x * mouse_sensitivity)
	root.rotate_object_local(Vector3.RIGHT, mouse_delta.y * mouse_sensitivity)
	

func handle_actions() -> void:
	if Input.is_action_just_pressed("look_backward"):
		auto_track_enabled = false
		look_backward()
	if Input.is_action_just_released("look_backward"):
		auto_track_enabled = true
		stop_look_backward()
	if Input.is_action_just_pressed("toggle_track"):
		auto_track_enabled = not auto_track_enabled

func look_backward() -> void:
	cam_spring_arm.on_look_backward(true)

func stop_look_backward() -> void:
	cam_spring_arm.on_look_backward(false)

func on_player_boost(enable: bool) -> void:
	cam_spring_arm.on_boosting(enable)
