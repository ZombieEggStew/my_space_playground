extends AIAction
class_name ActionTailChase

## 追尾猎手(参数化自旧 StateChase):已处于目标 6 点钟锥内时,贴尾保持 100~500m 距离。
## 距离控制:过近减速匹配、过远冲刺,维持射击窗口。

const TAIL_CONC_DOT := 0.7
const BACK_OFFSET := 10.0


func score(ctx: Dictionary, profile: PilotProfile) -> float:
	var body: Node3D = ctx.get("nearest")
	if body == null:
		return 0.0
	if not _is_tail_aligned(ctx, TAIL_CONC_DOT):
		return 0.0
	var d: float = ctx.get("nearest_dist", INF)
	if d > 600.0:
		return 0.0          # 过远不算咬尾
	return 0.65 * (0.4 + 0.6 * profile.aggression)


func execute(_delta: float, ctx: Dictionary) -> void:
	var body: Node3D = ctx.get("nearest")
	if body == null:
		return
	var m := ai.maneuvers
	var d: float = ctx.get("nearest_dist", INF)

	m.steer_to_point(body.global_position + _target_back_dir(body) * BACK_OFFSET)

	# 距离控制:太近减速,太远冲刺
	var speed := 0.9
	if d < 100.0:
		speed = 0.6
	elif d > 200.0:
		speed = 1.0
	m.set_speed_ratio(speed)
