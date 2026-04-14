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


func _input(event: InputEvent) -> void:
    if event is InputEventMouse:
        mouse_input.emit(event)
        if event is InputEventMouseMotion:
            mouse_movtion.emit(event)
    
    if event.is_action_pressed("lock_on"):
        SignalBus.on_player_try_lock.emit()
    if event.is_action_pressed("switch_cam"):
        SignalBus.on_player_switch_camera.emit()
    

    _handle_input_action(event, "shoot_player", is_toggle_mode_shoot, _is_shooting, SignalBus.on_player_shoot)
    _handle_input_action(event, "boost", is_toggle_mode_boost, _is_boosting, SignalBus.on_player_boost_input)
    _handle_input_action(event, "look_backward", is_toggle_mode_look_backward, _is_look_backward, SignalBus.on_player_look_backward)
    _handle_input_action(event, "toggle_track", is_toggle_mode_track_mouse, _is_track_mouse, SignalBus.on_track_mouse_change)
    _handle_input_action(event, "look_around", is_toggle_mode_look_around, _is_look_around, SignalBus.on_player_look_around)


func _handle_input_action(event: InputEvent, action_name: String, is_toggle: bool, state: BoolStat, signal_obj: Signal) -> void:
    if is_toggle:
        if event.is_action_pressed(action_name):
            state.value = not state.value
            signal_obj.emit(state.value)
    else:
        if event.is_action_pressed(action_name):
            state.value = true
            signal_obj.emit(true)
        elif event.is_action_released(action_name):
            state.value = false
            signal_obj.emit(false)



func set_player_boost_state(is_boosting: bool) -> void:
    _is_boosting.value = is_boosting

