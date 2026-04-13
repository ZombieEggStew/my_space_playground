extends Node
class_name Main

@export var hud_manager :HUDManager
@onready var ui_manager :UIManager= $UI_Manager

# Called when the node enters the scene tree for the first time.
func _enter_tree() -> void:
	GameManager.register_main_scene(self)

	# 向全局单例注册引用
	GameManager.register_world()
	GameManager.register_hud_manager(hud_manager)
	GameManager.register_ui_manager(ui_manager)
	GameManager.register_transition()
	
	# 也可以在这里执行初始加载逻辑
	GameManager.init_main_menu()





