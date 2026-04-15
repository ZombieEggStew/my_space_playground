extends HFlowContainer
class_name BuffUIContainer

@export var buff_icon_scene: PackedScene

var player_buff_manager: PlayerBuffManager


func setup(_manager: PlayerBuffManager) -> void:
	player_buff_manager = _manager
	player_buff_manager.get_buff.connect(_on_get_buff)

func _on_get_buff(buff: Buff) -> void:
	var buff_icon = buff_icon_scene.instantiate() as BuffIcon
	buff_icon.set_texture(buff.icon)
	add_child(buff_icon)
	buff.on_expire.connect(buff_icon.on_expire)



