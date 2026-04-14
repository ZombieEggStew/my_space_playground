extends Node

var main_scene: Main
var player_instance: PlayerShip
var hud_manager: HUDManager
var ui_manager: UIManager
var audio_manager: AudioManager
var input_manager : InputManager


func init_main_menu():
    pass

    

func register_player(node: PlayerShip):
    player_instance = node
    SignalBus.on_player_registered.emit(node)

func register_world():
    pass
func register_hud_manager(node: HUDManager):
    print("GameManager: HUD Manager registered.")
    hud_manager = node

func register_ui_manager(node: UIManager):
    ui_manager = node
func register_transition():
    pass

func get_current_player() -> PlayerShip:
    return player_instance

func register_input_manager(node: InputManager):
    input_manager = node

func register_audio_manager(node: AudioManager):
    audio_manager = node

func register_main_scene(node: Main):
    main_scene = node