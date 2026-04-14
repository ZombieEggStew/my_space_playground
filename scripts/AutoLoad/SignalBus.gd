extends Node


signal on_player_registered(player: PlayerShip)


signal on_player_shoot(enable: bool)

signal on_player_try_lock()

signal on_player_boost_input(enable: bool)

signal on_player_boost(enable:bool)

signal on_track_mouse_change(enable: bool)

signal on_player_look_backward(enable: bool)

signal on_player_look_around(enable: bool)




signal on_player_lock_target(target: AbleToBeLocked)

signal on_lockable_target_spawned(target: AbleToBeLocked)

signal on_lockable_target_died(target: AbleToBeLocked)



