extends BoosterModule
class_name Booster_1

@export var boost_progress_bar: TextureProgressBar
@export var boost_particle: GPUParticles3D
# boost
var _is_boosting := false
var boost_speed := 100.0
var boost_accel := 120.0

# energy system
var max_energy := 100.0
var current_energy := 100.0
var consume_rate := 2.0        # 每 0.1s 消耗
var recover_rate := 5.0        # 每 0.1s 恢复

@export var energy_tick : Timer
@export var recover_delay_timer : Timer

@export var smooth_speed := 10.0

var engine_module: EngineModule

func setup(_engine) -> void:
	engine_module = _engine

func _ready() -> void:
	if boost_particle:
		boost_particle.emitting = false
	SignalBus.on_player_boost_input.connect(_handle_boost_input)
	GameManager.hud_manager.register_hud_group(hud_container).set_flow_effect(ControlGroup.Index.GROUP_2).set_rotation_effect().set_boost_offset_effect().set_boost_shake_effect()
	
	if energy_tick:
		energy_tick.timeout.connect(_on_energy_tick)

	else:
		Log.log_missing_component(self,"energy_tick Timer")


	if boost_progress_bar:
		boost_progress_bar.max_value = max_energy
		boost_progress_bar.value = current_energy

func _process(delta: float) -> void:
	if boost_progress_bar:
		boost_progress_bar.value = lerp(boost_progress_bar.value, float(current_energy), smooth_speed * delta)

func _on_energy_tick() -> void:
	if _is_boosting:
		current_energy = max(0.0, current_energy - consume_rate)
		if current_energy <= 0.0:
			stop_speed_up()
	elif recover_delay_timer and recover_delay_timer.is_stopped():
		current_energy = min(max_energy, current_energy + recover_rate)
	
func _handle_boost_input(enable: bool) -> void:
	if enable and current_energy > 0.0:
		speed_up()
		
	else:
		stop_speed_up()
		

func speed_up() -> void:
	if not engine_module.is_engine_on:
		return
	if boost_particle:
		boost_particle.emitting = true
	_is_boosting = true
	if recover_delay_timer:
		recover_delay_timer.stop()
	SignalBus.on_player_boost.emit(true)


func stop_speed_up() -> void:
	if not engine_module.is_engine_on:
		return
	if boost_particle:
		boost_particle.emitting = false	
	_is_boosting = false
	if recover_delay_timer:
		recover_delay_timer.start()
	SignalBus.on_player_boost.emit(false)


func is_boosting() -> bool:
	return _is_boosting

func get_boost_speed() -> float:
	return boost_speed

func get_boost_accel() -> float:
	return boost_accel
