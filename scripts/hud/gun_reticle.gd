extends HUDFarBase
class_name HUD_GunReticle
## 绿色机炮十字准心(准心3):指示开火(子弹)瞄准方向,限制在机头 deadzone 圆周内。
##
## 鼠标在 deadzone 内 → 跟随鼠标;移出圆周 → 卡在圆周边缘;为瞄准系统提供屏幕瞄准点。
## 大小固定。
##
## 职责边界:
## - 数据来源:[code]HUDFarManager.nose_pos_2d[/code] / [code]mouse_pos[/code] / [code]is_on_screen[/code]。
## - 对外接口:[method setup]、[method set_target_pos]。
## - 注册方式:由 [code]LaserGunHudSystem[/code] 经 [code]HUDManager.register_hud[/code] 注册,
##   归属继承自 [code]HUDFarBase[/code] 的 [member hud_slot](FAR),自动挂到远层。
## - 坐标约定:父节点 hud_far_manager 定位到机头投影,本元素 position 为机头局部坐标,
##   消费方需 + hud.position 转回视口坐标。


@export var half_size := 32.0
@export var line_width := 2.0
@export var line_color := Color(0.2, 1.0, 0.2, 0.95)


var _line_h: Line2D
var _line_v: Line2D

var aim_dead_zone_px := 64.0

func _ready() -> void:
	_line_h = _create_line()
	_line_v = _create_line()
	_update_lines()
	reset()
	
func _process(_delta):
	update_from_center(hud.nose_pos_2d, hud.mouse_pos, hud.is_on_screen)

func setup(dead_zone:float) -> void:
	aim_dead_zone_px = dead_zone

func _create_line() -> Line2D:
	var line := Line2D.new()
	line.width = line_width
	line.default_color = line_color
	line.antialiased = true
	line.z_index = 10
	line.points = PackedVector2Array([Vector2.ZERO, Vector2.ZERO])
	add_child(line)
	return line



func _update_lines() -> void:
	if _line_h == null or _line_v == null:
		return
	_line_h.points = PackedVector2Array([
		Vector2(-half_size, 0.0),
		Vector2(half_size, 0.0)
	])
	_line_v.points = PackedVector2Array([
		Vector2(0.0, -half_size),
		Vector2(0.0, half_size)
	])


func set_target_pos(target_pos: Vector2) -> void:
	# hud_far_manager 自身定位到机头投影,子元素处于"机头局部"坐标系。
	# 传入的 target_pos 是视口全局坐标,需减去机头偏移作为局部 position。
	position = target_pos - hud.position
	visible = true


func update_from_center(center: Vector2, mouse_pos: Vector2, is_center_on_screen: bool = true) -> void:
	if not is_center_on_screen:
		visible = false
		return
	
	visible = true
	var to_mouse := mouse_pos - center
	var radius := max(aim_dead_zone_px, 0.0) as float

	if to_mouse.length() <= radius:
		set_target_pos(mouse_pos)
		return

	var dir := to_mouse.normalized()
	var clamped_pos := center + dir * radius
	set_target_pos(clamped_pos)


func reset() -> void:
	position = get_viewport().get_visible_rect().size / 2.0 - hud.position
	visible = true
