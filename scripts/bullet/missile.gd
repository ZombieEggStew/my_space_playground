extends Bullet
class_name Missile_1


var _locked_target: Node3D = null

@export_group("Missile Physics")
@export var turn_speed: float = 3.0      # 转向速度（弧度/秒），决定转弯半径
@export var acceleration: float = 150.0  # 加速度
@export var max_speed: float = 200.0     # 最高航速
@export var start_delay: float = 0.5     # 点火延迟：延迟追踪，增加发射时的力量感

var _current_speed: float = 100.0 # 初始初速


# 默认设置
func _enter_tree() -> void:
	damage = 100
	max_lifetime = 15.0
	destroy_on_hit = true
	team_id = TeamID.NEUTRAL 


func set_target(target: Node3D) -> void:
	_locked_target = target


func _physics_process(delta: float) -> void:

	# 1. 速度逻辑：逐渐加速
	_current_speed = move_toward(_current_speed, max_speed, acceleration * delta)
	
	# 2. 追踪引导逻辑
	if max_lifetime > start_delay and is_instance_valid(_locked_target):
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
	var target_pos = _locked_target.global_position
	var target_dir = (target_pos - global_position).normalized()
	
	# 计算当前方向与目标方向的夹角
	var angle_to_target = move_dir.angle_to(target_dir)
	if angle_to_target < 0.001:
		return
		
	# 限制每帧最大转动角度，产生“转弯半径”效果
	var max_angle = turn_speed * delta
	var t = min(1.0, max_angle / angle_to_target)
	
	# 使用球形插值平滑转向
	var current_basis = Basis.looking_at(move_dir)
	var target_basis = Basis.looking_at(target_dir)
	var next_basis = Basis(Quaternion(current_basis).slerp(Quaternion(target_basis), t))
	
	move_dir = -next_basis.z # Basis.looking_at 默认前方是 -Z
