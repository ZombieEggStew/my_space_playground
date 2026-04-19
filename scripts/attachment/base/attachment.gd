extends Node3D
class_name Attachment


var _owner: CharacterBody3D

var slot: Slot

func setup(__owner:CharacterBody3D) -> void:
    _owner = __owner
    slot = get_parent() as Slot
    slot.on_active.connect(active)

func active() -> void:
    pass

