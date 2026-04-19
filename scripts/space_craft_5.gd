extends CharacterBody3D

var team_id := TeamID.TEAM_ENEMY
@onready var health : HealthComponent = $HealthComponent
@onready var ai : AIBrain = $AI_Brain

func _ready() -> void:
	health.on_death.connect(die)
	health.setup(1000, 1000)

func hit(damage: int) -> void:
	health.take_damage(damage)












# 对外接口-----------------------------------------------------------------
func get_health_component() -> HealthComponent:
	return health
	
func get_team_id() -> int:
	return team_id

func die() -> void:
	queue_free()
