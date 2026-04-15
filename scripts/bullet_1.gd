extends Area3D

enum Team {
	NEUTRAL = 0,
	PLAYER = 1,
	ENEMY = 2,
}

@export var speed := 500.0
@export var max_lifetime := 10.0
@export var destroy_on_hit := true
@export var team_id := Team.NEUTRAL as int

var move_dir: Vector3 = Vector3.ZERO
var _alive_time := 0.0
var _shooter: Node = null

var damage := 10

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func get_team_id() -> int:
	return team_id


func setup(_damage:int,pos: Vector3, dir: Vector3, p_team_id: int = Team.NEUTRAL, shooter: Node = null) -> void:
	damage = _damage
	global_position = pos
	move_dir = dir.normalized()
	team_id = p_team_id
	_shooter = shooter
	_alive_time = 0.0
	look_at(pos + dir, Vector3.UP)

func _physics_process(delta: float) -> void:
	_alive_time += delta
	if _alive_time >= max_lifetime:
		queue_free()
		return

	global_position += move_dir * speed * delta


func _on_body_entered(body: Node) -> void:
	_try_handle_hit(body)


func _on_area_entered(area: Area3D) -> void:
	_try_handle_hit(area)


func _try_handle_hit(collider: Node) -> void:
	if _should_ignore_collider(collider):
		return

	var collider_team := _extract_team_id(collider)
	_print_hit_message(collider_team, collider)

	if destroy_on_hit:
		queue_free()


func _should_ignore_collider(collider: Node) -> bool:
	if collider == null:
		return true

	if is_instance_valid(_shooter) and collider == _shooter:
		return true

	var collider_team := _extract_team_id(collider)
	if team_id != Team.NEUTRAL and collider_team == team_id:
		return true

	return false


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

	return Team.NEUTRAL


func _print_hit_message(collider_team: int, collider: Node) -> void:
	if team_id == Team.ENEMY and collider_team == Team.PLAYER:
		print("Enemy hit player: ", collider.name)
		collider.call("hit", 10.0) # 直接调用接口造成伤害，后续可以改成发信号或者其他方式解耦
	elif team_id == Team.PLAYER and collider_team == Team.ENEMY:
		collider.call("hit", damage) # 直接调用接口造成伤害，后续可以改成发信号或者其他方式解耦
		GameManager.audio_manager.play_hit_sound()
