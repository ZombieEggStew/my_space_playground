extends UIModule
class_name HUDModule

## 门面模块(决策 #19):集中管理本船所有模块 HUD 的注册,转发包装给 HUDManager。
## 可被打坏/卸载——模块被卸载时,经本门面注册的 2D 节点统一清理,玩家失去 HUD(玩法)。
##
## 职责边界:
## - 只做"模块 HUD 注册 → 转发 HUDManager"与统一清理;**不做 2D 投影**(投影原语在 camera,
##   决策 #18)与**悬停检测**(在 aim,决策 #21)。
## - 玩家固有面板(血量/速度/buff)是可换子插件 player_stats_view(决策 #19)。
## - 各能力模块的 `<name>_view` 注册进本门面,卸载时经 on_uninstall 统一回收。

@export var player_stats_view: PlayerStatsView

## 经本门面注册到 HUD 层的 2D 节点(被 reparent,脱离本模块场景树,须持引用清理)
var _registered_hud: Array[Node] = []

func _ready() -> void:
	if player_stats_view == null:
		Log.log_missing_component(self, "player_stats_view")
		return
	player_stats_view.setup(root)
	register_hud(player_stats_view).set_flow_effect(ControlGroup.Index.GROUP_1).set_rotation_effect().set_boost_offset_effect()

## 门面注册 API:转发给 HUDManager,并记录到本门面的清理清单。
func register_hud(element) -> HudHandle:
	var handle := GameManager.hud_manager.register_hud(element)
	if handle != null and handle.node != null and not (handle.node in _registered_hud):
		_registered_hud.append(handle.node)
	return handle

## 卸载清理(§4.2-5):经本门面注册的 2D 节点已被 reparent 到 HUD 层,
## 模块 queue_free 带不走,须在此统一清除;幂等(重复调用安全)。
func on_uninstall() -> void:
	for node in _registered_hud:
		if is_instance_valid(node):
			node.queue_free()
	_registered_hud.clear()
