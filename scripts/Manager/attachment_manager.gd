extends Node3D
class_name AttachmentManager

var player_ship: PlayerShip

func _ready():
    player_ship = get_parent() as PlayerShip

func attach_to(slot : int , scene:PackedScene) -> void:
    var attachment_instance = scene.instantiate()
    match slot:
        Slot.SLOT_1:
            get_child(Slot.SLOT_1).add_child(attachment_instance)
        Slot.SLOT_2:
            get_child(Slot.SLOT_2).add_child(attachment_instance)
        Slot.SLOT_3:
            get_child(Slot.SLOT_3).add_child(attachment_instance)
        Slot.SLOT_4:
            get_child(Slot.SLOT_4).add_child(attachment_instance)

    attachment_instance.setup(player_ship)
