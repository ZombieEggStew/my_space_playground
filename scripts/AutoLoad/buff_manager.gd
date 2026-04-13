extends Node

const BUFFS = {
	"healing": preload("res://scenes/buff/buff_healing.tscn"),

}

func apply_buff(target: Node, source: Node, buff: PackedScene, duration:int) -> void:
	var new_buff = buff.instantiate() as Buff
	target.add_child(new_buff)
	new_buff.apply(source , duration)
