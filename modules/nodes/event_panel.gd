extends Control
## 奇遇面板：展示随机事件和选项

signal confirmed

const CardDisplayScene := preload("res://modules/core/card_display.tscn")
const EVENTS_PATH := "res://data/events.json"

var _events: Array = []
var _current_event: Dictionary = {}
var _pending_consume_cards: Array = []
var _pending_produce_cards: Array = []

@onready var title_label: Label = %TitleLabel
@onready var desc_label: RichTextLabel = %DescLabel
@onready var choices_container: VBoxContainer = %ChoicesContainer
@onready var result_label: RichTextLabel = %ResultLabel
@onready var btn_close: Button = %BtnClose


func _ready() -> void:
	_setup_panel_style()
	_setup_close_button()
	_load_events()
	visible = false


func _load_events() -> void:
	if not FileAccess.file_exists(EVENTS_PATH):
		return
	var file := FileAccess.open(EVENTS_PATH, FileAccess.READ)
	if not file:
		return
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		return
	_events = json.data


func show_panel() -> void:
	result_label.visible = false
	result_label.text = ""
	btn_close.visible = false

	if _events.is_empty():
		visible = false
		confirmed.emit()
		return

	# 随机选一个事件
	_current_event = _events[randi() % _events.size()]
	title_label.text = _current_event.get("name", "奇遇")
	desc_label.text = _current_event.get("description", "")
	_spawn_choices()
	visible = true


func hide_panel() -> void:
	visible = false


func get_consume_cards() -> Array:
	return _pending_consume_cards


func get_produce_cards() -> Array:
	return _pending_produce_cards


func _spawn_choices() -> void:
	for child in choices_container.get_children():
		child.queue_free()

	var choices: Array = _current_event.get("choices", [])
	for i in choices.size():
		var choice: Dictionary = choices[i]
		var btn := Button.new()
		btn.text = choice.get("text", "...")
		btn.custom_minimum_size = Vector2(0, 40)
		btn.add_theme_font_size_override("font_size", 16)
		_style_choice_button(btn)
		btn.pressed.connect(_on_choice_selected.bind(i))
		choices_container.add_child(btn)


func _on_choice_selected(index: int) -> void:
	var choices: Array = _current_event.get("choices", [])
	if index >= choices.size():
		return
	var choice: Dictionary = choices[index]

	# 禁用所有按钮
	for child in choices_container.get_children():
		if child is Button:
			child.disabled = true
			child.modulate = Color(0.5, 0.5, 0.5, 0.7)

	# 显示结果
	var result_text: String = choice.get("result", "")
	if result_text != "":
		result_label.text = result_text
		result_label.visible = true

	# 记录卡牌变化
	_pending_consume_cards = choice.get("consumeCards", [])
	_pending_produce_cards = choice.get("produceCards", [])

	btn_close.visible = true


func _style_choice_button(btn: Button) -> void:
	UITheme.style_list_item(btn)


func _setup_panel_style() -> void:
	var panel_node: PanelContainer = $Panel
	if panel_node:
		UITheme.apply_panel(panel_node)


func _setup_close_button() -> void:
	if not btn_close:
		return
	UITheme.style_btn_secondary(btn_close)
	btn_close.pressed.connect(_on_close)


func _on_close() -> void:
	hide_panel()
	confirmed.emit()
