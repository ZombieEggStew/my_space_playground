#TO DO : 目前只能锁定一个目标，后续加入多目标锁定
#TO DO : 锁定目标后视角持续朝向目标，加速改为快速调头
#TO DO : 
#TO DO : 
#TO DO : 
#TO DO : 
#TO DO : 
#TO DO : 

#FIX ME : 敌人死亡 ui 锁定 逻辑
#FIX ME :
#FIX ME :
#FIX ME :
#FIX ME :
#FIX ME :
#FIX ME :

extends CanvasLayer

@export var aim_manager : Node

@export var offset_node: Node2D


@export var label_set: LabelSettings

#----label
@export var v_box_container: VBoxContainer

var info := {}
var _info_labels := {}


var player: CharacterBody3D
var test_box: CharacterBody3D
var cam_main: Camera3D



var predicted_aim_data :Dictionary = {}

func _ready() -> void:
	player = get_parent() as CharacterBody3D
	test_box = GameManager.instance.get_test_box()
	cam_main = player.cam_main


	predicted_aim_data = aim_manager.predicted_aim_data

func _update_info_label() -> void:
	info["speed"] = player.velocity.length()
	info["aim ray length"] = player.aim_ray_length

	var locked_enemy: Node3D = null
	# if crosshair_2 and crosshair_2.has_method("get_locked_enemy"):
	# 	locked_enemy = crosshair_2.get_locked_enemy() as Node3D

	if is_instance_valid(locked_enemy):
		var target_speed := 0.0
		var target_velocity = locked_enemy.get("velocity")
		if target_velocity is Vector3:
			target_speed = target_velocity.length()
		elif locked_enemy.has_method("get") and locked_enemy.get("speed") != null:
			target_speed = float(locked_enemy.get("speed"))

		var target_world_pos := locked_enemy.global_transform.origin
		if locked_enemy.has_method("get_pivot_offset"):
			target_world_pos += locked_enemy.call("get_pivot_offset") as Vector3

		info["locked target speed"] = target_speed
		info["locked target distance"] = player.global_transform.origin.distance_to(target_world_pos)
	else:
		info.erase("locked target speed")
		info.erase("locked target distance")


		if bool(predicted_aim_data.get("valid", false)):
			info["lead time"] = float(predicted_aim_data.get("time", 0.0))
		else:
			info.erase("lead time")
	info["hit count"] = test_box.get_hit_count()

	_sync_info_labels()


func _sync_info_labels() -> void:
	if v_box_container == null:
		return

	# Create missing labels and update all current values.
	for key in info.keys():
		var label := _info_labels.get(key) as Label
		if label == null:
			label = Label.new()
			label.name = "label_%s" % str(key).replace(" ", "_")
			label.z_index = 10
			if label_set:
				label.label_settings = label_set
			v_box_container.add_child(label)
			_info_labels[key] = label

		label.text = "%s: %s" % [str(key), _format_info_value(info[key])]

	# Remove labels for keys that are no longer present.
	var stale_keys := []
	for key in _info_labels.keys():
		if not info.has(key):
			stale_keys.append(key)
	for key in stale_keys:
		var stale_label := _info_labels[key] as Label
		if stale_label:
			stale_label.queue_free()
		_info_labels.erase(key)


func _format_info_value(value: Variant) -> String:
	if value is float:
		return "%.2f" % value
	return str(value)




func _process(_delta: float) -> void:
	_update_info_label()






	

	
