extends Module
class_name ControlModule

## 玩家大脑(决策 #11/#13):键鼠 → 归一化命令 → 共享模块(行为不变 = 纯搬运)。
## 连续量 = 直接方法(set_throttle / set_steer / set_roll / set_boosting / set_firing);
## 离散事件(右键锁定 / Q 引擎 / Tab 跟随 / Esc 回头看 / 1 挂件)仍经 InputManager → ② ShipBus。
## 输入来源暂直接读 Input(§4.2-6 InputManager 位置搁置,拍板后一换、接口不变)。

var _move: MoveControllerModule
var _booster: BoosterModule
var _laser: LaserModule

func _ready() -> void:
	_move = modules_manager.get_move_module() if modules_manager else null
	if _move == null:
		Log.log_missing_component(self, "move module")
		queue_free()
		return
	_booster = _move.get_booster_module()
	_laser = modules_manager.get_laser_module() if modules_manager else null
	# laser/booster 缺失 → 对应命令不发(降级不硬崩)

func _physics_process(_delta: float) -> void:
	if _move == null:
		return
	_move.set_throttle(_read_throttle())
	_move.set_steer(_read_steer())
	_move.set_roll(Input.get_axis("left", "right"))
	if _booster:
		_booster.set_boosting(Input.is_action_pressed("boost"))
	if _laser:
		_laser.set_firing(Input.is_action_pressed("shoot_player"))

## 油门:前进=1(全速),后退=-1(刹车到 0),都不按=0(滑行)——语义与原 MoveControllerModule.handle_move 一致
func _read_throttle() -> float:
	if Input.is_action_pressed("forward"):
		return 1.0
	if Input.is_action_pressed("backward"):
		return -1.0
	return 0.0

## 鼠标跟随:偏移 → 死区 → 归一化(原 MoveControllerModule.track_mouse 逻辑原样搬移;
## 死区内的平滑归零由 move 内部 lerp 完成,故此处直接返回 ZERO)
func _read_steer() -> Vector2:
	var viewport_size := get_viewport().get_visible_rect().size
	var center := viewport_size * 0.5
	var offset := get_viewport().get_mouse_position() - center
	if offset.length() <= PlayerInfo.dead_zone_px:
		return Vector2.ZERO
	var nx := clampf(offset.x / max(center.x, 1.0), -1.0, 1.0)
	var ny := clampf(offset.y / max(center.y, 1.0), -1.0, 1.0)
	return Vector2(-nx, -ny)
