extends PanelContainer
class_name SpeedPanel

var player : PlayerShip

@export var speed_label: Label

func setup(_player: PlayerShip) -> void:
	player = _player

func _process(_delta):
	_updata_speed_ui()	

 
func _updata_speed_ui() -> void:
	speed_label.text = player.get_speed_string()