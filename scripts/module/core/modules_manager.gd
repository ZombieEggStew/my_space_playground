extends Node3D
class_name ModulesManager

## 模块装卸广播(方案 A):install 完成后 / uninstall 销毁前各发一次。
## 消费方(如 aim_view / target_selection)订阅即可拿到"已装/被卸"通知,
## 替代"每帧 get_*() 补拉引用"的轮询写法;装卸瞬间自动重取/降级。
signal module_installed(module: Module)
signal module_uninstalled(module: Module)

## 模块注册表(决策 #30):按实例存 Array,getter 按 `is` 语义查询。
## 取代旧"逐类型槽位 + install if 链 + uninstall 手工清槽"——那个写法每加一个模块
## 要改两处且必须同步,漏一处就是悬挂引用。现在新模块 manager 零改动:
## install 一行 append、uninstall 一行 erase,类型化 getter 签名不变(调用方零改动)。
## getter 为 O(n) 扫描(n≈8),但全部调用点都在 setup/装卸事件(方案 A 无每帧轮询),可忽略。
var _modules: Array[Module] = []

## 安装模块:显式注入 root/modules_manager(不再靠 _enter_tree 猜树结构,见 .memo 讨论)。
## [param module_scene] 实例化后立即注入,再挂到树上;注入失败(父不是 CharacterBody3D)也照常挂载,
## 由模块 _enter_tree 兜底按旧逻辑推算。
func install_module(module_scene:PackedScene) -> Module:
	var module = module_scene.instantiate()
	_inject_module_deps(module)
	_modules.append(module)
	add_child(module)
	module_installed.emit(module)
	return module

## 注入基类依赖:模块脚本里 `root`/`modules_manager`/`ship_bus` 在 _enter_tree 前就被赋值。
## 模块统一继承 Module(Node3D),故参数不写死类型,靠字段注入(兼容 booster 等链式子模块)。
## ship_bus 用 duck typing 取根节点的 `ship_bus` 属性(与 Module._enter_tree 兜底一致):
## 玩家船 = PlayerShip.ship_bus;敌人船(Ph0/ai_rework_plan)挂同名节点后同样注入,不限于 PlayerShip。
func _inject_module_deps(module) -> void:
	module.modules_manager = self
	module.root = get_parent() as CharacterBody3D
	var ship_bus_node: Variant = get_parent().get("ship_bus") if get_parent() != null else null
	module.ship_bus = ship_bus_node as ShipBus if ship_bus_node is ShipBus else null

## 通用查询(按 `is` 语义,基类可查到子类;测试/AI/动态场景用)。
func get_module(module_type) -> Module:
	return _get_module_by_type(module_type)

func get_camera_module() -> ThirdCameraModule:
	return _get_module_by_type(ThirdCameraModule) as ThirdCameraModule

## P5(决策 #11):aim 拆两层 —— mechanics(共享,算 3D 预测/准星方向)与
## selection(大脑侧,选目标)。激光/敌人 AI 用 mechanics;悬停/锁定用 selection。
func get_aim_mechanics_module() -> AimMechanicsModule:
	return _get_module_by_type(AimMechanicsModule) as AimMechanicsModule

func get_target_selection_module() -> TargetSelectionModule:
	return _get_module_by_type(TargetSelectionModule) as TargetSelectionModule

## 基类语义:move 是 MoveControllerModule(extends EngineModule),用 EngineModule 可查到
## (与旧 `if module is EngineModule` 槽位行为一致)。
func get_move_module() -> EngineModule:
	return _get_module_by_type(EngineModule) as EngineModule

func get_radar_module() -> RadarModule:
	return _get_module_by_type(RadarModule) as RadarModule

func get_laser_module() -> LaserModule:
	return _get_module_by_type(LaserModule) as LaserModule

## 注册表按 `is` 语义扫描(首个匹配)。已释放实例跳过,防悬挂引用。
func _get_module_by_type(module_type) -> Module:
	for module in _modules:
		if is_instance_valid(module) and is_instance_of(module, module_type):
			return module
	return null

## 决策 #27:aim(selection)拉取 hover 几何数据的入口(radar 模块场景内子节点)。
func get_radar_view() -> RadarView:
	var radar := get_radar_module()
	if radar == null or not is_instance_valid(radar):
		return null
	return radar.get_node_or_null("radar_view") as RadarView

## 卸载模块(幂等,§4.2-5):
## 1. 调模块的 on_uninstall() 钩子清理 reparent 出去的 2D 节点 / 手动断连
## 2. 从注册表擦除(自动,无需逐类型清槽)
## 3. queue_free(模块 _exit_tree 再兜底一次 on_uninstall)
## 对已释放/不在树上的模块直接跳过,绝不硬崩。
func uninstall_module(module: Module) -> void:
	if module == null or not is_instance_valid(module):
		return
	if module.get_parent() != self:
		push_warning("ModulesManager.uninstall_module: %s 不是本管理器的直接子节点" % module.name)
	module.on_uninstall()
	_modules.erase(module)
	# 在 queue_free 前广播:监听方此刻仍可安全断开模块信号、读模块属性
	module_uninstalled.emit(module)
	module.queue_free()
