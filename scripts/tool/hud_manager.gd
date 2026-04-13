extends CanvasLayer

func _ready():
	var item := get_parent()

	if item == null:
		return

	if item is Module:
		var module := item.modules_manager.get_screen_module() as ScreenModule
		
		if module:
			module.add_hud(self)
		else :
			print(item.name + ": Failed to find ScreenModule in parent ModulesManager.")
			queue_free()
		return
