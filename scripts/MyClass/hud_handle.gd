extends RefCounted
class_name HudHandle

## HUD 注册句柄:[method HUDManager.register_hud] 的唯一返回类型。
##
## 元素通过 `@export var hud_slot: HudElement.Slot` 自声明归属;register_hud 读取该值
## 决定挂到哪一层,并把 [member node] 与实际槽位一起包进本句柄返回。
## 链式特效方法(`set_*_effect`)仅对 [constant HudElement.Slot.GROUP] 有效,其余归属调用会被忽略。
##
## 职责边界:
## - 只是"注册结果"的持有者/链式配置器,不含节点生命周期管理。
## - 需要操作实际节点时用 [member node](PackedScene 实例或调用方传入的节点)。
## - 元件本身的公共接口见 [code]HudElement[/code] 基类。
## - 废弃的 [code]MyHUD[/code] 由此类取代(统一返回类型,修复四套并行注册 API,见 .memo/.CURRENT.md §4.1)。

## 被包裹的实际节点(PackedScene 实例或调用方传入的节点)。
var node: Node

## 元素归属。
var slot: HudElement.Slot

var _manager: HUDManager

func _init(element: Node, slot: HudElement.Slot) -> void:
	node = element
	self.slot = slot
	_manager = GameManager.hud_manager

## 鼠标视差特效。仅对 [constant HudElement.Slot.GROUP] 生效。
func set_flow_effect(index: ControlGroup.Index = ControlGroup.Index.GROUP_1) -> HudHandle:
	if slot == HudElement.Slot.GROUP:
		_manager.flow_effect.setup(node as Control, index)
	return self

## 象限旋转特效。仅对 [constant HudElement.Slot.GROUP] 生效。
func set_rotation_effect() -> HudHandle:
	if slot == HudElement.Slot.GROUP:
		_manager.rotation_effect.setup(node as Control)
	return self

## 加速扩散特效。仅对 [constant HudElement.Slot.GROUP] 生效。
func set_boost_offset_effect() -> HudHandle:
	if slot == HudElement.Slot.GROUP:
		_manager.boost_offset_effect.setup(node as Control)
	return self

## 加速抖动特效。仅对 [constant HudElement.Slot.GROUP] 生效。
func set_boost_shake_effect() -> HudHandle:
	if slot == HudElement.Slot.GROUP:
		_manager.boost_shake_effect.setup(node as Control)
	return self
