extends Node
class_name StateMachine

var controlled_ship: CharacterBody3D = null

var current_state: Node = null

var state_by_name: Dictionary = {}

var initial_state: StringName = State.default_state_name

func _ready() -> void:
	if initial_state:
		transition_to(initial_state)

func set_controlled_ship(ship: CharacterBody3D) -> void:
	controlled_ship = ship

func get_controlled_ship() -> CharacterBody3D:
	return controlled_ship

func register_state(state: Node) -> void:
	state_by_name[state.name] = state


func get_state_by_name(state_name: StringName) -> Node:
	return state_by_name.get(state_name, null)


func transition_to(next_state_name: StringName) -> void:
	if next_state_name == State.default_state_name:
		push_error("Cannot transition to default state. Please set a valid initial state.")
		return

	var next_state: Node = get_state_by_name(next_state_name)
	if next_state == null:
		next_state = get_node_or_null(NodePath(String(next_state_name)))
		if next_state:
			register_state(next_state)

	if current_state == next_state:
		return

	var prev_state_name: StringName = StringName("")
	if current_state:
		prev_state_name = current_state.name
		current_state.exit(next_state_name)

	current_state = next_state

	current_state.enter(prev_state_name)