extends Control
## 章节结算面板：击败Boss后弹出

signal confirmed

@onready var chapter_label: Label = %ChapterLabel
@onready var desc_label: Label = %DescLabel
@onready var btn_confirm: Button = %BtnConfirm


func _ready() -> void:
	_setup_panel_style()
	_setup_button()
	visible = false


func show_panel(chapter_name: String, description: String, is_final: bool = false) -> void:
	chapter_label.text = chapter_name
	desc_label.text = description
	if is_final:
		btn_confirm.text = "通关！"

	visible = true


func hide_panel() -> void:
	visible = false


func _setup_panel_style() -> void:
	var panel_node: PanelContainer = $Panel
	if panel_node:
		UITheme.apply_panel(panel_node)


func _setup_button() -> void:
	if btn_confirm:
		UITheme.style_btn_primary(btn_confirm)
		btn_confirm.pressed.connect(_on_confirm)


func _on_confirm() -> void:
	hide_panel()
	confirmed.emit()
