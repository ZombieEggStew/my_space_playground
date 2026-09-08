extends Node
class_name HUD_TargetSelector

## 白色方形目标选择框(准心1):纯显示,由 radar_view(方案 A + 决策 #27)喂入屏幕数据。
##
## 职责边界:
## - 只负责"目标选择框"的显示与高亮外观;不含投影/尺寸计算(在 radar_view)与
##   悬停检测(在 aim/selection,决策 #27)。
## - 数据来源:[method set_target_pos](radar_view 每帧投影喂入)、
##   [method set_hovered](radar_view 订阅 ② hover 事件后转发)。
## - 注册方式:由 [code]HUDManager.register_hud[/code] 读取本脚本的
##   [member hud_slot](STATIC)自动挂到静态层。

## HUD 归属:静态层(由 HUDManager.register_hud 读取)
@export var hud_slot: HudElement.Slot = HudElement.Slot.STATIC

@export var rect := NinePatchRect

var target: AbleToBeLocked

var _base_modulate := Color(1, 1, 1, 0.5137)
const HOVERED_MODULATE := Color(0.6, 1.0, 0.6, 0.9)

func setup(_target: AbleToBeLocked) -> void:
	target = _target
	if rect:
		_base_modulate = rect.modulate
	# 目标销毁/离开场景树时立即自毁(双保险,queue_free 幂等)
	if not target.tree_exited.is_connected(queue_free):
		target.tree_exited.connect(queue_free)
	reset()

func reset() -> void:
	if rect:
		rect.visible = false
		rect.modulate = _base_modulate

## radar_view 每帧喂入:选择框中心屏幕坐标 + 尺寸(方案 A,单一数据源)
func set_target_pos(center: Vector2, size: Vector2) -> void:
	if rect == null:
		return
	rect.size = size
	rect.position = center - size / 2.0
	rect.visible = true

func set_active(visible: bool) -> void:
	if rect:
		rect.visible = visible

func set_hovered(hovered: bool) -> void:
	if rect == null:
		return
	rect.modulate = HOVERED_MODULATE if hovered else _base_modulate
