extends SceneTree

## P5 aim 拆两层冒烟测试(无头):验证 AimMechanicsModule(共享)与 TargetSelectionModule
## (大脑侧)的拆分装配与数据流。运行:
##   godot --headless --path . --script res://scripts/test/p5_aim_split_smoke_test.gd
## 退出码:0 = 全部通过;1 = 有失败。
##
## 覆盖范围:P5 = mechanics 安装/被 laser 接线 / 预测函数(P4 AI 将复用);
## selection → mechanics 锁定当前值推送 / ship_bus 离散脉冲 / aim_view 呈现。
## 2D 视觉效果(准星/预测圈/面板布局)由编辑器手动核对。

var _player: Node
var _mm: Node
var _mechanics: Node
var _selection: Node
var _laser: Node
var _results: Array[String] = []


func _initialize() -> void:
	var main_scene: PackedScene = load("res://scenes/game_scene.tscn")
	root.add_child(main_scene.instantiate())
	_run()


func _run() -> void:
	for i in range(90):
		await process_frame

	_player = (root.get_node_or_null("/root/GameManager") as Node).get_current_player() if root.get_node_or_null("/root/GameManager") else null
	if _player == null:
		_results.append("FAIL: 玩家未注册")
		_finish()
		return

	_mm = _player.get_node_or_null("ModulesManager")
	if _mm == null:
		_results.append("FAIL: 无 ModulesManager")
		_finish()
		return

	_mechanics = _mm.get_aim_mechanics_module() if _mm.has_method("get_aim_mechanics_module") else null
	_selection = _mm.get_target_selection_module() if _mm.has_method("get_target_selection_module") else null
	_laser = _mm.get_laser_module() if _mm.has_method("get_laser_module") else null

	# 1. 拆分装配:两个新槽位就位
	_passed_or_failed(_mechanics != null, "aim_mechanics 已安装(get_aim_mechanics_module)")
	_passed_or_failed(_selection != null, "target_selection 已安装(get_target_selection_module)")
	_passed_or_failed(_selection.aim_view != null, "selection 持有 aim_view")
	_passed_or_failed(_laser != null and _laser.aim_modrule == _mechanics, "laser 已接线 AimMechanicsModule")

	if _mechanics == null or _selection == null:
		_results.append("FAIL: mechanics/selection 缺失,后续检查跳过")
		_finish()
		return

	# 2. 选一个可侦测的非同阵营目标(雷达全量含玩家自身,消费方按阵营过滤)
	var radar: Node = _mm.get_radar_module() if _mm.has_method("get_radar_module") else null
	var target: Node = null
	if radar != null:
		for t in radar.get_targets_found():
			if is_instance_valid(t) and t.get_team_id() != _player.get_team_id():
				target = t
				break
	_passed_or_failed(target != null, "radar 视野内有非同阵营可侦测目标(全量含自身,过滤后取敌)" if target != null else "FAIL(无目标):radar 视野内无非同阵营目标")

	# 3. selection.set_locked_target → mechanics 当前值 + ship_bus 脉冲 + aim_view 呈现
	var lock_args: Array = []
	_player.ship_bus.on_player_lock_target.connect(func(...args): lock_args.append(args))
	if target != null:
		_selection.set_locked_target(target)
	await process_frame
	_passed_or_failed(_mechanics.locked_target == target, "selection 锁定 → mechanics.locked_target 推送")
	_passed_or_failed(_selection.aim_view.get("_locked_target") == target, "selection 锁定 → aim_view 呈现")
	_passed_or_failed(lock_args.size() > 0 and lock_args[0][0] == target, "selection 锁定 → ship_bus.on_player_lock_target(target)")

	# 4. 预测函数(P4 AI 复用入口):3D 预测点/拦截时间有效
	if target != null:
		var aim_data: Dictionary = _mechanics.get_predicted_aim_data(target, float(_laser.get_bullet_speed()))
		var valid: bool = aim_data.get("valid", false)
		var world_pos: Vector3 = aim_data.get("world_pos", Vector3.ZERO)
		_passed_or_failed(valid and world_pos != Vector3.ZERO, "get_predicted_aim_data 返回有效 3D 预测点")
		_passed_or_failed(aim_data.get("time", -1.0) >= 0.0, "拦截时间非负")

	# 5. 准星方向(激光用):返回归一化方向且不崩溃
	var dir: Vector3 = _mechanics.get_aim_direction_from_crosshair(Vector2(960, 540))
	_passed_or_failed(dir.length() > 0.99 and dir.length() < 1.01, "get_aim_direction_from_crosshair 返回归一化方向")

	# 6. 解锁 → 清理同步
	if target != null:
		_selection.set_locked_target(null)
		await process_frame
		_passed_or_failed(_mechanics.locked_target == null, "解锁 → mechanics.locked_target 清空")

	_finish()


func _passed_or_failed(ok: bool, label: String) -> void:
	_results.append(("PASS: " if ok else "FAIL: ") + label)


func _finish() -> void:
	print("\n===== P5 aim 拆两层冒烟测试 =====")
	for r in _results:
		print(r)
	var failed := 0
	for r in _results:
		if r.begins_with("FAIL"):
			failed += 1
	print("===== 结果:%d FAIL / %d 总检查点 =====" % [failed, _results.size()])
	quit(1 if failed > 0 else 0)
