extends Node
class_name Main


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GameManager.register_main_scene(self)

	# 向全局单例注册引用
	GameManager.register_world()
	GameManager.register_hud()
	GameManager.register_transition()
	
	# 也可以在这里执行初始加载逻辑
	GameManager.init_main_menu()





