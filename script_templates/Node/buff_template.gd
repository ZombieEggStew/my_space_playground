# meta-name: buff template
# meta-description: new buff

extends Buff

func _init() -> void:
	NAME = "Buff Name"
	interval = 0.1
	duration = 5.0
	max_stack = 12
	add_new_stack_method = ADD.NEW_STACK_AND_REFRESH
	expire_method = EXPIRE.GRADUALLY
	expire_duration = .5

	
func _ready():
	super()
	NAME = "Buff Name"

# after add to scene , target and duration has been set up
func _setup() -> void:
	pass

func every_tick() -> void:
	pass