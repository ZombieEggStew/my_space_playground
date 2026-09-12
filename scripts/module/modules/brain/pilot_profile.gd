extends Resource
class_name PilotProfile

## 敌机个性参数(见 .memo/ai_rework_plan.md §6)。Ph1 全部用默认值;
## Ph3 开启差异化时,每艘敌机随机/模板化一份,决定行为权重与执行参数。

## 攻击倾向 0..1:敢不敢贴身缠斗(影响 orbit/tail_chase 等进攻行为权重)
@export_range(0.0, 1.0) var aggression := 0.6
## 防御倾向 0..1:威胁回避/disengage 行为权重(Ph2 启用)
@export_range(0.0, 1.0) var caution := 0.5
## 射击精度 0..1:影响开火散布/命中判据(Ph2 启用)
@export_range(0.0, 1.0) var marksmanship := 0.6
## 偏好交战距离(米):风筝手大、缠斗手小(Ph3 启用)
@export_range(50.0, 2000.0) var preferred_range := 400.0
## 机动能力倍率(Ph3 启用)
@export_range(0.5, 1.5) var turn_ability := 1.0
## 巡航速度偏好 0..1(Ph3 启用)
@export_range(0.5, 1.5) var speed_pref := 1.0
## 决策打分随机抖动幅度(打破整齐划一)
@export_range(0.0, 0.2) var randomness := 0.05
## 决策节流间隔(秒)
@export_range(0.1, 0.6) var decision_interval := 0.25

# --- 放水设计(.memo/ai_rework_plan.md §11,2026-09-12 用户审核通过) ---
## 敌人 move 限速倍率(相对玩家:max_speed 60 / yaw 3.0 / pitch 2.0)
@export_range(0.4, 1.0) var max_speed_mult := 0.75
## 转向率倍率(0.55 = 明显钝于玩家;配合 steer 不满舵 + 转向脉冲,移动规律可预测)
@export_range(0.4, 1.0) var turn_mult := 0.55
## 近距逃离阈值(米):距玩家小于此值主动拉开,避免贴脸互转
@export_range(50.0, 300.0) var min_engage_range := 100.0
## 决策失误:选次优的概率
@export_range(0.0, 0.5) var blunder_probability := 0.15
## 失误窗口间隔区间(秒,随机)
@export_range(0.5, 6.0) var blunder_interval_min := 2.5
@export_range(0.5, 6.0) var blunder_interval_max := 4.0
## 失误窗口时长区间(秒,随机):期间转向迟钝 + 不开火(天然攻击窗口)
@export_range(0.2, 2.0) var blunder_duration_min := 0.8
@export_range(0.2, 2.0) var blunder_duration_max := 1.2
## 球面巡逻半径(玩家为球心;无事可做时绕玩家规律飞行)
@export_range(50.0, 2000.0) var orbit_radius := 500.0
## 距离上限:离玩家超过此值强制回球面轨道
@export_range(100.0, 3000.0) var max_engage_range := 800.0
## 咬尾"跟丢"平均间隔(秒):周期性松口给玩家摆脱窗口
@export_range(0.5, 6.0) var tail_lose_interval := 2.5
