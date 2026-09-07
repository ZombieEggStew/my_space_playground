# AGENTS.md — test-1(Godot 4.7 太空空战原型)

> 架构总览见根目录 [`code-map.md`](code-map.md)。
> Godot API 问题:使用 `godot-docs` 技能(离线文档在 `godot-docs-md/`),不要凭记忆猜 API 签名。
> godot位置：D:/.godot/Godot_v4.7.2-stable_win64.exe

## 项目概述

单人太空空战原型:模块化玩家飞船 + AI 状态机敌机 + 激光/导弹武器 + HUD/Buff 系统。
主场景:`scenes/game_scene.tscn`。

## 工作原则：实践是检验真理的唯一标准（最高优先级，必须遵守）
- **DEBUG**：证据不足时，不要根据代码埋头推理，先写最小调试代码，请用户进游戏做针对性测试和信息收集（例如「请进游戏验证 X，并告诉我 Y」），再根据结果定位问题。
- **成本意识**：每轮思考前问自己「这一步真的必要吗？还是我其实可以直接问用户」。宁可多问一句，也不要让用户为一次长考买单。
- **动手前先判断**：这个问题我现在就能定位或给出方案吗？不能 → 立即用 `ask_user_question` 提问（复现步骤、具体表现、期望行为），禁止先埋头搜索。
- **禁止长考**：禁止在缺少关键信息或证据不足时，继续长时间自主推理、反复读证据而不向用户提问。如果遇到遇到矛盾信息，陷入自我怀疑，立即停止空转。


## 架构规则(必须遵守)

### 全局单例(autoload)——职责固定,不要混用

| 单例 | 职责 |
|---|---|
| `SignalBus` | **事件总线。只声明信号,零逻辑、零状态。** 所有跨模块通信走它。 |
| `GameManager` | 服务定位器。持有引用(`player_instance`、`hud_manager`、`input_manager`…);通过 `register_*()` 注册,通过字段/`get_current_player()` 读取。 |
| `Scenes`(`my_scenes.gd`) | **PackedScene 集中注册表。** 运行时实例化的场景必须在这里 preload,禁止在功能脚本里散落 `preload()`。 |
| `BuffManager` | Buff 工厂,按文件名约定应用 Buff。 |
| `PlayerInfo` | 玩家共享常量(目前是 `dead_zone_px`)。 |

### 通信模式

- 模块/组件之间**禁止直接互相调用**。通过 `SignalBus` 信号收发
  (`on_player_shoot`、`on_player_lock_target`、`on_player_boost`…)。
- 信号命名:前缀 `on_`(如 `on_player_registered`、`on_lockable_target_died`)。
- 新功能需要新事件时:先在 `SignalBus.gd` 声明信号,再 emit/connect。
  **所有 emit 的信号必须已声明**(已知 bug:`input_manager.gd` 发射了未声明的
  `on_player_switch_camera`——不要复制这种写法)。
- 共享节点引用一律通过 `GameManager` / `ModulesManager` 的 getter 获取
  (`get_camera_module()`、`get_aim_module()`…),不要写 `get_node("../../...")` 相对路径。

### 模块系统(`scripts/modules/`)

- 飞船功能是 `Module`/`Module3D` 节点,安装进 `ModulesManager`
  (`install_module()` / `install_module_3d()`),通常在 `PlayerShip._ready` 中完成。
- 基类在 `_enter_tree` 缓存 `modules_manager` 与 `root`(飞船)——不要在 `_ready` 里重复解析。
- 缺依赖的标准处理:`Log.log_missing_component(self, "x")` 然后 `queue_free()`。
  缺失兄弟模块时绝不能硬崩溃。
- 新增模块 = `scripts/modules/` 下建脚本 + `scenes/modules/` 下建场景 + 在 `Scenes` 中加 preload。

### 组件与战斗

- `HealthComponent`(Area3D hurtbox)持有血量;载具对外暴露 `hit(damage)` /
  `get_team_id()` / `get_health_component()` 作为战斗接口。伤害流向:
  `Bullet` → `HealthComponent.take_damage()` → `changed` 信号 → UI。
- 阵营:`TeamID` 枚举(PLAYER/NEUTRAL/ENEMY)+ 物理层 9/10/11(hurtbox)。
  投射物在 `Bullet.setup()` 中按 `team_id` 计算 `collision_mask`——友军伤害规则集中在那里,
  不要在别处硬编码掩码。
- 投射物继承 `Bullet`(`scripts/bullet/base/bullet_base.gd`):使用链式
  `setup(pos, dir, team, shooter).set_damage().set_speed()` API。保留双命中通道
  (逐帧射线步进 + `area_entered`)和寿命 `Timer`——它们防止高速穿透和子弹泄漏。
- Buff:在 `scripts/buff/buff_<id>.gd` 新建继承 `Buff` 的脚本;图标放
  `textures/icon/icon_buff_<id>.png`;通过 `BuffManager.apply_buff_by_name()` 应用。

### AI(`scripts/ai/`)

- 状态是 `StateMachine` 的子节点;用 `transition_to(index)` 切换。
  **场景树中状态的顺序就是 index**——不要随意调整子节点顺序。
- 新行为:继承 `State`,实现 `enter()`/`exit()`/`physics_update()`。
  机动动作优先用 `MoveSM` 的公共原语(`rotate_towards`、`move_forward`、`set_target_speed`)。

### HUD

- 动态 HUD 组:`GameManager.hud_manager.register_hud_group(control)` 返回 `MyHUD`,
  链式配置特效:`.set_flow_effect(...).set_rotation_effect().set_boost_offset_effect()...`。
- 屏幕投影("远")HUD 元素继承 `HUDFarBase`,通过 `register_hud_far(_node)` 注册;
  从 `HUDFarManager.nose_pos_2d` / `mouse_pos` 读取数据。

## 代码风格

- GDScript,Godot 4.7 语法。缩进用 **Tab**(Godot 默认);部分旧文件用空格——跟随所编辑文件的现状。
- 命名:`class_name` 用 PascalCase;文件/函数/变量用 snake_case;私有成员加 `_` 前缀
  (`_locked_target`、`_is_destroyed`);信号用 `on_*`。
- UI 监听的可观察数值用 `BoolStat` / `IntStat` / `FloatStat` 资源(set 时发信号),不要轮询。
- 返回 `self` 的链式 setup 方法是首选配置风格。
- 诊断信息用 `Log.log_error` / `Log.log_missing_component` / `Log.log_info`,不要裸 `print`。
- 长期意图写入文件顶部的 `# TO DO :` / `# FIX ME :` 注释块(现有惯例,见 `character_body_3d.gd`)。

## Godot 坑点(本项目实测)

- **注册进单例要放在 `_enter_tree`,不要放 `_ready`**——子节点 `_ready` 可能早于父节点执行,
  `_ready` 时注册会太晚(见 `Main.gd`)。
- **不要重复 `class_name`**:场景内嵌脚本与外部脚本同名 class_name 会导致
  "Class X hides a global script class"。应在 `.tscn` 中引用外部脚本。
- 节点清理:寿命超时与命中触发的 `queue_free()` 双保险;访问已释放目标前用
  `is_instance_valid()` 防护(导弹、锁定、Buff 均如此)。
- 相机/弹簧臂平滑:必须把局部变量赋回节点属性(`spring_arm.position = arm_pos`),
  并缓存基准偏移用于相对加速——只改局部副本无效。

## 构建 / 运行 / 验证

- 无构建步骤,**无自动化测试**。验证方式:在 Godot 4.7 编辑器中运行主场景
  (`scenes/game_scene.tscn`)并手动操作功能。
- 调试按键:`O` = 自伤 10,`P` = 施加治疗 Buff,`1` = 发射导弹,
  右键 = 锁定,左键 = 开火,Shift = 加速,Q = 引擎开关。
- 不要改动生成/忽略路径:`.godot/`、`godot-docs-md/`(离线文档语料)、`.dsh/`、`*.import` 文件。
