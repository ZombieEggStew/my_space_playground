extends Module
class_name AimMechanicsModule

## 共享瞄准力学(决策 #11/#20,P5 落地):给定目标算 3D 预测点/拦截时间,
## 以及"屏幕点 → 世界瞄准方向"(玩家激光用)。吸收原 module_predict_aim(决策 #20,
## 独立 predict 模块/场景已删)。
##
## 职责边界(两通道,决策 #23):
## - 本模块只算 **3D 数据**:get_predicted_aim_data 返回世界预测点/拦截时间/距离,
##   不投影、不渲染(投影归 aim_view,决策 #18);AI(P4)由此算射击角度。
## - 目标选择(悬停/RMB/AI 选谁)是大脑侧 target_selection 的职责,本模块不持有选择状态;
##   locked_target 只是"当前值"(决策 #12 连续量),由 selection 锁定变化时经
##   set_locked_target() 直接推入,不走总线(变化脉冲 on_player_lock_target
##   已由 selection 发 ② ShipBus)。
## - 缺相机(如未来敌人复用)不硬崩:预测数学不依赖相机,仅准星方向接口降级为机头朝向。

var cam_main: Camera3D

var locked_target: AbleToBeLocked
var aim_ray_length := 5000.0  # 非锁定时使用,预测射击点


func _ready() -> void:
	cam_main = modules_manager.get_camera_module().get_main_camera()
	if cam_main == null:
		Log.log_missing_component(self, "main camera")
		# 不 queue_free:预测数学不依赖相机,仅 get_aim_direction_from_crosshair 降级


## selection 锁定变化时推入"当前值"(决策 #12:连续量直接方法)。
func set_locked_target(target: AbleToBeLocked) -> void:
	locked_target = target


## 玩家激光:把准星屏幕点换算成世界瞄准方向;锁定时射线长 = 到锁定目标距离
## (瞄准点落在目标当前位置)。缺相机 → 机头朝向降级。
func get_aim_direction_from_crosshair(aim_screen_pos: Vector2) -> Vector3:
	if cam_main == null:
		return -root.global_transform.basis.z.normalized() if root else Vector3.FORWARD
	if is_instance_valid(locked_target):
		aim_ray_length = locked_target.global_position.distance_to(root.global_position)

	var ray_origin := cam_main.project_ray_origin(aim_screen_pos)
	var ray_dir := cam_main.project_ray_normal(aim_screen_pos).normalized()
	var aim_point := ray_origin + ray_dir * aim_ray_length
	return (aim_point - root.global_transform.origin).normalized()


## 给定目标与弹速,算 3D 预测点/拦截时间(决策 #18/#23:只算 3D,投影由 aim_view 自理)。
## 返回 {valid, world_pos, time, distance};目标失效/弹速非法 → valid=false。
func get_predicted_aim_data(target: AbleToBeLocked, bullet_speed: float) -> Dictionary:
	var out := {"valid": false, "world_pos": Vector3.ZERO, "time": 0.0, "distance": 0.0}
	if not is_instance_valid(target) or target.target_node3d == null:
		return out
	if bullet_speed <= 0.0:
		return out

	var target_world_pos := target.target_node3d.global_position
	var target_vel := get_target_velocity(target.target_node3d)

	var relative_pos := target_world_pos - root.global_position
	var intercept_t := solve_intercept_time(relative_pos, target_vel, bullet_speed) as float
	intercept_t = max(intercept_t, 0.0)

	var predicted_world_pos := target_world_pos + target_vel * intercept_t

	out["valid"] = true
	out["world_pos"] = predicted_world_pos
	out["time"] = intercept_t
	out["distance"] = root.global_position.distance_to(predicted_world_pos)
	return out


## 二次方程解析拦截时间(原 PredictAimModule.solve_intercept_time,原样迁移)。
static func solve_intercept_time(relative_pos: Vector3, target_vel: Vector3, proj_speed: float) -> float:
	var s := max(proj_speed, 0.001) as float
	var a := target_vel.dot(target_vel) - s * s
	var b := 2.0 * relative_pos.dot(target_vel)
	var c := relative_pos.dot(relative_pos)

	if abs(a) < 0.0001:
		if abs(b) < 0.0001:
			return c / s
		var linear_t := -c / b
		return linear_t if linear_t > 0.0 else c / s

	var disc := b * b - 4.0 * a * c
	if disc < 0.0:
		return c / s

	var sqrt_disc := sqrt(disc)
	var t1 := (-b - sqrt_disc) / (2.0 * a)
	var t2 := (-b + sqrt_disc) / (2.0 * a)

	var t := INF
	if t1 > 0.0:
		t = t1
	if t2 > 0.0:
		t = min(t, t2)
	if t == INF:
		return c / s
	return t


## 读取目标速度(CharacterBody3D 的 velocity 属性);无则 ZERO。
static func get_target_velocity(target: Node3D) -> Vector3:
	if target == null:
		return Vector3.ZERO
	var v = target.get("velocity")
	if v is Vector3:
		return v
	return Vector3.ZERO
