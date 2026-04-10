extends Node

@export var base_size := Vector2(64, 64)
@export var size_scale_numerator := 100.0
@export var min_size_factor := 0.5

@export var rect := NinePatchRect

var _size_factor := 1.0

func _ready() -> void:
	reset()

func reset() -> void:
	rect.visible = false
	rect.size = base_size
	_size_factor = 1.0
	rect.position = get_viewport().get_visible_rect().size / 2.0 - rect.size / 2.0

func set_active(t:bool) -> void:
	rect.visible = t


func update_from_target(screen_pos: Vector2, distance: float) -> void:
	set_active(true)
	var safe_distance := max(distance, 0.001) as float
	_size_factor = max(size_scale_numerator / safe_distance, min_size_factor)
	rect.size = base_size * _size_factor
	rect.position = screen_pos - rect.size / 2.0


func get_size_factor() -> float:
	return _size_factor
