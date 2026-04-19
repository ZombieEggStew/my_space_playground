extends Attachment
class_name MissileLauncherModule

@export var missile_scene: PackedScene

@export var launch_point: Node3D

var _locked_target: AbleToBeLocked = null

func _ready():
	SignalBus.on_player_lock_target.connect(_on_player_lock_target)

func active() -> void:
	_launch_missile()

func _on_player_lock_target(target: AbleToBeLocked) -> void:
	_locked_target = target

func _launch_missile() -> void:
	if not is_instance_valid(_locked_target):
		print("No valid target locked. Missile launch aborted.")
		return
	print("Missile Launcher Activated!")
	var missile_instance := missile_scene.instantiate() as Missile_1
	add_child(missile_instance)
	missile_instance.setup(launch_point.global_position, -launch_point.global_transform.basis.z,TeamID.PLAYER,self)
	missile_instance.set_target(_locked_target)
