extends Resource
class_name BoolStat

signal value_changed(new_value: bool)

var value: bool = false:
    set(v):
        value = v
        value_changed.emit(value)

func _init(_value: bool = false) -> void:
    value = _value