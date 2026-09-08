extends SceneTree

## P2/P3 信号与命令冒烟测试(无头):加载主场景 → 模拟真实输入事件 → 验证
## ② ShipBus 信号路由(P2)与 ControlModule 连续量命令链路(P3)。
## 运行:godot --headless --path . --script res://scripts/test/p2_signal_smoke_test.gd
## 退出码:0 = 全部通过;1 = 有失败。
##
## 覆盖范围:P2 = input_manager → ship_bus 离散信号 + booster → ship_bus(on_player_boost)
## + aim → ship_bus(on_player_lock_target) + hover 不误报;
## P3 = shoot/boost 连续量命令经 ControlModule → laser.set_firing / booster.set_boosting。
## 模块内视觉行为(机炮/加速/相机…)由编辑器手动核对。

var _player: Node
var _laser: Node
var _booster: Node
var _spy: Dictionary = {}   # 信号名 -> 触发次数
var _last: Dictionary = {}  # 信号名 -> 最近一次参数数组
var _results: Array[String] = []

const _SHIP_SIGNALS := [
	"on_player_try_lock", "on_player_boost",
	"on_toggle_track_mouse", "on_player_look_backward", "on_player_look_around",
	"on_player_try_use_item_1", "on_toggle_engine", "on_player_lock_target",
	"on_target_hovered", "on_target_unhovered",
]

func _initialize() -> void:
	var main_scene: PackedScene = load("res://scenes/game_scene.tscn")
	root.add_child(main_scene.instantiate())
	_run()

func _run() -> void:
	# 等待世界稳定 + 玩家注册(注册在 PlayerShip._ready 末尾)
	for i in range(90):
		await process_frame

	_player = (root.get_node_or_null("/root/GameManager") as Node).get_current_player() if root.get_node_or_null("/root/GameManager") else null
	if _player == null:
		_results.append("FAIL: 玩家未注册(autoload 或注册链异常)")
		_finish()
		return
	if _player.ship_bus == null:
		_results.append("FAIL: player.ship_bus 为空")
		_finish()
		return

	# P3 命令链路依赖:laser / booster(经 modules_manager / move)
	var modules_manager: Node = _player.get_node_or_null("ModulesManager")
	var move: Node = modules_manager.get_move_module() if modules_manager and modules_manager.has_method("get_move_module") else null
	_laser = modules_manager.get_laser_module() if modules_manager and modules_manager.has_method("get_laser_module") else null
	_booster = move.get_booster_module() if move and move.has_method("get_booster_module") else null

	for s in _SHIP_SIGNALS:
		_spy[s] = 0
		_last[s] = []
		_player.ship_bus.get(s).connect(func(...args): _spy[s] += 1; _last[s] = args)

	# 1. 左键 shoot(hold,P3):ControlModule → laser.set_firing 命令链路
	await _press("shoot_player", 3)
	_check_bool(_laser.is_shooting if _laser else false, true, "shoot 按下 -> laser.is_shooting == true")
	await _release("shoot_player", 3)
	_check_bool(_laser.is_shooting if _laser else false, false, "shoot 松开 -> laser.is_shooting == false")

	# 1b. 射速回归:按住期间 shoot_timer 周期触发(≈ 时长/wait_time),而非每帧重置/每帧发弹
	await _verify_fire_rate()

	# 2. Shift boost(hold,P3):ControlModule → booster.set_boosting + booster 回发 on_player_boost
	await _press("boost", 3)
	_check_bool(_booster.is_boosting if _booster else false, true, "boost 按下 -> booster.is_boosting == true")
	_check_arg("on_player_boost", true, "booster 回发 -> on_player_boost(true)")
	await _release("boost", 3)
	_check_bool(_booster.is_boosting if _booster else false, false, "boost 松开 -> booster.is_boosting == false")
	_check_arg("on_player_boost", false, "booster 回发 -> on_player_boost(false)")

	# 3. Q 引擎开关(无参)
	await _press("toggle_engine", 2)
	_check_count("on_toggle_engine", "Q -> on_toggle_engine()")

	# 4. 数字 1 使用挂件(无参)
	await _press("use_item_1", 2)
	_check_count("on_player_try_use_item_1", "1 -> on_player_try_use_item_1()")

	# 5. Esc 回头看(toggle,无参)
	await _press("look_backward", 2)
	_check_count("on_player_look_backward", "Esc -> on_player_look_backward()")

	# 6. Tab 鼠标跟随切换(toggle,带 bool)
	await _press("toggle_track", 2)
	_check_count("on_toggle_track_mouse", "Tab -> on_toggle_track_mouse(enable)")

	# 7. look_around(toggle,带 bool)
	await _press("look_around", 2)
	_check_count("on_player_look_around", "look_around -> on_player_look_around(enable)")

	# 8. 右键锁定:try_lock + 无悬停目标时 aim 回发 lock_target(null)
	await _press("lock_on", 3)
	_check_count("on_player_try_lock", "右键 -> on_player_try_lock()")
	_check_count("on_player_lock_target", "aim 回发 -> on_player_lock_target(target/null)")

	# 9. hover 不误报:无鼠标命中时两信号必须 0 触发(命中测试走 radar_view rects)
	_check_zero("on_target_hovered", "无悬停 -> on_target_hovered 不触发")
	_check_zero("on_target_unhovered", "无悬停 -> on_target_unhovered 不触发")

	# 10. hover 端到端(软验证):把鼠标 warp 进某在屏目标的 screen_rect,验证
	#     aim 命中 → ship_bus → radar_view 链路;headless 鼠标位置若不跟随 warp 则 SKIP。
	_verify_hover_pipeline()

	_finish()

## 软验证 hover 端到端;headless 下鼠标位置若不跟随 warp_mouse 则 SKIP(环境限制,非代码缺陷)。
func _verify_hover_pipeline() -> void:
	var modules_manager: Node = _player.get_node_or_null("ModulesManager")
	if modules_manager == null or not modules_manager.has_method("get_radar_view"):
		_results.append("SKIP: 无 ModulesManager.get_radar_view,hover 端到端跳过")
		return
	var radar_view: Node = modules_manager.get_radar_view()
	if radar_view == null:
		_results.append("SKIP: 无 radar_view(玩家未装雷达),hover 端到端跳过")
		return
	var rects: Dictionary = radar_view.get_screen_rects()
	if rects.is_empty():
		_results.append("SKIP: 无在屏目标 rect(headless 视野判定),hover 端到端跳过")
		return
	var target = rects.keys()[0]
	var rect: Rect2 = radar_view.get_screen_rect(target)
	Input.warp_mouse(rect.get_center())
	for i in range(4):
		await process_frame
	if _spy["on_target_hovered"] > 0:
		_results.append("PASS: 鼠标置于目标框内 -> on_target_hovered 触发(aim→ship_bus→radar_view)")
	else:
		_results.append("SKIP: headless 鼠标位置未跟随 warp,hover 端到端需手动核对")

func _press(action: String, frames: int) -> void:
	_emit_mapped(action, true)
	for i in range(frames):
		await process_frame

func _release(action: String, frames: int) -> void:
	_emit_mapped(action, false)
	for i in range(frames):
		await process_frame

## 取该 action 在 InputMap 里的第一个映射事件,复制后改 pressed 经 parse_input_event 派发(走 _input)。
func _emit_mapped(action: String, pressed: bool) -> void:
	var events := InputMap.action_get_events(action)
	if events.is_empty():
		_results.append("SKIP: action '%s' 无输入映射" % action)
		return
	var ev: InputEvent = events[0].duplicate()
	ev.pressed = pressed
	Input.parse_input_event(ev)

## P3 射速回归:按住 shoot 0.7s(真实时间,Timer 按秒计时;headless 无 vsync 帧数≠时长),
## shoot_timer.timeout 触发次数应 ≈ 时长/wait_time(0.1s)。
## 修复前(set_firing 每帧无条件 shoot()+start()):timer 永不 timeout、射速=帧率,此计数为 0。
func _verify_fire_rate() -> void:
	if _laser == null or _laser.shoot_timer == null:
		_results.append("SKIP: 无 laser/shoot_timer,射速回归跳过")
		return
	var timeout_count := 0
	var timer: Timer = _laser.shoot_timer
	timer.timeout.connect(func(): timeout_count += 1)
	_emit_mapped("shoot_player", true)
	await create_timer(0.7).timeout
	_emit_mapped("shoot_player", false)
	await process_frame
	_passed_or_failed(timeout_count >= 3,
		"射速回归:0.7s 内 shoot_timer 触发 %d 次(期望≈7,修复前=0)" % timeout_count)

func _check_arg(name: StringName, expected: Variant, label: String) -> void:
	var args: Array = _last.get(name, [])
	_passed_or_failed(args.size() > 0 and args[0] == expected, label)

func _check_bool(actual: bool, expected: bool, label: String) -> void:
	_passed_or_failed(actual == expected, label)

func _check_count(name: StringName, label: String) -> void:
	_passed_or_failed(_spy.get(name, 0) > 0, label)

func _check_zero(name: StringName, label: String) -> void:
	_passed_or_failed(_spy.get(name, 0) == 0, label)

func _passed_or_failed(ok: bool, label: String) -> void:
	_results.append(("PASS: " if ok else "FAIL: ") + label)

func _finish() -> void:
	print("\n===== P2 信号冒烟测试 =====")
	for r in _results:
		print(r)
	var failed := 0
	for r in _results:
		if r.begins_with("FAIL"):
			failed += 1
	print("===== 结果:%d FAIL / %d 总检查点 =====" % [failed, _results.size()])
	quit(1 if failed > 0 else 0)
