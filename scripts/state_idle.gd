extends Node


var _parent_sm: Node = null
var _is_active := false

func _ready() -> void:
	name = State.idle_state_name
	_parent_sm = get_parent()
	_parent_sm.register_state(self)

func enter(_prev_state_name: StringName = StringName("")) -> void:
	_is_active = true


func exit(_next_state_name: StringName = StringName("")) -> void:
	_is_active = false
