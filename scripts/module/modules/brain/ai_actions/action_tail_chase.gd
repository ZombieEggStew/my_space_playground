extends AIAction
class_name ActionTailChase

## 追尾猎手(§11 M5 放水):不再死贴 6 点——
## ①目标点侧偏 25~40m(不完美贴尾,玩家可见其转弯圈外侧);
## ②周期性"跟丢"(每 2~3s 概率松口,让位 orbit 重新找位),给玩家摆脱窗口。

const TAIL_CONC_DOT := 0.7
const BACK_OFFSET := 10.0


var _side_offset := 0.0    # 目标点侧偏(米,enter/复位时随机)
var _lose_timer := 0.0     # 跟丢倒计时
var _losing := false       # 本回合"跟丢"(score=0,让位 orbit)
var _lose_reset := 0.0     # 跟丢后冷却:期间重新找位
var _burst_timer := 0.0    # 转向脉冲:转向相位剩余(§11 二次调整:规律化)
var _cruise_timer := 0.0   # 转向脉冲:直飞相位剩余(不转向)


func score(ctx: Dictionary, profile: PilotProfile) -> float:
	var body: Node3D = ctx.get("nearest")
	if body == null:
		return 0.0
	if _losing:
		return 0.0
	if not _is_tail_aligned(ctx, TAIL_CONC_DOT):
		return 0.0
	var d: float = ctx.get("nearest_dist", INF)
	if d > 600.0 or d < ai.profile.min_engage_range:
		return 0.0  # 过近让位 keep_distance(§11 二次调整)
	return 0.65 * (0.4 + 0.6 * profile.aggression)


func enter() -> void:
	_losing = false
	_side_offset = randf_range(-40.0, 40.0)
	_lose_timer = randf_range(2.0, 3.0)
	_burst_timer = 0.0
	_cruise_timer = 0.0


func execute(delta: float, ctx: Dictionary) -> void:
	var body: Node3D = ctx.get("nearest")
	if body == null:
		return

	if _losing:
		# 跟丢冷却:期间不咬(score=0 让位 orbit 重新找位),复位后重新咬
		_lose_reset -= delta
		if _lose_reset <= 0.0:
			_losing = false
			_side_offset = randf_range(-40.0, 40.0)
			_lose_timer = randf_range(2.0, 3.0)
		return

	_lose_timer -= delta
	if _lose_timer <= 0.0:
		_losing = true
		_lose_reset = 1.5
		return

	var m := ai.maneuvers
	var d: float = ctx.get("nearest_dist", INF)
	var speed := 0.9
	if d < 100.0:
		speed = 0.6
	elif d > 200.0:
		speed = 1.0

	# 转向脉冲(§11 二次调整):转 0.8~1.4s → 直飞 0.4~0.8s 交替,
	# 移动"锯齿状规律、可预测",不再与玩家对转圈。
	if _cruise_timer > 0.0:
		_cruise_timer -= delta
		m.set_speed_ratio(speed)  # 直飞相位:只给油门不转向
		return
	_burst_timer -= delta
	if _burst_timer <= 0.0:
		_burst_timer = randf_range(0.8, 1.4)
		_cruise_timer = randf_range(0.4, 0.8)
	var back := _target_back_dir(body)
	var side := body.global_transform.basis.x  # 目标机体右侧
	m.steer_to_point(body.global_position + back * BACK_OFFSET + side * _side_offset)
	m.set_speed_ratio(speed)
