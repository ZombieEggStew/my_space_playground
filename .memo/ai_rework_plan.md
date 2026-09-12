# 敌人 AI 系统完全重做方案(Utility AI)

> 创建:2026-09-12 状态:🔶 方案待评审(未动代码)
> 决策依据:用户反馈"现有 AI 傻傻的僵硬";2026-09-12 讨论定案——**决策层用 Utility AI 打分**,
> 优先级:**战术多样 > 威胁回避与反击 > 移动自然度**(敌机差异化 profile 列为后期可选)。
> 与本仓库计划的关系:本方案是 `.memo/.CURRENT.md` §P4(敌人 AIModule 替换)的**决策层规格升级版**;
> 若采纳,则 P4 按本方案执行,原"状态机内部保留"改为"Utility AI 决策"。
>
> **实施进度(2026-09-12)**:
> - ✅ **Ph0**:敌人接模块系统(ModulesManager + radar 身体 + aim_mechanics),旧 AI 行为不变;已提交。
> - ✅ **Ph1**:Perception + Utility 决策器 + patrol/orbit/tail_chase + 机动原语;敌人装齐
>   move/laser(独立纯身体场景 `module_laser_gun_enemy.tscn`,决策 #33 AI 通道)+ AIModule;
>   **旧 AI_Brain 已退役**(场景移除节点,scripts/ai/ 遗留待 Ph4 删)。无头零错误 + p4 冒烟 21/21。
>   **实测发现(--script 测试模式坑)**:测试脚本若**静态引用新 class_name**(如 AIModule),
>   编译时递归编译依赖链,此时 autoload 标识符(SignalBus/GameManager)未注册 → 连锁编译失败;
>   测试改用 `load("...").new()` + resource_path 匹配避免静态引用(旧类如 TeamID 已缓存不受影响)。
> - ✅ **Ph2**:威胁回避落地——perception 扩展(HealthComponent.changed 被打监听 + 血量比例 +
>   "missile" 组扫描),`ActionEvadeFire/ActionEvadeMissile/ActionDisengage` 三个行为,
>   booster 敌人适配(纯逻辑场景 `module_booster_enemy.tscn` + HUD 注册 null 防护)。
>   **设计修正(实测/评审)**:威胁分数原设计乘 `caution`,默认 0.5 时压不过进攻行为(尾追 0.65
>   + 滞后 0.15)导致"被打不躲";改为**生存硬约束**(`0.9*(0.4+0.6*intensity)` 等,不乘 caution),
>   被打/导弹贴脸/残血时分数逼近紧急阈值(0.9)立即打断进攻,caution 留 Ph3 做差异化。
>   p4 冒烟 28/28 + p5 回归 13/13 + 无头零错误。

---

## 1. 背景与动机

### 1.1 现状架构

敌人船 = `scenes/space_craft_5.tscn` + `scripts/space_craft_5.gd`(extends CharacterBody3D),
挂 `AI_Brain`(`scenes/state_machine/AI_Brain.tscn`)子节点,**完全在模块系统之外**:

```
AI_Brain (AIBrain)
├─ CombatSM ── StateIdle / StateAttack(自己 spawn 子弹,挂 get_tree().root)
└─ MoveSM ──── StateOrbit / StateChase / StateIntercept / StateEvade / StateJoust / StateDisengage
              (直接 global_basis.slerp + velocity.move_toward + move_and_slide)
```

### 1.2 "僵硬"根因诊断(基于代码)

| # | 根因 | 代码证据 | 表现 |
|---|---|---|---|
| 1 | **全知视角** | `AI_brain.gd:13` 直接 `GameManager.get_current_player()` | 所有敌机无视距离/视线/个体差异,同时精确知道玩家位置 |
| 2 | **零差异化** | 全部敌机同参数、同逻辑、同步决策 | 克隆人军队,动作整齐划一、可被完美预测 |
| 3 | **硬编码阈值切换** | `state_orbit/chase` 全用 `dot>0.7`、`dist<600` 等固定阈值 | 阈值边缘来回切换、抽搐;行为单一(永远绕后→咬尾) |
| 4 | **无威胁感知** | `state_evade.gd` 存在但**全项目无任何 transition 调它** | 被打不躲、导弹来了不闪,只会机械绕圈 |
| 5 | **机动不自然** | `move_state_machine.gd` 直接 slerp 全局朝向 + 直接改 velocity | 无转向率上限、无加减速惯性,急转急停僵硬 |
| 6 | **决策无节流** | 每帧 `physics_process` 都可能切状态 | 行为抽搐,无人类感的反应延迟 |

架构债(同时是 `.CURRENT.md` P4 计划收口项):
- `state_attack.gd:27` 子弹挂 `get_tree().root`,无统一 spawn 点/容器;
- `MoveSM` 直接操作刚体,与共享 move 模块(决策 #13/#28)双套实现并存。

### 1.3 范围

- **本次只出方案**,不动代码(用户指示)。
- 目标:完全重做敌人 AI,消灭 1.2 的 6 个根因 + 2 条架构债;
  与 P4(敌人接入共享模块系统)合并执行。

---

## 2. 目标架构总览:感知 → 决策 → 执行

```
┌────────────────── 敌人船 (space_craft_5 + ModulesManager) ──────────────────┐
│                                                                             │
│  [AIModule = ai_module.gd]                [共享模块:move / booster / laser] │
│   ├─ Perception(感知)  ──输入── radar 模块、被打事件、导弹接近检测            │
│   ├─ Decision(Utility) ──打分选行为,决策节流 + 滞后                          │
│   └─ Execute(执行)     ──输出── set_steer / set_throttle / set_boosting /   │
│                            set_firing + aim 射击解                          │
│                                                                             │
│  [radar 身体] → 目标列表(全量,消费方按阵营过滤,决策 #24)                      │
│  [aim_mechanics] → get_predicted_aim_data / 射击解(决策 #33 接口)            │
└─────────────────────────────────────────────────────────────────────────────┘
```

**核心原则(与 `.CURRENT.md` §2.4 对齐)**:
- AI 只输出**归一化命令**,不知道"键鼠"——与玩家 ControlModule 对称;
- 共享模块只懂命令、不懂意图(前进键与 AI 追击都是 `set_throttle(1.0)`,决策 #12);
- 决策层与执行层解耦:行为只描述"想干什么 + 参数",机动由 `maneuvers` 原语执行。

### 2.1 目录规划(遵循 `.CURRENT.md` §2.3 命名约定)

```
scripts/module/modules/brain/
├─ ai_module.gd            # AIModule 大脑(Module,决策 #10):每帧 drive 感知→决策→执行
├─ ai_perception.gd        # 感知(ModuleComponent):目标快照 + 威胁源 + 反应延迟
├─ pilot_profile.gd        # 个性资源(Resource,后期可选启用)
├─ ai_maneuvers.gd         # 机动原语:受限转向率/平滑加减速/滚转 → 包装共享 move 模块
└─ ai_actions/             # 行为库:每个行为一个脚本(AIAction)
   ├─ action_patrol.gd     # 巡航
   ├─ action_orbit.gd      # 轨道绕后
   ├─ action_tail_chase.gd # 追尾猎手
   ├─ action_kite.gd       # 远程风筝
   ├─ action_joust.gd      # 高速对冲
   ├─ action_intercept.gd  # 侧向拦截
   ├─ action_evade_fire.gd # 规避子弹(替代旧 EVADE,真正被调用)
   ├─ action_evade_missile.gd # 规避导弹
   └─ action_disengage.gd  # 低血/劣势脱离
```

旧文件 `scripts/ai/`(AIBrain/MoveSM/CombatSM/State 系列)在迁移完成后**整体删除**。

---

## 3. 感知层 Perception

| 输入 | 来源 | 说明 |
|---|---|---|
| 目标列表 | `RadarModule.get_targets_in_range()` | 按 `team_id` 过滤;radar 给全量含自身(决策 #24,对称性已落地) |
| 自身状态 | 血量(`get_health_component()`)、热/能量(若装 heat/booster) | 驱动"低血脱离"等行为 |
| 被打事件 | ③ `SignalBus.on_damage_dealt` / `HealthComponent.changed` | 驱动 `evade_fire`(被打 = 被瞄准的证据) |
| 导弹威胁 | 导弹节点组扫描(距离/逼近速度) | 驱动 `evade_missile`;成本控制见 §9 |

**人类化(消灭根因 #1)**:
- 目标位置做**低通滞后**:缓存目标位置,每 0.1~0.3s(带个体抖动)才更新;
- 距离越远,位置噪声越大(模拟"看得不真切");
- 感知结果统一打包成 `PerceptionSnapshot`(每决策 tick 计算一次,行为打分只读快照,不直接读场景)。

---

## 4. 决策层 Utility AI(核心)

### 4.1 机制

- 每个行为 = 一个 `AIAction`,实现两个方法:
  - `score(context: PerceptionSnapshot, profile: PilotProfile) -> float`
  - `execute(delta, context) -> void`(执行时经 `ai_maneuvers` / 模块命令)
- **打分公式**:`score = base_utility × profile_weight × situational_factor + noise`
  - `base_utility`:行为固有倾向(如 chase=0.6,evade=0.9);
  - `profile_weight`:个性加权(caution 高 → 防御类 ×1.5);
  - `situational_factor`:情境因子(导弹逼近 → evade_missile 因子 → 5.0,分数瞬间压过进攻);
  - `noise`:±0.05 随机,打破整齐划一(根因 #2 的廉价版)。
- **决策节流(消灭根因 #6)**:每 `decision_interval`(默认 0.25s ± 个性抖动)重打分一次,
  不是每帧;执行是每帧的(命令连续输出),决策是节流的。
- **滞后判据(hysteresis,消灭根因 #3 的抽搐)**:切行为需要
  `new_score > current_score + HYSTERESIS(0.15)`;正在执行的同分行为不切,
  杜绝阈值边缘来回跳。

### 4.2 行为库(按用户优先级排序)

#### A. 移动自然度(基础,最先落地)

| 措施 | 实现位置 | 消灭的根因 |
|---|---|---|
| 受限转向率 | `ai_maneuvers.rotate_towards`:最大角速度 `max_turn_rate`(deg/s),不直接 slerp 全量 | #5 |
| 平滑加减速 | 走共享 `move.set_throttle`(内部 acceleration 已实现) | #5 |
| 决策节流 + 滞后 | §4.1 | #3/#6 |
| 滚转协调(可选) | 转向时按需 `set_roll`,视觉自然感 | #5(观感) |

#### B. 战术多样(用户第一优先级)

| 行为 | 触发(打分要素) | 执行 | 替代旧状态 |
|---|---|---|---|
| `patrol` | 无目标/距离极远,`base 0.2` | 慢速巡航,随机航点或固定路线 | StateIdle + ORBIT 远距分支 |
| `orbit` | 目标在近距但未咬尾,`base 0.55` | 侧向偏移盘旋找位(保留旧螺旋逻辑,参数化) | StateOrbit |
| `tail_chase` | 已在目标 6 点钟锥内,`base 0.65` | 贴尾保持 200~500m,匹配速度 | StateChase |
| `kite` | `profile.preferred_range` 大(风筝手),`base 0.5` | 保持距离绕圈 + 持续射击(远程压制) | 新 |
| `joust` | 迎头对冲几何,`base 0.45` | 高速迎头一波,接近后切 evade/disengage | StateJoust |
| `intercept` | 目标侧向横穿,`base 0.5` | 算预判点切入(可复用 aim 预测) | StateIntercept |

#### C. 威胁回避与反击(用户第二优先级)

| 行为 | 触发(打分要素) | 执行 | 替代旧状态 |
|---|---|---|---|
| `evade_fire` | 被打事件 / 检测到射击线朝己,`situational ×3~5` | 急转 + 随机方向 + 必要时 boost(旧 EVADE 逻辑复活并参数化) | StateEvade(从未被调 → 现在真正接入) |
| `evade_missile` | 导弹接近(距离/逼近速度),`situational ×5` | 朝导弹横向急转 + boost,导弹过穿后切回 | 新 |
| `disengage` | 血量 < 阈值 × caution 加权 / 连续挨打,`situational ×3` | 拉距 + 侧向切线逃离(旧逻辑参数化) | StateDisengage |
| 反击射击(可选) | 逃跑中仍可开火 | `set_firing(true)` 朝后/侧向 | 新(手感增强) |

> 关键点:Utility 的**动态优先级**天然解决旧双 SM"各自为政"问题——
> 被咬尾/被导弹追时防御分数暴涨压过进攻,无需手工协调两个状态机。

---

## 5. 执行层(与 P4 合并)

### 5.1 敌人接入模块系统

`space_craft_5` 装配:

| 模块 | 装/不装 | 说明 |
|---|---|---|
| ModulesManager + move(执行器) | ✅ | `set_throttle/set_steer/set_roll`,纯执行器(决策 #13/#28) |
| booster | ✅ | `set_boosting(bool)`,evade/disengage 用 |
| laser | ✅ | `set_firing(bool)` + 射击解(共享武器) |
| radar(身体) | ✅ | 感知源(§3);**不装 radar_view**(敌人无相机,决策 #24/#31 已保证降级) |
| aim_mechanics | ✅ | `get_predicted_aim_data` / 射击解(决策 #33 接口,AI 复用) |
| camera / module_hud / control / 各 _view | ❌ | 玩家侧/大脑侧独有 |
| shield / missile | 可选 | 按难度装配 |

### 5.2 射击解(接口对齐点)

- 玩家侧:激光 `shoot()` 走 `aim_mechanics.get_aim_basis_from_crosshair(screen_pos)`(决策 #33,屏幕坐标);
- **AI 侧没有屏幕坐标**,射击解需新通道(方案待定,落地时按决策 #33 接口对齐):
  - 推荐:AIModule 用 `get_predicted_aim_data(target, bullet_speed)` 得 3D 预测点 →
    自己算方向 → 调 laser 新增的 AI 方向通道(如 `set_ai_aim_dir(Vector3)`)或
    直接给 laser 一个"朝向即射"模式;
  - 备选:复用 `get_aim_basis_from_crosshair` 的降级分支(缺相机 → 机头朝向),AI 直接机头直射 + 预测转向。
- 命中判据(旧 `state_attack` 的 `fire_angle 0.95`):保留为 AI 射击节流(机头对齐预测点才开枪),参数入 profile(markmanship 影响精度 → 叠加散布)。

### 5.3 删旧

- `scripts/ai/` 全部(AIBrain / MoveSM / CombatSM / State 系列)+ `scenes/state_machine/AI_Brain.tscn`;
- `state_attack.spawn_bullet()` 的"子弹挂 root"清理与 `.CURRENT.md` P4 的 bullet 统一 spawn 收口一并做。

---

## 6. 差异化 PilotProfile(后期可选,用户未列为首要优先级)

```
pilot_profile.gd (Resource):
  aggression: 0..1      # 敢不敢贴身
  caution:    0..1      # 防御类行为权重(evade/disengage ×caution)
  marksmanship: 0..1    # 精度 → 叠加到散布(菜鸟乱射/老兵点射)
  preferred_range: m    # 风筝流 vs 缠斗流
  turn_ability: 0..1    # 最大转向率倍率
  speed_pref: 0..1      # 巡航速度偏好
  randomness: 0..1      # 决策抖动幅度
```

模板示例(供场景/生成器选用):`菜鸟(低 aggression,低 marksmanship,高 randomness)`、
`老兵(高 marksmanship,中 aggression,低 randomness)`、`风筝手(大 preferred_range,高 caution)`、
`莽夫(高 aggression,低 caution,小 preferred_range)`。
启用方式:场景里给敌人挂 profile 资源,或生成时随机 roll;启用后"克隆人"观感消失。

---

## 7. 迁移步骤与验证闸门

| 阶段 | 内容 | 验证闸门 | 状态 |
|---|---|---|---|
| **Ph0** | 敌人接入模块系统(只装不换行为,现有 AI 照跑) | 无头 `--import` + `--quit-after 15` 零 SCRIPT ERROR;敌人行为与接入前一致 | ✅ **已完成(2026-09-12)** |
| **Ph1** | 建 Perception + Utility 决策器 + 首批行为(patrol/orbit/tail_chase)+ 机动原语 | 决策节流生效;单敌能巡航/绕后/咬尾,无抽搐 | ✅ **已完成(2026-09-12)**,p4 冒烟 21/21;编辑器手动待确认 |
| **Ph2** | 威胁回避:evade_fire / evade_missile / disengage 接入 | 被打会躲、导弹接近会闪、低血脱离;旧 EVADE 正式退役 | ✅ **已完成(2026-09-12)**,p4 冒烟 28/28 + p5 回归 13/13;编辑器手动待确认 |
| **Ph3** | 战术多样:kite / joust / intercept;开启 profile 差异化(可后延) | 同场多敌行为分工;玩家难以一招吃遍 | 🔶 待做 |
| **Ph4** | 删旧 `scripts/ai/` + 子弹 spawn 收口 + 文档 | 全量回归:输入/调试键逐键 × 敌人行为;code-map 更新 | 🔶 待做 |

每阶段结束跑 §7 无头检查 + 编辑器手动验证对应行为。

---

## 8. 验证方式

- **无头冒烟**(新增 `scripts/test/p4_ai_smoke_test.gd`):感知快照有效性、各行为打分
  单调性(威胁↑→防御分↑)、命令输出范围(set_throttle∈[-1,1] 等)、决策节流不每帧切。
- **编辑器手动清单**:
  1. 单敌:巡航 → 发现玩家 → 绕后 → 咬尾 → 开火,全程无抽搐/急停;
  2. 被打:玩家命中敌机 → 敌机急转规避(不再无反应);
  3. 导弹:发射导弹 → 敌机横向规避(若 Ph2 已做导弹感知);
  4. 低血:把敌机打到残血 → 它脱离逃跑;
  5. 多敌(≥2):不同 profile → 行为分工可见;
  6. 自然度:观察转向过程(有转向率上限、非瞬移)。

---

## 9. 风险与待定项

| 项 | 说明 |
|---|---|
| 敌人无相机 | radar_view/aim_view 无相机降级已就位(决策 #24/#31),敌人只装 radar 身体不装 _view |
| AI 射击解新通道 | §5.2 待定,落地时与决策 #33 接口对齐(laser 需补 AI 方向通道) |
| 导弹感知成本 | 每 tick 扫 missile 节点组,量小可接受;或改事件驱动(导弹发射时登记) |
| 决策节流 vs 响应性 | 0.25s 决策延迟 + 紧急行为(evade)可走"紧急旁路"立即打断(分数 > 硬阈值 0.9 时不等节流) |
| 与 P6 的关系 | P4 完成并入 P6 收尾回归;本方案若评审通过,P4 即按此执行 |
| profile 差异化 | 用户列为后期可选,默认先不做,不影响主线 |

---

## 10. 结论

- 本方案把敌人 AI 从"硬编码双层 FSM + 直接操作刚体"重做为
  **"感知(带反应延迟)→ Utility AI 决策(节流 + 滞后)→ 共享模块命令执行"**;
- 一次性消灭 6 个"僵硬"根因 + 2 条架构债,并顺带完成 `.CURRENT.md` 的 P4;
- 待用户评审通过后,按 Ph0→Ph4 实施;首个可运行里程碑 = Ph1(移动自然度 + 基础行为)。

---

## 11. 敌机"放水"设计(2026-09-12 用户审核通过,待实施)

### 11.1 背景(用户实测反馈)

| # | 反馈 | 代码根因 |
|---|---|---|
| 1 | 敌机咬尾咬太死,玩家几乎无法摆脱 | `ActionTailChase` 每帧精确贴 6 点 + 速度完美匹配,且与玩家共用同一份 move 模块(转向敏捷度相同、永不失误) |
| 2 | 攻击敌机,敌机会飞离玩家非常远,远到看不清、难击中 | `ActionEvadeFire` 满油门+boost 持续 2s(方向可能含远离分量);`ActionDisengage` 无退出条件(血不回就永远逃);`patrol` 朝机头前方无限漂移 |

背景:后续会有大量敌机、部分会组成小队;敌机需要"傻"一点——故意选非最优、露破绽、给攻击窗口,让玩家能摆脱/截击。

### 11.2 设计原则

**敌机是"表演者",不是"猎手"**:能力低于玩家、有失误、有破绽、有活动范围;
多敌/小队场景下每个个体再傻一点,避免围殴玩家到无解。

### 11.3 机制(M1–M7,用户决策已并入)

| # | 机制 | 内容 | 用户决策 |
|---|---|---|---|
| M1 | 执行层限速 | AI 启动时调低敌人 move 实例参数:max_speed 60→~45、转向率 3.0/2.0→~2.2/1.6 rad/s(共享模块不动,只调敌人实例) | — |
| M2 | 决策放水 | ①打分噪声 0.05→~0.15;②失误概率 ~15% 随机选非最高分行为;③失误窗口:每 2.5~4s 随机触发 0.8~1.2s"发呆"(转向迟钝+不开火),天然攻击窗口 | — |
| M3 | 球面巡逻(替代 patrol) | 无事可做时,在**以玩家为球心半径 500m 的球面**上规律绕行(绕圈+轻微上下波动,方向周期性翻转) | ✅ 500m |
| M4 | 距离上限 | AI 层每帧检查:离玩家 > **800m** 时,steer 目标强制改为"回球面轨道最近点",谁都不许飞出战斗圈 | — |
| M5 | 咬尾给窗口 | ①目标点从"正后方 10m"改为"后方 10m + 侧偏 25~40m"(不完美贴尾);②每 2~3s 概率判定"跟丢"回 orbit 重新找位 | ✅ 侧偏+周期跟丢 |
| M6 | 威胁机动轻量化 | 被激光攻击:小幅横移,**速度 ~0.7、不 boost、~1s 结束**,方向限侧向/斜前(不远离);导弹接近:保留横向急转+boost(贴脸威胁大才紧急) | ✅ 自定义 |
| M7 | 取消低血脱离 | **删除 disengage**:低血敌机照常战斗,战死为止,不脱离战场 | ✅ 自定义 |

### 11.4 参数默认值(全部进 `PilotProfile`)

| 参数 | 默认 | 说明 |
|---|---|---|
| `max_speed_mult` / `turn_mult` | 0.75 / 0.75 | 敌人 move 限速倍率(相对玩家) |
| `blunder_probability` | 0.15 | 决策选次优概率 |
| `blunder_interval` | 2.5~4s(随机) | 失误窗口间隔 |
| `blunder_duration` | 0.8~1.2s(随机) | 失误窗口时长 |
| `orbit_radius` | 500m | 球面巡逻半径(玩家为球心) |
| `max_engage_range` | 800m | 距离上限 |
| `tail_lose_interval` | 2~3s(随机) | 咬尾"跟丢"概率间隔 |

> Ph3 差异化时这些参数就是每架敌机的个性来源(莽夫失误少追得凶、菜鸟失误多)。

### 11.5 落地清单(审核已通过,实施命令待用户叫停)

1. `pilot_profile.gd`:加 11.4 参数
2. `ai_module.gd`:初始化对 move 限速;决策失误概率/随机次优;失误窗口定时器;每帧距离上限回飞覆盖
3. `ai_actions/`:
   - `action_patrol.gd` → 重写为球面巡逻(玩家为球心)
   - `action_tail_chase.gd`:目标点侧偏 + 周期性"跟丢"
   - `action_evade_fire.gd`:轻量化(0.7 速、无 boost、~1s、方向限侧向/斜前)
   - **删 `action_disengage.gd` + AIModule 取消注册**
4. p4 冒烟测试补检查(限速生效、失误概率范围、距离上限覆盖、球面巡逻方向合理性)
5. 无头 + 编辑器手动验证

### 11.6 验证点

- 咬尾能被玩家急转/boost 甩开(侧偏 + 周期跟丢)
- 被打只小幅机动,不飞出视野
- 低血继续战斗,不脱离
- 无事时绕玩家 500m 球面规律飞行
- 失误窗口期间能稳定命中敌机(截击窗口)
- 导弹接近仍会闪避

### 11.7 二次调整(2026-09-12 用户实测反馈后追加,已实施)

| # | 用户反馈 | 落地 |
|---|---|---|
| R1 | 敌机不要离玩家太近(距离 <100m 时尝试逃离) | 新增 `ActionKeepDistance`:score = `0.9*sqrt(1-d/100)`(越近越高,生存约束);orbit/tail_chase 在 d<100m 时降分让位;`pilot_profile.min_engage_range = 100m` |
| R2 | 转弯太灵敏,锁尾互转圈;要移动更规律、简单、可预测 | ①`turn_mult` 0.75→**0.55**(转向率 1.65/1.1);②`steer_towards_dir` **不满舵**(±0.7)+ **5° 死区**;③tail_chase **转向脉冲**(转 0.8~1.4s → 直飞 0.4~0.8s 交替,锯齿状规律移动) |
| R3 | 规避时加连续滚转更有意思 | `ai_maneuvers.set_roll()`;evade_fire/evade_missile enter 随机 ±1 滚转方向、execute 持续滚转、exit 复位;`AIModule._transition_to` 兜底 set_roll(0) 防残留 |

> 实施状态:✅ 已提交;无头零错误 + p4 冒烟 39/39 + p5 回归 13/13。
> **编辑器手动验证(2026-09-12 用户确认):基本没问题**——近距逃离、转弯钝化规律化、
> 规避滚转三项生效,无报错;后续如需微调(如放水程度/巡逻半径/失误频率)改 PilotProfile 默认值即可。
> ⏸ 当前暂停:Ph3(战术多样+差异化)与 Ph4(清理)未做,等用户叫停继续。
