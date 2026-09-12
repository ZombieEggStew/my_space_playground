extends AIAction
class_name ActionKeepDistance

## 近距逃离(§11 二次调整,用户反馈):距最近敌对目标小于 profile.min_engage_range
## (默认 100m)时主动拉开,避免贴脸互转圈。score 越近越高(生存约束,压过进攻行为)。


var _escape_dir := Vector3.ZERO


func score(ctx: Dictionary, _profile: PilotProfile) -> float:
	var body: Node3D = ctx.get("nearest")
	var d: float = ctx.get("nearest_dist", INF)
	if body == null:
		return 0.0
	var min_r: float = ai.profile.min_engage_range
	if d >= min_r:
		return 0.0
	return 0.9 * sqrt(1.0 - d / min_r)


func enter() -> void:
	var root := ai.root
	var body: Node3D = ai.perception.snapshot.get("nearest")
	if body == null or not is_instance_valid(body):
		_escape_dir = root.global_transform.basis.x
		return
	# 远离目标为主 + 轻微侧向(不完全直线后退,保持一点机动)
	var away := (root.global_position - body.global_position).normalized()
	var side := away.cross(Vector3.UP)
	if side.length() < 0.01:
		side = root.global_transform.basis.x
	_escape_dir = (away + side.normalized() * 0.4).normalized()


func execute(_delta: float, _ctx: Dictionary) -> void:
	var m := ai.maneuvers
	m.steer_towards_dir(_escape_dir)
	m.set_speed_ratio(0.9)
