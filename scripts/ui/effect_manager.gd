extends Node

var is_boosting : = false

func _ready() -> void:
	SignalBus.on_player_boost.connect(_on_player_boost)

func _on_player_boost(enable:bool) -> void:
	is_boosting = enable