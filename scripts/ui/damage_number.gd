extends Label

func setup(amount: int, pos: Vector2) -> void:
	text = str(amount)
	global_position = pos - size / 2.0
	pivot_offset = size / 2.0

	var tween = create_tween().set_parallel(true)
	
	# 向上飘动并带有随机偏转
	var target_pos = global_position + Vector2(randf_range(-50, 50), -100)
	tween.tween_property(self, "global_position", target_pos, 0.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	# 缩放效果 (先大后小) (弹出感)
	scale = Vector2.ZERO
	var scale_tween = create_tween()
	scale_tween.tween_property(self, "scale", Vector2(1.5, 1.5), 0.1)
	scale_tween.tween_property(self, "scale", Vector2.ONE, 0.1)
	
	# 透明度淡出
	tween.tween_property(self, "modulate:a", 0.0, 0.4).set_delay(0.3)
	
	# 这里改为隐藏。如果是对象池管理的，会在 get 时重新 show
	tween.chain().finished.connect(func(): hide())
