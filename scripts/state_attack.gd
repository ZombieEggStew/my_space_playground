extends Node

@export var fire_interval := 0.35
@export var attack_range := 70.0
@export var eye_height := 1.0
@export var muzzle_forward_offset := 3.5
@export var bullet_spread_deg := 1.5
@export var lead_time := 0.15
@export_flags_3d_physics var visibility_collision_mask := 0xFFFFFFFF

var _parent_sm: Node = null
var _is_active := false
var _chase_active := false
var _ship: CharacterBody3D = null
var _player: CharacterBody3D = null
var _fire_cd := 0.0

func _ready() -> void:
	name = GameManager.attack_state_name
	_parent_sm = get_parent()
	_parent_sm.register_state(self)
	_cache_refs()

func enter(_prev_state_name: StringName = StringName("")) -> void:
	_is_active = true
	_cache_refs()
	_fire_cd = 0.0


func _process(delta: float) -> void:
	if not _is_active:
		return

	_fire_cd = maxf(_fire_cd - delta, 0.0)

	if not _chase_active:
		return

	if _ship == null or _player == null:
		_cache_refs()
		if _ship == null or _player == null:
			return

	if _fire_cd > 0.0:
		return

	if not _can_shoot_player():
		return

	_fire_once()
	_fire_cd = fire_interval


func exit(_next_state_name: StringName = StringName("")) -> void:
	_is_active = false


func set_chase_active(active: bool) -> void:
	_chase_active = active


func _cache_refs() -> void:
	if _ship == null and _parent_sm and _parent_sm.has_method("get_controlled_ship"):
		_ship = _parent_sm.get_controlled_ship()

	if _player == null and GameManager.instance:
		_player = GameManager.instance.get_player()


func _can_shoot_player() -> bool:
	if _ship == null or _player == null:
		return false

	var eye_pos := _ship.global_position + Vector3.UP * eye_height
	var player_pos := _player.global_position
	var to_player := player_pos - eye_pos

	if to_player.length_squared() > attack_range * attack_range:
		return false

	var query := PhysicsRayQueryParameters3D.create(eye_pos, player_pos)
	query.exclude = [_ship]
	query.collision_mask = visibility_collision_mask
	var hit := _ship.get_world_3d().direct_space_state.intersect_ray(query)

	if hit.is_empty():
		return true

	var collider := hit.get("collider") as Node
	if collider == null:
		return false

	return collider == _player or _player.is_ancestor_of(collider)


func _fire_once() -> void:
	if _ship == null or _player == null:
		return
	if GameManager.instance == null:
		return

	var muzzle_pos := _ship.global_position + _ship.global_transform.basis.z * muzzle_forward_offset

	var target_pos := _player.global_position
	if _player is CharacterBody3D:
		target_pos += (_player as CharacterBody3D).velocity * lead_time

	var dir := (target_pos - muzzle_pos).normalized()
	if dir == Vector3.ZERO:
		dir = _ship.global_transform.basis.z.normalized()

	var spread := deg_to_rad(bullet_spread_deg)
	if spread > 0.0:
		var right := _ship.global_transform.basis.x.normalized()
		var up := _ship.global_transform.basis.y.normalized()
		dir = (dir + right * randf_range(-spread, spread) + up * randf_range(-spread, spread)).normalized()

	GameManager.instance.spawn_bullet(muzzle_pos, dir, GameManager.TEAM_ENEMY, _ship)
