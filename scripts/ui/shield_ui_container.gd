extends VBoxContainer
class_name ShieldUIContainer

@export var shield_label: Label
@export var shield_progress_bar: TextureProgressBar

var _value := 0.0
var _max := 0.0
var target_value := 0.0

## 绑定 FloatStat:数值/上限经信号订阅(取代 update_shield_value 直调,见 .memo/.CURRENT.md P2)。
func bind(stat: FloatStat) -> void:
	stat.value_changed.connect(_on_value_changed)
	stat.max_value_changed.connect(_on_max_changed)
	# 立即用当前值初始化一次
	_on_max_changed(stat.max_value)
	_on_value_changed(stat.value)

func _on_value_changed(new_value: float) -> void:
	_value = new_value
	target_value = new_value
	_refresh_label()

func _on_max_changed(new_max: float) -> void:
	_max = new_max
	shield_progress_bar.max_value = new_max
	_refresh_label()

func _refresh_label() -> void:
	shield_label.text = "%d / %d" % [int(_value), int(_max)]

func _process(delta):
	# 显示平滑:缓冲条追平目标值(数值本身已由信号驱动,这里只做表现层 catch-up)
	shield_progress_bar.value = lerp(shield_progress_bar.value, target_value, delta * 5)
