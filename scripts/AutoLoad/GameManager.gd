extends Node

var main_scene: Main
var player_instance: PlayerShip
var hud_manager: HUDManager
var ui_manager: UIManager

func register_player(node: PlayerShip):
    player_instance = node

func register_world():
    pass
func register_hud_manager(node: HUDManager):
    print("GameManager: HUD Manager registered.")
    hud_manager = node

func register_ui_manager(node: UIManager):
    ui_manager = node
func register_transition():
    pass
func init_main_menu():
    pass

func register_main_scene(node: Main):
    main_scene = node