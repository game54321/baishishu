extends Control
## 章节预览面板
## 显示当前章节及后续两章的基本信息

signal closed

@onready var current_label: Label = %CurrentLabel
@onready var next_1_container: VBoxContainer = %Next1Container
@onready var next_2_container: VBoxContainer = %Next2Container
@onready var next_1_label: Label = %Next1Label
@onready var next_2_label: Label = %Next2Label
@onready var next_1_desc: Label = %Next1Desc
@onready var next_2_desc: Label = %Next2Desc
@onready var no_more_label: Label = %NoMoreLabel
@onready var btn_close: Button = %BtnClose


func _ready() -> void:
	btn_close.pressed.connect(_on_btn_close)


func show_panel(chapters: Array, chapter_index: int) -> void:
	visible = true

	# 当前章节
	if chapter_index < chapters.size():
		var cur = chapters[chapter_index]
		current_label.text = "当前 - " + cur.get("name", "未知章节")
	else:
		current_label.text = "当前 - 未知"

	# 后续两章
	var next_1_idx := chapter_index + 1
	var next_2_idx := chapter_index + 2

	if next_1_idx < chapters.size():
		var ch1 = chapters[next_1_idx]
		next_1_container.show()
		next_1_label.text = ch1.get("name", "未知章节")
		next_1_desc.text = ch1.get("description", "")
	else:
		next_1_container.hide()

	if next_2_idx < chapters.size():
		var ch2 = chapters[next_2_idx]
		next_2_container.show()
		next_2_label.text = ch2.get("name", "未知章节")
		next_2_desc.text = ch2.get("description", "")
	else:
		next_2_container.hide()

	# 没有后续章节时的提示
	if next_1_idx >= chapters.size():
		no_more_label.show()
	else:
		no_more_label.hide()


func hide_panel() -> void:
	visible = false
	closed.emit()


func _on_btn_close() -> void:
	hide_panel()
