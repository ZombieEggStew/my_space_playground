extends Node
class_name LaserGunHudSystem


var crosshair_3: Crosshair3
var indicator: Node2D

func setup(dead_zone:float) -> void:
	indicator = GameManager.hud_manager.register_hud_static(Scenes.dead_zone_indicator_scene)
	indicator.setup(dead_zone)
	crosshair_3 = GameManager.hud_manager.register_hud_static(Scenes.crosshair_3)
	crosshair_3.setup(dead_zone)

func _process(_delta):
	if crosshair_3 == null or indicator == null:
		return
	
	var mouse_pos = get_viewport().get_mouse_position()
	var center = indicator.get_nose_screen_pos()
	var is_on_screen = indicator.is_on_screen()
	crosshair_3.update_from_center(center, mouse_pos, is_on_screen)


func get_aim_point_screen_pos() -> Vector2:
	if crosshair_3 and crosshair_3.visible:
		return crosshair_3.position
	return Vector2.INF # 表示无效或离屏
