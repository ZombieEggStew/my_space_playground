extends Node

## ③ 世界级事件总线:只声明信号,零逻辑零状态(见 .memo/.CURRENT.md §2.2 三级通信模型)。
## 只承载"不依附任何一艘船的世界实体事件";② 飞船级 12 条信号已迁到 ShipBus。

signal on_player_registered(player: PlayerShip)

signal on_lockable_target_spawned(target: AbleToBeLocked)

signal on_lockable_target_died(target: AbleToBeLocked)

signal on_damage_dealt(amount: int, pos: Vector2)
