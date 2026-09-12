extends AIAction
class_name ActionOrbit

## 轨道绕后(参数化自旧 StateOrbit):目标在中近距离时侧向偏移盘旋,寻找咬尾切入机会。
## 远距直扑目标后方预判点;近距叠加侧向偏移形成螺旋逼近,避免直线撞上去。

const ATTACK_RANGE := 600.0
const MIN_DIST := 40.0
const BACK_OFFSET := 10.0


func score(ctx: Dictionary, profile: PilotProfile) -> float:
	var body: Node3D = ctx.get("nearest")
	if body == null:
		return 0.0
	var d: float = ctx.get("nearest_dist", INF)
	if d > ATTACK_RANGE:
		return 0.15          # 尚远:低分接近,patrol 让位
	if d < MIN_DIST:
		return 0.15          # 过近:避让倾向
	if _is_tail_aligned(ctx):
		return 0.1           # 已咬尾:让位 tail_chase
	return 0.55 * (0.3 + 0.7 * profile.aggression)


func execute(_delta: float, ctx: Dictionary) -> void:
	var body: Node3D = ctx.get("nearest")
	if body == null:
		return
	var m := ai.maneuvers
	var root := ai.root

	var back_dir := _target_back_dir(body)
	var to_target := body.global_position - root.global_position
	var dist := to_target.length()

	var target_pos := body.global_position + back_dir * BACK_OFFSET
	if dist <= ATTACK_RANGE:
		# 近距:加侧向偏移,距离越近偏移越小,形成螺旋逼近
		var side := to_target.cross(Vector3.UP).normalized()
		target_pos += side * (dist * 0.5)

	m.steer_to_point(target_pos)
	m.set_speed_ratio(0.8)
