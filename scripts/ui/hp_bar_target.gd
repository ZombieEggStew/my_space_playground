extends Node

@export var hp_bar : TextureProgressBar
@onready var hp_bar_catch : TextureProgressBar

var health : HealthComponent

func setup(_target: AbleToBeLocked) -> void:
	self.target = _target.target_node3d
	
	# 初始化捕获血条（用于平滑减少效果）
	if not hp_bar_catch:
		hp_bar_catch = hp_bar.duplicate()
		hp_bar.add_sibling(hp_bar_catch)
		hp_bar_catch.show_behind_parent = true
		hp_bar_catch.modulate = Color(1, 1, 1, 0.3)
		
	health.health_changed.connect(_updata_hp_bar)


func _updata_hp_bar(new_health: int , _amount:int) -> void:
	if health == null:
		return
	var target_value = (float(new_health) / health.max_health) * 100.0
	
	if target_value < hp_bar.value:
		hp_bar.value = target_value
		var tween = create_tween()
		tween.tween_property(hp_bar_catch, "value", target_value, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	else:
		hp_bar.value = target_value
		hp_bar_catch.value = target_value
