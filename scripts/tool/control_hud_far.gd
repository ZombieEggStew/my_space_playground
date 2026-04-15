extends Control

var hud : HUDFarManager

var _is_ready := false

func _ready():
	# GameManager.hud_manager.register_hud_far_2(self)
	pass

func setup() -> void:
	hud = get_parent()
	_is_ready = true


func _process(_delta: float) -> void:
	if not _is_ready:
		return
	# 绘制机头指示器
	if hud.is_on_screen:
		position = hud.nose_pos_2d - position
