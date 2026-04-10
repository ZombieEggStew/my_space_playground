extends Module
class_name PredictAimModule

var cam_main: Camera3D


@export var crosshair_4: Node2D #绿色 预判指示



var predicted_aim_data :Dictionary = {}
var _locked_enemy_target : AbleToBeLocked
var is_auto_aiming := false


var is_aim_assist_enabled := true

var is_aim_dead_zone_enabled := false


func _ready() -> void:
	SignalBus.on_player_lock_target.connect(_on_player_lock_target)
	cam_main = root.get_main_camera()


func _process(_delta: float) -> void:
	pass
	# if _locked_enemy_target == null:
	# 	crosshair_4.call("reset")
	# 	return

	# if _locked_enemy_target.is_visible:
	# 	crosshair_4.call("set_target_pos", predicted_aim_data.get("screen_pos", Vector2.ZERO))
	# else:
	# 	crosshair_4.call("reset")
	# if bool(root.is_aim_assist_enabled) and crosshair_4 and crosshair_4.visible:
	# 	var assist_radius := float(crosshair_4.get("circle_diameter")) * 0.5
	# 	assist_pos = crosshair_4.position
	# 	is_assist_active = mouse_pos.distance_to(assist_pos) <= assist_radius


func _on_player_lock_target(target: AbleToBeLocked) -> void:
	_locked_enemy_target = target

static func solve_intercept_time(relative_pos: Vector3, target_vel: Vector3, proj_speed: float) -> float:
	var s := max(proj_speed, 0.001) as float
	var a := target_vel.dot(target_vel) - s * s
	var b := 2.0 * relative_pos.dot(target_vel)
	var c := relative_pos.dot(relative_pos)

	if abs(a) < 0.0001:
		if abs(b) < 0.0001:
			return c / s
		var linear_t := -c / b
		return linear_t if linear_t > 0.0 else c / s

	var disc := b * b - 4.0 * a * c
	if disc < 0.0:
		return c / s

	var sqrt_disc := sqrt(disc)
	var t1 := (-b - sqrt_disc) / (2.0 * a)
	var t2 := (-b + sqrt_disc) / (2.0 * a)

	var t := INF
	if t1 > 0.0:
		t = t1
	if t2 > 0.0:
		t = min(t, t2)
	if t == INF:
		return c / s
	return t

static func _get_target_velocity(target: Node3D) -> Vector3:
	if target == null:
		return Vector3.ZERO
	var v = target.get("velocity")
	if v is Vector3:
		return v
	return Vector3.ZERO

func get_predicted_aim_data(bullet_speed :float) -> Dictionary:
	var out := {"valid": false, "screen_pos": Vector2.ZERO, "world_pos": Vector3.ZERO, "time": 0.0}
	if cam_main == null:
		return out
	if not is_instance_valid(_locked_enemy_target):
		return out

	var target_world_pos := _locked_enemy_target.target_node3d.global_transform.origin
	if _locked_enemy_target.has_method("get_pivot_offset"):
		target_world_pos += _locked_enemy_target.call("get_pivot_offset") as Vector3
	var target_vel := _get_target_velocity(_locked_enemy_target.target_node3d)

	var shooter_pos := root.global_transform.origin
	var relative_pos := target_world_pos - shooter_pos
	var intercept_t := solve_intercept_time(relative_pos, target_vel, bullet_speed) as float
	intercept_t = max(intercept_t, 0.0)

	var predicted_world_pos := target_world_pos + target_vel * intercept_t
	var predicted_screen_pos := cam_main.unproject_position(predicted_world_pos)

	out["valid"] = true
	out["screen_pos"] = predicted_screen_pos
	out["world_pos"] = predicted_world_pos
	out["time"] = intercept_t
	return out
