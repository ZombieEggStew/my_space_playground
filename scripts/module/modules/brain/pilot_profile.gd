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
