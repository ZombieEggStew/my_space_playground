extends AIAction
class_name ActionPatrol

## 球面巡逻(§11 M3,替换原"朝机头前方漂移"——那个会越飞越远):
## 无事可做时,以玩家为球心、profile.orbit_radius 半径的球面上规律绕行
## (绕圈 + 轻微上下波动,方向周期性翻转)。既"别离玩家太远",又有规律可循、
## 可被玩家预测。玩家未注册时兜底原地慢速漂移。

const PATROL_RADIUS := 1000.0  # 目标距离阈值:目标进入此范围让位进攻行为


var _flip_dir := 1.0
var _flip_timer := 0.0


func score(_ctx: Dictionary, _profile: PilotProfile) -> float:
	var d: float = _ctx.get("nearest_dist", INF)
	if d < PATROL_RADIUS:
		return 0.05  # 目标在附近:进攻行为应压过巡航
	return 0.2      # 兜底:始终可巡航


func execute(delta: float, ctx: Dictionary) -> void:
	var m := ai.maneuvers
	var player: Node3D = ctx.get("player")
	if player == null or not is_instance_valid(player):
		# 无玩家:原地慢速漂移兜底
		var fwd := -ai.root.global_transform.basis.z
		m.steer_to_point(ai.root.global_position + fwd * 50.0)
		m.set_speed_ratio(0.3)
		return

	var center := player.global_position
	var to_center := center - ai.root.global_position
	var radius: float = ai.profile.orbit_radius

	# 周期性翻转绕行方向(4~8s)
	_flip_timer -= delta
	if _flip_timer <= 0.0:
		_flip_dir = 1.0 if randf() < 0.5 else -1.0
		_flip_timer = randf_range(4.0, 8.0)

	var orbit_dir := Vector3.UP.cross(to_center.normalized())
	if orbit_dir.length() < 0.01:
		orbit_dir = ai.root.global_transform.basis.x
	orbit_dir = orbit_dir.normalized() * _flip_dir
	# 目标点 = 球面上沿切向偏移的点(带轻微上下波动,保持规律性)
	var target := center + (to_center.normalized() + orbit_dir * 0.8 + Vector3.UP * 0.15).normalized() * radius
	m.steer_to_point(target)
	m.set_speed_ratio(0.5)
