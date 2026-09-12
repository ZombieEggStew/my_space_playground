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


func setup(ai_mod: AIModule) -> void:
	ai = ai_mod


## 重建快照(决策节流时才调,不每帧)。targets 元素:
## {target: AbleToBeLocked, body: Node3D, dist: float, rel_pos: Vector3, rel_vel: Vector3}
func refresh(time: float) -> void:
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

	snapshot = {
		"targets": targets,
		"nearest": nearest,
		"nearest_abl": nearest_abl,
		"nearest_dist": nearest_dist,
		"time": time,
	}


func _body_velocity(body: Node3D) -> Vector3:
	if body == null:
		return Vector3.ZERO
	var v: Variant = body.get("velocity")
	if v is Vector3:
		return v
	return Vector3.ZERO
