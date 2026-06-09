extends Control
## 游戏开始界面

const MAP_VIEW_PATH := "res://modules/map/map_view.tscn"
const BG_PATH := "res://assets/chapter/1/bg.png"

@onready var bg_rect: TextureRect = $BgRect
@onready var btn_start: Button = $VBox/BtnStart
@onready var btn_continue: Button = $VBox/BtnContinue


func _ready() -> void:
	# 加载背景图
	if ResourceLoader.exists(BG_PATH):
		bg_rect.texture = load(BG_PATH)

	# 按钮样式
	_style_button(btn_start)
	_style_button(btn_continue)

	# 无存档时旧的回忆按钮置灰
	if not SaveManager.has_save():
		btn_continue.disabled = true
		btn_continue.modulate = Color(0.5, 0.5, 0.5, 0.6)

	btn_start.pressed.connect(_on_start_pressed)
	btn_continue.pressed.connect(_on_continue_pressed)


func _on_start_pressed() -> void:
	# 新游戏：删除旧存档
	SaveManager.delete_save()
	_switch_to_game()


func _on_continue_pressed() -> void:
	# 继续游戏：直接进入，map_view会自动加载存档
	_switch_to_game()


func _switch_to_game() -> void:
	get_tree().change_scene_to_file(MAP_VIEW_PATH)


func _style_button(btn: Button) -> void:
	var cs := StyleBoxFlat.new()
	cs.bg_color = Color(0.9, 0.9, 0.9, 1.0)
	cs.corner_radius_top_left = 4
	cs.corner_radius_top_right = 4
	cs.corner_radius_bottom_left = 4
	cs.corner_radius_bottom_right = 4
	cs.content_margin_top = 10
	cs.content_margin_bottom = 10
	cs.content_margin_left = 24
	cs.content_margin_right = 24
	btn.add_theme_stylebox_override("normal", cs)

	var cs_h := StyleBoxFlat.new()
	cs_h.bg_color = Color(1.0, 1.0, 1.0, 1.0)
	cs_h.corner_radius_top_left = 4
	cs_h.corner_radius_top_right = 4
	cs_h.corner_radius_bottom_left = 4
	cs_h.corner_radius_bottom_right = 4
	cs_h.content_margin_top = 10
	cs_h.content_margin_bottom = 10
	cs_h.content_margin_left = 24
	cs_h.content_margin_right = 24
	btn.add_theme_stylebox_override("hover", cs_h)

	btn.add_theme_color_override("font_color", Color(0.1, 0.1, 0.1, 1.0))
	btn.add_theme_color_override("font_hover_color", Color(0.0, 0.0, 0.0, 1.0))
	btn.add_theme_color_override("font_pressed_color", Color(0.3, 0.3, 0.3, 1.0))
