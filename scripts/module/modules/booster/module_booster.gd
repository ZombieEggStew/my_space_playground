extends BoosterModule
class_name Booster_1

@export var boost_progress_bar: TextureProgressBar
@export var boost_particle: GPUParticles3D

# energy system
var max_energy := 100.0
var current_energy := 100.0
var consume_rate := 2.0        # 每 0.1s 消耗
var recover_rate := 5.0        # 每 0.1s 恢复

@export var energy_tick : Timer
@export var recover_delay_timer : Timer

@export var smooth_speed := 10.0


func _ready() -> void:
	if boost_particle:
		boost_particle.emitting = false
	# 敌人装配(ai_rework_plan §5.1)无 HUD 容器:跳过 HUD 注册,能量逻辑照常
	if hud_container and GameManager.hud_manager:
		GameManager.hud_manager.register_hud(hud_container).set_flow_effect(ControlGroup.Index.GROUP_2).set_rotation_effect().set_boost_offset_effect().set_boost_shake_effect()
	
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
	if is_boosting:
		current_energy = max(0.0, current_energy - consume_rate)
		if current_energy <= 0.0:
			stop_speed_up()
	elif recover_delay_timer and recover_delay_timer.is_stopped():
		current_energy = min(max_energy, current_energy + recover_rate)
	
## 决策 #13/P3:连续量命令,由 ControlModule / AIModule 每帧调用。
## 变化检测(_boosting_requested):仅在请求翻转时动作;按住期间能量耗尽不自动恢复(与原信号驱动一致)。
var _boosting_requested := false

func set_boosting(enable: bool) -> void:
	if enable == _boosting_requested:
		return
	_boosting_requested = enable
	if enable and current_energy > 0.0:
		speed_up()
	else:
		stop_speed_up()
		

func speed_up() -> void:
	if not engine_module.is_engine_on:
		return
	if boost_particle:
		boost_particle.emitting = true
	is_boosting = true
	if recover_delay_timer:
		recover_delay_timer.stop()
	ship_bus.on_player_boost.emit(true)


func stop_speed_up() -> void:
	if not engine_module.is_engine_on:
		return
	if boost_particle:
		boost_particle.emitting = false	
	is_boosting = false
	if recover_delay_timer:
		recover_delay_timer.start()
	ship_bus.on_player_boost.emit(false)
