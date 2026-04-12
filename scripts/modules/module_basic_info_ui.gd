extends UIModule

@export var hp_bar: HPBar

@export var speed_label: Label


var screen_module: ScreenModule



func _ready() -> void:

	var hp_component = root.get_health_component() 
	
	hp_bar.setup(hp_component)

	screen_module = root.modules_manager.get_screen_module()
	if not screen_module:
		log_missing_component("ScreenModule")
		queue_free()

func _process(_delta):
	_updata_speed_ui()	

 
func _updata_speed_ui() -> void:
	speed_label.text = root.get_speed_string()
