extends Container
class_name HPBar




#回血特效21：40，回大血22：09

@export var hp_bar: TextureProgressBar
@export var hp_label: Label
@export var health_down_effect: GPUParticles2D

@onready var hp_bar_catch: TextureProgressBar = hp_bar.duplicate()

var health: HealthComponent

func setup(health_component: HealthComponent) -> void:
	health = health_component
	health.changed.connect(update_hp_ui)
	update_hp_ui(health.get_health())

func _ready():
	# 初始化缓存血条
	hp_bar.add_sibling(hp_bar_catch)
	hp_bar_catch.name = "hp_bar_catch"
	hp_bar_catch.show_behind_parent = true # 放在主血条后面
	hp_bar_catch.modulate = Color(1, 1, 1, .5) # 略微透明或设置不同颜色

	

func update_hp_ui(val: int) -> void:


	var max_hp := health.get_max_health()
	var current_hp_percent = float(val) / max_hp
	var target_value = current_hp_percent * 100.0

	hp_label.text = "%d/%d" % [val, max_hp]
	
	# 处理低血量闪烁效果
	_handle_low_hp_blinking(current_hp_percent)

	var is_damage = hp_bar.value - target_value
	hp_bar.value = target_value
	# 如果是血量减少，先让 hp_bar 立即减少，hp_bar_catch 随后平滑减少
	if is_damage > 0:
		# 触发粒子效果
		if health_down_effect:
			# 计算血条当前的像素长度
			var bar_width = hp_bar.size.x
			# 根据当前百分比计算位置
			var effect_pos_x = (hp_bar.value / hp_bar.max_value) * bar_width
			health_down_effect.position.x = effect_pos_x
			health_down_effect.position.y = hp_bar.position.y
			
			# 修改 AtlasTexture 的 region 宽度为血条减少的宽度
			var atlas_tex = health_down_effect.texture as AtlasTexture
			var drop_width : float = 0.0
			if atlas_tex:
				var drop_percent = is_damage / hp_bar.max_value
				drop_width = drop_percent * bar_width
				atlas_tex.region.size.x = drop_width


			# 修改粒子的发射角度为当前容器/血条的角度
			if health_down_effect.process_material is ParticleProcessMaterial:
				health_down_effect.process_material.angle_min = rad_to_deg(-rotation)
				health_down_effect.process_material.angle_max = rad_to_deg(-rotation)
				health_down_effect.process_material.emission_shape_offset.y = hp_bar.size.y / 2 + 4 # 调整发射位置到血条中心
				health_down_effect.process_material.emission_shape_offset.x = drop_width / 2 + 10 # 调整发射位置到血条减少的中心
			
			
			
				
			health_down_effect.restart()
			health_down_effect.emitting = true


		var tween = create_tween()
		tween.tween_property(hp_bar_catch, "value", target_value, 1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	else:
		# 如果是加血，同步更新
		hp_bar.value = target_value
		hp_bar_catch.value = target_value


var _blink_tween: Tween

func _handle_low_hp_blinking(percent: float) -> void:
	if percent <= 0.3:
		# 如果还没有开始闪烁，或者之前的 Tween 已失效，则创建新的闪烁动画
		if _blink_tween == null or not _blink_tween.is_valid():
			_blink_tween = create_tween().set_loops()
			_blink_tween.tween_property(hp_bar, "modulate:a", 0, .5).set_trans(Tween.TRANS_SINE)
			_blink_tween.tween_property(hp_bar, "modulate:a", 1, .5).set_trans(Tween.TRANS_SINE)
	else:
		# 血量回升到 30% 以上，停止闪烁并恢复透明度
		if _blink_tween and _blink_tween.is_valid():
			_blink_tween.kill()
		hp_bar.modulate.a = 1.0
