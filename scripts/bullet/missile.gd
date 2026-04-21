extends Bullet
class_name Missile_1


var _locked_target: AbleToBeLocked = null

@export_group("Missile Physics")
@export var turn_speed: float = 3.0      # 基础由于转弯半径导致的转向速度
@export var acceleration: float = 100.0    # 加速度
@export var max_speed: float = 500.0     # 最高航速
@export var start_delay: float = 0.5     # 点火延迟
@export var navigation_constant: float = 4.0 # 比例导引 N 值：值越大，导弹响应越快，转弯越狠

var _current_speed: float = 0.0 # 初始初速
var _last_los: Vector3 = Vector3.ZERO # 上一帧的视线向量


func set_velocity(_velocity: Vector3) -> Bullet:
	_current_speed = _velocity.length()

	return self

# 默认设置
func _enter_tree() -> void:
	damage = 100
	max_lifetime = 15.0
	destroy_on_hit = true
	team_id = TeamID.NEUTRAL 


func set_target(target: AbleToBeLocked) -> Bullet:
	_locked_target = target
	return self

func _physics_process(delta: float) -> void:

	# 1. 速度逻辑：逐渐加速
	_current_speed = move_toward(_current_speed, max_speed, acceleration * delta)
	
	# 2. 追踪引导逻辑
	if timer.wait_time - timer.time_left > start_delay and is_instance_valid(_locked_target):
		_guide_towards_target(delta)

	# 3. 位移逻辑
	var move_step := move_dir * _current_speed * delta
	_check_ray_collision(move_step)
	
	if is_instance_valid(self):
		global_position += move_step
		# 导弹朝向随移动方向改变
		if move_dir.length() > 0.01:
			look_at(global_position + move_dir, Vector3.UP)



func _guide_towards_target(delta: float) -> void:
	if not is_instance_valid(_locked_target): return
	
	var target_pos = _locked_target.global_position
	# 1. 计算当前的视线向量 (Line of Sight, LOS)
	var los := (target_pos - global_position).normalized()
	
	# 2. 计算视线变化率 (LOS Rate)
	if _last_los == Vector3.ZERO:
		_last_los = los
		
	var los_rate := (los - _last_los) / delta
	_last_los = los
	
	# 3. 比例导引逻辑：计算向心加速度修正量
	# 比例导引公式：加速度 = N * 视线变化率
	var lateral_correction := los_rate * navigation_constant
	
	# 4. 更新移动方向 (move_dir)
	# 将修正量叠加到当前方向，并限制其最大转向速率以符合导弹物理性能
	var next_dir := (move_dir + lateral_correction * delta).normalized()
	
	# 计算转向角以应用 turn_speed 限制
	var angle_to_next = move_dir.angle_to(next_dir)
	if angle_to_next > 0.001:
		var max_angle = turn_speed * delta
		var t = min(1.0, max_angle / angle_to_next)
		move_dir = move_dir.slerp(next_dir, t).normalized()
	else:
		move_dir = next_dir
