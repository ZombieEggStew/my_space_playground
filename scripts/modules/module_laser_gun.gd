extends WeaponModule

var cam_main: Camera3D

@export var shoot_timer: Timer
@export var bullet_scene: PackedScene
@export var bullets_parent: Node

@export var left_laser_audio : AudioStreamPlayer
@export var right_laser_audio : AudioStreamPlayer
@export var aim_system: LaserGunAimSystem

var gun_pivot_left : Node3D

var aim_modrule: BasicAimModule

var is_shooting := false
var _fire_from_left := true
var bullet_spread_deg := 0  # 子弹随机散布角度（度）

var default_bullet_speed := 500.0


var crosshair_3: Crosshair3 #绿色 十字准心

# 机炮最大转向角度
const aim_dead_zone_px: float = 64.0

func _ready() -> void:
	aim_system.setup(aim_dead_zone_px)
	set_bullet_speed(default_bullet_speed)

	cam_main = root.get_main_camera()
	gun_pivot_left = root.get_gun_pivot_left()

	if cam_main == null or gun_pivot_left == null:
		log_error("Main camera or gun pivot not found in CharacterBody3D.")
		queue_free()
	aim_modrule = modules_manager.get_aim_module()
	if aim_modrule == null:
		log_error("Aim module not found in ModulesManager.")
		queue_free()


func _get_crosshair3_screen_pos() -> Vector2:
	if crosshair_3 :
		return crosshair_3.position  
	else:
		return get_viewport().get_mouse_position()


func _get_next_muzzle_pos() -> Vector3:
	var left_global_pos := gun_pivot_left.global_transform.origin
	var muzzle_pos := left_global_pos

	if not _fire_from_left:
		var left_local_pos := root.to_local(left_global_pos)
		var right_local_pos := left_local_pos
		right_local_pos.x = -right_local_pos.x
		muzzle_pos = root.to_global(right_local_pos)
		right_laser_audio.play()
	else:
		left_laser_audio.play()

	_fire_from_left = not _fire_from_left
	return muzzle_pos

func spawn_bullet(pos: Vector3, dir: Vector3, team_id: int, shooter: Node = null) -> void:
	if bullet_scene == null:
		return

	var bullet = bullet_scene.instantiate() as Area3D
	if bullet == null:
		return

	bullets_parent.add_child(bullet)

	if bullet.has_method("setup"):
		bullet.call("setup", pos, dir, team_id, shooter)

func handle_shooting() -> void:
	if Input.is_action_just_pressed("shoot_player"):
		is_shooting = true
	if Input.is_action_just_released("shoot_player"):
		is_shooting = false

	if is_shooting and shoot_timer.is_stopped():
		var forward := aim_modrule.get_aim_direction_from_crosshair(aim_system.get_aim_point_screen_pos())
		var right := cam_main.global_transform.basis.x.normalized() if cam_main else root.global_transform.basis.x.normalized()
		var up := cam_main.global_transform.basis.y.normalized() if cam_main else root.global_transform.basis.y.normalized()
		var spread := deg_to_rad(bullet_spread_deg)
		var offset_x := randf_range(-spread, spread)
		var offset_y := randf_range(-spread, spread)
		var shot_dir := (forward + right * offset_x + up * offset_y).normalized() as Vector3
		var muzzle_pos := _get_next_muzzle_pos()
		spawn_bullet(muzzle_pos, shot_dir, TeamID.TEAM_PLAYER)
		shoot_timer.start()


func _process(_delta: float) -> void:
	handle_shooting()
