extends AIAction
class_name ActionDisengage

## 低血脱离(Ph2,参数化自旧 StateDisengage):血量低于阈值时拉距 + 侧向切线逃离,
## 利用惯性拉开距离,脱离交战。score 随血量下降上升(caution 加权)。

const DISENGAGE_HEALTH := 0.35
const SAFE_DISTANCE := 500.0


var _escape_dir := Vector3.ZERO


func score(ctx: Dictionary, _profile: PilotProfile) -> float:
	var hr: float = ctx.get("health_ratio", 1.0)
	if hr > DISENGAGE_HEALTH:
		return 0.0
	var need := clampf(1.0 - hr / DISENGAGE_HEALTH, 0.0, 1.0)
	# 生存硬约束:残血逼近紧急阈值(0.9);不乘 caution(Ph3 再差异化)
	return 0.9 * (0.4 + 0.6 * need)


func enter() -> void:
	var root := ai.root
	var body: Node3D = ai.perception.snapshot.get("nearest")
	if body == null or not is_instance_valid(body):
		_escape_dir = root.global_transform.basis.x
		return
	# 远离目标 + 侧向切线(与旧 disengage 同思路,参数化)
	var to_target := (root.global_position - body.global_position).normalized()
	var side := to_target.cross(Vector3.UP)
	if side.length() < 0.01:
		side = root.global_transform.basis.x
	side = side.normalized()
	_escape_dir = (side * 0.5 + to_target).normalized()


func execute(_delta: float, _ctx: Dictionary) -> void:
	var m := ai.maneuvers
	m.steer_towards_dir(_escape_dir)
	m.set_speed_ratio(1.0)
	var boost := ai.get_booster_module()
	if boost:
		boost.set_boosting(true)


func exit() -> void:
	var boost := ai.get_booster_module()
	if boost:
		boost.set_boosting(false)
