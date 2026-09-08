extends Node
class_name InputManager

signal mouse_input(event: InputEventMouse)
signal mouse_movtion(event: InputEventMouseMotion)

@export_group("Toggle Modes")
@export var is_toggle_mode_shoot := false
var _is_shooting : = BoolStat.new(false)

@export var is_toggle_mode_boost := false
var _is_boosting := BoolStat.new(false)

@export var is_toggle_mode_track_mouse := true
var _is_track_mouse := BoolStat.new(true)

@export var is_toggle_mode_look_backward := true
var _is_look_backward := BoolStat.new(false)

@export var is_toggle_mode_look_around := true
var _is_look_around := BoolStat.new(false)

## ② 飞船级总线引用:on_player_registered 时缓存(解决"哪个玩家的 bus"问题);
## 未注册前(bus 为 null)输入信号安全丢弃,不 emit 到全局。
var _player_bus: ShipBus


func _ready() -> void:
	SignalBus.on_player_registered.connect(_on_player_registered)

func _on_player_registered(player: PlayerShip) -> void:
	_player_bus = player.ship_bus


func _input(event: InputEvent) -> void:
	if event is InputEventMouse:
		mouse_input.emit(event)
		if event is InputEventMouseMotion:
			mouse_movtion.emit(event)
	
	if event.is_action_pressed("lock_on"):
		_emit_to_bus("on_player_try_lock")
	if event.is_action_pressed("toggle_engine"):
		_emit_to_bus("on_toggle_engine")
	if event.is_action_pressed("use_item_1"):
		_emit_to_bus("on_player_try_use_item_1")

	# P3:shoot(连发)/boost(持续)改为连续量命令,由 ControlModule 每帧直接调
	# laser.set_firing / booster.set_boosting,不再经总线信号(决策 #12/#13)。
	_handle_input_action(event, "look_backward", is_toggle_mode_look_backward, _is_look_backward, "on_player_look_backward")
	_handle_input_action(event, "toggle_track", is_toggle_mode_track_mouse, _is_track_mouse, "on_toggle_track_mouse")
	_handle_input_action(event, "look_around", is_toggle_mode_look_around, _is_look_around, "on_player_look_around")


func _handle_input_action(event: InputEvent, action_name: String, is_toggle: bool, state: BoolStat, bus_signal_name: StringName) -> void:
	if is_toggle:
		if event.is_action_pressed(action_name):
			state.value = not state.value
			_emit_to_bus(bus_signal_name, state.value)
	else:
		if event.is_action_pressed(action_name):
			state.value = true
			_emit_to_bus(bus_signal_name, true)
		elif event.is_action_released(action_name):
			state.value = false
			_emit_to_bus(bus_signal_name, false)

## 输入翻译层:统一经玩家船 ShipBus 发射(信号名中转,零状态);bus 未就绪时安全跳过。
func _emit_to_bus(signal_name: StringName, value: Variant = null) -> void:
	if _player_bus == null or not is_instance_valid(_player_bus):
		return
	if value == null:
		_player_bus.emit_signal(signal_name)
	else:
		_player_bus.emit_signal(signal_name, value)



func set_player_boost_state(is_boosting: bool) -> void:
	_is_boosting.value = is_boosting
