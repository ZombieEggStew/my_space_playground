extends SceneTree

## P4/Ph1 敌人 AI 冒烟测试(无头,见 .memo/ai_rework_plan.md §8):
## 验证敌人船模块装配、AIModule 依赖解析、感知过滤、Utility 打分、命令输出、
## laser AI 通道。运行:
##   godot --headless --path . --script res://scripts/test/p4_ai_smoke_test.gd
## 退出码:0 = 全部通过;1 = 有失败。
## 覆盖范围:Ph1 = 敌人接模块系统 + AIModule 基础行为(patrol/orbit/tail_chase)。
## 2D 表现/机动自然度(急转、抽搐)由编辑器手动核对。

var _results: Array[String] = []
var _enemy: Node3D


func _initialize() -> void:
	var main_scene: PackedScene = load("res://scenes/game_scene.tscn")
	root.add_child(main_scene.instantiate())
	_run()


func _run() -> void:
	for i in range(150):
		await process_frame

	_enemy = _find_enemy()
	if _enemy == null:
		_results.append("FAIL: 场景中未找到敌人船(space_craft_5)")
		_finish()
		return

	var mm: Node = _enemy.get_node_or_null("ModulesManager")
	_passed_or_failed(mm != null, "敌人船有 ModulesManager")
	if mm == null:
		_finish()
		return

	var move: Node = mm.get_move_module() if mm.has_method("get_move_module") else null
	var laser: Node = mm.get_laser_module() if mm.has_method("get_laser_module") else null
	var radar: Node = mm.get_radar_module() if mm.has_method("get_radar_module") else null
	var mechanics: Node = mm.get_aim_mechanics_module() if mm.has_method("get_aim_mechanics_module") else null
	# 注意:不直接引用 AIModule 类标识符(测试脚本静态依赖会触发 autoload 标识符
	# 编译时序问题),用资源路径匹配注册表实例。
	var ai: Node = null
	for m in mm._modules:
		var s: Variant = m.get_script()
		if s != null and s.resource_path == "res://scripts/module/modules/brain/ai_module.gd":
			ai = m
			break

	_passed_or_failed(move != null, "敌人已装 move 模块")
	_passed_or_failed(laser != null, "敌人已装 laser 模块")
	_passed_or_failed(radar != null, "敌人已装 radar 模块")
	_passed_or_failed(mechanics != null, "敌人已装 aim_mechanics 模块")
	_passed_or_failed(ai != null, "敌人已装 AIModule")
	_passed_or_failed(_enemy.get_node_or_null("AI_Brain") == null, "旧 AI_Brain 已退役")

	if ai == null or move == null or laser == null:
		_results.append("FAIL: 关键模块缺失,后续检查跳过")
		_finish()
		return

	# 1. AIModule 依赖解析(决策 #32 事件驱动后经注册表 getter)
	_passed_or_failed(ai.move_mod == move, "AIModule.move_mod 解析")
	_passed_or_failed(ai.laser_mod == laser, "AIModule.laser_mod 解析")
	_passed_or_failed(ai.radar_mod == radar, "AIModule.radar_mod 解析")
	_passed_or_failed(ai.mechanics_mod == mechanics, "AIModule.mechanics_mod 解析")
	_passed_or_failed(ai.perception != null and ai.maneuvers != null, "AIModule 持有 perception/maneuvers")
	_passed_or_failed(ai.get_node_or_null("ActionPatrol") != null and ai.get_node_or_null("ActionOrbit") != null and ai.get_node_or_null("ActionTailChase") != null, "行为库就位(patrol/orbit/tail_chase)")

	# 2. Utility 打分:无目标时 patrol 兜底最高(profile 用 load 实例化,避免静态类引用)
	var profile: Variant = load("res://scripts/module/modules/brain/pilot_profile.gd").new()
	var s_patrol: float = ai.get_node("ActionPatrol").score({"nearest": null, "nearest_dist": INF}, profile)
	var s_orbit: float = ai.get_node("ActionOrbit").score({"nearest": null, "nearest_dist": INF}, profile)
	var s_tail: float = ai.get_node("ActionTailChase").score({"nearest": null, "nearest_dist": INF}, profile)
	_passed_or_failed(s_patrol > s_orbit and s_patrol > s_tail, "无目标时 patrol 分数最高(兜底)")

	# 3. 感知过滤:快照排除自身(敌人 radar 全量含自身,决策 #24 消费方过滤)
	ai.perception.refresh(1.0)
	var snap: Dictionary = ai.perception.snapshot
	var self_filtered := true
	for t: Dictionary in snap.get("targets", []):
		if t.get("body") == _enemy:
			self_filtered = false
	_passed_or_failed(self_filtered, "感知快照排除自身")
	_passed_or_failed(snap.has("nearest_abl"), "感知快照含 nearest_abl(供射击预测)")

	# 4. maneuvers 命令输出:归一化范围
	ai.maneuvers.set_speed_ratio(1.5)
	_passed_or_failed(abs(float(move._throttle)) <= 1.0 and float(move._throttle) == 1.0, "set_speed_ratio 输出 throttle 归一化")
	ai.maneuvers.steer_towards_dir(-_enemy.global_transform.basis.z)  # 机头方向 → steer ≈ 0
	var steer: Vector2 = move._steer
	_passed_or_failed(abs(steer.x) < 0.05 and abs(steer.y) < 0.05, "steer_towards_dir(机头方向) 输出零转向")

	# 5. laser AI 通道(决策 #33 对齐):set_ai_aim_dir 后射击基用 AI 方向
	laser.set_ai_aim_dir(Vector3.FORWARD)
	var aim_basis: Basis = laser._get_aim_basis(Vector2.INF)
	_passed_or_failed(aim_basis.z.normalized().dot(Vector3.FORWARD) > 0.99, "laser AI 通道:射击基用 set_ai_aim_dir 方向")
	laser.clear_ai_aim_dir()
	var fallback_basis: Basis = laser._get_aim_basis(Vector2.INF)
	var fwd: Vector3 = -_enemy.global_transform.basis.z.normalized()
	_passed_or_failed(fallback_basis.z.normalized().dot(fwd) > 0.99, "laser 清空 AI 方向后回退机头朝向")

	# 6. 决策循环运行过(旧 AI 退役后 AIPerception 已 refresh)
	_passed_or_failed(float(snap.get("time", -1.0)) >= 0.0, "感知快照时间戳有效(决策循环在跑)")

	_finish()


func _find_enemy() -> Node3D:
	var enemies: Array[Node] = []
	_find_enemy_rec(root, enemies)
	return enemies[0] as Node3D if enemies.size() > 0 else null


func _find_enemy_rec(node: Node, out: Array) -> void:
	if out.size() > 0:
		return
	if node is CharacterBody3D and node.has_method("get_team_id") and node.get_team_id() == TeamID.ENEMY \
		and node.get_node_or_null("ModulesManager") != null:
		out.append(node)
		return
	for child in node.get_children():
		_find_enemy_rec(child, out)


func _passed_or_failed(ok: bool, label: String) -> void:
	_results.append(("PASS: " if ok else "FAIL: ") + label)


func _finish() -> void:
	print("\n===== P4/Ph1 敌人 AI 冒烟测试 =====")
	for r in _results:
		print(r)
	var failed := 0
	for r in _results:
		if r.begins_with("FAIL"):
			failed += 1
	print("===== 结果:%d FAIL / %d 总检查点 =====" % [failed, _results.size()])
	quit(1 if failed > 0 else 0)
