extends Node3D
class_name Buff

signal on_expire()

@onready var timer : Timer = $Timer

@export var particle : GPUParticles3D

@export var icon : Texture2D

var target : Node
var interval: float = 0.1

# 持续时间，单位秒，0 或负数表示无限持续
var duration: float = 0.0

var source: Node

var _current_tick: float = 0.0

var expire_timer : Timer

var NAME := "unnamed_buff"

func _ready():
	
	if particle:
		particle.emitting = false
		expire_timer = Timer.new()
		expire_timer.one_shot = true
		expire_timer.wait_time = particle.lifetime
		expire_timer.timeout.connect(on_exit_tree)
		add_child(expire_timer)
		if not icon :
			icon = load("res://icon.svg") as Texture2D

func setup(_target: Node , _duration:float = 0.0, _interval :float = .1) -> void:
	target = _target
	duration = _duration
	interval = _interval
	timer.wait_time = interval
	timer.timeout.connect(_every_tick)

func _setup() -> void:
	pass

func apply() -> void:

	timer.start()
	particle.emitting = true


func _every_tick() -> void:
	_current_tick += interval
	
	if duration > 0 and _current_tick >= duration:
		_on_expire()
		return
	every_tick()


func every_tick() -> void:
	pass

func _on_expire() -> void:
	on_expire.emit()
	timer.stop()
	particle.emitting = false
	expire_timer.start()


func on_exit_tree() -> void:
	queue_free()
