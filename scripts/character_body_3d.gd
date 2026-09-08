extends CharacterBody3D
class_name PlayerShip

var team_id := TeamID.PLAYER

# --- 可观察数值(Stat 桥接,见 .memo/.CURRENT.md P2) ---
## 速度大小(每物理帧更新;UI 经 value_changed 订阅,不再每帧轮询 get_speed_string)
var speed_stat := FloatStat.new(0.0, INF)
## 前进分量速度(带符号,沿机体 -Z 投影)
var forward_speed_stat := FloatStat.new(0.0, INF)

# --- Component references ---
var cam_main: Camera3D
var cam_main_pivot: Node3D
var cam_pivot: Node3D

@export_group("test")
@export var scene_module_move_controller:PackedScene
@export var scene_module_third_camera:PackedScene
@export var scene_module_aim_mechanics:PackedScene
@export var scene_module_target_selection:PackedScene
@export var scene_module_basic_info_ui:PackedScene
@export var scene_module_booster:PackedScene
@export var scene_module_radar:PackedScene
@export var scene_module_laser_gun:PackedScene
@export var scene_module_missile_launcher:PackedScene
@export var scene_module_control:PackedScene

@export_group("")
@export var model_node: Node3D	

@onready var health : HealthComponent = $HealthComponent
@onready var move_component : MoveComponent = $MoveComponent
@onready var attachment_manager : AttachmentManager = $AttachmentManager

var fov_smooth := 8.0         # FOV 平滑插值速度


@onready var modules_manager: ModulesManager = $ModulesManager

## ② 飞船级事件总线(见 .memo/.CURRENT.md §2.2);模块经 ModulesManager 注入,
## 船外节点(InputManager/HUD 特效)经 on_player_registered 取此引用。
@onready var ship_bus: ShipBus = $ShipBus

func _ready() -> void:
	
	health.setup(team_id,100, 100)
	health.on_death.connect(die)
	var engine_module =  modules_manager.install_module(scene_module_move_controller) as EngineModule
	engine_module.install_booster_module(scene_module_booster)

	
	modules_manager.install_module(scene_module_third_camera)

	modules_manager.install_module(scene_module_radar)
	modules_manager.install_module(scene_module_basic_info_ui)
	# P5(决策 #11/#20):aim 拆两层 —— mechanics(共享预测力学)先装,selection(大脑侧)后装;
	# 独立 predict 模块已删,预测并入 aim_mechanics + aim_view。
	modules_manager.install_module(scene_module_aim_mechanics)
	modules_manager.install_module(scene_module_target_selection)

	var laser := modules_manager.install_module(scene_module_laser_gun)

	# P3:玩家大脑(键鼠 → 归一化命令);依赖 move/booster/laser,须在其后安装
	modules_manager.install_module(scene_module_control)

	attachment_manager.attach_to(Slot.SLOT_1, scene_module_missile_launcher)

	GameManager.register_player(self)


func take_damage(damage: int) -> void:
	health.take_damage(damage)

func get_main_camera() -> Camera3D:
	return modules_manager.get_camera_module().get_main_camera()

func get_model_node() -> Node3D:
	return model_node

func get_health_component() -> HealthComponent:
	return health

# 每物理帧把速度发布到 Stat(单写者);仅变化时赋值,避免信号空发
func _physics_process(_delta: float) -> void:
	var s := velocity.length()
	if speed_stat.value != s:
		speed_stat.value = s
	var fs := velocity.dot(-global_transform.basis.z.normalized())
	if forward_speed_stat.value != fs:
		forward_speed_stat.value = fs

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




	
