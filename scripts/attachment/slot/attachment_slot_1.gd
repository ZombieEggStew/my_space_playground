extends Slot

func _ready():
    SignalBus.on_player_try_use_item_1.connect(active)


