extends Node
class_name StateBase

var state_name: StringName = State.default_state_name

var parent_sm: Node = null
var ship: CharacterBody3D = null
var player: CharacterBody3D = null
var is_active := false

func _ready() -> void:
    name = state_name
    parent_sm = get_parent()
    parent_sm.register_state(self)
    cache_refs()

func enter(_prev_state_name: StringName = StringName("")) -> void:
    is_active = true
    cache_refs()

func exit(_next_state_name: StringName = StringName("")) -> void:
    is_active = false

func _process(delta: float) -> void:
    if is_active:
        physics_update(delta)

func physics_update(_delta: float) -> void:
    cache_refs()

func cache_refs() -> void:
    if ship == null:
        ship = parent_sm.get_controlled_ship()
    if player == null:
        player = GameManager.player_instance

func cache_ship() -> void:
    if ship:
        return
    ship = parent_sm.get_controlled_ship()

func cache_player() -> void:
    if player:
        return
    player = GameManager.player_instance
