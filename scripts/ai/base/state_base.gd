extends Node
class_name StateBase

var parent_sm: CombatStateMachine = null
var ship: CharacterBody3D = null
var player: CharacterBody3D = null
var is_active := false

func _ready() -> void:
	parent_sm = get_parent() as CombatStateMachine
	if parent_sm:
		parent_sm.register_state(self)
	cache_refs()

func enter(_prev_state_name: StringName = &"") -> void:
	is_active = true
	cache_refs()

func exit(_next_state_name: StringName = &"") -> void:
	is_active = false

func physics_update(_delta: float) -> void:
	if not is_active:
		return
	cache_refs()

func cache_refs() -> void:
	if ship == null and parent_sm:
		ship = parent_sm.controlled_ship
	if player == null:
		player = GameManager.player_instance

