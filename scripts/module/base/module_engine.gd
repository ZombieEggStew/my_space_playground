extends Module3D
class_name EngineModule

var booster_module: BoosterModule 
var is_engine_on := true


func install_booster_module(module_scene: PackedScene) -> void:
	var module = module_scene.instantiate()
	if module is BoosterModule:
		booster_module = module
		add_child(module)
		booster_module.setup(self)
	else:
		Log.log_error(self,"Installed module is not a BoosterModule: %s" % module_scene)