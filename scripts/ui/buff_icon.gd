extends PanelContainer
class_name BuffIcon

var buff : Buff

@export var icon_rect: TextureRect
@export var progress_bar: TextureProgressBar
@export var stack_label: Label


func setup(_buff : Buff) -> void:
	buff = _buff
	icon_rect.texture = buff.icon
	
	buff.on_expire.connect(on_expire)
	buff.on_stack_changed.connect(_on_stack_changed)
	
	_show_stack_count()
	_play_spawn_animation()

func _play_spawn_animation() -> void:
	# 初始状态：缩小且透明
	modulate.a = 0.0
	
	var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 1.0, 1)

func _process(_delta: float) -> void:
	if buff and buff.duration > 0:
		# 更新倒计时进度条 (1.0 -> 0.0)
		progress_bar.value = (1.0 - (buff.elapsed_time / buff.duration)) * 100 
	else:
		progress_bar.value = 100

func on_expire() -> void:
	# 可以在这里播放消失动画后再删除
	queue_free()

func _on_stack_changed(_new_stack: int) -> void:
	_show_stack_count()
	_play_stack_update_animation()

func _play_stack_update_animation() -> void:

	var tween_stack_update = create_tween().set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_OUT)
	tween_stack_update.tween_property(self, "scale", Vector2(1.1, 1.1), .1)
	tween_stack_update.tween_property(self, "scale", Vector2.ONE, .1)

func _show_stack_count() -> void:
	if not stack_label: return
	if buff.stack_count > 1:
		stack_label.text = str(buff.stack_count)
		stack_label.show()
	else:
		stack_label.hide()
