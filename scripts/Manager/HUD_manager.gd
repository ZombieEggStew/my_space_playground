extends CanvasLayer
class_name HUDManager

@export var hud_container: Node
@export var hud_static: Node
@export var hud_far : Node



@export var flow_effect : UIFlowEffect
@export var rotation_effect : UIRotationEffect 
@export var boost_offset_effect : UIBoostOffsetEffect
@export var boost_shake_effect : UIBoostShakeEffect

# 动态 HUD 组:特效只写独立的 offset 通道,由这里统一合成,避免互相抢占 position
var _dynamic_groups: Array[Control] = []


## 统一注册契约:把元素挂到 HUD(取代旧的 register_hud_group / register_hud_static /
## register_hud_far / register_hud_far_node 四套并行 API,见 .memo/.CURRENT.md §4.1)。
##
## [param element] 可为 [PackedScene](自动实例化)或已有节点([Node])。
## 归属由元素自声明的 `@export var hud_slot: HudElement.Slot` 决定;未声明时默认 [constant HudElement.Slot.GROUP]。
## 返回 [HudHandle] 句柄:GROUP 元素可链式配置特效,通过 `.node` 取回实际节点。
func register_hud(element) -> HudHandle:
	if element is PackedScene:
		element = element.instantiate()
	if not (element is Node):
		push_error("HUDManager.register_hud: 需要 PackedScene 或 Node,收到 %s" % element)
		return null

	var slot := HudElement.Slot.GROUP
	var declared: Variant = element.get("hud_slot")
	if declared is int:
		slot = declared

	print("HUDManager: Registering HUD element: " + element.name + " (slot=" + HudElement.Slot.keys()[slot] + ")")

	match slot:
		HudElement.Slot.GROUP:
			if not (element is Control):
				push_error("HUDManager.register_hud: GROUP 元素必须是 Control,收到 %s" % element)
				return null
			if element.get_parent() == null:
				hud_container.add_child(element)
			else:
				element.reparent(hud_container)
			_init_dynamic_group(element as Control)
		HudElement.Slot.STATIC:
			hud_static.add_child(element)
		HudElement.Slot.FAR:
			# 场景实例无父节点 → add_child;已有父节点(如 heat 容器)→ reparent 保持全局变换
			if element.get_parent() == null:
				hud_far.add_child(element)
			else:
				element.reparent(hud_far)
	return HudHandle.new(element, slot)


# 捕获作者好的布局基准位置,并初始化各特效的 offset 通道
func _init_dynamic_group(group: Control) -> void:
	if group in _dynamic_groups:
		return
	group.set_meta("hud_base_pos", group.position)
	group.set_meta("hud_flow_offset", Vector2.ZERO)
	group.set_meta("hud_shake_offset", Vector2.ZERO)
	_dynamic_groups.append(group)


func _process(_delta: float) -> void:
	_compose_dynamic_groups()


# 特效各自只写 meta 里的 offset 通道,这里统一合成到 position(保留布局基准)
func _compose_dynamic_groups() -> void:
	var i := 0
	while i < _dynamic_groups.size():
		var group: Control = _dynamic_groups[i]
		if not is_instance_valid(group):
			_dynamic_groups.remove_at(i)
			continue
		var base: Vector2 = group.get_meta("hud_base_pos", Vector2.ZERO)
		var flow: Vector2 = group.get_meta("hud_flow_offset", Vector2.ZERO)
		var shake: Vector2 = group.get_meta("hud_shake_offset", Vector2.ZERO)
		group.position = base + flow + shake
		i += 1
