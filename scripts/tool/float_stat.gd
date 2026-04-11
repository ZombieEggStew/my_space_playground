extends Resource
class_name FloatStat

signal value_changed(new_value: float)
signal max_value_changed(new_value: float)

var value: float = 0.0:
    set(v):
        value = v
        value_changed.emit(value)

var max_value: float = 0.0:
    set(v):
        max_value = v
        max_value_changed.emit(max_value)

func _init(_value: float = 0.0, _max_value: float = 0.0) -> void:
    value = _value
    max_value = _max_value