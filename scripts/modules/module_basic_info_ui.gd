extends UIModule

@export var hp_label: Label
@export var hp_bar: TextureProgressBar

@export var speed_label: Label


var screen_module: ScreenModule

var my_hp_ref: FloatStat



func _enter_tree() -> void:
	super._enter_tree()

	print("Basic info UI module entered tree")


func _ready() -> void:

	my_hp_ref = root.get_health_stat() 
	
	# 依然建议连接信号以更新显示，否则你需要每帧去读 my_hp_ref.value
	my_hp_ref.changed.connect(_update_hp_ui)
	_update_hp_ui(my_hp_ref.value)

	screen_module = root.modules_manager.get_screen_module()
	if not screen_module:
		log_missing_component()
		queue_free()

func _process(_delta):
	_updata_speed_ui()	


func _update_hp_ui(val: float) -> void:
	hp_label.text = "%s/%s" % [val, my_hp_ref.max_value]
	hp_bar.value = val / my_hp_ref.max_value * 100.0

 
func _updata_speed_ui() -> void:
	speed_label.text = root.get_speed_string()
