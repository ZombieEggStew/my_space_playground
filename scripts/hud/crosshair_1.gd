extends Node

signal mouse_entered(target: AbleToBeLocked)
signal mouse_exited()

@export var base_size := Vector2(64, 64)
@export var size_scale_numerator := 100.0
@export var min_size_factor := 0.5

@export var rect := NinePatchRect

var _size_factor := 1.0

var target: AbleToBeLocked

var player: PlayerShip
var cam: Camera3D

func setup(_target: AbleToBeLocked, _player:PlayerShip, _cam:Camera3D) -> void:
	self.target = _target
	self.player = _player
	self.cam = _cam
	target.screen_entered.connect(_on_enter_screen)
	target.screen_exited.connect(_on_exit_screen)

func _ready() -> void:
	reset()

func _on_enter_screen():
	set_process(true)
	
func _on_exit_screen():
	set_process(false)
	set_active(false)


func _process(_delta):
	update_visuals()


func reset() -> void:
	set_process(false)
	rect.visible = false
	rect.size = base_size
	_size_factor = 1.0
	rect.position = get_viewport().get_visible_rect().size / 2.0 - rect.size / 2.0

func set_active(t:bool) -> void:
	rect.visible = t


func update_visuals() -> void:
	set_active(true)
	var safe_distance := max(target.global_position.distance_to(player.global_position), 0.001) as float
	_size_factor = max(size_scale_numerator / safe_distance, min_size_factor)
	rect.size = base_size * _size_factor
	rect.position = cam.unproject_position(target.global_position) - rect.size / 2.0


func get_size_factor() -> float:
	return _size_factor

func _on_crosshair_1_mouse_exited() -> void:
	mouse_exited.emit()

func _on_crosshair_1_mouse_entered() -> void:
	mouse_entered.emit(target)
