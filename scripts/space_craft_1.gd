#TO DO : strafe attack evade:别玩家锁定时的逻辑 dead：死亡
#TO DO : 锁定：计算玩家速度进行射击预测

extends CharacterBody3D

const team_id := 2

# 是否移动到state machine里
var speed := 20.0
var accel := 25.0
var turn_speed := 4.0

var health := 100.0
var hit_count := 0

@export var move_sm: Node
@export var combat_sm: Node
@export var collision_shape: CollisionShape3D

func get_hit(damage: float) -> void:
	health -= damage
	hit_count += 1
	if health <= 0:
		queue_free()

func get_team_id() -> int:
	return team_id

func get_pivot_offset() -> Vector3:
	return collision_shape.position

func _ready() -> void:
	add_to_group("enemies")

	if move_sm == null:
		push_error("Move State machine node is not assigned!")
	if combat_sm == null:
		push_error("Combat State machine node is not assigned!")
	setup_sms()
	

func setup_sms() -> void:
	if move_sm:
		move_sm.set_controlled_ship(self)
	if combat_sm:
		combat_sm.set_controlled_ship(self)


func _physics_process(delta: float) -> void:
	var desired_velocity := Vector3.ZERO
	desired_velocity = move_sm.get_desired_velocity()

	desired_velocity = desired_velocity.limit_length(speed)

	velocity = velocity.move_toward(desired_velocity, accel * delta)

	if velocity.length() > 0.05:
		_face_to_velocity(delta)

	move_and_slide()


func _face_to_velocity(delta: float) -> void:
	# Basis.looking_at expects local -Z as forward; this model uses +Z forward.
	var forward := -velocity.normalized()
	var t := clamp(turn_speed * delta, 0.0, 1.0) as float
	var target_basis := Basis.looking_at(forward, Vector3.UP)
	global_transform.basis = global_transform.basis.slerp(target_basis, t)
