extends ModuleComponent
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
		# crosshair_3.position 是机头局部坐标(父节点 hud_far_manager 定位在机头),
		# 瞄准需要视口全局坐标 → 加回机头偏移
		return crosshair_3.position + crosshair_3.hud.position
	return Vector2.INF # 表示无效或离屏
