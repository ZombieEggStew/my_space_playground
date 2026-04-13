extends Node
class_name Buff

signal expired()

@onready var timer : Timer = $Timer
@onready var target : = get_parent() as Node

var interval: float = 0.1

# 持续时间，单位秒，0 或负数表示无限持续
var duration: float = 0.0

var source: Node

var _current_tick: float = 0.0


func _ready():
	timer.timeout.connect(_every_tick)

func apply(_source: Node , _duration:float = 0.0, _interval :float = .1) -> void:
	source = _source
	duration = _duration
	interval = _interval
	timer.wait_time = interval

	timer.start()


func _every_tick() -> void:
	_current_tick += interval
	
	if duration > 0 and _current_tick >= duration:
		on_expire()
		return
	every_tick()


func every_tick() -> void:
	pass

func on_expire() -> void:
	expired.emit()
	timer.stop()
	queue_free()