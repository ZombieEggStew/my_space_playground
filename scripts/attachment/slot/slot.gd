extends Node3D
class_name Slot

enum {
    SLOT_1,
    SLOT_2,
    SLOT_3,
    SLOT_4
}

signal on_active()

func active() -> void:
    on_active.emit()