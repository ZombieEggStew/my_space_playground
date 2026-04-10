extends Line2D
@export var line_color: Color = Color(1, 1, 1, 1)
@export var line_width: float = 2.0
@export var parent_node: Node2D



func _ready() -> void:
    width = line_width
    default_color = line_color
    # 先放两个点，后续每帧更新
    points = PackedVector2Array([Vector2.ZERO, Vector2.ZERO])


func _process(_delta: float) -> void:
    var center = get_viewport_rect().size / 2.0
    var mouse_pos = get_viewport().get_mouse_position() - parent_node.get_global_position()
    set_point_position(0, center)
    set_point_position(1, mouse_pos)