extends Buff
class_name Buff_Healing

func _ready():
	super()
	NAME = "Healing"

func _setup() -> void:
	pass


func every_tick() -> void:
	var health := ComponentManager.get_health_component(target)
	if health:
		health.heal(1)  # 每秒恢复 5 点生命值
