extends HudElement
class_name HUD_LeadIndicator
## 绿色预测射击点圆环(准心4):指示预测射击命中点(对移动目标的提前量)。
##
## 圆环大小随与目标的距离变化(越近越大、越远越小,有下限)。
##
## 职责边界:
## - 数据来源:由 [code]AimView[/code](aim_view,归 selection;预测点由 AimMechanicsModule 计算)
##   每帧传入 [method set_target_pos](视口坐标) + [method set_target_distance] 驱动。
## - 对外接口:[method set_target_pos]、[method set_target_distance]、[method reset](继承自基类)。
## - 注册方式:由 [code]HUDManager.register_hud[/code] 读取本元素的
##   [member hud_slot](继承基类默认 STATIC)自动挂到静态层。
## - HUD 归属:STATIC(本脚本自声明,枚举来自 [code]HudElement[/code] 基类)。

## HUD 归属:静态层(由 HUDManager.register_hud 读取)
@export var hud_slot: HudElement.Slot = HudElement.Slot.STATIC

## 与目标的距离(用于计算圆环半径)
var distance_to_target := 0.0

@export var circle_diameter := 16.0
@export var line_width := 2.0
@export var circle_color := Color(0.2, 1.0, 0.2, .5)

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

## 设置预测点的屏幕位置(视口坐标)并显示。
func set_target_pos(pos: Vector2) -> void:
	position = pos
	visible = true
	queue_redraw()

## 设置到目标的距离(决定圆环半径)。
func set_target_distance(dist: float) -> void:
	distance_to_target = dist
	queue_redraw()

func reset() -> void:
	visible = false


