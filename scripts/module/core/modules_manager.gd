extends Node3D
class_name ModulesManager

# basic modules
var movement_module: MoveControllerModule
var third_camera_module: ThirdCameraModule
var aim_mechanics_module: AimMechanicsModule
var target_selection_module: TargetSelectionModule
var rader_module: RadarModule
var laser_module: LaserModule

## 安装模块:显式注入 root/modules_manager(不再靠 _enter_tree 猜树结构,见 .memo 讨论)。
## [param module_scene] 实例化后立即注入,再挂到树上;注入失败(父不是 CharacterBody3D)也照常挂载,
## 由模块 _enter_tree 兜底按旧逻辑推算。
func install_module(module_scene:PackedScene) -> Module:
	var module = module_scene.instantiate()
	_inject_module_deps(module)

	if module is AimMechanicsModule:
		aim_mechanics_module = module

	if module is TargetSelectionModule:
		target_selection_module = module

	if module is RadarModule:
		rader_module = module

	if module is EngineModule:
		movement_module = module

	if module is ThirdCameraModule:
		third_camera_module = module

	if module is LaserModule:
		laser_module = module

	add_child(module)
	return module

## 注入基类依赖:模块脚本里 `root`/`modules_manager`/`ship_bus` 在 _enter_tree 前就被赋值。
## 模块统一继承 Module(Node3D),故参数不写死类型,靠字段注入(兼容 booster 等链式子模块)。
func _inject_module_deps(module) -> void:
	module.modules_manager = self
	module.root = get_parent() as CharacterBody3D
	var player := get_parent() as PlayerShip
	module.ship_bus = player.ship_bus if player else null

func get_camera_module() -> ThirdCameraModule:
	return third_camera_module

## P5(决策 #11):aim 拆两层 —— mechanics(共享,算 3D 预测/准星方向)与
## selection(大脑侧,选目标)。激光/敌人 AI 用 mechanics;悬停/锁定用 selection。
func get_aim_mechanics_module() -> AimMechanicsModule:
	return aim_mechanics_module

func get_target_selection_module() -> TargetSelectionModule:
	return target_selection_module

func get_move_module() -> EngineModule:
	return movement_module

func get_radar_module() -> RadarModule:
	return rader_module

func get_laser_module() -> LaserModule:
	return laser_module

## 决策 #27:aim(selection)拉取 hover 几何数据的入口(radar 模块场景内子节点)。
func get_radar_view() -> RadarView:
	if rader_module == null or not is_instance_valid(rader_module):
		return null
	return rader_module.get_node_or_null("radar_view") as RadarView

## 卸载模块(幂等,§4.2-5):
## 1. 调模块的 on_uninstall() 钩子清理 reparent 出去的 2D 节点 / 手动断连
## 2. 清掉本管理器持有的槽位引用(置 null)
## 3. queue_free(模块 _exit_tree 再兜底一次 on_uninstall)
## 对已释放/不在树上的模块直接跳过,绝不硬崩。
func uninstall_module(module: Module) -> void:
	if module == null or not is_instance_valid(module):
		return
	if module.get_parent() != self:
		push_warning("ModulesManager.uninstall_module: %s 不是本管理器的直接子节点" % module.name)
	module.on_uninstall()
	if module == aim_mechanics_module:
		aim_mechanics_module = null
	if module == target_selection_module:
		target_selection_module = null
	if module == rader_module:
		rader_module = null
	if module == movement_module:
		movement_module = null
	if module == third_camera_module:
		third_camera_module = null
	if module == laser_module:
		laser_module = null
	module.queue_free()
