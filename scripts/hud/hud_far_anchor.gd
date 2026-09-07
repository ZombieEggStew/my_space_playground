extends Node2D
class_name HUDFarAnchor
## 远 HUD 锚点:给场景里无内联脚本的容器声明归属。
##
## 挂到某个 Node2D 容器上(如 heat 的 laser_gun_heat),并把该节点绑定为
## 模块的 hud_container 传入 [method HUDManager.register_hud];register_hud 读取
## 本脚本的 [member hud_slot] = [constant HudElement.Slot.FAR],挂到 hud_far_manager。
@export var hud_slot: HudElement.Slot = HudElement.Slot.FAR
