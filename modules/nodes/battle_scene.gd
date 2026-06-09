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
var _last_played_card_pos: Vector2 = Vector2.ZERO
var _battle_stats: Dictionary = {}

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
	_load_portrait(enemy_card, _enemy_type, "待机")
	_load_portrait(player_card, _player_type, "待机")
	_refresh_enemy_card()
	_refresh_player_info()
	enemy_card.hp_bar.color = Color(0.8, 0.2, 0.2)
	player_card.hp_bar.color = Color(0.2, 0.4, 0.8)
	_build_hand()
	_battle_stats = {
		"damage_dealt": 0,
		"damage_taken": 0,
		"turns": 1,
		"skills": {},
		"wudao_exp": 0,
		"result": "",
	}
	visible = true


func _load_portrait(card: CharacterCard, char_type: String, state: String = "待机") -> void:
	var path := String("{0}/{1}/{2}.png").format({"0": PORTRAIT_BASE, "1": char_type, "2": state})
	var tex := load(path)
	if tex:
		card.portrait.texture = tex


func _show_hit_portrait(card: CharacterCard, char_type: String) -> void:
	var hit_state := "受击" if char_type != "男性凡人" else "受伤"
	_load_portrait(card, char_type, hit_state)
	var timer := get_tree().create_timer(0.5)
	timer.timeout.connect(_restore_portrait.bind(card, char_type))


func _restore_portrait(card: CharacterCard, char_type: String) -> void:
	_load_portrait(card, char_type, "待机")


func _create_fly_card_visual(src: CardDisplay) -> Control:
	var box := Control.new()
	box.size = src.size

	var bg := ColorRect.new()
	bg.color = Color(0.10, 0.10, 0.10, 0.95)
	bg.position = Vector2.ZERO
	bg.size = src.size
	box.add_child(bg)

	if src.card_icon != "":
		var texture := load(src.card_icon)
		if texture:
			var tex := TextureRect.new()
			tex.texture = texture
			tex.expand_mode = 1
			tex.stretch_mode = 5
			tex.size = Vector2(src.size.x - 16, 60)
			tex.position = Vector2(8, 8)
			box.add_child(tex)
		else:
			var icon_lbl := Label.new()
			icon_lbl.text = src.card_icon
			icon_lbl.add_theme_font_size_override("font_size", 36)
			icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			icon_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			icon_lbl.size = Vector2(src.size.x, 60)
			icon_lbl.position = Vector2(0, 8)
			box.add_child(icon_lbl)

	var name_lbl := Label.new()
	name_lbl.text = src.card_name
	name_lbl.add_theme_font_size_override("font_size", 10)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_lbl.size = Vector2(src.size.x, 30)
	name_lbl.position = Vector2(0, 72)
	box.add_child(name_lbl)

	var count_lbl := Label.new()
	if src.count_text != "":
		count_lbl.text = src.count_text
	elif src.count_unit != "":
		count_lbl.text = src.count_unit + "x" + str(src.card_count)
	elif src.card_count != 0:
		count_lbl.text = ("+" if not src.is_cost else "-") + str(src.card_count)
	count_lbl.add_theme_font_size_override("font_size", 13)
	count_lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	count_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count_lbl.size = Vector2(src.size.x, 20)
	count_lbl.position = Vector2(0, src.size.y - 28)
	box.add_child(count_lbl)

	return box


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


func _shake_target(target: Control) -> void:
	var original_pos := target.position
	var shake_tween := create_tween()
	shake_tween.tween_property(target, "position", original_pos + Vector2(8, 0), 0.03)
	shake_tween.tween_property(target, "position", original_pos + Vector2(-6, 0), 0.03)
	shake_tween.tween_property(target, "position", original_pos + Vector2(4, 0), 0.03)
	shake_tween.tween_property(target, "position", original_pos + Vector2(-2, 0), 0.03)
	shake_tween.tween_property(target, "position", original_pos, 0.03)


func _show_hit_effect(target: Control, g: Dictionary = {}) -> void:
	# 震动
	_shake_target(target)

	# 红色闪光
	var flash := ColorRect.new()
	flash.color = Color(1, 0.15, 0.15, 0.35)
	flash.size = target.size
	flash.position = Vector2.ZERO
	flash.z_index = 95
	target.add_child(flash)
	var flash_tween := create_tween()
	flash_tween.tween_property(flash, "color:a", 0.0, 0.3)
	flash_tween.tween_callback(flash.queue_free)

	# 功法击中特效
	if g.is_empty():
		return
	var hit_path: String = g.get("hit_effect_path", g.get("icon_path", ""))
	if hit_path == "" or not load(hit_path):
		return

	var tex := TextureRect.new()
	tex.texture = load(hit_path)
	tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex.size = Vector2(80, 80)
	tex.pivot_offset = Vector2(40, 40)
	tex.modulate = Color(1, 1, 1, 0.9)
	tex.z_index = 90
	add_child(tex)

	var target_center := target.global_position + target.size * 0.5
	tex.global_position = target_center - tex.size * 0.5

	# 缩放弹出 + 旋转 + 淡出
	var hit_tween := create_tween()
	hit_tween.set_parallel(true)
	hit_tween.tween_property(tex, "scale", Vector2(1.5, 1.5), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	hit_tween.tween_property(tex, "rotation_degrees", randf_range(-20, 20), 0.3)
	hit_tween.tween_property(tex, "modulate:a", 0.0, 0.5).set_delay(0.1)
	hit_tween.set_parallel(false)
	hit_tween.tween_callback(tex.queue_free)


func _show_proficiency_gain(gain: int) -> void:
	var label := Label.new()
	label.text = "+" + str(gain) + " 熟练"
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))
	label.add_theme_color_override("font_shadow_color", Color(0, 0.3, 0, 0.8))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.z_index = 100
	add_child(label)
	label.global_position = _last_played_card_pos + Vector2(15, 20)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "global_position:y", label.global_position.y - 60, 0.9).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.9).set_delay(0.3)
	tween.set_parallel(false)
	tween.tween_callback(label.queue_free)


func _show_level_up_effect(skill_name: String, new_level: int) -> void:
	var level_name: String
	if _card_inventory_panel:
		level_name = _card_inventory_panel.get_level_name(new_level)
	else:
		level_name = "Lv" + str(new_level)

	var label := Label.new()
	label.text = skill_name + " → " + level_name + "!"
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.4))
	label.add_theme_color_override("font_shadow_color", Color(0.6, 0.4, 0, 0.9))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.z_index = 110
	add_child(label)
	label.global_position = _last_played_card_pos + Vector2(-20, -10)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "global_position:y", label.global_position.y - 50, 1.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.4).set_delay(0.6)
	tween.set_parallel(false)
	tween.tween_callback(label.queue_free)


func _refresh_enemy_card() -> void:
	for child in enemy_card.card_area.get_children():
		child.queue_free()
	enemy_card.name_label.text = _enemy_name + "  ATK" + str(_enemy_attack)
	_update_hp_bar(enemy_card.hp_bar, _enemy_hp, _enemy_max_hp)
	enemy_card.hp_label.text = str(_enemy_hp) + " / " + str(_enemy_max_hp)


func _apply_hit_to_target(card: CharacterCard, char_type: String, damage: int, g: Dictionary = {}) -> void:
	_show_hit_effect(card, g)
	_show_hit_portrait(card, char_type)
	_show_damage_number(card, damage, Color(1, 0.3, 0.3))


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
				var gongfa_icon: String = g.get("icon_path", "")
				if gongfa_icon == "" or not load(gongfa_icon):
					gongfa_icon = String("{0}/sprite_{1}.png").format({"0": GONGFA_ICON_BASE, "1": "%03d" % (idx % 4)})
				var prof_text := str(g["exp"]) + "/" + str(g["max_exp"])
				var display: CardDisplay = CardDisplayScene.instantiate()
				display.setup(gongfa_icon, g["name"] + " " + _card_inventory_panel.get_level_name(g["level"]), g["base_damage"], card["color"], false, "伤害", prof_text)
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
	_last_played_card_pos = start_pos
	display.modulate = Color(1, 1, 1, 0.3)

	var fly_size := display.size
	var copy := _create_fly_card_visual(display)
	add_child(copy)
	copy.position = start_pos
	copy.pivot_offset = fly_size * 0.5

	var target_pos := enemy_card.card_area.global_position + enemy_card.card_area.size * 0.5 - fly_size * 0.5

	var tween := create_tween()
	tween.tween_property(copy, "position", target_pos, 0.4).set_trans(Tween.TRANS_LINEAR)
	tween.tween_callback(_on_card_arrived.bind(copy, g))


func _on_card_arrived(display: Control, g: Dictionary) -> void:
	display.queue_free()
	_hand.erase(g)

	_enemy_hp = maxi(_enemy_hp - g["base_damage"], 0)
	_apply_hit_to_target(enemy_card, _enemy_type, g["base_damage"], g)
	_show_proficiency_gain(g["gain_exp"])
	var old_level: int = g["level"]
	g["exp"] += g["gain_exp"]
	while g["exp"] >= g["max_exp"]:
		g["exp"] -= g["max_exp"]
		g["level"] += 1
		g["max_exp"] = int(g["max_exp"] * 1.5)
		g["base_damage"] = int(g["base_damage"] * 1.3)
	if g["level"] > old_level:
		await get_tree().create_timer(0.5).timeout
		_show_level_up_effect(g["name"], g["level"])
	if _card_inventory_panel:
		_card_inventory_panel._add_wudao_exp(g["gain_exp"])

	_battle_stats["damage_dealt"] += g["base_damage"]
	var skill_id: String = g.get("id", "")
	if not _battle_stats["skills"].has(skill_id):
		_battle_stats["skills"][skill_id] = {"name": g["name"], "uses": 0, "exp_gained": 0, "level_ups": 0}
	_battle_stats["skills"][skill_id]["uses"] += 1
	_battle_stats["skills"][skill_id]["exp_gained"] += g["gain_exp"]
	if g["level"] > old_level:
		_battle_stats["skills"][skill_id]["level_ups"] += g["level"] - old_level
	_battle_stats["wudao_exp"] += g["gain_exp"]

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
	var fly_visual := _create_fly_card_visual(attack_card)
	attack_card.queue_free()
	add_child(fly_visual)
	fly_visual.position = start_pos
	fly_visual.pivot_offset = start_size * 0.5

	var target_pos := player_card.global_position + player_card.size * 0.5 - start_size * 0.5

	var tween := create_tween()
	tween.tween_property(fly_visual, "position", target_pos, 0.4).set_trans(Tween.TRANS_LINEAR)
	tween.tween_callback(_on_enemy_card_arrived.bind(fly_visual))


func _on_enemy_card_arrived(attack_card: Control) -> void:
	attack_card.queue_free()
	_player_hp = maxi(_player_hp - _enemy_attack, 0)
	_battle_stats["damage_taken"] += _enemy_attack
	_apply_hit_to_target(player_card, _player_type, _enemy_attack)
	_refresh_player_info()
	if _player_hp <= 0:
		_on_player_dead()
		return
	_turn += 1
	_battle_stats["turns"] = _turn
	_refresh_player_info()
	_build_hand()


func _on_enemy_dead() -> void:
	_battle_stats["result"] = "win"
	_battle_stats["turns"] = _turn
	_show_settlement_panel()


func _on_player_dead() -> void:
	_battle_stats["result"] = "lose"
	_battle_stats["turns"] = _turn
	_show_settlement_panel()


func _show_settlement_panel() -> void:
	var is_win: bool = _battle_stats["result"] == "win"

	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.7)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 200
	add_child(overlay)

	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.08, 0.95)
	style.border_color = Color(0.5, 0.5, 0.5, 0.4)
	style.border_width_bottom = 2
	style.border_width_top = 2
	style.border_width_left = 2
	style.border_width_right = 2
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.content_margin_top = 20
	style.content_margin_bottom = 20
	style.content_margin_left = 24
	style.content_margin_right = 24
	panel.add_theme_stylebox_override("panel", style)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel.z_index = 201
	add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "胜利" if is_win else "战败"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(1, 0.85, 0.2) if is_win else Color(0.8, 0.2, 0.2))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var sep := ColorRect.new()
	sep.color = Color(0.5, 0.5, 0.5, 0.3)
	sep.custom_minimum_size = Vector2(0, 1)
	vbox.add_child(sep)

	var info := Label.new()
	info.text = "敌人: " + _enemy_name + "    回合: " + str(_battle_stats["turns"])
	info.add_theme_font_size_override("font_size", 14)
	info.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(info)

	var dmg := Label.new()
	dmg.text = "造成伤害: " + str(_battle_stats["damage_dealt"]) + "    承受伤害: " + str(_battle_stats["damage_taken"])
	dmg.add_theme_font_size_override("font_size", 13)
	dmg.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	dmg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(dmg)

	var skills: Dictionary = _battle_stats["skills"]
	if not skills.is_empty():
		var sep2 := ColorRect.new()
		sep2.color = Color(0.5, 0.5, 0.5, 0.2)
		sep2.custom_minimum_size = Vector2(0, 1)
		vbox.add_child(sep2)

		var skill_title := Label.new()
		skill_title.text = "功法熟练度"
		skill_title.add_theme_font_size_override("font_size", 15)
		skill_title.add_theme_color_override("font_color", Color(0.9, 0.8, 0.4))
		skill_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(skill_title)

		for skill_id in skills:
			var s: Dictionary = skills[skill_id]
			var line := Label.new()
			var text: String = s["name"] + "  x" + str(s["uses"]) + "  熟练+" + str(s["exp_gained"])
			if s["level_ups"] > 0:
				text += "  ↑升级!"
			line.text = text
			line.add_theme_font_size_override("font_size", 13)
			line.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5) if s["level_ups"] > 0 else Color(0.85, 0.85, 0.85))
			line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			vbox.add_child(line)

	if _battle_stats["wudao_exp"] > 0:
		var wudao := Label.new()
		wudao.text = "武道经验 +" + str(_battle_stats["wudao_exp"])
		wudao.add_theme_font_size_override("font_size", 14)
		wudao.add_theme_color_override("font_color", Color(0.8, 0.7, 0.3))
		wudao.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(wudao)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	vbox.add_child(spacer)

	var btn := Button.new()
	btn.text = "确认"
	btn.custom_minimum_size = Vector2(120, 36)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.pressed.connect(_on_settlement_confirm.bind(overlay, panel))
	vbox.add_child(btn)


func _on_settlement_confirm(overlay: ColorRect, panel: PanelContainer) -> void:
	overlay.queue_free()
	panel.queue_free()
	visible = false
	if _battle_stats["result"] == "win":
		battle_won.emit()
	else:
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
