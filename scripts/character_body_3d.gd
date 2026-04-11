#TO DO : 玩家未锁定射击扩散逐渐变大，加入过热机制
#TO DO : 玩家鼠标跟踪目标一定时间后锁定目标，获取目标信息（血量，速度），并且可以根据目标速度预判射击
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
#TO DO : 解决摄像机中心与弹道不一致问题
#TO DO : 锁定敌人UI显示，锁定前？？？ 锁定后绿色方框大小随距离变化，并且显示敌人基本信息
#TO DO : 玩家转向减速，掉头速度归零
#TO DO : 添加雷达扫描机制，扫描过后获取附近敌人位置，一级锁定
#TO DO : 叶绿弹：使用奇特的绿色矿石制成的子弹，具有跟踪效果
#TO DO : 子弹 实例池
#TO DO : 瞄准 线性43（能自定义）
#TO DO : 关卡设计 极简主义 镜之边缘
#TO DO : 根据锁定目标的远近 修改子弹的留存时间
#TO DO : 加速视角抖动
#TO DO :
#TO DO : 地平线指示器？
#TO DO :
#TO DO : 锁定设计：锁定后出现预测射击指示器，屏幕边缘显示相对位置：1级：手动锁定；2级：自动锁定，最大锁定目标为1；3-级：自动锁定，最大锁定目标为多个
#TO DO :
#TO DO :
#TO DO : 受击ui效果，转向ui效果,ui扫描码效果
#TO DO :
#TO DO :
#TO DO : 连续开火散布增大
#TO DO : 武器跟踪鼠标：考虑炮管转速
#TO DO : 发射导弹后坐力
#TO DO :
#TO DO : 异步联机设计，玩家死后或者通关过后可以”同意捐献“自己的载具，其他玩家可以回收或者收到捐献的载具，增加玩家之间的互动，凉宫春日：johnSmith我就在这里
#TO DO : 没有意义就是最大的意义 朝圣
#TO DO : 对大他者的反抗，但是越是反抗，就越是证明了大他者的存在




#FIX ME :
#FIX ME :
#FIX ME :
#FIX ME :
#FIX ME :
#FIX ME :
#FIX ME :
#FIX ME :
#FIX ME :
#FIX ME :
#FIX ME :
#FIX ME :
extends CharacterBody3D

signal health_changed(new_health: float)

@export var team_id := 1

# --- Component references ---
@export var cam_main: Camera3D
@export var cam_main_pivot: Node3D


@export var particle_speed_up: GPUParticles3D


@export var cam_spring_arm: SpringArm3D 
@export var cam_pivot: Node3D
@export var model_node: Node3D	


var default_health := 100.0
var health_stat := FloatStat.new(default_health,default_health)




var fov_smooth := 8.0         # FOV 平滑插值速度


@export var gun_pivot_left : Node3D



@export var modules_manager: ModulesManager

func _ready() -> void:
	cam_main.current = true
	modules_manager.install_module(Scenes.module_move_controller_scene)
	modules_manager.install_module(Scenes.module_third_camera_scene)
	modules_manager.install_module(Scenes.module_player_aim_scene)
	modules_manager.install_module(Scenes.basic_info_ui_scene)
	modules_manager.install_module(Scenes.test_module_scene)

	var laser := modules_manager.install_module(Scenes.module_laser_gun_scene)
	var laser_predict := modules_manager.install_module(Scenes.module_predict_aim_scene)
	laser_predict.init_module(laser)

func get_gun_pivot_left() -> Node:
	return gun_pivot_left

func get_cam_pivot() -> Node3D:
	return cam_pivot

func get_cam_spring_arm() -> SpringArm3D:
	return cam_spring_arm

func get_main_camera() -> Camera3D:
	return cam_main

func get_boost_particle() -> GPUParticles3D:
	return particle_speed_up

func get_model_node() -> Node3D:
	return model_node

func get_health_stat() -> FloatStat:
	return health_stat

func get_speed_string() -> String:
	return "%.2f" % velocity.length()
# func _extract_enemy_nodes() -> Array[Node3D]:
# 	var result: Array[Node3D] = []

# 	for node in enemies_parent.get_children():
# 		if node == self:
# 			continue
# 		if node.has_method("get_team_id") and node.call("get_team_id") != team_id:
# 			result.append(node)

# 	return result



func get_hit(damage: float) -> void:
	if health_stat.value - damage <= 0:
		health_stat.value = 0

	else:

		health_stat.value -= damage


func get_team_id() -> int:
	return team_id






	
