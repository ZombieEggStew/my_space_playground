extends Node
class_name State

var parent_sm: StateMachine = null

var is_active := false

var player: PlayerShip = null

var ship: CharacterBody3D = null

func _ready() -> void:
	parent_sm = get_parent() as StateMachine

func setup(_player : PlayerShip , _ship : CharacterBody3D) -> void:
	player = _player
	ship = _ship


func enter(_prev_state: int = 0) -> void:
	is_active = true
	print("Entering state: " + str(self))

func exit(_next_state: int = 0) -> void:
	is_active = false

func physics_update(_delta: float) -> void:
	if not is_active:
		return





