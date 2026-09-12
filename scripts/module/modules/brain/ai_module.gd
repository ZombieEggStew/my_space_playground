extends Module
class_name AIModule

## 敌人 AI 大脑(.memo/ai_rework_plan.md §2/§4):感知 → Utility 决策(节流+滞后)→
## 归一化命令 → 共享模块执行。玩家侧对称物 = ControlModule;本模块只输出命令,
## 不懂键鼠,不直接操作刚体(根治旧 AI_Brain 直接 slerp 刚体的僵硬)。
##
## 决策机制:
## - 节流:每 profile.decision_interval 才重打分(带个体抖动),不每帧切;
## - 滞后(hysteresis):切行为需新分 > 当前分 + HYSTERESIS,杜绝阈值边缘抽搐;
## - 紧急旁路:分数 > EMERGENCY_THRESHOLD(Ph2 威胁行为用)可立即打断节流;
## - 随机噪声:打分叠加 ±profile.randomness,打破整齐划一。
## 开火与机动正交:机动由当前行为驱动,射击窗口(距离+机头对齐)由本模块统一判断。

var move_mod: EngineModule
var laser_mod: LaserModule
var radar_mod: RadarModule
var mechanics_mod: AimMechanicsModule

var profile := PilotProfile.new()
var perception: AIPerception
var maneuvers: AIManeuvers
var _actions: Array[AIAction] = []

var _current_action: AIAction
var _current_score := -INF
var _decision_timer := 0.0

const HYSTERESIS := 0.15
const EMERGENCY_THRESHOLD := 0.9
const FIRE_RANGE := 600.0
const FIRE_ANGLE_COS := 0.93
const BULLET_SPEED := 500.0


func _ready() -> void:
	# 决策 #32:依赖模块装卸事件驱动重取(重装立即生效,缺失置 null 降级)
	watch_modules([EngineModule, LaserModule, RadarModule, AimMechanicsModule])
	_resolve_module_refs()
	_setup_brain()


## 决策 #32:跨模块引用重取(幂等;缺模块 → 对应引用 null,各调用点降级)。
func _resolve_module_refs() -> void:
	move_mod = modules_manager.get_move_module() if modules_manager else null
	laser_mod = modules_manager.get_laser_module() if modules_manager else null
	radar_mod = modules_manager.get_radar_module() if modules_manager else null
	mechanics_mod = modules_manager.get_aim_mechanics_module() if modules_manager else null


func _setup_brain() -> void:
	perception = AIPerception.new()
	perception.name = "perception"
	add_child(perception)
	perception.setup(self)

	maneuvers = AIManeuvers.new()
	maneuvers.name = "maneuvers"
	add_child(maneuvers)
	maneuvers.setup(self)

	_actions = []
	var patrol := ActionPatrol.new()
	patrol.name = "ActionPatrol"
	_actions.append(patrol)
	var orbit := ActionOrbit.new()
	orbit.name = "ActionOrbit"
	_actions.append(orbit)
	var tail_chase := ActionTailChase.new()
	tail_chase.name = "ActionTailChase"
	_actions.append(tail_chase)
	for a: AIAction in _actions:
		add_child(a)
		a.setup(self)
	_current_action = _actions[0]
	_current_action.enter()


func _physics_process(delta: float) -> void:
	if move_mod == null:
		return  # 无执行器:降级不动作(装配矩阵"缺模块不崩溃")

	_decision_timer -= delta
	if _decision_timer <= 0.0:
		_decision_timer = profile.decision_interval * randf_range(0.8, 1.2)
		_decide()

	var ctx := perception.snapshot
	if _current_action:
		_current_action.execute(delta, ctx)
	_update_firing(ctx)


func _decide() -> void:
	perception.refresh(perception.snapshot.get("time", 0.0) + profile.decision_interval)
	var ctx := perception.snapshot
	var best: AIAction = null
	var best_score := -INF
	for a: AIAction in _actions:
		var s: float = a.score(ctx, profile) + randf_range(-profile.randomness, profile.randomness)
		if s > best_score:
			best_score = s
			best = a
	if best == null:
		return
	if best == _current_action:
		_current_score = best_score
		return
	# 滞后或紧急旁路才切换
	if best_score > _current_score + HYSTERESIS or best_score > EMERGENCY_THRESHOLD:
		_transition_to(best, best_score)


func _transition_to(action: AIAction, score: float) -> void:
	if _current_action and _current_action != action:
		_current_action.exit()
	_current_action = action
	_current_score = score
	_current_action.enter()


## 射击窗口判断(与机动行为正交):目标在射程内且机头对齐 → 开火。
## 方向走 laser 的 AI 通道(set_ai_aim_dir,决策 #33 对齐),优先 mechanics 3D 预测点。
func _update_firing(ctx: Dictionary) -> void:
	if laser_mod == null:
		return
	var body: Node3D = ctx.get("nearest")
	var d: float = ctx.get("nearest_dist", INF)
	if body == null or d > FIRE_RANGE:
		laser_mod.set_firing(false)
		laser_mod.clear_ai_aim_dir()
		return

	var aim_dir := _aim_dir_to(body, ctx.get("nearest_abl"))
	var forward := -root.global_transform.basis.z.normalized()
	if forward.dot(aim_dir) > FIRE_ANGLE_COS:
		laser_mod.set_ai_aim_dir(aim_dir)
		laser_mod.set_firing(true)
	else:
		laser_mod.set_firing(false)
		laser_mod.clear_ai_aim_dir()


## 射击方向:优先 aim_mechanics 的 3D 预测点;缺 mechanics → 目标当前方向。
func _aim_dir_to(body: Node3D, abl: AbleToBeLocked) -> Vector3:
	var aim_dir := (body.global_position - root.global_position).normalized()
	if mechanics_mod and abl != null and is_instance_valid(abl):
		var data := mechanics_mod.get_predicted_aim_data(abl, BULLET_SPEED)
		if data.get("valid", false):
			var wp: Vector3 = data.get("world_pos", body.global_position)
			aim_dir = (wp - root.global_position).normalized()
	return aim_dir
