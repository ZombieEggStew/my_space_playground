extends Module
class_name TargetSelectionModule

## 大脑侧目标选择(决策 #11,P5 落地):玩家悬停 + RMB 选目标(替代原 BasicAimModule)。
## 与共享 AimMechanicsModule 拆开:本模块只做"选谁打"与事件发布,预测力学/准星方向
## 在 aim_mechanics(决策 #11/#20);2D 呈现(锁定准星/预测圈/信息面板)在 aim_view。
##
## 职责边界:
## - 悬停判定(决策 #27):每帧拉 radar_view 缓存 screen_rect 做命中测试,状态变化才发
##   ② ship_bus.on_target_hovered / on_target_unhovered(载荷只带 target 身份)。
## - RMB 锁定:set_locked_target → 本地状态 + 推 aim_mechanics 当前值 + aim_view 呈现
##   + 发 ② ship_bus.on_player_lock_target(相机/挂架等消费方订阅)。
## - 缺 radar_view → 悬停/锁定降级(§4.2-2,不硬崩);缺 aim_mechanics → 预测降级。

@export var aim_view: AimView

var hovered_target: AbleToBeLocked
var locked_target: AbleToBeLocked

## 决策 #27:hover 几何数据源(radar_view 缓存 screen_rect),install 顺序保证 radar 先于 aim。
var _radar_view: RadarView
var _mechanics: AimMechanicsModule


func _ready() -> void:
	ship_bus.on_player_try_lock.connect(_handle_lock_action)
	# 决策 #27:hover 由本模块(selection)自判;无 radar 时 _radar_view 为 null → 降级。
	# 目标死亡/离开场景树时清掉悬挂引用(防 _process 访问已释放目标)。
	SignalBus.on_lockable_target_died.connect(_on_target_died)
	_mechanics = modules_manager.get_aim_mechanics_module() if modules_manager else null
	# 方案 A:radar_view 一次性解析 + 订阅雷达装卸事件,替代 _update_hover 每帧 get_radar_view
	# (radar 先于 selection 安装,此刻可拉到;中途装卸经信号自动重取/降级)。
	if modules_manager:
		_resolve_radar_view()
		modules_manager.module_installed.connect(_on_module_installed)
		modules_manager.module_uninstalled.connect(_on_module_uninstalled)


func _process(_delta: float) -> void:
	_update_hover()


## 决策 #27:每帧拉 radar_view 缓存的 screen_rect 命中测试鼠标位置;
## 命中多个按遍历序尾者胜;离屏/未知目标不在 rects 中 → 自动 unhover。
func _update_hover() -> void:
	var hovered: AbleToBeLocked = null
	if _radar_view != null and is_instance_valid(_radar_view):
		var mouse_pos := get_viewport().get_mouse_position()
		for target: AbleToBeLocked in _radar_view.get_screen_rects():
			if _radar_view.get_screen_rect(target).has_point(mouse_pos):
				hovered = target
	_set_hovered(hovered)


## 方案 A:radar_view 解析(getter 拉取只在装卸事件时执行,不再每帧跑)。
func _resolve_radar_view() -> void:
	_radar_view = modules_manager.get_radar_view() if modules_manager else null


func _on_module_installed(module: Module) -> void:
	if module is RadarModule:
		_resolve_radar_view()


func _on_module_uninstalled(module: Module) -> void:
	if module is RadarModule:
		_radar_view = null
		# radar 卸载 → 无 rects 数据源 → 立即清 hover,防 _process 访问已释放对象
		_set_hovered(null)


## hover 状态变化才动作(本地状态驱动 aim_view;变化脉冲经 ② 发布供 radar_view 高亮)
func _set_hovered(target: AbleToBeLocked) -> void:
	if target == hovered_target:
		return
	hovered_target = target
	if aim_view:
		aim_view.set_hovered_target(target)
	if ship_bus:
		if target != null:
			ship_bus.on_target_hovered.emit(target)
		else:
			ship_bus.on_target_unhovered.emit()


func _handle_lock_action() -> void:
	if hovered_target != null:
		set_locked_target(hovered_target)
	else:
		set_locked_target(null)


## 目标死亡/离开场景树时清掉悬挂引用 + 同步到 aim_view / aim_mechanics。
func _on_target_died(target: AbleToBeLocked) -> void:
	if locked_target == target:
		locked_target = null
		if _mechanics:
			_mechanics.set_locked_target(null)
	if hovered_target == target:
		hovered_target = null
	if aim_view:
		aim_view.set_locked_target(locked_target)
		aim_view.set_hovered_target(hovered_target)


func set_locked_target(target: AbleToBeLocked) -> void:
	if target:
		target.set_locked(true)
	else:
		if locked_target:
			locked_target.set_locked(false)

	locked_target = target
	if _mechanics:
		_mechanics.set_locked_target(target)
	if aim_view:
		aim_view.set_locked_target(target)
	if ship_bus:
		ship_bus.on_player_lock_target.emit(target)
