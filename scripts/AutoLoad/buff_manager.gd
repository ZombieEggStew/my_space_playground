extends Node

const BUFFS = {
	"healing": preload("res://scenes/buff/buff_healing.tscn"),

}

func apply_buff(target: Node, source: Node, buff: PackedScene, duration:int) -> void:
	var new_buff = buff.instantiate() as Buff
	if target is PlayerShip:
		target.get_player_buff_manager().add_buff(new_buff)
	else :
		target.add_child(new_buff)

	new_buff.setup(source , duration)
	new_buff._setup()

	new_buff.apply()
