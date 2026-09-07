extends Node2D
class_name HUD_LeadIndicator
## 绿色预测射击点圆环(准心4):指示预测射击命中点(对移动目标的提前量)。
##
## 圆环大小随与目标的距离变化(越近越大、越远越小,有下限)。
##
## 职责边界:
## - 数据来源:由 [code]PredictAimModule[/code](module_predict_aim) 每帧传入 aim_data 驱动。
## - 对外接口:[method set_target_pos]、[method reset]。
##   aim_data 键:[code]screen_pos: Vector2[/code]、[code]distance: float[/code] 等。
## - 注册方式:由 [code]HUDManager.register_hud[/code] 读取本脚本的
##   [member hud_slot](STATIC)自动挂到静态层。
## - 注意:目前经 [code].call("set_target_pos", aim_data)[/code] + Dictionary 鸭子类型驱动,
##   建议后续统一为类型化接口(见 .memo/.CURRENT.md §5)。

## HUD 归属:静态层(由 HUDManager.register_hud 读取)
@export var hud_slot: HudElement.Slot = HudElement.Slot.STATIC

@export var circle_diameter := 16.0
@export var line_width := 2.0
@export var circle_color := Color(0.2, 1.0, 0.2, .5)

var distance_to_target := 0.0

func _ready() -> void:
	visible = false
	queue_redraw()


func _draw() -> void:
	var radius := get_radius_for_distance(distance_to_target)
	# print("drawing crosshair at distance: ", distance_to_target)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 32, circle_color, line_width, true)

# 根据采样数据进行曲线拟合或插值
# 100m -> 48px
# 200m -> 16px
# 600m -> 12px
func get_radius_for_distance(dist: float) -> float:
	if dist <= 100:
		return 48.0
	elif dist <= 200:
		# 在 100m 和 200m 之间线性插值 (48 -> 16)
		return remap(dist, 100, 200, 48, 16)
	elif dist <= 600:
		# 在 200m 和 600m 之间线性插值 (16 -> 12)
		return remap(dist, 200, 600, 16, 12)
	else:
		# 远于 600m 保持最小半径
		return 12.0

# y = -0.072 x + 55
func set_target_pos(aim_data : Dictionary) -> void:
	
	position = aim_data.get("screen_pos", Vector2.ZERO)
	distance_to_target = aim_data.get("distance", 0.0)
	visible = true
	queue_redraw()	

func reset() -> void:
	visible = false


