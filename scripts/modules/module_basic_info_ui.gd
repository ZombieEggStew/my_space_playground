extends UIModule

@export var hp_bar: HPBar

@export var speed_panel: SpeedPanel

var screen_module: ScreenModule


func _ready() -> void:

	var hp_component = root.get_health_component() 
	
	hp_bar.setup(hp_component)

	speed_panel.setup(root)
	

	GameManager.hud_manager.register_hud_group(hud_container).set_flow_effect(ControlGroup.Index.GROUP_1).set_rotation_effect().set_boost_offset_effect()
	
