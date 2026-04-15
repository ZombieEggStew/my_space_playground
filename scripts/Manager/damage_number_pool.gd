extends Node
## 简单的伤害数字对象池

@export var damage_number_scene: PackedScene
@export var pool_size: int = 20

var _pool: Array[Label] = []

func _ready() -> void:
    # 预填充对象池
    for i in range(pool_size):
        _create_new_to_pool()
    
    # 监听全局信号
    
    SignalBus.on_damage_dealt.connect(spawn)

func _create_new_to_pool() -> Label:
    var instance = damage_number_scene.instantiate() as Label
    instance.hide()
    # 断开脚本中自带的 queue_free 逻辑，交由对象池管理
    # 注意：如果 damage_number.gd 里的 tween.finished 连了 queue_free，需要修改它
    add_child(instance)
    _pool.append(instance)
    return instance

func get_damage_number() -> Label:
    for item in _pool:
        if not item.visible:
            return item
    
    # 如果池子满了，动态扩容
    return _create_new_to_pool()

func spawn(amount: int, pos: Vector2) -> void:
    var label = get_damage_number()
    label.show()
    label.modulate.a = 1.0 # 重置透明度
    label.scale = Vector2.ZERO # 重置缩放
    label.setup(amount, pos)
    
    # 我们监听动画结束，在结束后 hide 而不是 queue_free
    # 由于 setup 内部有自己的 Tween，这里我们可以通过一个小技巧：
    # 修改 damage_number.gd 让它在完成后发出信号或调用 hide()
