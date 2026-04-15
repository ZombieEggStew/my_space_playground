extends Node

@export var base_size := Vector2(64, 64)

@export var rect: NinePatchRect

var _target_pos := Vector2.ZERO
var move_smooth := 10.0


func _ready() -> void:
    reset()


func reset() -> void:
    rect.visible = true
    rect.size = base_size
    _target_pos = get_viewport().get_visible_rect().size / 2.0 - rect.size / 2.0



func set_target_pos(pos: Vector2) -> void:
    _target_pos = pos - rect.size / 2.0
    rect.visible = true

func get_position_center() -> Vector2:
    return rect.position + rect.size / 2.0



func _process(_delta: float) -> void:
    rect.position = lerp(rect.position , _target_pos, move_smooth * _delta)

