extends EngineModule
class_name MoveControllerModule


@export var particle_speed: GPUParticles3D

# normal
var max_speed := 60.0
var forward_speed := 0.0
var forward_brake := 45.0
var forward_accel := 30.0
var boost_release_decel := 5.0
var engine_off_decel := 0.0     # 引擎关闭时的失速减速度


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

var base_smooth_factor := 10.0
var boost_smooth_factor := 20.0

var is_ship_rolling := true

var model_node: Node3D


func _ready() -> void:

	SignalBus.on_toggle_track_mouse.connect(_on_track_mouse_change)

	SignalBus.on_toggle_engine.connect(_on_engine_toggle)

	model_node = root.get_model_node()
	if model_node == null:
		Log.log_missing_component(self , "model node")
		queue_free()

	is_engine_on = true

func get_rotation_speed() -> Vector2:
	return Vector2(_yaw_speed, _pitch_speed)

func _on_track_mouse_change(enable: bool) -> void:
	auto_track_enabled = enable


func _on_engine_toggle() -> void:
	is_engine_on = not is_engine_on

@export var turn_curve: Curve

func handle_move(delta: float) -> void:
	var is_forward_pressed := Input.is_action_pressed("forward")
	var is_backward_pressed := Input.is_action_pressed("backward")
	
	var is_boosting :bool = booster_module.is_boosting if booster_module else false
	var direction := -root.global_transform.basis.z.normalized()

	# 如果引擎开启，则更新速度和方向
	if is_engine_on:
		var boost_speed : float = booster_module.boost_speed if booster_module else max_speed
		var boost_accel : float = booster_module.boost_accel if booster_module else forward_accel

		var target_max_speed := boost_speed if is_boosting else max_speed
		var accel_rate := boost_accel if is_boosting else forward_accel as float

		if is_backward_pressed:
			forward_speed = move_toward(forward_speed, 0.0, forward_brake * delta)
		elif is_forward_pressed:
			forward_speed = move_toward(forward_speed, target_max_speed, accel_rate * delta)
		elif is_boosting and forward_speed > 0.0:
			forward_speed = move_toward(forward_speed, boost_speed, boost_accel * delta)
		elif not is_boosting and forward_speed > max_speed:
			forward_speed = move_toward(forward_speed, max_speed, boost_release_decel * delta)

		var angle := root.velocity.normalized().angle_to(direction)
	

		var curve_factor = turn_curve.sample(angle / PI) # 从曲线中获取调整后的权重
	
		var factor := boost_smooth_factor if is_boosting else base_smooth_factor

		var new_dir : = root.velocity.normalized().slerp(direction , curve_factor * delta * factor)

		# 引擎开启时，保持速度方向跟随飞船朝向
		root.velocity = new_dir * forward_speed

	else:
		pass
		# 引擎关闭（环顾模式）：失速逻辑
		# if root.velocity.length() > 0.001:
		# 	var speed = root.velocity.length()
		# 	var new_speed = move_toward(speed, 0.0, engine_off_decel * delta)
		# 	root.velocity = root.velocity.normalized() * new_speed
			# # 同步更新 forward_speed，确保引擎重启时速度顺滑
			# forward_speed = new_speed

	_handle_rotation(delta)
	_handle_particle(is_boosting)

func _handle_rotation(delta: float) -> void:
	var roll_input := Input.get_axis("left", "right")
	# 飞船正面朝向改为 -Z
	var target_roll_rate := roll_input * roll_speed
	var roll_change_rate := roll_accel if abs(roll_input) > 0.001 else roll_decel
	roll_rate = move_toward(roll_rate, target_roll_rate, roll_change_rate * delta)

	if abs(roll_rate) > 0.0001:
		# 绕着本地 Z 轴旋转（现在 Z 轴是前后轴）
		root.rotate_object_local(Vector3.FORWARD, roll_rate * delta)

func _handle_particle(is_boosting : bool) -> void:
	# 更新粒子效果
	if particle_speed:
		# 设置 amount_ratio：速度为 100 时 ratio 为 1
		particle_speed.amount_ratio = clamp(forward_speed / 100.0, 0.0, 1.0)
		
		if is_boosting:
			particle_speed.emitting = false
		elif is_engine_on:
			particle_speed.emitting = true
		else:
			particle_speed.emitting = false

func track_mouse(delta: float) -> void:
	# if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
	# 	target_pitch = 0.0
	# 	target_yaw = 0.0
	# 	return
	
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
			target_pitch = -ny * max_pitch_speed


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
		# 使用 Basis 的旋转来设置模型倾斜，避免直接操作 rotation.z 导致的欧拉角问题
		# 偏航时侧倾
		model_node.rotation.z = _yaw_speed * 0.2
		# 俯仰时微调
		model_node.rotation.x = _pitch_speed * 0.1

	root.move_and_slide()
