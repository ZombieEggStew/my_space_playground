extends Buff

func _init() -> void:
	# buff_name 现在由 BuffManager 自动赋值
	interval = 0.1 # 每 0.1 秒触发一次
	duration = 2.0 
	max_stack = 0
	add_new_stack_method = ADD.NEW_STACK
	expire_method = EXPIRE.ONE_STACK
	expire_duration = 0.5
	# particle_path = "res://scenes/particles/healing_particle.tscn" 

func on_tick() -> void:
	if not target: return
	
	# 如果 target 身上有健康组件
	var health = ComponentManager.get_health_component(target)
	if health:
		health.heal(1)
