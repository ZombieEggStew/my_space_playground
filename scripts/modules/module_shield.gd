extends Module
class_name ShieldModule

var team_id := TeamID.TEAM_NEUTRAL
@export var mesh : MeshInstance3D
var active_alpha := 0.0

var tween: Tween

var shield_value := 0:
	set(v):
		shield_value = v
		if ui_container != null:
			ui_container.update_shield_value(shield_value, max_shield_value)
			

var max_shield_value := 100 :
	set(v):
		max_shield_value = v
		if ui_container != null:
			ui_container.update_shield_value(shield_value, max_shield_value)

var shield_regen_rate := 5  # 每秒恢复的护盾强度
var is_shield_active := true

@export var ui_container: ShieldUIContainer

func _ready():
	team_id = root.get_team_id()
	shield_value = max_shield_value
	active_alpha = mesh.material_override.get("albedo_color").a
	# 初始化为透明
	var color = mesh.material_override.get("albedo_color")
	color.a = 0.0
	mesh.material_override.set("albedo_color", color)


func get_team_id() -> int:
	return team_id

func take_damage(amount: int) -> void:
	if not is_shield_active:
		return
	
	# 处理显示逻辑
	if tween:
		tween.kill()
	
	# 瞬间显示
	var color = mesh.material_override.get("albedo_color")
	color.a = active_alpha
	mesh.material_override.set("albedo_color", color)
	
	# 创建新的逐渐隐藏动画
	tween = create_tween()
	# 停留 0.5 秒后开始淡出，淡出持续 1.0 秒
	tween.tween_interval(0.5)
	tween.tween_property(mesh.material_override, "albedo_color:a", 0.0, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	shield_value -= amount
	if shield_value < 0:
		shield_value = 0
		is_shield_active = false
