extends State
class_name StateAttack


@export var fire_angle := 0.95
@export var stop_attack_dist := 1000.0
@export var damage := 10
@export var bullet_scene: PackedScene
@export var fire_rate := 0.15 # 射击间隔
@export var bullet_speed := 500.0

var fire_timer := 0.0

func enter(_prev: int = CombatSM.IDLE) -> void:
	super.enter(_prev)
	fire_timer = 0.0

func spawn_bullet( pos: Vector3, dir: Vector3, team_id: int, shooter: Node = null) -> void:
	if bullet_scene == null:
		return

	var bullet = bullet_scene.instantiate() as Node3D # 修改为 Node3D 以适配更多类型
	if bullet == null:
		return

	# 通常子弹应该加在场景根节点或专门的容器中，这里暂加在根级
	get_tree().root.add_child(bullet)

	if bullet.has_method("setup"):
		bullet.call("setup", damage ,pos, dir, team_id, shooter)

func physics_update(delta: float) -> void:
	if player == null or ship == null: 
		parent_sm.transition_to(CombatSM.IDLE)
		return
	
	var pos_diff = player.global_position - ship.global_position
	var dist = pos_diff.length()
	var forward = -ship.global_basis.z
	
	# 1. 射击预判逻辑 (弹速 500)
	var time_to_hit = dist / bullet_speed
	var lead_pos = player.global_position + (player.velocity * time_to_hit)
	var dir_to_lead = (lead_pos - ship.global_position).normalized()
	
	# 2. 判断是否满足射击角度 (机头指向预判点)
	var current_dot = forward.dot(dir_to_lead)
	
	if current_dot > fire_angle:
		fire_timer -= delta
		if fire_timer <= 0:
			spawn_bullet(ship.global_position + forward * 2.0, dir_to_lead, TeamID.ENEMY, ship)
			fire_timer = fire_rate
	
	# 3. 退出条件：如果玩家太远或角度偏差太大
	if dist > stop_attack_dist or current_dot < 0.7:
		parent_sm.transition_to(CombatSM.IDLE)

