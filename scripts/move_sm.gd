extends StateMachine
class_name MoveSM

var _desired_velocity := Vector3.ZERO

func get_desired_velocity() -> Vector3:
	return _desired_velocity

func set_desired_velocity(v: Vector3) -> void:
	_desired_velocity = v

func _init() -> void:
	initial_state = State.patrol_state_name

