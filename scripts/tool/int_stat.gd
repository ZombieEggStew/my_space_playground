extends Resource
class_name IntStat

signal value_changed(new_value: int)
signal max_value_changed(new_value: int)

var value: int = 0:
    set(v):
        value = v
        value_changed.emit(value)

var max_value: int = 0:
    set(v):
        max_value = v
        max_value_changed.emit(max_value)

func _init(_value: int = 0, _max_value: int = 0) -> void:
    value = _value
    max_value = _max_value
