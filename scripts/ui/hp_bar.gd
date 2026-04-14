extends Container
class_name HPBar

#回血特效21：40，回大血22：09

@export var hp_bar: TextureProgressBar
@export var hp_label: Label
@export var health_down_effect: GPUParticles2D
@export var health_change_effect: GPUParticles2D

@export var hp_bar_catch: TextureProgressBar

var health_catch_tween: Tween

func setup(health_component: HealthComponent) -> void:
	health_component.changed.connect(_health_changed)
	_health_changed(health_component.get_health() , health_component.get_max_health() , 0)
	hp_bar_catch.value = hp_bar.value

func _health_changed(new_health: int , new_max_health : int,changed_amount:int) -> void:
	hp_bar.value = new_health
	hp_bar.max_value = new_max_health
	_handle_low_hp_blinking()

	#label
	hp_label.text = "%d/%d (%d%%)" % [new_health, new_max_health , int(float(new_health) / new_max_health * 100)]

	var _amount := abs(changed_amount) as int

	if _amount > 0:
		set_health_change_effect(_amount)

	if changed_amount < 0:
		set_health_down_effect(-changed_amount , new_health)
		
	if changed_amount > 0:
		pass

		if health_catch_tween and health_catch_tween.is_valid():
			health_catch_tween.kill()

		hp_bar_catch.value = new_health

func set_health_down_effect(damage_amount:int , target_value:int) -> void:
	# 触发粒子效果
	if health_down_effect:
		# 计算血条当前的像素长度
		var bar_width = hp_bar.size.x
		# 根据当前百分比计算位置
		var effect_pos_x = (hp_bar.value / hp_bar.max_value) * bar_width + hp_bar.position.x
		health_down_effect.position.x = effect_pos_x
		health_down_effect.position.y = hp_bar.position.y
		
		# 修改 AtlasTexture 的 region 宽度为血条减少的宽度
		var atlas_tex = health_down_effect.texture as AtlasTexture
		var drop_width : float = 0.0

		if atlas_tex:
			var drop_percent = damage_amount / hp_bar.max_value
			drop_width = drop_percent * bar_width
			atlas_tex.region.size.x = drop_width


		# 修改粒子的发射角度为当前容器/血条的角度
		if health_down_effect.process_material is ParticleProcessMaterial:
			health_down_effect.process_material.angle_min = rad_to_deg(-rotation)
			health_down_effect.process_material.angle_max = rad_to_deg(-rotation)
			health_down_effect.process_material.emission_shape_offset.y = hp_bar.size.y / 2 # 调整发射位置到血条中心
			health_down_effect.process_material.emission_shape_offset.x = drop_width / 2 # 调整发射位置到血条减少的中心
			
		health_down_effect.restart()
		health_down_effect.emitting = true

	health_catch_tween = create_tween()
	health_catch_tween.tween_property(hp_bar_catch, "value", target_value, 1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func set_health_change_effect(_amount:int) -> void:
	if health_change_effect:
		# 计算血条当前的像素长度
		var bar_width = hp_bar.size.x
		# 根据当前百分比计算位置
		var effect_pos_x = (hp_bar.value / hp_bar.max_value) * bar_width + hp_bar.position.x

		health_change_effect.position.x = effect_pos_x
		health_change_effect.position.y = hp_bar.position.y


		# # 修改 AtlasTexture 的 region 宽度为血条减少的宽度
		# var atlas_tex = health_change_effect.texture as AtlasTexture
		# var drop_width : float = 0.0
		
		# if atlas_tex:
		# 	var drop_percent = healing_amount / hp_bar.max_value
		# 	drop_width = drop_percent * bar_width
		# 	atlas_tex.region.size.x = drop_width

		# 修改粒子的发射角度为当前容器/血条的角度
		if health_change_effect.process_material is ParticleProcessMaterial:
			health_change_effect.process_material.angle_min = rad_to_deg(-rotation)
			health_change_effect.process_material.angle_max = rad_to_deg(-rotation)
			health_change_effect.process_material.emission_shape_offset.y = hp_bar.size.y / 2 # 调整发射位置到血条中心
			# health_change_effect.process_material.emission_shape_offset.x = drop_width / 2 # 调整发射位置到血条减少的中心


		health_change_effect.restart()
		health_change_effect.emitting = true

var _blink_tween: Tween

func _handle_low_hp_blinking() -> void:
	var percent := hp_bar.value / hp_bar.max_value
	if percent <= 0.3:
		# 如果还没有开始闪烁，或者之前的 Tween 已失效，则创建新的闪烁动画
		if _blink_tween == null or not _blink_tween.is_valid():
			_blink_tween = create_tween().set_loops()
			_blink_tween.tween_property(hp_bar, "modulate:a", 0, .3).set_trans(Tween.TRANS_SINE)

			_blink_tween.tween_property(hp_bar, "modulate:a", 1, .3).set_trans(Tween.TRANS_SINE)
	else:
		# 血量回升到 30% 以上，停止闪烁并恢复透明度
		if _blink_tween and _blink_tween.is_valid():
			_blink_tween.kill()
		hp_bar.modulate.a = 1.0
