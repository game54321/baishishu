class_name CardDisplay
extends PanelContainer
## 资源卡牌展示组件

const CARD_TYPES_PATH := "res://data/card_types.json"

static var _card_type_cache: Dictionary = {}

@export var card_icon: String = "":
	set(v):
		card_icon = v
		_update()
@export var card_name: String = "":
	set(v):
		card_name = v
		_update()
@export var card_count: int = 0:
	set(v):
		card_count = v
		_update()
@export var card_color: Color = Color.WHITE:
	set(v):
		card_color = v
		_update()
@export var is_cost: bool = false:
	set(v):
		is_cost = v
		_update()
@export var count_unit: String = "":
	set(v):
		count_unit = v
		_update()
@export var count_text: String = "":
	set(v):
		count_text = v
		_update()

@onready var icon_rect: TextureRect = $VBox/IconRect
@onready var icon_label: Label = $VBox/IconLabel
@onready var name_label: Label = $VBox/NameLabel
@onready var count_label: Label = $VBox/CountLabel


static func _ensure_cache() -> void:
	if not _card_type_cache.is_empty():
		return
	if not FileAccess.file_exists(CARD_TYPES_PATH):
		return
	var file := FileAccess.open(CARD_TYPES_PATH, FileAccess.READ)
	if not file:
		return
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		return
	if not json.data is Array:
		return
	for ct in json.data:
		_card_type_cache[ct.get("id", "")] = ct


static func get_card_type_info(type_id: String) -> Dictionary:
	_ensure_cache()
	return _card_type_cache.get(type_id, {})


func _ready() -> void:
	_apply_card_style()
	_update()


func setup(p_icon: String, p_name: String, p_count: int, p_color: Color, p_is_cost: bool = false, p_unit: String = "", p_count_text: String = "") -> void:
	card_icon = p_icon
	card_name = p_name
	card_count = p_count
	card_color = p_color
	is_cost = p_is_cost
	count_unit = p_unit
	count_text = p_count_text


func setup_from_card(type_id: String, count: int, p_is_cost: bool = false, p_count_text: String = "") -> void:
	var info := get_card_type_info(type_id)
	if info.is_empty():
		setup("❓", type_id, count, Color.WHITE, p_is_cost, "", p_count_text)
		return

	var icon: String = info.get("icon_path", info.get("icon", "❓"))
	var name: String = info.get("name", type_id)
	var color := Color.from_string(info.get("color", "#FFFFFF"), Color.WHITE)
	var unit: String = info.get("unit", "")

	if type_id == "功法":
		icon = info.get("icon_path", info.get("icon", "👊"))

	setup(icon, name, count, color, p_is_cost, unit, p_count_text)


func _update() -> void:
	if not is_node_ready():
		return

	if icon_rect and icon_label:
		if card_icon != "" and ResourceLoader.exists(card_icon):
			icon_rect.texture = load(card_icon)
			icon_rect.visible = true
			icon_label.visible = false
		elif card_icon != "":
			icon_rect.visible = false
			icon_label.visible = true
			icon_label.text = card_icon
		else:
			icon_rect.visible = false
			icon_label.visible = false
	if name_label:
		name_label.text = card_name
	if count_label:
		if count_text != "":
			count_label.text = count_text
			count_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
		elif count_unit != "":
			count_label.text = count_unit + "x" + str(card_count)
			count_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
		elif card_count == 0:
			count_label.text = ""
		else:
			var sign := "+" if not is_cost else "-"
			count_label.text = sign + str(card_count)
			count_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	_apply_card_style()


func _apply_card_style() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.10, 0.10, 0.95)
	style.border_color = Color(0.35, 0.35, 0.35, 0.4)
	style.border_width_bottom = 1
	style.border_width_top = 1
	style.border_width_left = 1
	style.border_width_right = 1
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	style.content_margin_left = 8
	style.content_margin_right = 8
	add_theme_stylebox_override("panel", style)
