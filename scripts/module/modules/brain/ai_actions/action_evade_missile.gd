extends AIAction
class_name ActionEvadeMissile

## 规避导弹(Ph2):导弹进入威胁距离时横向急转 + boost,摆脱导弹制导。
## score 随导弹接近单调上升,接近时逼近紧急阈值(0.9)直接打断当前行为。

const MISSILE_THREAT_RANGE := 250.0


var _evade_dir := Vector3.ZERO
var _roll_dir := 0.0  # §11 二次调整:规避时连续滚转方向(±1)


func score(ctx: Dictionary, _profile: PilotProfile) -> float:
	var md: float = ctx.get("nearest_missile_dist", INF)
	if md == INF or md > MISSILE_THREAT_RANGE:
		return 0.0
	var threat := clampf(1.0 - md / MISSILE_THREAT_RANGE, 0.0, 1.0)
	# 生存硬约束:导弹贴脸逼近紧急阈值(0.9);不乘 caution(Ph3 再差异化)
	return 0.9 * (0.4 + 0.6 * threat)


func enter() -> void:
	var root := ai.root
	var missile: Node3D = ai.perception.snapshot.get("nearest_missile")
	if missile == null or not is_instance_valid(missile):
		_evade_dir = root.global_transform.basis.x
		return
	# 朝导弹方向的横向急转(垂直于导弹视线),随机选一侧,叠加"远离"分量
	var to_missile := (missile.global_position - root.global_position).normalized()
	var side := to_missile.cross(Vector3.UP)
	if side.length() < 0.01:
		side = root.global_transform.basis.x
	side = side.normalized()
	if randf() < 0.5:
		side = -side
	_evade_dir = (side - to_missile * 0.3).normalized()
	_roll_dir = 1.0 if randf() < 0.5 else -1.0


func execute(_delta: float, _ctx: Dictionary) -> void:
	var m := ai.maneuvers
	m.steer_towards_dir(_evade_dir)
	m.set_speed_ratio(1.0)
	var boost := ai.get_booster_module()
	if boost:
		boost.set_boosting(true)
	m.set_roll(_roll_dir)  # §11 二次调整:连续滚转(视觉机动)


func exit() -> void:
	var boost := ai.get_booster_module()
	if boost:
		boost.set_boosting(false)
	var m := ai.maneuvers
	m.set_roll(0.0)
