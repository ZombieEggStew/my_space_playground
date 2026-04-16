extends Node
class_name BuffComponent

signal buff_added(buff: Buff)
signal buff_removed(buff: Buff)

# 存储正在生效的 Buff: { buff_name: Buff }
var active_buffs: Dictionary = {}

# 存储粒子效果实例: { buff_name: GPUParticles3D }
var active_particles: Dictionary = {}

func _process(delta: float) -> void:
	# 由于可能在遍历时删除，先获取键
	var buff_names = active_buffs.keys()
	for b_name in buff_names:
		var buff = active_buffs[b_name]
		buff.update(delta)

# source: 施法者, duration: 覆盖持续时间(传0使用Buff默认)
func add_buff(buff: Buff, source: Node, duration: float = 0.0) -> void:
	if active_buffs.has(buff.buff_name):
		var existing = active_buffs[buff.buff_name]
		existing.add_stack(duration if duration > 0 else existing.duration)
	else:
		_apply_new_buff(buff, source, duration if duration > 0 else buff.duration)

func _apply_new_buff(buff: Buff, source: Node, duration: float) -> void:
	active_buffs[buff.buff_name] = buff
	buff.on_expire.connect(_on_buff_expired.bind(buff.buff_name))
	
	buff.setup(get_parent(), source, duration)
	buff.apply()
	buff_added.emit(buff)
	
	# 处理粒子效果
	if buff.particle_path != "":
		var p_scene = load(buff.particle_path)
		if p_scene:
			var p = p_scene.instantiate() as GPUParticles3D
			add_child(p)
			p.emitting = true
			active_particles[buff.buff_name] = p

func _on_buff_expired(b_name: String) -> void:
	if active_buffs.has(b_name):
		var b = active_buffs[b_name]
		buff_removed.emit(b)
		active_buffs.erase(b_name)
	
	if active_particles.has(b_name):
		var p = active_particles[b_name]
		p.emitting = false
		active_particles.erase(b_name)
		# 延迟删除粒子以保证效果播完
		get_tree().create_timer(p.lifetime).timeout.connect(p.queue_free)

func has_buff(b_name: String) -> bool:
	return active_buffs.has(b_name)

func remove_buff(b_name: String) -> void:
	if active_buffs.has(b_name):
		_on_buff_expired(b_name)
