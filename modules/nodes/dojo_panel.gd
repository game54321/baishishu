class_name DojoPanel
extends Control
## 武馆学武面板

signal confirmed
signal skipped
signal cancelled

const CardDisplayScene := preload("res://modules/core/card_display.tscn")

var _current_consume: Array = []
var _current_produce: Array = []
var _confirm_count: int = 0


func _ready() -> void:
	_setup_panel_style()
	_setup_buttons()
	visible = false


func show_panel(dojo_name: String = "", produce_cards: Array = [], consume_cards: Array = []) -> void:
	if dojo_name != "":
		var title_label: Label = $Panel/Margin/VBox/TopRow/Header/TitleLabel
		if title_label:
			title_label.text = dojo_name
	_current_consume = consume_cards
	_current_produce = produce_cards
	_confirm_count = 0
	_clear_cards()
	_spawn_cards(consume_cards, produce_cards)
	if %ResultLabel:
		%ResultLabel.text = ""
	visible = true


func hide_panel() -> void:
	visible = false


func _clear_cards() -> void:
	var cost_container: HBoxContainer = %CostCards
	var reward_container: HBoxContainer = %RewardCards
	if cost_container:
		for child in cost_container.get_children():
			child.queue_free()
	if reward_container:
		for child in reward_container.get_children():
			child.queue_free()


func _spawn_cards(consume_cards: Array, produce_cards: Array) -> void:
	var cost_container: HBoxContainer = %CostCards
	var reward_container: HBoxContainer = %RewardCards

	if cost_container:
		for c in consume_cards:
			var card: CardDisplay = CardDisplayScene.instantiate()
			if c.get("type", "") == "功法":
				_setup_gongfa_card(card, c, true)
			else:
				card.setup_from_card(c.get("type", ""), c.get("count", 0), true)
			cost_container.add_child(card)

	if reward_container:
		for c in produce_cards:
			var card: CardDisplay = CardDisplayScene.instantiate()
			if c.get("type", "") == "功法":
				_setup_gongfa_card(card, c, false)
			else:
				card.setup_from_card(c.get("type", ""), c.get("count", 0), false)
			reward_container.add_child(card)


func _setup_gongfa_card(card: CardDisplay, c: Dictionary, p_is_cost: bool) -> void:
	var info := CardDisplay.get_card_type_info("功法")
	var gongfa_name: String = "功法"
	var gongfa_id: String = c.get("gongfaId", "")
	if gongfa_id != "":
		for g in info.get("gongfaList", []):
			if g.get("id", "") == gongfa_id:
				gongfa_name = g.get("name", "功法")
				break
	var color := Color.from_string(info.get("color", "#D97333"), Color(0.85, 0.45, 0.2))
	card.setup(info.get("icon", "👊"), gongfa_name, c.get("gainExp", 0), color, p_is_cost)


func _setup_panel_style() -> void:
	var panel_node: PanelContainer = $Panel
	if panel_node:
		UITheme.apply_panel(panel_node)


func _setup_buttons() -> void:
	if %BtnConfirm:
		UITheme.style_btn_primary(%BtnConfirm)
		%BtnConfirm.pressed.connect(_on_confirm)
	if %BtnSkip:
		UITheme.style_btn_secondary(%BtnSkip)
		%BtnSkip.pressed.connect(_on_skip)
	if %BtnClose:
		UITheme.style_btn_close(%BtnClose)
		%BtnClose.pressed.connect(_on_cancel)


func _on_confirm() -> void:
	_confirm_count += 1

	var parts: Array[String] = []
	for c in _current_consume:
		var info := CardDisplay.get_card_type_info(c.get("type", ""))
		var name: String = info.get("name", c.get("type", ""))
		parts.append(String("{name}×{count}").format({"name": name, "count": c.get("count", 0)}))
	var cost_text: String = "消耗: " + ", ".join(parts) if not parts.is_empty() else ""

	parts.clear()
	for c in _current_produce:
		if str(c.get("type", "")) == "功法":
			var gongfa_info := CardDisplay.get_card_type_info("功法")
			var gongfa_name: String = "功法"
			for g in gongfa_info.get("gongfaList", []):
				if g.get("id", "") == c.get("gongfaId", ""):
					gongfa_name = g.get("name", "功法")
					break
			parts.append(String("{name} +{exp}经验").format({"name": gongfa_name, "exp": c.get("gainExp", 0)}))
		else:
			var info := CardDisplay.get_card_type_info(c.get("type", ""))
			var name: String = info.get("name", c.get("type", ""))
			parts.append(String("{name}×{count}").format({"name": name, "count": c.get("count", 0)}))
	var gain_text: String = "  |  获得: " + ", ".join(parts) if not parts.is_empty() else ""

	var toast_text := cost_text + gain_text + "  (第" + str(_confirm_count) + "次)"
	ToastManager.show_toast(toast_text, ToastManager.ToastType.SUCCESS)

	confirmed.emit()


func _on_skip() -> void:
	hide_panel()
	skipped.emit()


func _on_cancel() -> void:
	hide_panel()
	cancelled.emit()
