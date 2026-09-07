extends PanelContainer
class_name SpeedPanel

@export var speed_label: Label
@export var magnitude_label: Label

## 绑定玩家速度 Stat:订阅 value_changed,不再每帧轮询 get_speed_string(见 .memo/.CURRENT.md P2)。
func setup(player: PlayerShip) -> void:
	player.speed_stat.value_changed.connect(_on_speed_changed)
	player.forward_speed_stat.value_changed.connect(_on_forward_speed_changed)
	# 立即用当前值初始化一次
	_on_speed_changed(player.speed_stat.value)
	_on_forward_speed_changed(player.forward_speed_stat.value)

func _on_speed_changed(v: float) -> void:
	speed_label.text = "%.2f" % v

func _on_forward_speed_changed(v: float) -> void:
	magnitude_label.text = "%.2f" % v
