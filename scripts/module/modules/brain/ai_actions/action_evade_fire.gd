extends AIAction
class_name ActionEvadeFire

## 规避子弹(§11 M6 轻量化):被激光攻击时**小幅**横移规避——
## 速度 ~0.7、不 boost、~1s 结束、方向限侧向/斜前(削减远离分量)。
## 目的:被打有反应(不再无脑硬吃),但不会满油门飞离战场(用户实测问题 2)。

const HIT_DECAY := 1.2


var _evade_dir := Vector3.ZERO


func score(ctx: Dictionary, _profile: PilotProfile) -> float:
	var last_hit: float = ctx.get("last_hit_time", -INF)
	if last_hit < 0.0:
		return 0.0
	var age := float(ctx.get("time", 0.0)) - last_hit
	if age < 0.0 or age > HIT_DECAY:
		return 0.0
	var intensity := exp(-age / 1.0)  # 1.0 → 0.0
	return 0.9 * (0.4 + 0.6 * intensity)


func enter() -> void:
	var root := ai.root
	var fwd := -root.global_transform.basis.z
	var side := root.global_transform.basis.x * randf_range(-1.0, 1.0)
	var up := root.global_transform.basis.y * randf_range(0.2, 0.6)
	_evade_dir = (side + fwd * 0.3 + up * 0.4).normalized()
	# 削减"远离最近目标(攻击者)"分量:方向明显背离目标时折向侧向,避免飞离战场
	var body: Node3D = ai.perception.snapshot.get("nearest")
	if body != null and is_instance_valid(body):
		var to_target := (body.global_position - root.global_position).normalized()
		var away := _evade_dir.dot(to_target)
		if away > 0.4:
			_evade_dir = (_evade_dir - to_target * away).normalized()
			if _evade_dir.length_squared() < 0.01:
				_evade_dir = root.global_transform.basis.x


func execute(_delta: float, _ctx: Dictionary) -> void:
	var m := ai.maneuvers
	m.steer_towards_dir(_evade_dir)
	m.set_speed_ratio(0.7)
