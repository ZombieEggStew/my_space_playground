extends Node
class_name RadarView

## 雷达模块的 2D 呈现层(玩家侧,决策 #24/#27):负责"目标 UI 簇"(选择框+血条)的
## 组装、生命周期与**集中投影**(方案 A)。radar 身体只算 3D、不碰相机。
## 敌人复用 radar 时若无相机(非 PlayerShip),本 view 自动禁用,不影响雷达身体。
##
## 职责边界:
## - 每帧集中算每个目标的 `screen_rect`(单一数据源,决策 #27):喂 selector 显示 +
##   缓存给 aim(selection)做 hover 命中测试;不做悬停判定(在 aim)。
## - 订阅 ② on_target_hovered/unhovered 做选择框高亮。
## - 只做"目标 ↔ 目标 UI 簇"的映射与生命周期调度,不含雷达侦测/半径过滤(在身体)。

@export var target_selector_scene: PackedScene
@export var hp_bar_scene: PackedScene

## 选择框尺寸参数(方案 A 收口到本 view 集中配置;原 selector 自持参数迁移至此)
@export var base_size := Vector2(64, 64)
@export var size_scale_numerator := 100.0
@export var min_size_factor := 0.5

var _radar_module: RadarModule
var _root: Node3D
var _ship_bus: ShipBus
var _cam: Camera3D
var _cam_mod: ThirdCameraModule

# target -> TargetReticle
var _reticles: Dictionary = {}
# target -> Rect2(仅当前在屏目标;离屏/未知目标不缓存 → aim 判定天然不命中)
var _rect_cache: Dictionary = {}

func _enter_tree() -> void:
	_radar_module = get_parent() as RadarModule
	if _radar_module:
		_root = _radar_module.root
		_ship_bus = _radar_module.ship_bus
		# 决策 #30:相机走 camera 模块,不再用 _root.has_method("get_main_camera") 判断"是否玩家";
		# 敌人复用 radar 无 camera 模块 → null,呈现层禁用。
		_cam_mod = _radar_module.modules_manager.get_camera_module() if _radar_module.modules_manager else null

func _ready() -> void:
	# 只有装了 camera 模块的船(玩家)需要 2D 呈现;敌人复用 radar 无 camera → 禁用
	if _cam_mod == null:
		set_process(false)
		return
	_cam = _cam_mod.get_main_camera()
	if _cam == null:
		set_process(false)
		return
	SignalBus.on_lockable_target_spawned.connect(_on_target_spawned)
	SignalBus.on_lockable_target_died.connect(_on_target_died)
	if _ship_bus:
		_ship_bus.on_target_hovered.connect(_on_target_hovered)
		_ship_bus.on_target_unhovered.connect(_on_target_unhovered)

func _on_target_spawned(target: AbleToBeLocked) -> void:
	if target in _reticles:
		return
	# P5 对称性(§4.1):玩家已挂 AbleToBeLocked,自身/同阵营目标不建选择框、不进 rect 缓存
	# (hover 自然 miss)。阵营过滤归消费方做(radar 身体给全量,决策 #23)。
	if _root.has_method("get_team_id") and target.get_team_id() == _root.get_team_id():
		return
	if _cam == null or not is_instance_valid(_cam):
		return

	var reticle := TargetReticle.new()
	reticle.name = "TargetReticle_" + target.name
	add_child(reticle)
	reticle.setup(target, _cam, target_selector_scene, hp_bar_scene)
	_reticles[target] = reticle

func _on_target_died(target: AbleToBeLocked) -> void:
	# 只做簿记:实际的整簇回收由 TargetReticle 监听 target.tree_exited 触发
	_reticles.erase(target)
	_rect_cache.erase(target)

## 决策 #27/方案 A:每帧集中投影 → 喂 selector 显示 + 缓存 rect 供 aim 判定
func _process(_delta: float) -> void:
	if _cam == null or not is_instance_valid(_cam):
		return
	_rect_cache.clear()
	for target: AbleToBeLocked in _reticles.keys():
		var reticle: TargetReticle = _reticles[target] as TargetReticle
		if not is_instance_valid(target) or not is_instance_valid(reticle):
			_reticles.erase(target)
			continue
		# 离屏:隐藏选择框且不缓存 rect(aim 判定天然 miss → 自动 unhover)
		if not target.is_on_screen():
			reticle.set_on_screen(false)
			continue
		var world_pos := target.global_position
		var screen_pos := _cam.unproject_position(world_pos)
		var dist: float = max(world_pos.distance_to(_root.global_position), 0.001)
		var factor: float = max(size_scale_numerator / dist, min_size_factor)
		var size: Vector2 = base_size * factor
		_rect_cache[target] = Rect2(screen_pos - size / 2.0, size)
		reticle.set_on_screen(true)
		reticle.set_screen_rect(screen_pos, size)

## 决策 #27:aim(selection)拉取用——目标 -> Rect2 快照(离屏/未知目标不在其中)
func get_screen_rects() -> Dictionary:
	return _rect_cache

## 决策 #27:单目标查询;未知/离屏目标返回空 Rect2(永不命中)
func get_screen_rect(target: AbleToBeLocked) -> Rect2:
	return _rect_cache.get(target, Rect2())

func _on_target_hovered(target: AbleToBeLocked) -> void:
	var reticle: TargetReticle = _reticles.get(target)
	if reticle != null and is_instance_valid(reticle):
		reticle.set_hovered(true)

func _on_target_unhovered() -> void:
	for reticle: TargetReticle in _reticles.values():
		if is_instance_valid(reticle):
			reticle.set_hovered(false)

## 兜底清理(§4.2-5):断开总线 + 回收全部目标 UI 簇(幂等;用 is_connected 判定,
## 不再依赖 _root 是否有 get_main_camera——无相机时本就未连接)。
func _exit_tree() -> void:
	if _ship_bus != null and is_instance_valid(_ship_bus):
		if _ship_bus.on_target_hovered.is_connected(_on_target_hovered):
			_ship_bus.on_target_hovered.disconnect(_on_target_hovered)
		if _ship_bus.on_target_unhovered.is_connected(_on_target_unhovered):
			_ship_bus.on_target_unhovered.disconnect(_on_target_unhovered)
	if SignalBus.on_lockable_target_spawned.is_connected(_on_target_spawned):
		SignalBus.on_lockable_target_spawned.disconnect(_on_target_spawned)
	if SignalBus.on_lockable_target_died.is_connected(_on_target_died):
		SignalBus.on_lockable_target_died.disconnect(_on_target_died)
	for reticle in _reticles.values():
		if is_instance_valid(reticle):
			reticle.cleanup()
	_reticles.clear()
	_rect_cache.clear()
