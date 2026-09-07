extends Node
class_name HUD_LockReticle
## 绿色锁定准心(准心2):未锁定停在屏幕中心,悬停/锁定时平滑跟随目标。
##
## 鼠标进入准心1范围时平滑移动到目标屏幕位置;锁定状态下跟踪目标,
## 目标不在屏幕时把位置限制在屏幕边缘以指示相对方位。大小固定(64x64)。
##
## 职责边界:
## - 只负责视觉跟随与平滑,不含锁定判定(判定在 [code]BasicAimModule[/code])。
## - 数据来源:由 [code]BasicAimModule[/code] 每帧调用 [method set_target_pos] / [method reset] 驱动。
## - 对外接口:[method set_target_pos]、[method reset]、[method get_position_center]。
## - 注册方式:[code]HUDManager.register_hud_static[/code]。

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

