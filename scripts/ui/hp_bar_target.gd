extends Node

@export var hp_bar : TextureProgressBar
@export var hp_catch: TextureProgressBar
@export var mask: Control

# 取消 PackedScene 的导出，改为通过类似 SignalBus 的全局方式
# 或者在这里直接引用场景中的 Pool 节点（如果已作为单例）
# var _damage_pool: Node # 已有的 damage_number_pool 实例

var tween_hp_bar : Tween
var tween_hp_catch : Tween
var tween_fade : Tween

var _is_active := false
var _target: AbleToBeLocked
var _target_health : HealthComponent
var _cam: Camera3D
var _is_locked : bool = false 
var _is_on_screen := false

func _ready() -> void:
	mask.size.x = 0
	mask.modulate.a = 1.0 # 确保不被之前的 fade 脚本影响
	set_process(false)

func setup(target: AbleToBeLocked, cam: Camera3D) -> void:
	if not target: return
	
	_target = target
	_cam = cam
	
	_target_health = target.target_node3d.get_node_or_null("HealthComponent")
	if _target_health:
		if not _target_health.changed.is_connected(_on_health_changed):
			_target_health.changed.connect(_on_health_changed)
		_on_health_changed(_target_health.get_health(), _target_health.get_max_health(), 0)
	
	if not target.on_locked.is_connected(_on_locked):
		target.on_locked.connect(_on_locked)
	if not target.screen_entered.is_connected(_on_enter_screen):
		target.screen_entered.connect(_on_enter_screen)
	if not target.screen_exited.is_connected(_on_exit_screen):
		target.screen_exited.connect(_on_exit_screen)
	
	_is_locked = target.is_locked
	_is_on_screen = target.is_on_screen()
	# 初始状态直接应用，不播放动画
	_is_active = _is_locked and _is_on_screen
	set_process(_is_active)
	mask.size.x = hp_bar.size.x if _is_active else 0.0

func _on_health_changed(new_health: int, new_max_health: int, _changed_amount: int) -> void:
	hp_bar.max_value = new_max_health
	hp_catch.max_value = new_max_health
	
	# 立即更新主血条，平滑更新缓冲血条
	hp_bar.value = new_health
	
	if _changed_amount < 0:
		_show_damage_number(abs(_changed_amount))

	if tween_hp_catch and tween_hp_catch.is_valid():
		tween_hp_catch.kill()
	
	tween_hp_catch = create_tween()
	tween_hp_catch.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tween_hp_catch.tween_property(hp_catch, "value", new_health, 0.5).set_delay(0.2)

func _show_damage_number(amount: int) -> void:
	# 初始位置
	var start_pos = _cam.unproject_position(_target.global_position)
	# 通过信号总线或者单例触发飘字，让 ObjectPool 集中处理
	SignalBus.on_damage_dealt.emit(amount, start_pos)

func _on_locked(is_locked: bool) -> void:
	_is_locked = is_locked
	_update_active_state()

func _on_enter_screen() -> void:
	_is_on_screen = true
	_update_active_state()

func _on_exit_screen() -> void:
	_is_on_screen = false
	_update_active_state()

func _update_active_state() -> void:
	var should_be_active = _is_locked and _is_on_screen
	if _is_active == should_be_active:
		return
	
	_is_active = should_be_active
	
	if tween_fade and tween_fade.is_valid():
		tween_fade.kill()
	
	tween_fade = create_tween()
	var target_width = hp_bar.size.x if _is_active else 0.0
	
	tween_fade.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween_fade.tween_property(mask, "size:x", target_width, 0.4)

	if _is_active:
		set_process(true)
	else:
		# 逐渐关闭结束后停止 process
		tween_fade.finished.connect(func(): if not _is_active: set_process(false))

func _process(_delta: float) -> void:
	if not is_instance_valid(_target):
		queue_free()
		return
	
	var pos = _cam.unproject_position(_target.global_position)
	pos.y += 50
	mask.position = pos - mask.size / 2.0
