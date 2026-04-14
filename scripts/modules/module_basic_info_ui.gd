extends UIModule

@export var hp_bar: HPBar

@export var speed_label: Label


var screen_module: ScreenModule


func _ready() -> void:

	var hp_component = root.get_health_component() 
	
	hp_bar.setup(hp_component)

	GameManager.hud_manager.register_hud_group(hud_container).set_flow_effect().set_rotation_effect().set_boost_offset_effect()
	
func _process(_delta):
	_updata_speed_ui()	

 
func _updata_speed_ui() -> void:
	speed_label.text = root.get_speed_string()
