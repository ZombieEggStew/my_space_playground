extends CharacterBody3D

var team_id := TeamID.ENEMY
@onready var health : HealthComponent = $HealthComponent

## ② 飞船级总线(与玩家船一致:ModulesManager 注入经 root.get("ship_bus") duck typing,
## 见 .memo/ai_rework_plan.md Ph2 实测修复——缺此属性 booster.set_boosting 时
## ship_bus 为 null,on_player_boost.emit 崩溃)。
@onready var ship_bus: ShipBus = $ShipBus

## 敌人 AI 重做方案(.memo/ai_rework_plan.md):
## Ph0 接入模块系统(radar 身体 + aim_mechanics,旧 AI 行为不变);
## Ph1 装齐执行类模块(move/laser)+ AIModule 大脑,旧 AI_Brain 退役
## (场景不再挂 AI_Brain 节点;scripts/ai/ 遗留待 Ph4 整体删除)。
## 敌我复用同一份共享模块(决策 #10/#14),AI 只输出归一化命令。
@export_group("modules")
@export var scene_module_move: PackedScene
@export var scene_module_booster: PackedScene
@export var scene_module_radar: PackedScene
@export var scene_module_aim_mechanics: PackedScene
@export var scene_module_laser: PackedScene
@export var scene_module_ai: PackedScene
@export_group("")

@onready var modules_manager: ModulesManager = $ModulesManager

func _ready() -> void:
	health.on_death.connect(die)
	health.setup(team_id, 1000, 1000)

	# 安装顺序:执行器(move)→ 感知/计算(radar/aim_mechanics)→ 武器(laser)→ 大脑(AIModule 最后)
	if scene_module_move:
		var engine_mod: EngineModule = modules_manager.install_module(scene_module_move) as EngineModule
		if scene_module_booster:
			engine_mod.install_booster_module(scene_module_booster)
	if scene_module_radar:
		modules_manager.install_module(scene_module_radar)
	if scene_module_aim_mechanics:
		modules_manager.install_module(scene_module_aim_mechanics)
	if scene_module_laser:
		modules_manager.install_module(scene_module_laser)
	if scene_module_ai:
		modules_manager.install_module(scene_module_ai)

func hit(damage: int) -> void:
	health.take_damage(damage)

## move 模块所需:视觉根(粒子/倾斜用;决策 #13 后 move 是纯执行器,只读 model_node)
func get_model_node() -> Node3D:
	return $space_craft_5

func get_health_component() -> HealthComponent:
	return health

func get_team_id() -> int:
	return team_id

func die() -> void:
	queue_free()
