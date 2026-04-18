extends Node
class_name HealthComponent

signal on_death()
# signal health_changed(new_health: int , changed_amount:int)
# signal max_health_changed(new_max_health: int)
signal changed(new_health: int ,new_max_health: int, changed_amount:int)

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
	# health_changed.emit(health , -damage)

	changed.emit(health , max_health , -damage)

func set_max_health(new_max_health: int) -> void:
	max_health = new_max_health
	# max_health_changed.emit(max_health)

	var change_amount := health - max_health
	if change_amount > 0:
		health = max_health
		# health_changed.emit(health , -change_amount)
		changed.emit(health , max_health , -change_amount)
	else :
		changed.emit(health , max_health , 0)
		
func reset() -> void:
	health = max_health
	# health_changed.emit(health , 0)
	changed.emit(health , max_health , 0)
	

func heal(amount: int) -> void:
	health = min(health + amount, max_health)
	# health_changed.emit(health , amount)

	changed.emit(health , max_health , amount)

func die() -> void:
	on_death.emit()