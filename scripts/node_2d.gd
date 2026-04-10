extends Node2D

@export var line_color: Color = Color(1, 0.2, 0.2, 0.9)
@export var line_width: float = 2.0

func _process(_delta: float) -> void:
    queue_redraw() # 每帧重绘，保证线条实时跟随鼠标

func _draw() -> void:
    var viewport_size = get_viewport_rect().size
    var center = viewport_size / 2.0
    var mouse_pos = get_viewport().get_mouse_position()
    draw_line(center, mouse_pos, line_color, line_width, true)