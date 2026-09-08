extends Module
class_name ThirdCameraModule


@export var cam_spring_arm: SpringArm3D 
@export var cam_pivot: Node3D
@export var cam_main: Camera3D

@export var boost_effect: GPUParticles3D
var move_controller: EngineModule

var shaker: CameraShaker

# 自动追踪参数

var mouse_sensitivity := 0.01

# 运镜
var is_cam_move := true


var _base_cam_pivot_offset := Vector3(0, 0, 0)
var _base_cam_pivot_rotation := Vector3(0, 0, 0)

var is_looking_around := false
var look_around_sensitivity := 0.001 # 自由视角灵敏度

var _lock_target: AbleToBeLocked = null

func _ready() -> void:

	ship_bus.on_player_boost.connect(on_player_boost)
	ship_bus.on_player_look_backward.connect(_handle_look_backward)
	ship_bus.on_player_look_around.connect(_on_look_around_change)
	ship_bus.on_player_lock_target.connect(_on_lock_target)
	GameManager.input_manager.mouse_movtion.connect(_handle_mouse_move)
	_base_cam_pivot_offset = cam_pivot.position
	_base_cam_pivot_rotation = cam_pivot.rotation

	# 决策 #32:move 装卸事件驱动重取(move 缺失时 _physics_process 守卫,不崩)
	watch_modules([MoveControllerModule])
	_resolve_module_refs()

	if move_controller == null:
		Log.log_missing_component(self,"move controller")
		queue_free()
		return

	# 初始化抖动器
	shaker = CameraShaker.new()
	add_child(shaker)
	shaker.setup(cam_main)

	cam_main.current = true

## 决策 #32:move 装卸事件触发时重取引用(幂等;move 卸载 → null,_physics_process 跳过)。
func _resolve_module_refs() -> void:
	move_controller = modules_manager.get_move_module() if modules_manager else null

func _on_lock_target(_target : AbleToBeLocked) -> void:
	_lock_target = _target

func _on_look_around_change(enable: bool) -> void:
	is_looking_around = enable
	ship_bus.on_toggle_track_mouse.emit(not enable)
	if enable:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if not enable:
		# 重置相机旋转
		var tween = create_tween()
		tween.tween_property(cam_pivot, "rotation", Vector3.ZERO, 0.2).set_trans(Tween.TRANS_SINE)
		
func get_main_camera() -> Camera3D:
	return cam_main
func get_cam_pivot() -> Node3D:
	return cam_pivot

func _handle_mouse_move(event: InputEventMouseMotion) -> void:
	if is_looking_around:
		# 在自由视角模式下，直接旋转 cam_pivot
		cam_pivot.rotate_y(-event.relative.x * look_around_sensitivity)
		cam_pivot.rotate_object_local(Vector3.RIGHT, -event.relative.y * look_around_sensitivity)
		# 限制上下仰角，防止翻转
		cam_pivot.rotation.x = clamp(cam_pivot.rotation.x, deg_to_rad(-80), deg_to_rad(80))


func _physics_process(_delta: float) -> void:
	# move 卸载后跳过(决策 #32:引用事件驱动,缺失即降级,不硬崩)
	if move_controller == null:
		return
	var rotation_speed = move_controller.get_rotation_speed()

	if is_cam_move:
		cam_pivot.position.x = -rotation_speed.x * 2
		cam_pivot.position.z = -rotation_speed.y * 1

	if is_looking_around and _lock_target != null:
		# 锁定目标时的自由视角：平滑转向目标
		var target_transform = cam_pivot.global_transform.looking_at(_lock_target.global_position, Vector3.UP)
		var target_quat = target_transform.basis.get_rotation_quaternion()
		var current_quat = cam_pivot.global_transform.basis.get_rotation_quaternion()
		
		# 使用 slerp 进行平滑插值，0.1 为平滑系数，可以根据需要调整
		var interpolated_quat = current_quat.slerp(target_quat, 0.1)
		cam_pivot.global_transform.basis = Basis(interpolated_quat)
		# 消除 Z 轴旋转（Roll）
		cam_pivot.rotation.z = 0

	
func _handle_look_backward(enable:bool) -> void:
	cam_spring_arm.on_look_backward(enable)
	ship_bus.on_toggle_track_mouse.emit(not enable)
func on_player_boost(enable: bool) -> void:
	cam_spring_arm.on_boosting(enable)
	boost_effect.emitting = enable
	if enable:
		shaker.start_shake(1.0)
