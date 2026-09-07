extends Node2D
class_name HUDFarBase

## HUD 归属:远层(机头投影坐标系)。由 [method HUDManager.register_hud] 读取,挂到 hud_far_manager。
## 本元素必须是 hud_far_manager 的直接子节点,才能经 [member hud] 访问其机头投影数据。
@export var hud_slot: HudElement.Slot = HudElement.Slot.FAR

@onready var hud : HUDFarManager = get_parent()
