# AGENTS.md — test-1(Godot 4.7 太空空战原型)

> 架构/接口/场景/信号流细节见根目录 [`code-map.md`](code-map.md)。
> Godot API 问题:使用 `godot-docs` 技能(离线文档在 `godot-docs-md/`),不要凭记忆猜 API 签名。
> godot位置：D:\.godot\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe

## 项目概述

单人太空空战原型:模块化玩家飞船 + AI 状态机敌机 + 激光/导弹武器 + HUD/Buff 系统。
主场景:`scenes/game_scene.tscn`。

## 工作原则(最高优先级,必须遵守)

- **实测优先**:证据不足时不要埋头推理,先写最小调试代码,请用户进游戏做针对性测试并反馈结果,再定位问题。
- **少思考多提问**:每轮先问「这步真的必要吗」;缺关键信息或能直接问用户时,立即用 `ask_user_question` 提问(复现步骤、具体表现、期望行为),禁止在证据不足时长时间自主推理或空转。

## 架构规则(必须遵守)

### 全局单例(autoload)——职责固定,不要混用

| 单例 | 职责 |
|---|---|
| `SignalBus` | **事件总线。只声明信号,零逻辑、零状态。** 所有跨模块通信走它。 |
| `GameManager` | 服务定位器。持有引用;通过 `register_*()` 注册,通过字段/`get_current_player()` 读取。 |
| `BuffManager` | Buff 工厂,按文件名约定应用 Buff。 |
| `PlayerInfo` | 玩家共享常量(目前是 `dead_zone_px`)。 |

### 通信模式

- 模块/组件之间**禁止直接互相调用**,通过 `SignalBus` 信号收发;信号命名前缀 `on_`,
  所有 emit 的信号必须先在 `SignalBus.gd` 声明,再 emit/connect。
- 共享节点引用一律通过 `GameManager` / `ModulesManager` 的 getter 获取,不要写 `get_node("../../...")` 相对路径。
- 场景引用用 `@export var xxx: PackedScene` 在编辑器里绑定(`uid://` 自动维护),禁止散落 `preload("res://...")` 路径字符串。

### 模块系统(`scripts/modules/`)

- 飞船功能 = `Module`(统一 `extends Node3D`,见决策 #25-26)节点,装进 `ModulesManager`;`ModulesManager` 在 `install_module` 时**显式注入** `root`/`modules_manager`(见 code-map §4.1/决策 #25),基类 `_enter_tree` 只是兜底(未注入才推算)——**覆盖 `_enter_tree` 的子类必须调 `super._enter_tree()`**。
- 缺依赖:`Log.log_missing_component(self, "x")` 后 `queue_free()`,绝不硬崩溃。
- 新增模块 = `scripts/modules/` 建脚本 + `scenes/modules/` 建场景,消费方 `@export` 绑定。

### 组件与战斗

- 载具对外暴露 `hit(damage)` / `get_team_id()` / `get_health_component()`;伤害流
  `Bullet → HealthComponent.take_damage() → changed → UI`。
- 投射物必须继承 `Bullet`(双命中通道 + 寿命 Timer,防穿透/泄漏);**友军伤害规则集中在
  `Bullet.setup()` 的 collision_mask**,别处禁止硬编码掩码(详见 code-map.md §4.5)。

### AI(`scripts/ai/`)

- 状态是 `StateMachine` 的子节点,用 `transition_to(index)` 切换。
  **场景树中状态的顺序就是 index**——不要随意调整子节点顺序。
- 新行为:继承 `State`,实现 `enter()`/`exit()`/`physics_update()`;机动动作优先用 `MoveSM`
  的公共原语(`rotate_towards`、`move_forward`、`set_target_speed`)。

### HUD

- **特效不直接改 `position`**:只写 `meta` 里的独立 offset 通道(`hud_flow_offset` / `hud_shake_offset`),
  由 `HUDManager` 统一合成,避免特效互踩布局。
- 特效的 boost 状态监听 `SignalBus.on_player_boost`,不要读父节点属性。
- **目标 UI**(选择框/血条)在 `setup()` 里连 `target.tree_exited → queue_free` 自毁,不要靠 `_process` 轮询。
- HUD 组/远 HUD 的注册与 API 见 code-map.md §4.7。

## 代码风格

- GDScript,Godot 4.7;缩进用 **Tab**(部分旧文件用空格,跟随所编辑文件的现状)。
- 命名:`class_name` PascalCase;文件/函数/变量 snake_case;私有成员 `_` 前缀;信号 `on_*`。
- UI 可观察数值用 `BoolStat` / `IntStat` / `FloatStat` 资源(set 时发信号),不要轮询;链式 setup 返回 `self` 是首选。
- 诊断用 `Log.log_*`,不要裸 `print`;文档注释用官方 `##`(置于 `extends`/`class_name` 后),不用 `===` 分隔线。
- 长期意图写入文件顶部的 `# TO DO :` / `# FIX ME :` 注释块(见 `character_body_3d.gd`)。

## Godot 坑点(本项目实测)

- **注册进单例要放在 `_enter_tree`,不要放 `_ready`**(子节点 `_ready` 可能早于父节点执行)。
- **不要重复 `class_name`**:场景内嵌脚本与外部脚本同名会报 "Class X hides a global script class";应在 `.tscn` 中引用外部脚本。
- 节点清理:寿命超时与命中触发 `queue_free()` 双保险;访问已释放目标前用 `is_instance_valid()` 防护。
- 相机/弹簧臂平滑:必须把局部变量赋回节点属性(`spring_arm.position = arm_pos`)并缓存基准偏移,只改局部副本无效。

## 构建 / 运行 / 验证

- 无构建步骤,**无自动化测试**。验证方式:在 Godot 4.7 编辑器中运行主场景 `scenes/game_scene.tscn` 并手动操作。
- 调试按键:`O` 自伤 10,`P` 治疗 Buff,`1` 发射导弹,右键锁定,左键开火,Shift 加速,Q 引擎开关。
- 不要改动生成/忽略路径:`.godot/`、`godot-docs-md/`(离线文档语料)、`.dsh/`、`*.import` 文件。
