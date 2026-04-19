extends State
class_name StateDisengage

# 脱离状态：在对冲或拦截即将撞击时进行避让，并利用惯性拉开距离
@export var safe_distance := 300.0
@export var disengage_duration := 2.0

var timer := 0.0
var escape_dir := Vector3.ZERO

func enter(_prev: int = MoveSM.ORBIT) -> void:
    super.enter(_prev)
    timer = disengage_duration
    
    # 计算避让方向：基于当前与玩家的相对位置，计算一个侧向切线方向
    var to_player = (player.global_position - ship.global_position).normalized()
    # 找一个垂直于“朝向玩家”和“世界UP”的向量作为避让侧向
    var side_step = to_player.cross(Vector3.UP).normalized()
    if side_step.is_zero_approx():
        side_step = to_player.cross(Vector3.RIGHT).normalized()
    
    # 最终逃离方向：侧向避让线 + 远离玩家的方向（惯性保持）
    escape_dir = (side_step * 0.5 - to_player).normalized()

func physics_update(delta: float) -> void:
    if player == null or ship == null: return
    
    timer -= delta
    var dist = ship.global_position.distance_to(player.global_position)
    
    # 1. 转向逃离方向
    var target_pos = ship.global_position + escape_dir * 100.0
    parent_sm.rotate_towards(target_pos, delta, 0.5) # 转向不需要太生硬，利用惯性
    
    # 2. 保持高速远离
    parent_sm.set_target_speed(parent_sm.max_speed * 1.3)
    
    # --- 逻辑切换 ---
    # 时间到且距离足够远，或者已经完全甩开玩家
    if (timer <= 0 and dist > safe_distance) or dist > safe_distance * 1.5:
        parent_sm.transition_to(MoveSM.ORBIT) # 回到巡航，重新寻找切入机会
