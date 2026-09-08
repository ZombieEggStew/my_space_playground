extends Node3D
class_name ModulesManager

# basic modules
var movement_module: MoveControllerModule
var third_camera_module: ThirdCameraModule
var player_aim_module: BasicAimModule
var rader_module: RadarModule

func install_module(module_scene:PackedScene) -> Module:
	var module = module_scene.instantiate()

	if module is BasicAimModule:
		player_aim_module = module

	if module is RadarModule:
		rader_module = module

	add_child(module)
	return module

func install_module_3d(module_scene:PackedScene) -> Module3D:
	var module = module_scene.instantiate()

	if module is EngineModule:
		movement_module = module
	if module is ThirdCameraModule:
		third_camera_module = module

	add_child(module)
	return module

func get_camera_module() -> ThirdCameraModule:
	return third_camera_module

func get_aim_module() -> BasicAimModule:
	return player_aim_module

func get_move_module() -> EngineModule:
	return movement_module

func get_radar_module() -> RadarModule:
	return rader_module

## 卸载模块(幂等,§4.2-5):
## 1. 调模块的 on_uninstall() 钩子清理 reparent 出去的 2D 节点 / 手动断连
## 2. 清掉本管理器持有的槽位引用(置 null)
## 3. queue_free(模块 _exit_tree 再兜底一次 on_uninstall)
## 对已释放/不在树上的模块直接跳过,绝不硬崩。
func uninstall_module(module: Module) -> void:
	if module == null or not is_instance_valid(module):
		return
	if module.get_parent() != self:
		push_warning("ModulesManager.uninstall_module: %s 不是本管理器的直接子节点" % module.name)
	module.on_uninstall()
	if module == player_aim_module:
		player_aim_module = null
	if module == rader_module:
		rader_module = null
	module.queue_free()

## 卸载 3D 模块(幂等,语义同 uninstall_module)
func uninstall_module_3d(module: Module3D) -> void:
	if module == null or not is_instance_valid(module):
		return
	if module.get_parent() != self:
		push_warning("ModulesManager.uninstall_module_3d: %s 不是本管理器的直接子节点" % module.name)
	module.on_uninstall()
	if module == movement_module:
		movement_module = null
	if module == third_camera_module:
		third_camera_module = null
	module.queue_free()
