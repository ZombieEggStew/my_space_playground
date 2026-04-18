extends SpringArm3D

var spring_arm_boost_z := -10.0  # 加速时 SpringArm 的目标 Z 偏移
var spring_arm_backward_z := 21.0  # 看向后方时 SpringArm 的目标 Z 偏移

var spring_arm_smooth := 5        # SpringArm Z 偏移平滑插值速度
var spring_arm_rot_smooth := 6.0  # SpringArm Y 旋转平滑插值速度- 8

var backward_y_deg := -180.0
var forward_y_deg := 0.0

var _base_spring_arm_z := 0.0
var _target_spring_arm_z := 0.0
var _target_y_deg := 0.0
var _target_spring_arm_spring_length := 10.7

var _is_boosting := false
var _is_looking_backward := false

@export var cam_node: Node3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_base_spring_arm_z = position.z
	_target_spring_arm_z = _base_spring_arm_z
	_target_y_deg = cam_node.rotation_degrees.y
	_update_target_pose()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var arm_t := 1.0 - exp(-spring_arm_smooth * delta)
	var arm_pos := position
	arm_pos.z = lerp(arm_pos.z, _target_spring_arm_z, arm_t)
	position = arm_pos

	spring_length = lerp(spring_length, _target_spring_arm_spring_length, arm_t)

	var rot_t := 1.0 - exp(-spring_arm_rot_smooth * delta)
	cam_node.rotation_degrees.y = rad_to_deg(lerp_angle(deg_to_rad(cam_node.rotation_degrees.y), deg_to_rad(_target_y_deg), rot_t))



func on_boosting(is_boosting: bool) -> void:
	_is_boosting = is_boosting

	if _is_boosting:
		spring_arm_smooth = 5
	else:
		spring_arm_smooth = 2

	_update_target_pose()


func on_look_backward(is_looking_backward: bool) -> void:
	_is_looking_backward = is_looking_backward
	_update_target_pose()


func _update_target_pose() -> void:
	if _is_looking_backward :
		_target_y_deg = backward_y_deg 
	else :
		_target_y_deg = forward_y_deg

	var z_offset := 0.0
	if _is_boosting:
		z_offset -= spring_arm_boost_z
	if _is_looking_backward:
		z_offset -= spring_arm_backward_z

	_target_spring_arm_z = _base_spring_arm_z + z_offset
