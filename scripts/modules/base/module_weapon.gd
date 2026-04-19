extends Module3D
class_name WeaponModule

signal on_bullet_speed_change(new_speed: int)

@export var bullet_speed := 500

func set_bullet_speed(new_speed: int) -> void:
	bullet_speed = new_speed
	on_bullet_speed_change.emit(new_speed)

func get_bullet_speed() -> int:
	return bullet_speed