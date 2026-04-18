extends VBoxContainer
class_name ShieldUIContainer

@export var shield_label: Label
@export var shield_progress_bar: TextureProgressBar

var target_value := 0.0


func update_shield_value(new_value:int, max_value:int) -> void:
    shield_label.text = "%d / %d" % [new_value, max_value]
    target_value = new_value
    shield_progress_bar.max_value = max_value


func _process(delta):

    shield_progress_bar.value = lerp(shield_progress_bar.value, target_value, delta * 5)