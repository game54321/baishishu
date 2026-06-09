extends Control
## 商店面板：花银两购买物品

signal confirmed

const SHOPS_PATH := "res://data/shops.json"

var _shops: Array = []
var _current_shop: Dictionary = {}
var _bought: Dictionary = {}  # item index -> bool

@onready var title_label: Label = %TitleLabel
@onready var silver_label: Label = $Panel/Margin/VBox/SilverLabel
@onready var items_container: VBoxContainer = %ItemsContainer
@onready var btn_leave: Button = %BtnLeave

var _card_inventory_panel = null


func _ready() -> void:
	_setup_panel_style()
	_setup_buttons()
	_load_shops()
	visible = false


func _load_shops() -> void:
	if not FileAccess.file_exists(SHOPS_PATH):
		return
	var file := FileAccess.open(SHOPS_PATH, FileAccess.READ)
	if not file:
		return
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		return
	_shops = json.data


func show_panel(inventory_panel = null) -> void:
	_card_inventory_panel = inventory_panel
	_bought.clear()
	if _shops.is_empty():
		visible = false
		return
	_current_shop = _shops[randi() % _shops.size()]
	title_label.text = _current_shop.get("name", "商店")
	_refresh_silver()
	_spawn_items()
	visible = true


func hide_panel() -> void:
	visible = false


func _get_silver() -> int:
	if not _card_inventory_panel:
		return 0
	for card in _card_inventory_panel.card_inventory:
		if card["id"] == "银两":
			return card["count"]
	return 0


func _get_item_price(item: Dictionary) -> int:
	var consume: Array = item.get("consumeCards", [])
	for c in consume:
		if c.get("type", "") == "银两":
			return c.get("count", 0)
	return 0


func _refresh_silver() -> void:
	if silver_label:
		silver_label.text = "当前银两：" + str(_get_silver())


func _spawn_items() -> void:
	for child in items_container.get_children():
		child.queue_free()

	var items: Array = _current_shop.get("items", [])
	var current_silver: int = _get_silver()
	for i in items.size():
		var item: Dictionary = items[i]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)

		var info := VBoxContainer.new()
		info.add_theme_constant_override("separation", 2)

		var name_label := Label.new()
		name_label.text = item.get("name", "???")
		name_label.add_theme_font_size_override("font_size", 18)
		info.add_child(name_label)

		var desc_label := Label.new()
		desc_label.text = item.get("desc", "")
		desc_label.add_theme_font_size_override("font_size", 13)
		desc_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		info.add_child(desc_label)

		row.add_child(info)

		var spacer := Control.new()
		spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(spacer)

		var price: int = _get_item_price(item)
		var price_label := Label.new()
		price_label.text = "银两×" + str(price)
		price_label.add_theme_font_size_override("font_size", 16)
		if current_silver >= price:
			price_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		else:
			price_label.add_theme_color_override("font_color", Color(0.5, 0.3, 0.3))
		row.add_child(price_label)

		var btn_buy := Button.new()
		btn_buy.text = "购买"
		btn_buy.custom_minimum_size = Vector2(70, 34)
		btn_buy.add_theme_font_size_override("font_size", 15)
		UITheme.style_btn_secondary(btn_buy)
		if current_silver < price:
			btn_buy.disabled = true
			btn_buy.modulate = Color(0.4, 0.4, 0.4, 0.5)
		btn_buy.pressed.connect(_on_buy_pressed.bind(i, btn_buy, row, price, price_label))
		row.add_child(btn_buy)

		items_container.add_child(row)


func _on_buy_pressed(index: int, btn: Button, row: HBoxContainer, price: int, price_label: Label) -> void:
	if _bought.has(index):
		return
	if _get_silver() < price:
		# 银两不足，闪烁提示
		if silver_label:
			silver_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
			await get_tree().create_timer(0.5).timeout
			silver_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 1))
		return

	# 购买成功，扣除银两
	for card in _card_inventory_panel.card_inventory:
		if card["id"] == "银两":
			card["count"] -= price

	_bought[index] = true
	btn.disabled = true
	btn.text = "已购"
	btn.modulate = Color(0.5, 0.5, 0.5, 0.7)
	row.modulate = Color(0.6, 0.6, 0.6, 0.7)
	_refresh_silver()

	# 购买后更新剩余商品的可购买状态
	_update_affordability()


func _update_affordability() -> void:
	var current_silver: int = _get_silver()
	var items: Array = _current_shop.get("items", [])
	for i in items_container.get_children().size():
		var child = items_container.get_child(i)
		if child is HBoxContainer:
			var btn = child.get_child(child.get_child_count() - 1)
			var price_label = child.get_child(child.get_child_count() - 2)
			if btn is Button and i < items.size():
				var price: int = _get_item_price(items[i])
				if current_silver < price and not btn.disabled:
					btn.disabled = true
					btn.modulate = Color(0.4, 0.4, 0.4, 0.5)
				if price_label is Label:
					if current_silver >= price:
						price_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
					else:
						price_label.add_theme_color_override("font_color", Color(0.5, 0.3, 0.3))


func get_bought_items() -> Array:
	var result: Array = []
	var items: Array = _current_shop.get("items", [])
	for index in _bought.keys():
		if index < items.size():
			result.append(items[index])
	return result


func _setup_panel_style() -> void:
	var panel_node: PanelContainer = $Panel
	if panel_node:
		UITheme.apply_panel(panel_node)


func _setup_buttons() -> void:
	if btn_leave:
		UITheme.style_btn_primary(btn_leave)
		btn_leave.pressed.connect(_on_leave)


func _on_leave() -> void:
	hide_panel()
	confirmed.emit()
