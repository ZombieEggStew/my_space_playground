extends Area3D
class_name Bullet

var timer : Timer

const MASK_WORLD := 1 << 7         # 第8层
const MASK_PLAYER_HURT := 1 << 8   # 第9层
const MASK_NEUTRAL_HURT := 1 << 9  # 第10层
const MASK_ENEMY_HURT := 1 << 10   # 第11层


var move_dir: Vector3 = Vector3.ZERO
var _shooter: Node = null

var damage := 10
var speed :int = 500
var max_lifetime := 10.0
var destroy_on_hit := true
var team_id : int = TeamID.NEUTRAL

func _ready():
	area_entered.connect(_on_area_entered)

func set_speed(_speed: int) -> Bullet:
	speed = _speed
	return self
func set_damage(_damage: int) -> Bullet:
	damage = _damage
	return self

func setup(pos: Vector3, dir: Vector3, _team_id: int , shooter: Node = null) -> Bullet:
	global_position = pos
	move_dir = dir.normalized()
	team_id = _team_id
	_shooter = shooter
	timer = Timer.new()
	add_child(timer)
	timer.one_shot = true
	timer.wait_time = max_lifetime
	timer.start()
	timer.timeout.connect(_on_lifetime_timeout)
	
	look_at(pos + dir, Vector3.UP)
	
	# 动态分配 Collision Mask
	var new_mask := MASK_WORLD | MASK_NEUTRAL_HURT # 默认都能撞墙和中立单位
	
	match team_id:
		TeamID.PLAYER:
			# 玩家：关闭友伤，只撞敌人
			new_mask |= MASK_ENEMY_HURT
		TeamID.ENEMY:
			# 敌人：开启友伤，撞玩家也撞自己人（敌方单位）
			new_mask |= MASK_PLAYER_HURT | MASK_ENEMY_HURT
		TeamID.NEUTRAL:
			# 中立：撞所有人
			new_mask |= MASK_PLAYER_HURT | MASK_ENEMY_HURT
			
	collision_mask = new_mask

	return self

func get_team_id() -> int:
	return team_id

func _on_lifetime_timeout() -> void:
	queue_free()


func _check_ray_collision(move_step: Vector3) -> void:
	var space_state := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(global_position, global_position + move_step, collision_mask)
	
	# 排除自身和发射者
	query.exclude = [get_rid()]
	if is_instance_valid(_shooter):
		# 如果 _shooter 是 CollisionObject3D，则排除其 RID
		if _shooter is CollisionObject3D:
			query.exclude.append(_shooter.get_rid())
	
	# 启用区域检测（因为子弹可能需要击中 Area3D）
	query.collide_with_areas = true
	query.collide_with_bodies = true
	
	var result := space_state.intersect_ray(query)
	if result:
		# 强制移动到碰撞点，避免穿透效果
		global_position = result.position
		_try_handle_hit(result.collider)


func _on_area_entered(area: Area3D) -> void:
	_try_handle_hit(area)


func _try_handle_hit(collider: Node) -> void:
	var collider_team := _extract_team_id(collider)
	_handle_hit(collider_team, collider)

	if destroy_on_hit:
		queue_free()


func _extract_team_id(collider: Node) -> int:
	if collider.has_method("get_team_id"):
		return int(collider.call("get_team_id"))

	var self_team = collider.get("team_id")
	if self_team != null:
		return int(self_team)

	var parent := collider.get_parent()
	if parent and parent is Node:
		if parent.has_method("get_team_id"):
			return int(parent.call("get_team_id"))
		var parent_team = parent.get("team_id")
		if parent_team != null:
			return int(parent_team)

	return TeamID.NEUTRAL


func _handle_hit(collider_team: int, collider: Node) -> void:
	if team_id == TeamID.ENEMY and collider_team == TeamID.PLAYER:
		print("Enemy hit player: ", collider.name)
	elif team_id == TeamID.PLAYER and collider_team == TeamID.ENEMY:
		GameManager.audio_manager.play_hit_sound()
	elif team_id == TeamID.ENEMY and collider_team == TeamID.ENEMY:
		print("Enemy friendly fire: ", collider.name)

	var health = collider as HealthComponent

	if health:
		health.take_damage(damage)
