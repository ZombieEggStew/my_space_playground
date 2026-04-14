extends Module3D
class_name BoosterModule

var engien_module : EngineModule

func _enter_tree() -> void:
    engien_module = get_parent()

    modules_manager = engien_module.modules_manager
    root = engien_module.root
