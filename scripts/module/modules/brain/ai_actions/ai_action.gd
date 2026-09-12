extends Node
class_name AIAction

## AI 行为基类(.memo/ai_rework_plan.md §4):每个行为一个子类,实现
## score()(Utility 打分)+ enter()/exit() + execute()(每帧执行)。
## 行为只描述"想干什么 + 参数",机动/射击经 ai.maneuvers / 共享模块命令完成,
## 不直接操作刚体。打分只读 perception 快照,不直接读场景节点。

var ai: AIModule


func setup(ai_mod: AIModule) -> void:
	ai = ai_mod


## Utility 打分:越高越倾向执行。只读 ctx(perception 快照)与 profile,不做副作用。
func score(_ctx: Dictionary, _profile: PilotProfile) -> float:
	return 0.0


## 被选为当前行为时调用(可重置计时器等)。
func enter() -> void:
	pass


## 让出当前行为时调用。
func exit() -> void:
	pass


## 每物理帧执行:输出归一化命令(经 ai.maneuvers / 模块 set_*),不直接改刚体。
func execute(_delta: float, _ctx: Dictionary) -> void:
	pass


# --- 公共辅助(所有行为共用) ---

## 目标"后背方向":有速度时 = 速度反方向(其运动轨迹后方),否则 = 目标 +Z 机体方向。
func _target_back_dir(target: Node3D) -> Vector3:
	var vel: Vector3 = _body_velocity(target)
	if vel.length() > 0.1:
		return -vel.normalized()
	return target.global_transform.basis.z.normalized()


## 读 CharacterBody3D 的 velocity;无则 ZERO。
func _body_velocity(body: Node3D) -> Vector3:
	if body == null:
		return Vector3.ZERO
	var v: Variant = body.get("velocity")
	if v is Vector3:
		return v
	return Vector3.ZERO


## 是否已处于目标 6 点钟锥内(机头大致对着目标运动轨迹后方)。
func _is_tail_aligned(ctx: Dictionary, cone_dot: float = 0.7) -> bool:
	var body: Node3D = ctx.get("nearest")
	if body == null:
		return false
	var root := ai.root
	var from_player := (root.global_position - body.global_position).normalized()
	return from_player.dot(_target_back_dir(body)) > cone_dot
