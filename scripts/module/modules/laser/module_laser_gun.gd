extends WeaponModule
class_name LaserModule

@export var shoot_timer: Timer
@export var bullet_scene: PackedScene
@export var bullets_parent: Node

@export var left_laser_audio : AudioStreamPlayer
@export var right_laser_audio : AudioStreamPlayer
@export var aim_system: LaserGunHudSystem
@export var heat_manager: HeatManager

var damage := 10.0

@export var gun_pivot_left : Node3D

var aim_modrule: AimMechanicsModule

## 决策 #33 + AI 通道(.memo/ai_rework_plan.md §5.2):AI 没有屏幕坐标,由 AIModule
## 每帧 set_ai_aim_dir() 推入世界射击方向,shoot() 优先使用;Vector3.INF = 未设置
## (回退准星/机头逻辑)。玩家侧从未设置,行为不变。
var _ai_aim_dir: Vector3 = Vector3.INF

var _fire_from_left := true
var bullet_spread_deg := 0  # 子弹随机散布角度（度）

var default_bullet_speed := 500

var is_shooting := false
var crosshair_3: HUD_GunReticle #绿色 十字准心

# 机炮最大转向角度
const aim_dead_zone_px: float = 64.0

func _ready() -> void:
	shoot_timer.timeout.connect(_on_shoot_timer_timeout)

	if aim_system:
		aim_system.setup(aim_dead_zone_px)
	set_bullet_speed(default_bullet_speed)

	# 决策 #33:laser 不自持相机,射击完全由 aim 模块指导;缺 aim → 机炮直射降级(不硬崩)
	watch_modules([AimMechanicsModule])
	_resolve_module_refs()
	if aim_modrule == null:
		Log.log_missing_component(self, "aim mechanics module")

	if heat_manager:
		heat_manager.overheated.connect(_on_overheated)

## 决策 #32/#33:aim 装卸事件触发时重取(null 安全;缺 aim → 机炮直射降级)。
func _resolve_module_refs() -> void:
	aim_modrule = modules_manager.get_aim_mechanics_module() if modules_manager else null

	

func _on_overheated(overheated_status: bool) -> void:
	if overheated_status:
		shoot_timer.stop()

func _get_crosshair3_screen_pos() -> Vector2:
	if crosshair_3 :
		# crosshair_3.position 是机头局部坐标,换算回视口全局坐标
		return crosshair_3.position + crosshair_3.hud.position  
	else:
		return get_viewport().get_mouse_position()


func _get_next_muzzle_pos() -> Vector3:
	if gun_pivot_left == null:
		# 缺炮口节点(敌人装配):机头前方取炮口
		return root.global_position - root.global_transform.basis.z * 2.0
	var left_global_pos := gun_pivot_left.global_transform.origin
	var muzzle_pos := left_global_pos

	if not _fire_from_left:
		var left_local_pos := root.to_local(left_global_pos)
		var right_local_pos := left_local_pos
		right_local_pos.x = -right_local_pos.x
		muzzle_pos = root.to_global(right_local_pos)
		if right_laser_audio:
			right_laser_audio.play()
	else:
		if left_laser_audio:
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
	# 决策 #28:team 取自 root(玩家/敌人共用同一份 laser 模块,阵营不再硬编码 PLAYER)
	var team: int = root.get_team_id() if root.has_method("get_team_id") else TeamID.PLAYER
	bullet.setup(pos, dir, team , root).set_damage(_damage).set_speed(bullet_speed)


## 决策 #13/P3:连续量命令,由 ControlModule / AIModule 每帧调用。
## 必须做变化检测:仅在射击状态翻转时 shoot()+启停 Timer,否则每帧重置 Timer 且每帧发弹
## (修复:射速回归 wait_time 控制)。
func set_firing(firing: bool) -> void:
	if firing == is_shooting:
		return
	is_shooting = firing
	if firing:
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

	var aim_screen_pos := aim_system.get_aim_point_screen_pos() if aim_system else Vector2.INF
	var aim_basis := _get_aim_basis(aim_screen_pos)
	var spread := deg_to_rad(bullet_spread_deg)
	var offset_x := randf_range(-spread, spread)
	var offset_y := randf_range(-spread, spread)
	var shot_dir := (aim_basis.z + aim_basis.x * offset_x + aim_basis.y * offset_y).normalized()
	var muzzle_pos := _get_next_muzzle_pos()
	spawn_bullet(muzzle_pos, shot_dir)

## AI 通道:推入世界射击方向(决策 #33 对齐,AIModule 每帧调用;Vector3.INF = 未设置)
func set_ai_aim_dir(dir: Vector3) -> void:
	_ai_aim_dir = dir.normalized() if dir.length() > 0.001 else Vector3.INF

func clear_ai_aim_dir() -> void:
	_ai_aim_dir = Vector3.INF

## 决策 #33:laser 不自持相机,射击方向/散布基完全由 aim 模块给出;
## AI 通道优先,其次准星(缺 aim 或准星无效)→ 机头朝向直射,散布基取机体轴(世界系)。
func _get_aim_basis(aim_screen_pos: Vector2) -> Basis:
	if _ai_aim_dir != Vector3.INF:
		return _basis_from_forward(_ai_aim_dir)
	if aim_screen_pos != Vector2.INF and aim_modrule != null:
		return aim_modrule.get_aim_basis_from_crosshair(aim_screen_pos)
	var b := root.global_transform.basis
	return Basis(b.x, b.y, -b.z)

## 由 forward 造右手正交基(与 AimMechanicsModule.get_aim_basis_from_crosshair 同一套)。
static func _basis_from_forward(forward: Vector3) -> Basis:
	var f := forward.normalized()
	var right := Vector3.UP.cross(f)
	if right.length() < 0.0001:
		right = Vector3.RIGHT
	right = right.normalized()
	var up := f.cross(right).normalized()
	return Basis(right, up, f)


