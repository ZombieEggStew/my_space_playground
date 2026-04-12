extends ThirdCameraModule


var cam_spring_arm: SpringArm3D 
var cam_pivot: Node3D

var move_controller: MoveModule

# 自动追踪参数

var mouse_sensitivity := 0.01

# 运镜
var is_cam_move := true


var _base_cam_pivot_offset := Vector3(0, 0, 0)
var _base_cam_pivot_rotation := Vector3(0, 0, 0)


func _ready() -> void:

	SignalBus.on_player_boost.connect(on_player_boost)

	cam_pivot = root.get_cam_pivot()
	cam_spring_arm = root.get_cam_spring_arm()
	_base_cam_pivot_offset = cam_pivot.position
	_base_cam_pivot_rotation = cam_pivot.rotation

	move_controller = modules_manager.get_move_module()

	if cam_pivot == null or cam_spring_arm == null or move_controller == null:
		log_missing_component("camera pivot or spring arm or move controller")
		queue_free()



func _input(event: InputEvent) -> void:
	handle_actions()
	handle_mouse_move(event)


func _physics_process(_delta: float) -> void:
	var rotation_speed = move_controller.get_rotation_speed()

	if is_cam_move:
		cam_pivot.position.x = rotation_speed.x * 2
		cam_pivot.position.z = rotation_speed.y * 1



func handle_mouse_move(event: InputEvent) -> void:
	if event is not InputEventMouseMotion: return

	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED: return
		
	# 取消鼠标追踪后的校正
	var mouse_delta = event.relative
	root.rotate_object_local(Vector3.UP, -mouse_delta.x * mouse_sensitivity)
	root.rotate_object_local(Vector3.RIGHT, mouse_delta.y * mouse_sensitivity)
	

func handle_actions() -> void:
	if Input.is_action_just_pressed("look_backward"):
		SignalBus.on_track_mouse_change.emit(false)
		look_backward()
	if Input.is_action_just_released("look_backward"):
		SignalBus.on_track_mouse_change.emit(true)
		stop_look_backward()


func look_backward() -> void:
	cam_spring_arm.on_look_backward(true)

func stop_look_backward() -> void:
	cam_spring_arm.on_look_backward(false)

func on_player_boost(enable: bool) -> void:
	cam_spring_arm.on_boosting(enable)
