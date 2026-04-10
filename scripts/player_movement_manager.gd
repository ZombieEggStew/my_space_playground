extends Module



@export var particle_speed_up: GPUParticles3D

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



func speed_up() -> void:
	particle_speed_up.emitting = true
	_is_boosting = true
	SignalBus.on_player_boost.emit(true)

func stop_speed_up() -> void:
	particle_speed_up.emitting = false
	_is_boosting = false
	SignalBus.on_player_boost.emit(false)


func handle_speed_change() -> void:
	if Input.is_action_just_pressed("speed_up"):
		speed_up()
	if Input.is_action_just_released("speed_up"):
		stop_speed_up()


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


func _physics_process(delta: float) -> void:

	handle_speed_change()

	handle_move(delta)

	root.move_and_slide()