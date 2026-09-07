extends Node


signal on_player_registered(player: PlayerShip)


signal on_player_shoot(enable: bool)

signal on_player_try_lock()

signal on_player_boost_input(enable: bool)

signal on_player_boost(enable:bool)

signal on_toggle_track_mouse(enable: bool)

signal on_player_look_backward(enable: bool)

signal on_player_look_around(enable: bool)


signal on_player_try_use_item_1()

signal on_toggle_engine()


signal on_player_lock_target(target: AbleToBeLocked)

signal on_lockable_target_spawned(target: AbleToBeLocked)

signal on_lockable_target_died(target: AbleToBeLocked)

## 目标 UI 悬停(由 TargetReticle 转发选择框事件,供瞄准模块判定悬停目标,P3)
signal on_target_hovered(target: AbleToBeLocked)

signal on_target_unhovered()



signal on_damage_dealt(amount: int, pos: Vector2)