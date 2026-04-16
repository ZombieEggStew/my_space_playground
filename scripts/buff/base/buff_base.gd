extends RefCounted
class_name Buff

signal on_expire()
signal on_stack_changed(new_stack: int)

enum ADD {
	NEW_STACK,
	NEW_STACK_AND_REFRESH
}

enum EXPIRE {
	ONE_STACK,
	IMMEDIATELY,
	GRADUALLY
}

var buff_name: String = "unnamed_buff"
var icon_path: String = "" # 自动生成的图标路径
var icon: Texture2D:
	get:
		if icon == null and icon_path != "":
			icon = load(icon_path)
		return icon if icon != null else preload("res://icon.svg")

var particle_path: String = "" # 粒子效果场景路径

var target: Node
var source: Node

var interval: float = 0.1
var duration: float = 0.0 # 0 表示无限
var elapsed_time: float = 0.0
var next_tick_time: float = 0.0

var stack_count: int = 1
var max_stack: int = 5
var add_new_stack_method := ADD.NEW_STACK
var expire_method := EXPIRE.IMMEDIATELY
var expire_duration := 1.0 # 逐渐消失的过渡时间

# 由外部 Manager 驱动更新
func update(delta: float) -> void:
	if duration > 0:
		elapsed_time += delta
		if elapsed_time >= duration:
			_handle_expire()
			return

	# Tick 逻辑优化：支持精确频率
	if elapsed_time >= next_tick_time:
		_process_tick()
		next_tick_time += interval

func _process_tick() -> void:
	on_tick()

func on_tick() -> void:
	pass

func setup(_target: Node, _source: Node, _duration: float) -> void:
	target = _target
	source = _source
	duration = _duration
	elapsed_time = 0.0
	next_tick_time = 0.0 # 修改为 0.0，使 apply 时立即触发第一次 tick
	_on_setup()

func _on_setup() -> void:
	pass

func apply() -> void:
	elapsed_time = 0.0
	next_tick_time = 0.0 # 确保应用时重置 tick 计时
	_on_apply()

func _on_apply() -> void:
	pass

func refresh(new_duration: float) -> void:
	if new_duration > 0:
		duration = new_duration
	elapsed_time = 0.0
	next_tick_time = 0.0 # 刷新时也应立即触发一次 tick
	apply()

#-------------------- 叠层处理 --------------------

func add_stack(new_duration: float) -> void:
	var old_stack = stack_count
	if max_stack == 0 or stack_count < max_stack:
		stack_count += 1
	
	match add_new_stack_method:
		ADD.NEW_STACK:
			if stack_count == old_stack: # 已经满层则刷新
				refresh(new_duration)
		ADD.NEW_STACK_AND_REFRESH:
			refresh(new_duration)
	
	on_stack_changed.emit(stack_count)

#-------------------- 过期处理 --------------------

func _handle_expire() -> void:
	match expire_method:
		EXPIRE.IMMEDIATELY:
			expire_immediately()
		EXPIRE.ONE_STACK:
			expire_one_stack()
		EXPIRE.GRADUALLY:
			expire_gradually()

func expire_immediately() -> void:
	on_expire.emit()

func expire_one_stack() -> void:
	if stack_count > 1:
		stack_count -= 1
		on_stack_changed.emit(stack_count)
		refresh(duration) # 重置当前层的计时
	else:
		expire_immediately()

func expire_gradually() -> void:
	duration = expire_duration
	expire_one_stack()
