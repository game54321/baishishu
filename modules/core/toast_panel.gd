extends CanvasLayer
## 全局 Toast 弹出提示组件（Autoload 单例）
## 通过全局 ToastManager 调用，例如 ToastManager.show_toast(message, type, duration)

enum ToastType { SUCCESS, INFO, WARNING, ERROR }

## 最大同时可见 Toast 数量
const MAX_VISIBLE := 5

## 动画持续时间（秒）
const FADE_IN_DURATION := 0.3
const FADE_OUT_DURATION := 0.3

## 每个 Toast 的固定宽度
const TOAST_WIDTH := 500.0
## 顶部起始 Y 偏移
const START_Y := 50.0
## 每个 Toast 的垂直间距
const TOAST_GAP := 50.0

## 当前活跃的 Toast 列表
var _active_toasts: Array[PanelContainer] = []

@onready var _container: Control = %Container


func _ready() -> void:
	process_priority = -999


## 显示 Toast 消息
func show_toast(message: String, type: ToastType = ToastType.SUCCESS, duration: float = 2.0) -> void:
	if message.is_empty():
		return

	# 超出最大数量时移除最早的消息
	while _active_toasts.size() >= MAX_VISIBLE:
		var oldest = _active_toasts.pop_front()
		if oldest and is_instance_valid(oldest):
			oldest.queue_free()

	var item := _create_toast_item(message, type, duration)
	if item:
		_container.add_child(item)
		_active_toasts.append(item)
		_reposition_toasts()


func _create_toast_item(message: String, type: ToastType, duration: float) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var style := StyleBoxFlat.new()
	match type:
		ToastType.SUCCESS:
			style.bg_color = Color(0.04, 0.12, 0.04, 0.95)
			style.border_color = Color(0.3, 0.85, 0.3, 0.8)
		ToastType.INFO:
			style.bg_color = Color(0.06, 0.06, 0.06, 0.95)
			style.border_color = Color(0.7, 0.7, 0.7, 0.5)
		ToastType.WARNING:
			style.bg_color = Color(0.12, 0.10, 0.02, 0.95)
			style.border_color = Color(0.9, 0.8, 0.2, 0.8)
		ToastType.ERROR:
			style.bg_color = Color(0.14, 0.03, 0.03, 0.95)
			style.border_color = Color(0.9, 0.2, 0.2, 0.8)

	style.border_width_bottom = 1
	style.border_width_top = 1
	style.border_width_left = 1
	style.border_width_right = 1
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", style)

	# 创建图标
	var icon_label := Label.new()
	icon_label.add_theme_font_size_override("font_size", 18)
	match type:
		ToastType.SUCCESS:
			icon_label.text = "成功 "
		ToastType.INFO:
			icon_label.text = "提示 "
		ToastType.WARNING:
			icon_label.text = "警告 "
		ToastType.ERROR:
			icon_label.text = "失败 "

	# 创建文本
	var text_label := Label.new()
	text_label.text = message
	text_label.add_theme_font_size_override("font_size", 15)
	text_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1.0))
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# 水平排列图标+文本
	var hbox := HBoxContainer.new()
	hbox.add_child(icon_label)
	hbox.add_child(text_label)
	panel.add_child(hbox)

	# 设置最小宽度和初始位置（正上方居中）
	panel.custom_minimum_size.x = TOAST_WIDTH
	panel.position = Vector2(
		(_container.size.x - TOAST_WIDTH) / 2.0,
		START_Y
	)

	# 初始不可见
	panel.modulate = Color(1, 1, 1, 0)

	# 动画序列: 淡入 -> 停留 -> 淡出 -> 删除
	var tween := create_tween().set_parallel(false)
	tween.tween_property(panel, "modulate", Color(1, 1, 1, 1), FADE_IN_DURATION).set_ease(Tween.EASE_OUT)
	tween.tween_interval(duration)
	tween.tween_property(panel, "modulate", Color(1, 1, 1, 0), FADE_OUT_DURATION).set_ease(Tween.EASE_IN)
	tween.finished.connect(_on_toast_finished.bind(panel))

	return panel


func _on_toast_finished(panel: PanelContainer) -> void:
	if panel and is_instance_valid(panel):
		_active_toasts.erase(panel)
		panel.queue_free()
		_reposition_toasts()


func _reposition_toasts() -> void:
	var container_center_x = _container.size.x / 2.0
	for i in _active_toasts.size():
		var toast = _active_toasts[i]
		if toast and is_instance_valid(toast):
			var tw := create_tween()
			tw.tween_property(toast, "position", Vector2(
				container_center_x - TOAST_WIDTH / 2.0,
				START_Y + i * TOAST_GAP
			), 0.2).set_ease(Tween.EASE_OUT)
