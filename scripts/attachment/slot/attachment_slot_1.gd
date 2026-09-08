extends Slot

## 静态挂件槽位:消费 ② 船级输入事件。bus 在 on_player_registered 时取
## (此时 PlayerShip 完全就绪;子节点 _ready 早于父节点,不能直接经 get_parent 链取)。

func _ready() -> void:
	SignalBus.on_player_registered.connect(_on_player_registered)

func _on_player_registered(player: PlayerShip) -> void:
	if player.ship_bus:
		if not player.ship_bus.on_player_try_use_item_1.is_connected(active):
			player.ship_bus.on_player_try_use_item_1.connect(active)
