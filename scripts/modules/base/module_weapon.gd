extends Module
class_name WeaponModule

signal on_bullet_speed_change(new_speed: float)

@export var bullet_speed := 500.0

func set_bullet_speed(new_speed: float) -> void:
	bullet_speed = new_speed
	on_bullet_speed_change.emit(new_speed)

func get_bullet_speed() -> float:
	return bullet_speed