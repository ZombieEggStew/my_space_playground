#TO DO : 玩家未锁定射击扩散逐渐变大，加入过热机制
#TO DO : 
#TO DO : 加入新种类敌人：参考无人深空空战

#TO DO : 向右移动，中心参考圆UI，中心，向右移动,且固定
#TO DO : 玩家机体占据左边屏幕，且固定
#TO DO : 鼠标准心旁设置ui，显示当前锁定目标的血量，距离，速度等信息
#TO DO : 上移屏幕中心UI
#TO DO : 改变机械臂IK模式
#TO DO : 优化移动手感：加速模拟指数函数加速度逐渐加快，减速减速度逐渐减慢
#TO DO : 游戏声音 BV1JXZ1Y7ETL
#TO DO : 集群算法设计集群敌人 BV1XgM1zQEF5
#TO DO : godot字体动态效果 BV1ruqUBwEA6
#TO DO : 预警机 自动扫描 锁定敌人
#TO DO : 
#TO DO : 
#TO DO : 玩家转向减速，掉头速度归零
#TO DO : 添加雷达扫描机制，扫描过后获取附近敌人位置，一级锁定
#TO DO : 叶绿弹：使用奇特的绿色矿石制成的子弹，具有跟踪效果
#TO DO : 子弹 实例池
#TO DO : 瞄准 线性43（能自定义）
#TO DO : 关卡设计 极简主义 镜之边缘
#TO DO : 根据锁定目标的远近 修改子弹的留存时间
#TO DO : 
#TO DO :取消设计：BV1fUDQBMEgp
#TO DO :
#TO DO :速度矢量球 (Flight Path Marker / FPM):用 camera.unproject_position(aircraft.global_position + velocity) 将空间向量投射到屏幕坐标。
#TO DO :抖动 (Jitter)：在高速或大过载时，通过代码给 HUD 节点增加微小的随机位移。
#TO DO :伤害数字 根据伤害类型（如暴击、治疗、扣血）在 _show_damage_number 中设置不同的 font_color。
#TO DO :注册到hud_far的组件更加清晰，弄清楚为什么
#TO DO : 地平线指示器？
#TO DO : “以太阻力”与速度上限 (Etheric Drag / Speed Cap):虚构一种空间背景能量（如“以太”或“零点场”），飞船引擎必须消耗能量来对抗这种阻力。速度越快，阻力指数级增加。引入“超载冲刺（Overdrive）”。玩家或 AI 可以短时间突破速度上限，但代价是散热系统瘫痪或护盾暂时关闭。这创造了一个“高风险高收益”的切入机会。
#TO DO : 拾取音效：清脆
#TO DO : 锁定的目标添加高亮描边
#TO DO : 锁定设计：锁定后出现预测射击指示器，屏幕边缘显示相对位置：1级：手动锁定；2级：自动锁定，最大锁定目标为1；3-级：自动锁定，最大锁定目标为多个
#TO DO : 小地图（雷达）（黄牌空战7）,将可锁定敌人的3d坐标投射到玩家X-Z平面上，显示在小地图上
#TO DO : 
#TO DO : buff显示-hud
#TO DO : 优化crosshair2的逻辑，移动逻辑放在自身脚本里
#TO DO : 类无助之地描边效果
#TO DO : 受击ui效果，转向ui效果,ui扫描码效果
#TO DO : UI参考天国拯救，死亡空间 ， 全境封锁BV1MddhBrEqq
#TO DO : 冲刺：尾气
#TO DO :  “重力井”利用 (Gravity Slingshot):利用大型天体的引力进行“引力弹弓”加速，在不消耗燃料的情况下瞬间改变航向。
#TO DO : 道具:能在过热的时候进行特殊射击，特殊射击消耗热量值，但是普通射击dps降低
#TO DO :
#TO DO :“惯性弹道”。可以将飞船加速到极快，然后关闭引擎，此时飞船本身就是一个巨大的动能抛射体。
#TO DO :
#TO DO :
#TO DO : 敌人咬尾时使用PID控制器来调整速度和转向，以保持在玩家的后方。
#TO DO :
#TO DO :
#TO DO :
#TO DO : laser_gun: hud显示，timer与过热值，准星左半圆
#TO DO : 音乐风格：蒸汽波 ，迈阿密， 机核
#TO DO : 武器跟踪鼠标：考虑炮管转速
#TO DO : 发射导弹:在发射主动雷达制导导弹（如AIM-120）时，较高的初速可以赋予导弹更远的射程和更大的“不可逃逸区”（NEZ）。
#TO DO : 护盾被只有被击中的地方才显示
#TO DO : 异步联机设计，玩家死后或者通关过后可以”同意捐献“自己的载具，其他玩家可以回收或者收到捐献的载具，增加玩家之间的互动，凉宫春日：johnSmith我就在这里
#TO DO : 没有意义就是最大的意义 朝圣
#TO DO : 对大他者的反抗，但是越是反抗，就越是证明了大他者的存在




#FIX ME : 不同分辨率下各个准心大小问题
#FIX ME : 处理镜头穿模
#FIX ME : springarm逻辑
#FIX ME : 预测射击近距离失效
#FIX ME : player的rotation换成basis
#FIX ME :
#FIX ME :
#FIX ME :
#FIX ME :
#FIX ME :
#FIX ME :
#FIX ME :
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




	
