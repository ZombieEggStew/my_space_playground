extends CanvasLayer

func _ready():
	var module := get_parent() as Module

	module.modules_manager.get_screen_module().add_hud(self)
