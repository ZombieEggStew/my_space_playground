extends Node
class_name LaserGunAimSystem


var crosshair_3: Crosshair3

func setup(dead_zone:float) -> void:
	var indicator := GameManager.hud_manager.register_hud_static(Scenes.dead_zone_indicator_scene)
	indicator.setup(dead_zone)
	crosshair_3 = GameManager.hud_manager.register_hud_static(Scenes.crosshair_3)
	crosshair_3.setup(dead_zone)

func _process(_delta):
	if crosshair_3 == null:
		return
	
	var mouse_pos = get_viewport().get_mouse_position()
	crosshair_3.update_from_mouse(mouse_pos)


func get_aim_point_screen_pos() -> Vector2:
	if crosshair_3:
		return crosshair_3.position
	return get_viewport().get_mouse_position()
