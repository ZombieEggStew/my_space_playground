extends Node3D

@export var meteor_scene: PackedScene
@export var spawn_radius: float = 100.0  # 流星生成在玩家周围的范围
@export var spawn_interval: float = 1.0  # 生成频率
var player_node: Node3D         # 绑定玩家，围绕玩家生成

var timer: float = 0.0

func _process(delta):
	timer += delta
	if timer >= spawn_interval:
		timer = 0
		spawn_meteor()

func spawn_meteor():
	player_node = GameManager.get_current_player()
	if not meteor_scene: return
	
	var meteor = meteor_scene.instantiate()
	var spawn_pos = Vector3.ZERO
	
	if player_node:
		# 在玩家前方随机位置生成
		var random_offset = Vector3(
			randf_range(-spawn_radius, spawn_radius),
			randf_range(20, spawn_radius), # 从上方生成
			randf_range(-spawn_radius, spawn_radius)
		)
		spawn_pos = player_node.global_position + random_offset
	else:
		spawn_pos = Vector3(randf_range(-50, 50), 50, randf_range(-50, 50))
		
	meteor.global_position = spawn_pos
	add_child(meteor)
