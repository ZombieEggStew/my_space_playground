extends Node2D
class_name HudElement

## HUD 元件基类(统一接口,见 .memo/.CURRENT.md §5):声明归属枚举,并提供类型化元素接口。
##
## 归属:元素各自在脚本里 `@export var hud_slot: HudElement.Slot` 自声明(§5 机制),
## 由 [method HUDManager.register_hud] 读取决定挂载层;本基类不声明该成员(GDScript 禁止子类
## 重声明继承成员,故归属值放在各元素脚本上,枚举统一引用本类)。
## 类型化接口:[method set_target_pos] / [method reset] 是准星类元件的虚方法,
## 消费方用具体 class_name(如 [code]HUD_LockReticle[/code])静态调用,不再 `.call()` + Dictionary 鸭子类型。
##
## 注意:register_hud 的返回句柄是 [code]HudHandle[/code](RefCounted),不是本类;
## 本类是场景里准星/指示器元件的共同基类。Node 根元素的继承统一(准心1/2/血条)属 P5 清理,暂不并入。

enum Slot {
	STATIC,  ## 静态层 hud_static:普通 UI,不跟随世界(准星、目标框、血条等)
	FAR,     ## 远层 hud_far_manager:跟随机头投影的远 HUD(机炮十字、死区圈、热量条)
	GROUP,   ## 动态组 hud_container:可挂特效(视差/旋转/加速)的 UI 组
}

## 设置目标屏幕位置(视口坐标)。准星类元件子类应覆写。
func set_target_pos(_pos: Vector2) -> void:
	pass

## 复位(隐藏/回到默认位置)。准星类元件子类应覆写。
func reset() -> void:
	pass
