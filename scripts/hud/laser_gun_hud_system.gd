extends Node
class_name LaserGunHudSystem


var crosshair_3: Crosshair3
var indicator: Node2D

func setup(dead_zone:float) -> void:
	indicator = GameManager.hud_manager.register_hud_far(Scenes.dead_zone_indicator_scene)
	indicator.setup(dead_zone)
	crosshair_3 = GameManager.hud_manager.register_hud_far(Scenes.crosshair_3)
	crosshair_3.setup(dead_zone)

func get_aim_point_screen_pos() -> Vector2:
	if crosshair_3 and crosshair_3.visible:
		return crosshair_3.position
	return Vector2.INF # 表示无效或离屏
