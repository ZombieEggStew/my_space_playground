extends Control
class_name PlayerStatsView

## 玩家固有属性面板(血量/速度/buff)的可换子插件(决策 #19)。
## 归属判别(§2.1):玩家固有属性不依附任何玩法模块,统一由本插件显示,Stat 驱动;
## 由 module_hud(门面模块)持有并注册,可整体替换(换风格/布局)。
##
## 职责边界:
## - 只负责玩家固有面板的组装与 Stat 绑定,不含玩法逻辑。
## - 模块能力相关的 UI(目标/能量/热量/护盾/准星)各归各模块的 `<name>_view`,不在这里。

@export var hp_bar: HPBar
@export var speed_panel: SpeedPanel

func setup(player: PlayerShip) -> void:
	var hp_component := player.get_health_component()
	hp_bar.setup(hp_component)
	speed_panel.setup(player)
