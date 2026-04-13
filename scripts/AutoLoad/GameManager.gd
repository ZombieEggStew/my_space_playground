extends Node

var main_scene: Main
var player_instance: PlayerShip

func register_player(node: PlayerShip):
    player_instance = node

func register_world():
    pass
func register_hud():
    pass
func register_transition():
    pass
func init_main_menu():
    pass

func register_main_scene(node: Main):
    main_scene = node