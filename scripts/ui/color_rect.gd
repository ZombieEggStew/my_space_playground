extends ColorRect

@export var viewport : SubViewport

func _ready():
	# 找到你的 SubViewport 节点（根据你的实际路径修改）
	
	# 等一帧确保 Viewport 已经初始化
	await get_tree().process_frame
	
	# 获取 Viewport 的纹理并传给 Shader 中的变量
	var tex = viewport.get_texture()
	material.set_shader_parameter("ui_viewport_texture", tex)