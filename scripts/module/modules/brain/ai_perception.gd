extends Node
class_name AIPerception

## 感知层(.memo/ai_rework_plan.md §3):每决策 tick 由 AIModule 调 refresh() 重建快照。
## 输入:radar 身体目标列表(全量含自身,决策 #24)+ 自身状态;输出:过滤后的快照。
## 过滤职责(消费方/感知层,决策 #23):排除自身、同阵营、超出感知半径的目标。
## 人类化:感知只按决策节流刷新(反应延迟 = 决策间隔),Ph3 再加位置噪声。

## 感知半径(米):radar 身体不做事先过滤(决策 #24 全量给),感知层按半径收敛。
@export_range(100.0, 5000.0) var perception_radius := 1500.0

var ai: AIModule
## 当前快照(只读给行为打分/执行;每 refresh() 重建)
var snapshot: Dictionary = {}

## 最近一次被打的世界时间(HealthComponent.changed 驱动;Ph2 威胁感知)
var last_hit_time := -INF
## 最近一次被打的伤害量(封顶,供威胁强度)
var last_hit_strength := 0.0
## 最近一次 refresh 的世界时间(供信号回调记录时间戳)
var _time := 0.0


func setup(ai_mod: AIModule) -> void:
	ai = ai_mod
	var hc: Variant = ai.root.get_health_component() if ai.root.has_method("get_health_component") else null
	if hc != null and hc is HealthComponent:
		hc.changed.connect(_on_health_changed)


func _exit_tree() -> void:
	var hc: Variant = ai.root.get_health_component() if ai.root != null and ai.root.has_method("get_health_component") else null
	if hc != null and hc is HealthComponent and hc.changed.is_connected(_on_health_changed):
		hc.changed.disconnect(_on_health_changed)


## 被打回调(决策节流只读快照;这里是事件脉冲,只记时间戳不重算)
func _on_health_changed(_new_h: int, _new_max: int, changed_amount: int) -> void:
	if changed_amount < 0:
		last_hit_time = _time
		last_hit_strength = min(float(-changed_amount), 50.0)


## 重建快照(决策节流时才调,不每帧)。targets 元素:
## {target: AbleToBeLocked, body: Node3D, dist: float, rel_pos: Vector3, rel_vel: Vector3}
func refresh(time: float) -> void:
	_time = time
	var root := ai.root
	var targets: Array = []
	var nearest: Node3D = null
	var nearest_abl: AbleToBeLocked = null
	var nearest_dist := INF

	var radar: RadarModule = ai.radar_mod
	var found: Array[AbleToBeLocked] = []
	if radar != null:
		found = radar.get_targets_found()
	for t: AbleToBeLocked in found:
		if not is_instance_valid(t) or t.target_node3d == null:
			continue
		var body: Node3D = t.target_node3d
		if body == root:
			continue
		if body.has_method("get_team_id") and body.get_team_id() == root.get_team_id():
			continue
		var rel := body.global_position - root.global_position
		var dist := rel.length()
		if dist > perception_radius:
			continue
		var entry := {
			"target": t,
			"body": body,
			"dist": dist,
			"rel_pos": rel,
			"rel_vel": _body_velocity(body) - root.velocity,
		}
		targets.append(entry)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = body
			nearest_abl = t

	# Ph2 威胁感知:血量比例 / 最近被打 / 最近导弹(组扫描,量小;导弹进组见 missile.gd)
	var missile: Node3D = null
	var missile_dist := INF
	for m in get_tree().get_nodes_in_group("missile"):
		if not is_instance_valid(m):
			continue
		var md: float = (m.global_position - root.global_position).length()
		if md < missile_dist:
			missile_dist = md
			missile = m

	snapshot = {
		"targets": targets,
		"nearest": nearest,
		"nearest_abl": nearest_abl,
		"nearest_dist": nearest_dist,
		"time": time,
		"health_ratio": _health_ratio(root),
		"last_hit_time": last_hit_time,
		"last_hit_strength": last_hit_strength,
		"nearest_missile": missile,
		"nearest_missile_dist": missile_dist,
		# §11 放水:玩家引用(球面巡逻/距离上限的球心)
		"player": _get_player(),
	}


func _get_player() -> Node3D:
	var p: Variant = GameManager.get_current_player() if GameManager.has_method("get_current_player") else null
	return p as Node3D if p != null else null


func _health_ratio(root: Node3D) -> float:
	var hc: Variant = root.get_health_component() if root.has_method("get_health_component") else null
	if hc != null and hc is HealthComponent and hc.get_max_health() > 0:
		return float(hc.get_health()) / float(hc.get_max_health())
	return 1.0


func _body_velocity(body: Node3D) -> Vector3:
	if body == null:
		return Vector3.ZERO
	var v: Variant = body.get("velocity")
	if v is Vector3:
		return v
	return Vector3.ZERO
