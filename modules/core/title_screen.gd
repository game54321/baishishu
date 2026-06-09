extends Control
## 游戏开始界面

const MAP_VIEW_PATH := "res://modules/map/map_view.tscn"
const BG_PATH := "res://assets/ui/title/bg.png"

@onready var bg_rect: TextureRect = $BgRect
@onready var btn_start: TextureButton = $VBox/BtnStart
@onready var btn_continue: TextureButton = $VBox/BtnContinue
@onready var anim_player: AnimationPlayer = $AnimPlayer


func _ready() -> void:
	# 加载背景图
	if ResourceLoader.exists(BG_PATH):
		bg_rect.texture = load(BG_PATH)

	# 无存档时旧的回忆按钮置灰
	if not SaveManager.has_save():
		btn_continue.disabled = true
		btn_continue.modulate = Color(0.5, 0.5, 0.5, 0.6)

	btn_start.pressed.connect(_on_start_pressed)
	btn_continue.pressed.connect(_on_continue_pressed)

	# 播放入场动画，结束后切换到idle循环
	anim_player.play("entrance")
	anim_player.animation_finished.connect(_on_entrance_finished)


func _on_start_pressed() -> void:
	# 新游戏：删除旧存档
	SaveManager.delete_save()
	_switch_to_game()


func _on_continue_pressed() -> void:
	# 继续游戏：直接进入，map_view会自动加载存档
	_switch_to_game()


func _switch_to_game() -> void:
	get_tree().change_scene_to_file(MAP_VIEW_PATH)


func _on_entrance_finished(_anim_name: String) -> void:
	anim_player.play("idle")
