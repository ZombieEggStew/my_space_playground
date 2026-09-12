extends Node
class_name AIManeuvers

## 机动原语(.memo/ai_rework_plan.md §5):行为层的"手脚",只做两件事——
## 把"想往哪飞/多快"翻译成共享 move 模块的归一化命令(set_steer/set_throttle)。
## 转向率上限/加减速平滑由 move 模块内部保证(决策 #13/#28),本层不做物理,
## 因此敌人移动天然获得与玩家一致的"转向受限 + 平滑加减速"自然感(根治旧 AI 急转僵硬)。

var ai: AIModule


func setup(ai_mod: AIModule) -> void:
	ai = ai_mod


## 朝世界方向转向:换算成机体坐标的 yaw/pitch 归一化 steer。
## 放水(§11 二次调整):**不满舵**(上限 ±0.7)+ **小角度死区**(<5° 不转向)——
## 敌机转向"懒惰"、移动规律可预测,不会和玩家对转圈。
func steer_towards_dir(world_dir: Vector3) -> void:
	var m: EngineModule = ai.move_mod
	if m == null:
		return
	var dir := world_dir.normalized()
	if dir.length_squared() < 0.001:
		return
	var local := ai.root.global_transform.basis.inverse() * dir
	var yaw := atan2(-local.x, -local.z)
	var pitch := atan2(local.y, -local.z)
	var steer_x := clampf(yaw / (PI * 0.5), -1.0, 1.0) * 0.7
	var steer_y := clampf(pitch / (PI * 0.5), -1.0, 1.0) * 0.7
	if abs(yaw) < deg_to_rad(5.0):
		steer_x = 0.0
	if abs(pitch) < deg_to_rad(5.0):
		steer_y = 0.0
	m.set_steer(Vector2(steer_x, steer_y))


## 朝世界坐标点转向。
func steer_to_point(point: Vector3) -> void:
	var dir := point - ai.root.global_position
	if dir.length() < 0.001:
		return
	steer_towards_dir(dir)


## 滚转命令(-1..1;规避机动用,见 §11 二次调整)。
func set_roll(r: float) -> void:
	var m := ai.move_mod
	if m == null:
		return
	m.set_roll(clampf(r, -1.0, 1.0))


## 油门 0..1(-1..1:负 = 刹车);0.0 = 滑行。
func set_speed_ratio(r: float) -> void:
	var m: EngineModule = ai.move_mod
	if m == null:
		return
	m.set_throttle(clampf(r, -1.0, 1.0))
