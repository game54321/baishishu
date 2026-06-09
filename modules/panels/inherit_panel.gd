extends Control
## 转世继承面板：玩家选择至多5张卡牌带入来世

signal confirmed(inherit_list: Array)
signal cancelled

const CardDisplayScene := preload("res://modules/core/card_display.tscn")
const MAX_INHERIT := 5

var _selected: Dictionary = {}  # key -> card_data (Dictionary)
var _card_data_map: Dictionary = {}  # key -> card_data
var _key_counter: int = 0


@onready var selected_label: Label = %SelectedLabel
@onready var card_grid: GridContainer = %CardGrid
@onready var btn_confirm: Button = %BtnConfirm
@onready var btn_cancel: Button = %BtnCancel


func _ready() -> void:
	_setup_panel_style()
	_setup_buttons()
	visible = false


func show_panel(inventory_panel) -> void:
	_selected.clear()
	_card_data_map.clear()
	_key_counter = 0
	_populate_cards(inventory_panel)
	_update_selected_label()
	visible = true


func hide_panel() -> void:
	visible = false


func get_selected_cards() -> Array:
	return _selected.values()


func _populate_cards(inventory_panel) -> void:
	for child in card_grid.get_children():
		child.queue_free()

	if not inventory_panel:
		return

	for card in inventory_panel.card_inventory:
		if card["category"] == "功法":
			for g in card["gongfa_list"]:
				var key := str(_key_counter)
				_key_counter += 1
				_card_data_map[key] = {
					"id": "功法",
					"name": g["name"],
					"icon": g["icon"],
					"color": card["color"],
					"gongfa_list": [{"id": g["id"], "name": g["name"], "level": g["level"], "exp": g["exp"], "max_exp": g["max_exp"], "base_damage": g["base_damage"]}],
				}
				var display: CardDisplay = CardDisplayScene.instantiate()
				display.setup(g["icon"], g["name"] + " " + inventory_panel.get_level_name(g["level"]), g["base_damage"], card["color"], false, "伤害")
				display.gui_input.connect(_on_card_input.bind(key, display))
				card_grid.add_child(display)
		elif card["category"] == "武道":
			var key := str(_key_counter)
			_key_counter += 1
			var realms: Array = card["realms"]
			var realm_name: String = realms[card["realm_index"]] if card["realm_index"] < realms.size() else realms[-1]
			var req: Array = card["realm_exp_required"]
			var max_exp: int = req[card["realm_index"]] if card["realm_index"] < req.size() else req[-1]
			_card_data_map[key] = {
				"id": "武道",
				"name": realm_name,
				"icon": card["icon"],
				"color": card["color"],
				"gongfa_list": [{"realm_index": card["realm_index"], "exp": card["exp"]}],
			}
			var display: CardDisplay = CardDisplayScene.instantiate()
			display.setup(card["icon"], realm_name, card["exp"], card["color"], false, "", str(card["exp"]) + "/" + str(max_exp))
			display.gui_input.connect(_on_card_input.bind(key, display))
			card_grid.add_child(display)
		else:
			if card["count"] > 0:
				var key := str(_key_counter)
				_key_counter += 1
				_card_data_map[key] = {
					"id": card["id"],
					"name": card["name"],
					"icon": card["icon"],
					"color": card["color"],
					"count": card["count"],
				}
				var display: CardDisplay = CardDisplayScene.instantiate()
				display.setup(card.get("icon_path", card["icon"]), card["name"], card["count"], card["color"], false, card.get("unit", ""))
				display.gui_input.connect(_on_card_input.bind(key, display))
				card_grid.add_child(display)


func _on_card_input(event: InputEvent, key: String, display: CardDisplay) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return

	if key in _selected:
		_selected.erase(key)
		_update_card_highlight(display, false)
	else:
		if _selected.size() >= MAX_INHERIT:
			return
		_selected[key] = _card_data_map[key]
		_update_card_highlight(display, true)

	_update_selected_label()


func _update_card_highlight(display: CardDisplay, selected: bool) -> void:
	var style := StyleBoxFlat.new()
	if selected:
		style.bg_color = Color(0.15, 0.15, 0.15, 0.95)
		style.border_color = Color(0.9, 0.9, 0.9, 0.8)
		style.border_width_bottom = 2
		style.border_width_top = 2
		style.border_width_left = 2
		style.border_width_right = 2
	else:
		style.bg_color = Color(0.08, 0.08, 0.08, 0.95)
		style.border_color = Color(0.4, 0.4, 0.4, 0.4)
		style.border_width_bottom = 1
		style.border_width_top = 1
		style.border_width_left = 1
		style.border_width_right = 1
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	style.content_margin_left = 10
	style.content_margin_right = 10
	display.add_theme_stylebox_override("panel", style)


func _update_selected_label() -> void:
	selected_label.text = "已选：" + str(_selected.size()) + " / " + str(MAX_INHERIT)


func _setup_panel_style() -> void:
	var panel_node: PanelContainer = $Panel
	if panel_node:
		UITheme.apply_panel(panel_node)


func _setup_buttons() -> void:
	if btn_confirm:
		UITheme.style_btn_primary(btn_confirm)
		btn_confirm.pressed.connect(_on_confirm)
	if btn_cancel:
		UITheme.style_btn_secondary(btn_cancel)
		btn_cancel.pressed.connect(_on_cancel)


func _on_confirm() -> void:
	hide_panel()
	confirmed.emit(get_selected_cards())


func _on_cancel() -> void:
	hide_panel()
	cancelled.emit()
