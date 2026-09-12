extends AIAction
class_name ActionEvadeFire

## 规避子弹(Ph2,复活旧 EVADE 逻辑并参数化):被打后急转脱离。
## score 由"距上次被打的时间"指数衰减驱动——被打瞬间分数逼近紧急阈值,
## Utility 动态优先级让防御瞬间压过进攻(根治旧双 SM 无协调)。
## execute:向 enter 时固定的随机方向急转 + 满油门 + 短促 boost。

const HIT_DECAY := 2.0


var _evade_dir := Vector3.ZERO


func score(ctx: Dictionary, _profile: PilotProfile) -> float:
	var last_hit: float = ctx.get("last_hit_time", -INF)
	if last_hit < 0.0:
		return 0.0
	var age := float(ctx.get("time", 0.0)) - last_hit
	if age < 0.0 or age > HIT_DECAY:
		return 0.0
	var intensity := exp(-age / 1.5)  # 1.0 → 0.0
	# 生存硬约束:被打瞬间逼近紧急阈值(0.9)立即打断进攻行为;不乘 caution(Ph3 再差异化)
	return 0.9 * (0.4 + 0.6 * intensity)


func enter() -> void:
	var root := ai.root
	var side := root.global_transform.basis.x * randf_range(-1.0, 1.0)
	var up := root.global_transform.basis.y * randf_range(0.5, 1.5)
	_evade_dir = (side + up).normalized()
	if _evade_dir.length_squared() < 0.01:
		_evade_dir = root.global_transform.basis.x


func execute(_delta: float, _ctx: Dictionary) -> void:
	var m := ai.maneuvers
	m.steer_towards_dir(_evade_dir)
	m.set_speed_ratio(1.0)
	var boost := ai.get_booster_module()
	if boost:
		boost.set_boosting(true)


func exit() -> void:
	var boost := ai.get_booster_module()
	if boost:
		boost.set_boosting(false)
