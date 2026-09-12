extends AIAction
class_name ActionPatrol

## 巡航兜底行为:无目标或目标很远时低速漂移,保持敌机"活着"。
## score 恒有值(兜底),目标接近后让位给 orbit/tail_chase。

const PATROL_RADIUS := 1000.0


func score(_ctx: Dictionary, _profile: PilotProfile) -> float:
	var d: float = _ctx.get("nearest_dist", INF)
	if d < PATROL_RADIUS:
		return 0.05  # 目标在附近:进攻行为应压过巡航
	return 0.2      # 兜底:始终可巡航


func execute(_delta: float, _ctx: Dictionary) -> void:
	var m := ai.maneuvers
	# 低速朝机头前方漂移(绕当前位置缓慢移动,不自旋)
	var fwd := -ai.root.global_transform.basis.z
	m.steer_to_point(ai.root.global_position + fwd * 80.0)
	m.set_speed_ratio(0.3)
