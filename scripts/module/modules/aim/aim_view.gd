extends Node
class_name AimView

## aim(selection)的 2D 呈现层(决策 #20,P5 落地):拥有锁定准星 lock_reticle +
## 预测圈 lead_indicator + 预测信息面板(吸收 predict 的 UI,独立 predict 模块已删)。
##
## 数据来源:
## - target_selection 经 [method set_locked_target] / [method set_hovered_target] 传入目标身份;
## - AimMechanicsModule 提供 3D 预测点([method AimMechanicsModule.get_predicted_aim_data],
##   决策 #18 只算 3D);本 view 用相机投影(决策 #18/#23:radar/aim 身体永不投影)。
##
## 职责边界:
## - 只做显示/投影/平滑/屏幕边缘指示与预测面板文本,不含锁定/悬停判定(在 target_selection)。
## - 随 selection 模块一起装卸;卸载时回收经 register_hud 注册到 HUD 层的 2D 节点(幂等)。

@export var scene_lock_reticle: PackedScene
@export var scene_lead_indicator: PackedScene
@export var hud_container: Node
@export var lead_time_label: Label
@export var distance_label: Label
@export var velocity_desire_label: Label

var lock_reticle: HUD_LockReticle  # 绿色 二级锁定准星
var lead_indicator: HUD_LeadIndicator  # 绿色 预测射击点圆环

var _locked_target: AbleToBeLocked
var _hovered_target: AbleToBeLocked

var cam_main: Camera3D
var indicator_margin := 32.0

var _parent_module: Module
var _mechanics: AimMechanicsModule
var _laser: LaserModule
var _bullet_speed := 0.0


func _ready() -> void:
	_parent_module = get_parent() as Module
	_refresh_camera()
	init_lock_reticle()
	init_lead_indicator()
	# 面板注册延后一帧:register_hud(GROUP) 会 reparent 节点,不能在模块 add_child 的
	# _ready 窗口内执行(Godot 禁止"忙时 remove_child/add_child")。
	register_info_panel.call_deferred()
	# 方案 A:一次性拉取已装依赖 + 订阅模块装卸事件,替代原每帧 _ensure_refs 轮询。
	_bind_refs()


func init_lock_reticle() -> void:
	lock_reticle = GameManager.hud_manager.register_hud(scene_lock_reticle).node as HUD_LockReticle


func init_lead_indicator() -> void:
	lead_indicator = GameManager.hud_manager.register_hud(scene_lead_indicator).node as HUD_LeadIndicator


## 预测信息面板(GROUP 层,特效同原 predict:视差/旋转/加速扩散)
func register_info_panel() -> void:
	if hud_container == null:
		return
	GameManager.hud_manager.register_hud(hud_container).set_flow_effect(ControlGroup.Index.GROUP_1).set_rotation_effect().set_boost_offset_effect()


func set_locked_target(target: AbleToBeLocked) -> void:
	_locked_target = target


func set_hovered_target(target: AbleToBeLocked) -> void:
	_hovered_target = target


func _process(_delta: float) -> void:
	if cam_main == null:
		return
	if is_instance_valid(_locked_target):
		_handle_locked_target()
	elif is_instance_valid(_hovered_target):
		lock_reticle.set_target_pos(cam_main.unproject_position(_hovered_target.global_position))
		_reset_prediction_ui()
	else:
		lock_reticle.reset()
		_reset_prediction_ui()


## 方案 A:一次性拉取已装依赖并订阅模块装卸事件(替代原每帧 _ensure_refs 轮询)。
## 时序:mechanics 先于 selection 安装(character_body_3d._ready 顺序),此刻可直接拉到;
## laser 晚于 selection 安装,经 module_installed 信号在登场瞬间补绑;卸载经
## module_uninstalled 信号置 null 降级(动态装卸全自动,不再每帧碰运气)。
func _bind_refs() -> void:
	var mm: ModulesManager = _parent_module.modules_manager if _parent_module else null
	if mm == null:
		return
	_mechanics = mm.get_aim_mechanics_module()
	var laser := mm.get_laser_module()
	if laser:
		_bind_laser(laser)
	mm.module_installed.connect(_on_module_installed)
	mm.module_uninstalled.connect(_on_module_uninstalled)


func _on_module_installed(module: Module) -> void:
	if module is LaserModule:
		_bind_laser(module as LaserModule)
	elif module is AimMechanicsModule:
		_mechanics = module as AimMechanicsModule
	elif module is ThirdCameraModule:
		_refresh_camera()


func _on_module_uninstalled(module: Module) -> void:
	if module is LaserModule:
		_unbind_laser()
	elif module is AimMechanicsModule:
		_mechanics = null
	elif module is ThirdCameraModule:
		_refresh_camera()


## 决策 #32:camera 装卸事件驱动刷新(重装立即生效;缺相机 → cam_main=null,_process 整体跳过)。
func _refresh_camera() -> void:
	var mm: ModulesManager = _parent_module.modules_manager if _parent_module else null
	var cam_mod: ThirdCameraModule = mm.get_camera_module() if mm else null
	cam_main = cam_mod.get_main_camera() if cam_mod else null


## 绑定激光:缓存弹速 + 订阅弹速变化(幂等:同一实例不重复绑)。
func _bind_laser(laser: LaserModule) -> void:
	if _laser == laser:
		return
	_laser = laser
	_bullet_speed = laser.get_bullet_speed()
	if not laser.on_bullet_speed_change.is_connected(_on_bullet_speed_change):
		laser.on_bullet_speed_change.connect(_on_bullet_speed_change)


## 解绑激光:断开弹速订阅并置 null(幂等;模块卸载/本 view 退出共用)。
func _unbind_laser() -> void:
	if _laser != null and is_instance_valid(_laser):
		if _laser.on_bullet_speed_change.is_connected(_on_bullet_speed_change):
			_laser.on_bullet_speed_change.disconnect(_on_bullet_speed_change)
	_laser = null


func _on_bullet_speed_change(new_speed: float) -> void:
	_bullet_speed = new_speed


## 锁定目标:准星贴目标(含边缘指示) + 预测圈/信息面板(3D 预测点由 mechanics 算,本 view 投影)
func _handle_locked_target() -> void:
	if not is_instance_valid(_locked_target):
		_locked_target = null
		return

	var world_pos := _locked_target.global_position
	var viewport_size := get_viewport().get_visible_rect().size
	var center := viewport_size * 0.5
	var screen_pos := cam_main.unproject_position(world_pos)

	if cam_main.is_position_behind(world_pos):
		var to_enemy := world_pos - cam_main.global_transform.origin
		var right_component := cam_main.global_transform.basis.x.dot(to_enemy)
		var up_component := cam_main.global_transform.basis.y.dot(to_enemy)
		var dir_2d := Vector2(right_component, -up_component)
		if dir_2d.length() < 0.001:
			dir_2d = Vector2.UP
		screen_pos = center + dir_2d.normalized() * max(viewport_size.x, viewport_size.y)

	screen_pos = Vector2(
		clamp(screen_pos.x, indicator_margin, viewport_size.x - indicator_margin),
		clamp(screen_pos.y, indicator_margin, viewport_size.y - indicator_margin)
	)
	lock_reticle.set_target_pos(screen_pos)

	if _mechanics != null and _locked_target.is_on_screen():
		var aim_data := _mechanics.get_predicted_aim_data(_locked_target, _bullet_speed)
		if aim_data.get("valid", false):
			var predicted_pos: Vector3 = aim_data.get("world_pos", Vector3.ZERO)
			lead_indicator.set_target_pos(cam_main.unproject_position(predicted_pos))
			lead_indicator.set_target_distance(aim_data.get("distance", 0.0))
			_update_labels(aim_data)
			return
	_reset_prediction_ui()


## 预测面板文本(原 PredictAimModule 的三个 Label;AI 目标额外显示 speed/desire)
func _update_labels(aim_data: Dictionary) -> void:
	if lead_time_label:
		lead_time_label.text = "%.2f s" % aim_data.get("time", 0.0)
	if distance_label:
		var origin := _parent_module.root.global_transform.origin if _parent_module != null and _parent_module.root != null else Vector3.ZERO
		distance_label.text = "%.1f m" % origin.distance_to(aim_data.get("world_pos", Vector3.ZERO))
	if velocity_desire_label:
		var target_node: Node3D = _locked_target.target_node3d if is_instance_valid(_locked_target) else null
		if target_node is CharacterBody3D and target_node.has_node("AI_Brain"):
			var ai: AIBrain = target_node.ai
			if ai != null and ai.move_sm != null:
				velocity_desire_label.text = "%.1f/%.1f" % [target_node.velocity.length(), ai.move_sm.target_speed]


func _reset_prediction_ui() -> void:
	if lead_indicator:
		lead_indicator.reset()
	if lead_time_label:
		lead_time_label.text = "--"
	if distance_label:
		distance_label.text = "--"
	if velocity_desire_label:
		velocity_desire_label.text = "--"


## 兜底清理(§4.2-5):卸载时回收注册到 HUD 层的准星/预测圈/面板 + 断开模块装卸订阅与激光弹速订阅(幂等)
func _exit_tree() -> void:
	_unbind_laser()
	var mm: ModulesManager = _parent_module.modules_manager if _parent_module else null
	if mm != null and is_instance_valid(mm):
		if mm.module_installed.is_connected(_on_module_installed):
			mm.module_installed.disconnect(_on_module_installed)
		if mm.module_uninstalled.is_connected(_on_module_uninstalled):
			mm.module_uninstalled.disconnect(_on_module_uninstalled)
	_mechanics = null
	if is_instance_valid(lock_reticle):
		lock_reticle.queue_free()
	lock_reticle = null
	if is_instance_valid(lead_indicator):
		lead_indicator.queue_free()
	lead_indicator = null
	if is_instance_valid(hud_container):
		hud_container.queue_free()
	hud_container = null
