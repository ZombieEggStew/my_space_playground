extends CharacterBody3D

var team_id := TeamID.ENEMY
@onready var health : HealthComponent = $HealthComponent
@onready var ai : AIBrain = $AI_Brain

## 敌人 AI 重做方案(Ph0,见 .memo/ai_rework_plan.md):接入共享模块系统。
## 先装纯感知/计算模块(radar 身体 + aim_mechanics)——不碰刚体/输入,旧 AI_Brain
## 行为完全不受影响;执行类模块(move/booster/laser)在 Ph1 随 AIModule 一起接入。
@export_group("modules")
@export var scene_module_radar: PackedScene
@export var scene_module_aim_mechanics: PackedScene
@export_group("")

@onready var modules_manager: ModulesManager = $ModulesManager

func _ready() -> void:
	health.on_death.connect(die)
	health.setup(team_id,1000, 1000)

	if scene_module_radar:
		modules_manager.install_module(scene_module_radar)
	if scene_module_aim_mechanics:
		modules_manager.install_module(scene_module_aim_mechanics)

func hit(damage: int) -> void:
	health.take_damage(damage)












# 对外接口-----------------------------------------------------------------
func get_health_component() -> HealthComponent:
	return health
	
func get_team_id() -> int:
	return team_id

func die() -> void:
	queue_free()
