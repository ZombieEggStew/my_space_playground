extends Module3D
class_name BoosterModule

var engine_module : EngineModule

# boost
var is_boosting :bool = false
var boost_speed :float = 100.0
var boost_accel :float = 120.0

func setup(_engine) -> void:
	engine_module = _engine

func _enter_tree() -> void:
	engine_module = get_parent()

	modules_manager = engine_module.modules_manager
	root = engine_module.root
