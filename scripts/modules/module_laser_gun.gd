extends WeaponModule

var cam_main: Camera3D

@export var shoot_timer: Timer
@export var bullet_scene: PackedScene
@export var bullets_parent: Node

@export var left_laser_audio : AudioStreamPlayer
@export var right_laser_audio : AudioStreamPlayer
@export var aim_system: LaserGunHudSystem

@export var cool_down_timer:Timer

@export var heat_bar : TextureProgressBar

# 过热系统变量
@export var max_heat: float = 100.0
@export var heat_per_shot: float = 1.0

@export var heat_recovery_rate: float = 20.0  # 每秒降低的热量

var current_heat: float = 0.0
var is_overheated: bool = false

# 存储机炮发射角度
var forward: Vector3


var gun_pivot_left : Node3D

var aim_modrule: BasicAimModule

var _fire_from_left := true
var bullet_spread_deg := 0  # 子弹随机散布角度（度）

var default_bullet_speed := 500.0

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
	gun_pivot_left = root.get_gun_pivot_left()

	if cam_main == null or gun_pivot_left == null:
		log_error("Main camera or gun pivot not found in CharacterBody3D.")
		queue_free()
	aim_modrule = modules_manager.get_aim_module()
	if aim_modrule == null:
		log_error("Aim module not found in ModulesManager.")
		queue_free()
	
	if heat_bar:
		heat_bar.max_value = max_heat
		heat_bar.value = current_heat


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

func handle_shooting(enable: bool) -> void:
	if enable:
		if is_overheated:
			return
		shoot()
		shoot_timer.start()       # 开始循环计时
	else:
		shoot_timer.stop() # 停止计时器即停止射击



func _on_shoot_timer_timeout() -> void:
	if is_overheated:
		shoot_timer.stop()
		return
	shoot()


func _process(delta: float) -> void:
	# 只要计时器没在运行，就降低热量
	if cool_down_timer and cool_down_timer.is_stopped():
		if current_heat > 0:
			current_heat = max(0, current_heat - heat_recovery_rate * delta)
			# 如果处于过热状态且热量降低到0，则解除过热
			if is_overheated and current_heat <= 0:
				is_overheated = false
	
	if heat_bar:
		heat_bar.value = current_heat

func enter_overheat() -> void:
	is_overheated = true
	shoot_timer.stop()
	# 过热时启动冷却延迟计时，确保停止射击后延迟开始降热
	if cool_down_timer:
		cool_down_timer.start()

func shoot() -> void:
	if is_overheated:
		return

	# 增加热量
	current_heat += heat_per_shot
	
	# 每次射击重置/启动计时器，实现 heat_cooldown_delay 的延迟效果
	if cool_down_timer and not is_overheated:
		cool_down_timer.start()
	
	if current_heat >= max_heat:
		current_heat = max_heat
		enter_overheat()

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
	spawn_bullet(muzzle_pos, shot_dir, TeamID.TEAM_PLAYER)
