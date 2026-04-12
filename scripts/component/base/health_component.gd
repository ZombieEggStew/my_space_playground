extends Node
class_name HealthComponent

signal on_death()
signal changed(new_health: int)


var health :int = 10
var max_health :int = 10

func setup(default_health :int, _max_health :int = default_health) -> void:
	health = default_health

	max_health = _max_health


func get_health() -> int:
	return health

func get_max_health() -> int:
	return max_health

func take_damage(damage: int) -> void:
	health -= damage
	if health <= 0:
		health = 0
		die()
	changed.emit(health)


func heal(amount: int) -> void:
	health = min(health + amount, max_health)
	changed.emit(health)

func die() -> void:
	on_death.emit()