extends Node
class_name UIBoostOffsetEffect



# Boost 时的 UI 扩散强度
var boost_offset_intensity = 100.0

var smooth : float = 8.0


var groups: Array[Control] = []

# boost 状态:经 on_player_registered 连玩家船 ShipBus(②),不再读全局/父节点
var _is_boosting := false

func _ready() -> void:
	SignalBus.on_player_registered.connect(_on_player_registered)

func _on_player_registered(player: PlayerShip) -> void:
	if player and player.ship_bus:
		if not player.ship_bus.on_player_boost.is_connected(_on_player_boost):
			player.ship_bus.on_player_boost.connect(_on_player_boost)

func _on_player_boost(enable: bool) -> void:
	_is_boosting = enable

func setup(group: Control) -> void:
	for child in group.get_children():
		# 记录原始位置，用于 Boost 效果恢复
		child.set_meta("original_pos", child.position)
	if group not in groups:
		groups.append(group)

func _process(delta):

	_update_boost_effect(delta)

func _update_boost_effect(delta: float) -> void:
	# 遍历所有 UI 子节点;组已释放则反注册,避免 "previously freed"(与 flow/shake 防护一致)
	var i := 0
	while i < groups.size():
		var group: Control = groups[i]
		if not is_instance_valid(group):
			groups.remove_at(i)
			continue
		for ui_element in group.get_children():
			if not is_instance_valid(ui_element):
				continue

			# 计算目标 Boost 偏移量
			var target_boost_pos = Vector2.ZERO

			if _is_boosting:
				smooth = 8.0
				# 核心逻辑：根据自身的旋转角度（弧度）向“前方”偏移
				# 这里假设 rotation 指向的是 UI 的发散方向
				var angle = ui_element.rotation
				var boost_dir = Vector2(cos(angle), sin(angle)).normalized()

				# 为了让上下两排 UI 向屏幕边缘张开，这里需要根据其位置调整方向
				# 如果已经在 rotation 逻辑中计算好了方向，可以直接使用
				target_boost_pos = boost_dir * boost_offset_intensity
			else:
				smooth = 2.0

			# 平滑插值应用偏移 (注意：这里修改的是节点的 position 偏移)
			if ui_element.has_meta("original_pos"):
				var base_pos = ui_element.get_meta("original_pos")
				ui_element.position = ui_element.position.lerp(base_pos + target_boost_pos, delta * smooth)
		i += 1



