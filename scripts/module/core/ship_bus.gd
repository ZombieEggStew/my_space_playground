extends Node
class_name ShipBus

## ② 飞船级事件总线:只声明信号,零逻辑零状态(见 .memo/.CURRENT.md §2.2 三级通信模型)。
## 收发双方 = 同一艘船的兄弟模块/挂件,经 Module.ship_bus(install 注入)或
## player.ship_bus 访问;船外节点(InputManager / HUD 特效)经 on_player_registered 拿到后连接。
## 纪律:bus 只发"变化"脉冲,载荷只带身份不带坐标;"当前值"存模块/Stat,不走总线。
## P3 修订:on_player_shoot / on_player_boost_input 已删除——连发/持续加速改由
## ControlModule 每帧直接调 set_firing / set_boosting(连续量=直接方法,决策 #12)。

signal on_player_try_lock()
signal on_player_boost(enable: bool)
signal on_toggle_track_mouse(enable: bool)
signal on_player_look_backward(enable: bool)
signal on_player_look_around(enable: bool)
signal on_player_try_use_item_1()
signal on_toggle_engine()
signal on_player_lock_target(target: AbleToBeLocked)

## hover 事件(决策 #27):检测点在 aim(selection),载荷只带 target 身份;
## radar_view 订阅做选择框高亮。
signal on_target_hovered(target: AbleToBeLocked)
signal on_target_unhovered()
