extends Node

signal mouse_entered(target: AbleToBeLocked)
signal mouse_exited()

@export var base_size := Vector2(64, 64)
@export var size_scale_numerator := 100.0
@export var min_size_factor := 0.5

@export var rect := NinePatchRect

var _size_factor := 1.0

var target: AbleToBeLocked

var cam: Camera3D

func setup(_target: AbleToBeLocked, _cam: Camera3D):
	self.target = _target
	self.cam = _cam

func _ready() -> void:
	reset()

func _process(_delta):
	if not is_instance_valid(target) or not target.is_visible:
		set_active(false)
		return
	var screen_pos = cam.unproject_position(target.world_pos)
	update_visuals(screen_pos, target.distance_to_player)


func reset() -> void:
	rect.visible = false
	rect.size = base_size
	_size_factor = 1.0
	rect.position = get_viewport().get_visible_rect().size / 2.0 - rect.size / 2.0

func set_active(t:bool) -> void:
	rect.visible = t


func update_visuals(screen_pos: Vector2, distance: float) -> void:
	set_active(true)
	var safe_distance := max(distance, 0.001) as float
	_size_factor = max(size_scale_numerator / safe_distance, min_size_factor)
	rect.size = base_size * _size_factor
	rect.position = screen_pos - rect.size / 2.0


func get_size_factor() -> float:
	return _size_factor

func _on_crosshair_1_mouse_exited() -> void:
	mouse_exited.emit()

func _on_crosshair_1_mouse_entered() -> void:
	mouse_entered.emit(target)
