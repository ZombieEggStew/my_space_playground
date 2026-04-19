extends CharacterBody3D

var team_id := TeamID.ENEMY
@onready var health : HealthComponent = $HealthComponent

func _ready() -> void:
	health.on_death.connect(die)
	health.setup(team_id , 100, 100)

func hit(damage: int) -> void:
	health.take_damage(damage)












# 对外接口-----------------------------------------------------------------
func get_health_component() -> HealthComponent:
	return health
	
func get_team_id() -> int:
	return team_id

func die() -> void:
	queue_free()