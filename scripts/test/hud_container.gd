# HUD_PitchLadder.gd
extends Control

var aircraft: PlayerShip # 引用你的飞机节点
var screen_center: Vector2
var pixels_per_degree = 10.0 # 每一度在屏幕上占多少像素

func _ready():
	SignalBus.on_player_registered.connect(_on_player_registered)

func _on_player_registered(player:PlayerShip) -> void:
	aircraft = player

func _process(_delta):
	queue_redraw() # 每一帧重新绘制

func _draw():
	if not aircraft: return
	
	screen_center = get_viewport_rect().size / 2
	var _rotation = aircraft.global_transform.basis.get_euler()
	var pitch = rad_to_deg(_rotation.x)
	var roll = _rotation.z # 弧度制用于旋转绘图上下文

	# 1. 平移和旋转绘图上下文
	draw_set_transform(screen_center, -roll, Vector2.ONE)

	# 2. 绘制俯仰刻度线（例如每5度画一根线）
	for i in range(-18, 19): # -90度到90度
		var angle = i * 5
		var y_pos = (angle - pitch) * pixels_per_degree
		
		# 只绘制屏幕可见范围内的线
		if abs(y_pos) < 300:
			var line_width = 100 if i % 2 == 0 else 50
			draw_line(Vector2(-line_width, y_pos), Vector2(line_width, y_pos), Color.GREEN, 2.0)
			draw_string(ThemeDB.fallback_font, Vector2(line_width + 5, y_pos + 5), str(angle), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.GREEN)