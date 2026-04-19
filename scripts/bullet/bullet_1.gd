extends Bullet
class_name LaserBullet

# 默认设置
func _enter_tree() -> void:
	damage = 10
	speed = 500
	max_lifetime = 10.0
	destroy_on_hit = true
	team_id = TeamID.NEUTRAL

func _physics_process(delta: float) -> void:

	var move_step := move_dir * speed * delta
	_check_ray_collision(move_step)
	
	if is_instance_valid(self): # 防止射线检测已经销毁了子弹
		global_position += move_step
