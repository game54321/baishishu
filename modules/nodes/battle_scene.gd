extends Control
## 战斗场景：上方敌人卡牌，下方玩家手牌

signal battle_won
signal battle_lost
signal battle_fled

const CardDisplayScene := preload("res://modules/core/card_display.tscn")
const CharacterCardScene := preload("res://modules/core/character_card.tscn")
const CARD_TYPES_PATH := "res://data/card_types.json"

var _card_type_map: Dictionary = {}
var _card_inventory_panel = null

# 敌人数据
var _enemy_name: String = "山贼"
var _enemy_hp: int = 50
var _enemy_max_hp: int = 50
var _enemy_attack: int = 10
var _enemy_type: String = "男性凡人"

const PORTRAIT_BASE := "res://assets/立绘"
const GONGFA_ICON_BASE := "res://assets/功法插图"
const ENEMY_TYPES := {
	"山贼": "男性凡人",
	"匪首": "男性剑修",
	"魔教弟子": "男性法修",
	"护法": "男性体修",
	"女贼": "女性凡人",
	"女剑客": "女性剑修",
	"女修士": "女性法修",
	"女护法": "女性体修",
}

# 玩家数据
var _player_hp: int = 100
var _player_max_hp: int = 100
var _player_type: String = "男性凡人"

# 玩家手牌（功法卡列表）
var _hand: Array = []
var _turn: int = 1

@onready var enemy_card: CharacterCard = $Margin/VBox/EnemyCard
@onready var player_card: CharacterCard = $Margin/VBox/BottomSection/PlayerCard
@onready var hand_section: PanelContainer = $Margin/VBox/BottomSection/HandSection
@onready var hand_area: HBoxContainer = $Margin/VBox/BottomSection/HandSection/HandVBox/HandArea
@onready var turn_label: Label = $TurnLabel


func _ready() -> void:
	UITheme.apply_panel(enemy_card)
	UITheme.apply_panel(player_card)
	_card_type_map = _build_card_type_map()
	visible = false


func start_battle(inventory_panel, enemy_name: String = "山贼", enemy_hp: int = 50, enemy_attack: int = 10) -> void:
	_card_inventory_panel = inventory_panel
	_enemy_name = enemy_name
	_enemy_hp = enemy_hp
	_enemy_max_hp = enemy_hp
	_enemy_attack = enemy_attack
	_enemy_type = ENEMY_TYPES.get(enemy_name, "男性凡人")
	_turn = 1
	_player_hp = 100
	_player_max_hp = 100
	if _card_inventory_panel:
		for card in _card_inventory_panel.card_inventory:
			if card["category"] == "武道":
				_player_hp = 100 + card["realm_index"] * 20
				_player_max_hp = _player_hp
	_refresh_enemy_card()
	_load_portrait(player_card, _player_type, "待机")
	_refresh_player_info()
	_build_hand()
	visible = true


func _load_portrait(card: CharacterCard, char_type: String, state: String = "待机") -> void:
	var path := String("{0}/{1}/{2}.png").format({"0": PORTRAIT_BASE, "1": char_type, "2": state})
	if ResourceLoader.exists(path):
		card.portrait.texture = load(path)


func _show_hit_portrait(card: CharacterCard, char_type: String) -> void:
	var hit_state := "受击" if char_type != "男性凡人" else "受伤"
	_load_portrait(card, char_type, hit_state)
	await get_tree().create_timer(0.5).timeout
	_load_portrait(card, char_type, "待机")


func _show_damage_number(target: Control, damage: int, color: Color) -> void:
	var label := Label.new()
	label.text = "-" + str(damage)
	label.add_theme_font_size_override("font_size", 28)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.z_index = 100
	add_child(label)
	label.global_position = target.global_position + Vector2(target.size.x * 0.5 - 30, target.size.y * 0.3)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "global_position:y", label.global_position.y - 80, 0.8).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.8).set_delay(0.2)
	tween.set_parallel(false)
	tween.tween_callback(label.queue_free)


func _refresh_enemy_card() -> void:
	for child in enemy_card.card_area.get_children():
		child.queue_free()
	enemy_card.name_label.text = _enemy_name + "  ATK" + str(_enemy_attack)
	_load_portrait(enemy_card, _enemy_type, "待机")
	_update_hp_bar(enemy_card.hp_bar, _enemy_hp, _enemy_max_hp)
	enemy_card.hp_label.text = str(_enemy_hp) + " / " + str(_enemy_max_hp)


func _refresh_player_info() -> void:
	turn_label.text = "回合 " + str(_turn)
	player_card.hp_label.text = str(_player_hp) + "/" + str(_player_max_hp)
	_update_hp_bar(player_card.hp_bar, _player_hp, _player_max_hp)
	if _card_inventory_panel:
		player_card.name_label.text = _card_inventory_panel.get_wudao_realm()


func _update_hp_bar(bar: ColorRect, current: int, maximum: int) -> void:
	if not bar:
		return
	var ratio: float = clampf(float(current) / float(maximum), 0.0, 1.0)
	bar.anchor_right = ratio


func _build_hand() -> void:
	for child in hand_area.get_children():
		child.queue_free()
	_hand.clear()

	if not _card_inventory_panel:
		return

	for card in _card_inventory_panel.card_inventory:
		if card["category"] == "功法":
			var idx := 0
			for g in card["gongfa_list"]:
				_hand.append(g)
				var icon_path := String("{0}/sprite_{1}.png").format({"0": GONGFA_ICON_BASE, "1": "%03d" % (idx % 4)})
				var display: CardDisplay = CardDisplayScene.instantiate()
				display.setup(icon_path, g["name"] + " " + _card_inventory_panel.get_level_name(g["level"]), g["base_damage"], card["color"], false, "伤害")
				display.gui_input.connect(_on_card_clicked.bind(display, g))
				hand_area.add_child(display)
				display.size_flags_vertical = Control.SIZE_SHRINK_CENTER
				idx += 1


func _on_card_clicked(event: InputEvent, display: CardDisplay, g: Dictionary) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		for child in hand_area.get_children():
			child.gui_input.disconnect(_on_card_clicked)
		_fly_card_to_enemy(display, g)


func _fly_card_to_enemy(display: CardDisplay, g: Dictionary) -> void:
	var start_pos := display.global_position
	var start_size := display.size
	hand_area.remove_child(display)
	add_child(display)
	display.global_position = start_pos
	display.size = start_size
	display.pivot_offset = display.size * 0.5

	var target_pos := enemy_card.card_area.global_position + enemy_card.card_area.size * 0.5 - display.size * 0.5

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(display, "global_position", target_pos, 0.8).set_trans(Tween.TRANS_LINEAR)
	tween.tween_property(display, "rotation", deg_to_rad(720), 0.8).set_trans(Tween.TRANS_LINEAR)
	tween.set_parallel(false)
	tween.tween_callback(_on_card_arrived.bind(display, g))


func _on_card_arrived(display: CardDisplay, g: Dictionary) -> void:
	display.queue_free()
	_hand.erase(g)

	_enemy_hp = maxi(_enemy_hp - g["base_damage"], 0)
	_show_hit_portrait(enemy_card, _enemy_type)
	_show_damage_number(enemy_card, g["base_damage"], Color(1, 0.3, 0.3))
	g["exp"] += g["gain_exp"]
	while g["exp"] >= g["max_exp"]:
		g["exp"] -= g["max_exp"]
		g["level"] += 1
		g["max_exp"] = int(g["max_exp"] * 1.5)
		g["base_damage"] = int(g["base_damage"] * 1.3)
	if _card_inventory_panel:
		_card_inventory_panel._add_wudao_exp(g["gain_exp"])

	_refresh_enemy_card()
	_refresh_player_info()

	if _enemy_hp <= 0:
		_on_enemy_dead()
		return
	get_tree().create_timer(1.0).timeout.connect(_enemy_attack_player)


func _enemy_attack_player() -> void:
	var attack_card: CardDisplay = CardDisplayScene.instantiate()
	attack_card.setup("", _enemy_name + "攻击", _enemy_attack, Color(0.4, 0.2, 0.2), true, "伤害")
	enemy_card.card_area.add_child(attack_card)
	await get_tree().process_frame

	var start_pos := attack_card.global_position
	var start_size := attack_card.size
	enemy_card.card_area.remove_child(attack_card)
	add_child(attack_card)
	attack_card.global_position = start_pos
	attack_card.size = start_size
	attack_card.pivot_offset = attack_card.size * 0.5

	var target_pos := player_card.global_position + player_card.size * 0.5 - attack_card.size * 0.5

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(attack_card, "global_position", target_pos, 0.8).set_trans(Tween.TRANS_LINEAR)
	tween.tween_property(attack_card, "rotation", deg_to_rad(-720), 0.8).set_trans(Tween.TRANS_LINEAR)
	tween.set_parallel(false)
	tween.tween_callback(_on_enemy_card_arrived.bind(attack_card))


func _on_enemy_card_arrived(attack_card: CardDisplay) -> void:
	attack_card.queue_free()
	_player_hp = maxi(_player_hp - _enemy_attack, 0)
	_show_hit_portrait(player_card, _player_type)
	_show_damage_number(player_card, _enemy_attack, Color(1, 0.3, 0.3))
	_refresh_player_info()
	if _player_hp <= 0:
		_on_player_dead()
		return
	_turn += 1
	_refresh_player_info()
	_build_hand()


func _on_enemy_dead() -> void:
	visible = false
	battle_won.emit()


func _on_player_dead() -> void:
	visible = false
	battle_lost.emit()


func _build_card_type_map() -> Dictionary:
	var result: Dictionary = {}
	if not FileAccess.file_exists(CARD_TYPES_PATH):
		return result
	var file := FileAccess.open(CARD_TYPES_PATH, FileAccess.READ)
	if not file:
		return result
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		return result
	if not json.data is Array:
		return result
	for ct in json.data:
		result[ct.get("id", "")] = ct
	return result
