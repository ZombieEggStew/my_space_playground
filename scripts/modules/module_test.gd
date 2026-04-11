extends Module

@export var hit_count_label: Label


var hit_count_ref: IntStat

func _ready() -> void:
	SignalBus.on_player_lock_target.connect(_on_lock_target)

	# hit_count_ref = test_box_node.get_hit_count()
	# hit_count_ref.changed.connect(_update_hit_count_ui)
	# _update_hit_count_ui(hit_count_ref.value)

func _on_lock_target(target: AbleToBeLocked) -> void:
	if target.target_node3d.name == "test_box":
		hit_count_ref = target.target_node3d.get_hit_count()
		hit_count_ref.value_changed.connect(_update_hit_count_ui)
		_update_hit_count_ui(hit_count_ref.value)

func _update_hit_count_ui(new_val: int) -> void:
	hit_count_label.text = "%d" % new_val
