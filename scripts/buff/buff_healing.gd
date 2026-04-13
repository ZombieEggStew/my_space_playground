extends Buff


func _ready():
    super()

func every_tick() -> void:
    var health := ComponentManager.get_health_component(target)
    if health:
        health.heal(1)  # 每秒恢复 5 点生命值