# meta-name: buff template
# meta-description: new buff

extends Buff


func _ready():
    super()
    NAME = "Buff Name"

# after add to scene , target and duration has been set up
func _setup() -> void:
    pass

func every_tick() -> void:
    pass