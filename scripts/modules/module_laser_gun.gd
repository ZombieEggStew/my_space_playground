extends WeaponModule

var cam_main: Camera3D

@export var shoot_timer: Timer
@export var bullet_scene: PackedScene
@export var bullets_parent: Node

@export var left_laser_audio : AudioStreamPlayer
@export var right_laser_audio : AudioStreamPlayer
@export var aim_system: LaserGunHudSystem
@export var heat_manager: HeatManager

# 存储机炮发射角度
var forward: Vector3 = Vector3.FORWARD
var damage := 10.0

@export var gun_pivot_left : Node3D

var aim_modrule: BasicAimModule

var _fire_from_left := true
var bullet_spread_deg := 0  # 子弹随机散布角度（度）

var default_bullet_speed := 500

var is_shooting := false
var crosshair_3: Crosshair3 #绿色 十字准心

# 机炮最大转向角度
const aim_dead_zone_px: float = 64.0

func _ready() -> void:
	SignalBus.on_player_shoot.connect(handle_shooting)
	shoot_timer.timeout.connect(_on_shoot_timer_timeout)

	aim_system.setup(aim_dead_zone_px)
	set_bullet_speed(default_bullet_speed)

	cam_main = root.get_main_camera()

	if cam_main == null:
		Log.log_error(self,"Main camera not found in CharacterBody3D.")
		queue_free()
	aim_modrule = modules_manager.get_aim_module()
	if aim_modrule == null:
		Log.log_error(self,"Aim module not found in ModulesManager.")
		queue_free()
	
	if heat_manager:
		heat_manager.overheated.connect(_on_overheated)

	

func _on_overheated(overheated_status: bool) -> void:
	if overheated_status:
		shoot_timer.stop()

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


func spawn_bullet( pos: Vector3, dir: Vector3) -> void:
	if bullet_scene == null:
		return

	var bullet = bullet_scene.instantiate() as LaserBullet
	if bullet == null:
		return

	bullets_parent.add_child(bullet)

	var heat_ratio := heat_manager.get_heat_ratio() if heat_manager else 0.0
	var _damage :int = round(damage * (1 + heat_ratio))
	bullet.setup(pos, dir, TeamID.PLAYER , root).set_damage(_damage).set_speed(bullet_speed)


func handle_shooting(enable: bool) -> void:
	if enable:
		if heat_manager and heat_manager.is_overheated:
			return
		shoot()
		shoot_timer.start()       # 开始循环计时
	else:
		shoot_timer.stop() # 停止计时器即停止射击



func _on_shoot_timer_timeout() -> void:
	if heat_manager and heat_manager.is_overheated:
		shoot_timer.stop()
		return
	shoot()


func _process(_delta: float) -> void:
	pass

func shoot() -> void:
	if heat_manager:
		if not heat_manager.add_heat():
			return

	var aim_screen_pos = aim_system.get_aim_point_screen_pos()
	
	if aim_screen_pos != Vector2.INF:
		forward = aim_modrule.get_aim_direction_from_crosshair(aim_screen_pos)
	
	var right := cam_main.global_transform.basis.x.normalized() if cam_main else root.global_transform.basis.x.normalized()
	var up := cam_main.global_transform.basis.y.normalized() if cam_main else root.global_transform.basis.y.normalized()
	var spread := deg_to_rad(bullet_spread_deg)
	var offset_x := randf_range(-spread, spread)
	var offset_y := randf_range(-spread, spread)
	var shot_dir := (forward + right * offset_x + up * offset_y).normalized() as Vector3
	var muzzle_pos := _get_next_muzzle_pos()
	spawn_bullet(muzzle_pos, shot_dir)


