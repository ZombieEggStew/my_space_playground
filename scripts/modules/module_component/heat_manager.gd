extends ModuleComponent
class_name HeatManager

signal overheated(is_active: bool)

@export var cool_down_timer:Timer

@export var heat_bar : TextureProgressBar
@export var heat_bar_container: PanelContainer

# 过热系统变量
@export var max_heat: float = 100.0
@export var heat_per_shot: float = 1.0

@export var heat_recovery_rate: float = 20.0  # 每秒降低的热量

@export var overheat_audio: AudioStreamPlayer

var current_heat: float = 0.0
var is_overheated: bool = false

var _shake_tween: Tween
var _orig_bar_pos: Vector2


func _ready() -> void:

	GameManager.hud_manager.register_hud_far_node(hud_container)
	if heat_bar:
		# 强制等待一帧或在布局完成后的闲置时间记录位置
		await get_tree().process_frame
		heat_bar.max_value = max_heat
		heat_bar.value = current_heat
		_orig_bar_pos = heat_bar.position


		
func add_heat() -> bool:
	if is_overheated:
		return false
	
	current_heat += heat_per_shot
	
	if cool_down_timer:
		cool_down_timer.start()
	
	if current_heat >= max_heat:
		current_heat = max_heat
		enter_overheat()
	
	_update_bar(true) # 增加热量时触发震荡
	return true

func enter_overheat() -> void:
	is_overheated = true
	overheated.emit(true)
	# 过热时触发一个强力震荡
	_player_container_shake()
	overheat_audio.play()

func _process(delta: float) -> void:
	# 只要计时器没在运行，就降低热量
	if cool_down_timer and cool_down_timer.is_stopped():
		if current_heat > 0:
			current_heat = max(0, current_heat - heat_recovery_rate * delta)
			# 如果处于过热状态且热量降低到0，则解除过热
			if is_overheated and current_heat <= 0:
				is_overheated = false
				overheated.emit(false)
			_update_bar(false) # 冷却时不震荡

func _update_bar(should_shake: bool = false) -> void:
	if heat_bar:
		# 使用 Tween 平滑更新进度条
		var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		tween.tween_property(heat_bar, "value", current_heat, 0.1)
		
		if should_shake:
			_play_shake()

func _play_shake(force_intensity: float = -1.0) -> void:
	if not heat_bar: return
	
	if _shake_tween:
		_shake_tween.kill()
		
	# 如果没有强制强度，则根据当前热量比例计算强度
	var intensity = force_intensity
	if intensity < 0:
		var ratio = max(get_heat_ratio()-.5 , 0)
		intensity = ratio * 8.0 # 最大震荡幅度 8 像素
	
	_shake_tween = create_tween()
	# 快速来回震荡
	for i in range(2):
		var offset = Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
		_shake_tween.tween_property(heat_bar, "position", _orig_bar_pos + offset, 0.02)
	
	_shake_tween.tween_property(heat_bar, "position", _orig_bar_pos, 0.02)

func _player_container_shake() -> void:
	if not hud_container: return
	
	var shake_tween = create_tween()
	for i in range(10):
		var offset = Vector2(randf_range(-15, 15), randf_range(-15, 15))
		shake_tween.tween_property(hud_container, "position",  offset, 0.02)
	
	shake_tween.tween_property(hud_container, "position", Vector2.ZERO, 0.02)

func get_heat_ratio() -> float:
	return current_heat / max_heat
