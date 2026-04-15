extends UIModule

@export var hp_bar: HPBar

@export var speed_panel: SpeedPanel

@export var buff_container: BuffUIContainer

var screen_module: ScreenModule


func _ready() -> void:

	var hp_component = root.get_health_component() 
	
	hp_bar.setup(hp_component)

	speed_panel.setup(root)
	
	buff_container.setup(root.get_player_buff_manager())

	GameManager.hud_manager.register_hud_group(hud_container).set_flow_effect(ControlGroup.Index.GROUP_1).set_rotation_effect().set_boost_offset_effect()
	

