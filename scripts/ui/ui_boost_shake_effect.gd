extends Node
class_name UIBoostShakeEffect

var shake_intensity := 2.0
var shake_speed := 20.0
var _groups: Array[Control] = []
# group -> 当前平滑后的抖动偏移。
# 不再直接累加到 position(会随机漂移且抢占其他特效),只写 meta 里的 hud_shake_offset 通道,
# 由 HUDManager 统一合成。
var _offsets: Dictionary = {}

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
	if group not in _groups:
		_groups.append(group)
	_offsets[group] = Vector2.ZERO
	if not group.has_meta("hud_shake_offset"):
		group.set_meta("hud_shake_offset", Vector2.ZERO)

func _process(_delta: float) -> void:
	_update_shake(_delta)

func _update_shake(_delta: float) -> void:
	for group in _groups:
		if not is_instance_valid(group):
			_offsets.erase(group)
			continue

		var target_offset := Vector2.ZERO
		if _is_boosting:
			target_offset = Vector2(
				randf_range(-shake_intensity, shake_intensity),
				randf_range(-shake_intensity, shake_intensity)
			)

		# 平滑插值到目标抖动偏移(boost 时抖动,平时归零),不再累加造成随机漂移
		var current: Vector2 = _offsets.get(group, Vector2.ZERO)
		_offsets[group] = current.lerp(target_offset, _delta * shake_speed)
		group.set_meta("hud_shake_offset", _offsets[group])
