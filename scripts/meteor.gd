extends GPUParticles3D

var speed: float = 50.0
var direction: Vector3 = Vector3.BACK

func _ready():
	# 确保粒子在世界空间发射，这样移动时会留下轨迹
	fixed_fps = 0
	interpolate = true
	fract_delta = true
	local_coords = false
	
	# 随机化方向和速度
	direction = Vector3(randf_range(-1, 1), randf_range(-1, 0), randf_range(-1, 1)).normalized()
	speed = randf_range(40.0, 80.0)
	
	# 设置朝向
	if direction != Vector3.ZERO:
		look_at(global_position + direction)
	
	# 自动销毁
	get_tree().create_timer(lifetime).timeout.connect(queue_free)

func _process(delta):
	global_position += direction * speed * delta
