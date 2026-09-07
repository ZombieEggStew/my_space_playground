extends CharacterBody3D
class_name PlayerShip

var team_id := TeamID.PLAYER

# --- Component references ---
var cam_main: Camera3D
var cam_main_pivot: Node3D
var cam_pivot: Node3D



@export var model_node: Node3D	

@onready var health : HealthComponent = $HealthComponent

@onready var move_component : MoveComponent = $MoveComponent

@onready var attachment_manager : AttachmentManager = $AttachmentManager
var fov_smooth := 8.0         # FOV 平滑插值速度


@onready var modules_manager: ModulesManager = $ModulesManager

func _ready() -> void:
	
	health.setup(team_id,100, 100)
	health.on_death.connect(die)
	var engine_module =  modules_manager.install_module_3d(Scenes.module_move_controller_scene) as EngineModule
	engine_module.install_booster_module(Scenes.module_booster_scene)

	
	modules_manager.install_module_3d(Scenes.module_third_camera_scene)


	# modules_manager.install_module(Scenes.module_screen_scene)

	modules_manager.install_module(Scenes.module_radar_scene)
	modules_manager.install_module(Scenes.module_basic_info_ui_scene)
	modules_manager.install_module(Scenes.module_player_aim_scene)
	modules_manager.install_module(Scenes.test_module_scene)

	var laser := modules_manager.install_module_3d(Scenes.module_laser_gun_scene)
	var laser_predict := modules_manager.install_module(Scenes.module_predict_aim_scene)
	laser_predict.init_module(laser)

	attachment_manager.attach_to(Slot.SLOT_1, Scenes.attachment_missile_launcher_scene)

	GameManager.register_player(self)


func take_damage(damage: int) -> void:
	health.take_damage(damage)

func get_main_camera() -> Camera3D:
	return modules_manager.get_camera_module().get_main_camera()

func get_model_node() -> Node3D:
	return model_node

func get_health_component() -> HealthComponent:
	return health

func get_speed_string() -> String:
	return "%.2f" % velocity.length()

func get_speed_magnitude() -> String:
	return "%.2f" % velocity.dot(-global_transform.basis.z.normalized())

func hit(damage: int) -> void:
	health.take_damage(damage)

func get_module_manager() -> ModulesManager:
	return modules_manager

func get_team_id() -> int:
	return team_id

func die() -> void:
	pass

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == Key.KEY_O:
		health.take_damage(10)
	if event is InputEventKey and event.pressed and event.keycode == Key.KEY_P:
		BuffManager.apply_buff_by_name(self, self, "healing_1")




	
