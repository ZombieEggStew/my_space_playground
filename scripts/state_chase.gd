class_name StateChase
extends StateBase

var chase_speed := 16.0
var stop_distance := 40.0
var give_up_distance := 10000
var lost_target_timeout := 1.2

var _lost_timer := 0.0

var _combat_sm: Node = null

func _ready() -> void:
	super()
	name = State.chase_state_name

func enter(_prev_state_name: StringName = StringName("")) -> void:
	super(_prev_state_name)

	_lost_timer = 0.0

	_cache_combat_sm()
	_set_attack_enabled(true)


func exit(_next_state_name: StringName = StringName("")) -> void:
	super(_next_state_name)
	
	parent_sm.set_desired_velocity(Vector3.ZERO)
	_set_attack_enabled(false)


func physics_update(delta: float) -> void:
	super(delta)

	if ship == null or player == null:
		parent_sm.transition_to(&"patrol")
		return

	var to_player := player.global_position - ship.global_position
	var dist := to_player.length()

	if dist > give_up_distance:
		_lost_timer += delta
		if _lost_timer >= lost_target_timeout:
			parent_sm.transition_to(&"patrol")
			return
	else:
		_lost_timer = 0.0

	if dist <= stop_distance:
		parent_sm.set_desired_velocity(Vector3.ZERO)
		_cache_combat_sm()
		if _combat_sm and _combat_sm.has_method("transition_to"):
			_combat_sm.transition_to(State.attack_state_name)
		return

	if dist <= 0.001:
		parent_sm.set_desired_velocity(Vector3.ZERO)
		return

	var desired := to_player.normalized() * chase_speed
	parent_sm.set_desired_velocity(desired)



func _cache_combat_sm() -> void:
	if _combat_sm:
		return
	if ship == null:
		return
	var combat = ship.get("combat_sm")
	if combat is Node:
		_combat_sm = combat


func _set_attack_enabled(enabled: bool) -> void:
	_cache_combat_sm()
	if _combat_sm == null or not _combat_sm.has_method("get_state_by_name"):
		return
	var attack_state = _combat_sm.get_state_by_name(State.attack_state_name)
	if attack_state and attack_state.has_method("set_chase_active"):
		attack_state.set_chase_active(enabled)
