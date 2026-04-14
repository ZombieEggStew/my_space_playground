extends MoveModule



var particle_speed_up: GPUParticles3D

# normal
var max_speed := 40.0
var forward_speed := 0.0
var forward_brake := 45.0
var forward_accel := 30.0
var boost_release_decel := 60.0

# boost
var _is_boosting := false
var boost_speed := 100.0
var boost_accel := 120.0

# roll
var roll_speed := 1  # 最大滚转角速度（rad/s）
var roll_accel := 3.0  # 按下 left/right 时的滚转加速度（rad/s^2）
var roll_decel := 2.0  # 松开按键后的滚转减速度（rad/s^2）
var roll_rate := 0.0

# track mouse
var auto_track_enabled := true
var smooth_factor := 10.0     # 越大越“跟手”

var max_yaw_speed := 3.0      # rad/s
var max_pitch_speed := 2.0    # rad/s
var target_yaw := 0.0
var target_pitch := 0.0
var _yaw_speed := 0.0
var _pitch_speed := 0.0

var is_ship_rolling := true

var model_node: Node3D

var is_looking_around := false

func _ready() -> void:
	particle_speed_up = root.get_boost_particle()
	SignalBus.on_track_mouse_change.connect(_on_track_mouse_change)
	SignalBus.on_player_look_backward.connect(_on_look_backward_change)
	SignalBus.on_player_boost.connect(_handle_boost_input)
	SignalBus.on_player_look_around.connect(_on_look_around_change)
	if particle_speed_up == null:
		log_missing_component("boost particle")
		queue_free()
	model_node = root.get_model_node()
	if model_node == null:
		log_missing_component("model node")
		queue_free()

func get_rotation_speed() -> Vector2:
	return Vector2(_yaw_speed, _pitch_speed)

func _on_track_mouse_change(enable: bool) -> void:
	auto_track_enabled = enable

func _on_look_backward_change(enable: bool) -> void:
	auto_track_enabled = not enable

func _on_look_around_change(enable: bool) -> void:
	SignalBus.on_track_mouse_change.emit(not enable)
	is_looking_around = enable

func _handle_boost_input(enable: bool) -> void:
	if enable:
		speed_up()
	else:
		stop_speed_up()

func speed_up() -> void:
	particle_speed_up.emitting = true
	_is_boosting = true

func stop_speed_up() -> void:
	particle_speed_up.emitting = false
	_is_boosting = false


func handle_move(delta: float) -> void:
	var is_forward_pressed := Input.is_action_pressed("forward")
	var is_backward_pressed := Input.is_action_pressed("backward")
	var target_max_speed := boost_speed if _is_boosting else max_speed
	var accel_rate := boost_accel if _is_boosting else forward_accel as float

	if is_backward_pressed:
		forward_speed = move_toward(forward_speed, 0.0, forward_brake * delta)
	elif is_forward_pressed:
		forward_speed = move_toward(forward_speed, target_max_speed, accel_rate * delta)
	elif _is_boosting and forward_speed > 0.0:
		# Boost while cruising quickly ramps to boost speed even without holding W.
		forward_speed = move_toward(forward_speed, boost_speed, boost_accel * delta)
	elif not _is_boosting and forward_speed > max_speed:
		# On boost release, fall back to max cruise speed.
		forward_speed = move_toward(forward_speed, max_speed, boost_release_decel * delta)

	var roll_input := Input.get_axis("left", "right")
	var direction := (root.transform.basis * Vector3(0.0, 0.0, 1.0)).normalized()
	var target_roll_rate := roll_input * roll_speed
	var roll_change_rate := roll_accel if abs(roll_input) > 0.001 else roll_decel
	roll_rate = move_toward(roll_rate, target_roll_rate, roll_change_rate * delta)

	if abs(roll_rate) > 0.0001:
		root.rotate_object_local(Vector3.BACK, roll_rate * delta)


	root.velocity.x = direction.x * forward_speed
	root.velocity.y = direction.y * forward_speed
	root.velocity.z = direction.z * forward_speed


func track_mouse(delta: float) -> void:
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED or is_looking_around:
		target_pitch = 0.0
		target_yaw = 0.0
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

func _physics_process(delta: float) -> void:
	track_mouse(delta)
	handle_move(delta)

	var t := 1.0 - exp(-smooth_factor * delta)
	_yaw_speed = lerp(_yaw_speed, target_yaw, t)
	_pitch_speed = lerp(_pitch_speed, target_pitch, t)
	root.rotate_object_local(Vector3.UP, _yaw_speed * delta)
	root.rotate_object_local(Vector3.RIGHT, _pitch_speed * delta)


	if is_ship_rolling:
		model_node.rotation.z = - _yaw_speed * 0.2

		model_node.rotation.x = _pitch_speed * 0.1

	root.move_and_slide()
