extends ModuleComponent
class_name HeatManager

signal overheated(is_active: bool)

@export var cool_down_timer:Timer

@export var heat_bar : TextureProgressBar

# 过热系统变量
@export var max_heat: float = 100.0
@export var heat_per_shot: float = 1.0

@export var heat_recovery_rate: float = 20.0  # 每秒降低的热量

var current_heat: float = 0.0
var is_overheated: bool = false

func _ready() -> void:
	if heat_bar:
		heat_bar.max_value = max_heat
		heat_bar.value = current_heat
	GameManager.hud_manager.register_hud_far_node(hud_container)

func add_heat() -> bool:
	if is_overheated:
		return false
	
	current_heat += heat_per_shot
	
	if cool_down_timer:
		cool_down_timer.start()
	
	if current_heat >= max_heat:
		current_heat = max_heat
		enter_overheat()
	
	_update_bar()
	return true

func enter_overheat() -> void:
	is_overheated = true
	overheated.emit(true)

func _process(delta: float) -> void:
	# 只要计时器没在运行，就降低热量
	if cool_down_timer and cool_down_timer.is_stopped():
		if current_heat > 0:
			current_heat = max(0, current_heat - heat_recovery_rate * delta)
			# 如果处于过热状态且热量降低到0，则解除过热
			if is_overheated and current_heat <= 0:
				is_overheated = false
				overheated.emit(false)
			_update_bar()

func _update_bar() -> void:
	if heat_bar:
		heat_bar.value = current_heat

func get_heat_ratio() -> float:
	return current_heat / max_heat
