extends Node

@export var hp_bar : TextureProgressBar
@export var hp_catch: TextureProgressBar

@export var mask: ColorRect

var tween : Tween
var tween_hp_catch : Tween

var _is_active := false


var _target: AbleToBeLocked
var _target_health : HealthComponent

var cam: Camera3D

var _is_locked : bool = false 


var _is_on_screen := false


func _ready() -> void:
	mask.size.x = 0
	set_process(_is_active)

func setup(target: AbleToBeLocked , _cam : Camera3D) -> void:
	_target = target
	_target_health = target.target_node3d.get_node_or_null("HealthComponent")
	if _target_health:
		_target_health.changed.connect(_on_health_changed)
		_on_health_changed(_target_health.get_health() , _target_health.get_max_health() , 0)
	target.on_locked.connect(_on_locked)
	target.screen_entered.connect(_on_enter_screen)
	target.screen_exited.connect(_on_exit_screen)

	cam = _cam

func _on_health_changed(new_health: int , new_max_health: int, _changed_amount:int) -> void:
	hp_bar.value = new_health
	hp_bar.max_value = new_max_health

func _on_locked(is_locked: bool) -> void:
	if _is_locked == is_locked:
		return
	_is_locked = is_locked
	if _is_on_screen:
		set_active(is_locked)
	else:
		_set_active_immediately(false)

func _on_enter_screen():
	_is_on_screen = true
	if _is_locked:
		_set_active_immediately(true)


func _on_exit_screen():
	_is_on_screen = false
	_set_active_immediately(false)

func set_active(active: bool) -> void:
	
	if _is_active == active:
		return
	_is_active = active
	set_process(active)

	if tween and tween.is_valid():
		tween.kill()


	if _is_active:
		tween = create_tween()
		tween.tween_property(mask, "size:x", hp_bar.size.x, 1)
	else:
		tween = create_tween()
		tween.tween_property(mask, "size:x", 0, 1.0)

func _set_active_immediately(active: bool) -> void:
	if tween and tween.is_valid():
		tween.kill()
	_is_active = active
	set_process(active)
	if active:
		mask.size.x = hp_bar.size.x
	else:
		mask.size.x = 0


func _process(_delta):
	update_visuals(cam.unproject_position(_target.global_position))
	
func update_visuals(pos : Vector2) -> void:
	pos.y += 50
	mask.position = pos - mask.size / 2.0
