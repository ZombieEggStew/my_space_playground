extends Node3D
class_name PlayerBuffManager

signal get_buff(buff: Buff)

func add_buff(buff : Buff) -> void:
    add_child(buff)
    get_buff.emit(buff)