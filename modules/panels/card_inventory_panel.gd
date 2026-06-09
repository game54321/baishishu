extends Control
## 卡牌仓库面板：展示玩家当前拥有的所有卡牌

signal closed

const CardDisplayScene := preload("res://modules/core/card_display.tscn")

# 卡牌分类排序
const CATEGORY_ORDER := ["生命", "货币", "武道", "功法"]

const CARD_TYPES_PATH := "res://data/card_types.json"

# 所有卡牌放在一个列表里，普通卡有count，功法卡count永远为1，内含gongfa_list
var card_inventory: Array = []

@onready var overlay: ColorRect = $Overlay
@onready var panel: PanelContainer = $Panel
@onready var btn_close: Button = $Panel/VBox/TitleBar/BtnClose
@onready var card_grid: GridContainer = $Panel/VBox/ScrollContainer/CardGrid


func _ready() -> void:
	btn_close.pressed.connect(_on_close_pressed)
	overlay.gui_input.connect(_on_overlay_input)
	_apply_panel_style()
	_init_inventory_from_json()


func _init_inventory_from_json() -> void:
	if not FileAccess.file_exists(CARD_TYPES_PATH):
		return
	var file := FileAccess.open(CARD_TYPES_PATH, FileAccess.READ)
	if not file:
		return
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		return
	var data: Array = json.data
	for card_def in data:
		var entry: Dictionary = {
			"id": card_def.get("id", ""),
			"name": card_def.get("name", ""),
			"icon": card_def.get("icon", "❓"),
			"icon_path": card_def.get("icon_path", ""),
			"color": Color.from_string(card_def.get("color", "#FFFFFF"), Color.WHITE),
			"category": _category_cn(card_def.get("category", "")),
			"count": 0,
			"unit": card_def.get("unit", ""),
		}
		if card_def.get("category", "") == "gongfa":
			entry["count"] = 1
			entry["gongfa_list"] = []  # 空的，获得功法时才添加
			entry["gongfa_defs"] = {}   # 功法定义缓存，用于获得时查表
			entry["level_names"] = card_def.get("levelNames", ["初学乍练", "略有小成", "驾轻就熟", "融会贯通", "炉火纯青", "登峰造极", "返璞归真"])
			for g in card_def.get("gongfaList", []):
				entry["gongfa_defs"][g.get("id", "")] = {
					"id": g.get("id", ""),
					"name": g.get("name", ""),
					"icon": g.get("icon", "👊"),
					"base_damage": g.get("baseDamage", 10),
					"gain_exp": g.get("gainExp", 30),
				}
		elif card_def.get("category", "") == "wudao":
			entry["count"] = 1
			entry["realms"] = card_def.get("realms", [])
			entry["realm_exp_required"] = card_def.get("realmExpRequired", [])
			entry["realm_index"] = 0
			entry["exp"] = 0
		card_inventory.append(entry)
	# 初始默认值
	for card in card_inventory:
		if card["id"] == "寿元":
			card["count"] = 75
		elif card["id"] == "银两":
			card["count"] = 30
	add_gongfa("wild-dog-fist")


func _category_cn(cat: String) -> String:
	var map := { "life": "生命", "currency": "货币", "gongfa": "功法", "wudao": "武道" }
	return map.get(cat, cat)


func get_level_name(level: int) -> String:
	for card in card_inventory:
		if card["category"] == "功法":
			var names: Array = card.get("level_names", [])
			if names.size() == 0:
				return "Lv" + str(level)
			var idx: int = mini(level - 1, names.size() - 1)
			if idx >= 0:
				return names[idx]
			return names[0]
	return "Lv" + str(level)


func show_panel() -> void:
	_refresh_cards()
	visible = true


func hide_panel() -> void:
	visible = false


func add_card(card_id: String, count: int = 1) -> void:
	for card in card_inventory:
		if card["id"] == card_id:
			if card["category"] == "功法":
				# 功法卡重复获得只加经验
				for g in card["gongfa_list"]:
					g["exp"] += g["gain_exp"]
					while g["exp"] >= g["max_exp"]:
						g["exp"] -= g["max_exp"]
						g["level"] += 1
						g["max_exp"] = int(g["max_exp"] * 1.5)
						g["base_damage"] = int(g["base_damage"] * 1.3)
			else:
				card["count"] += count
			return
	# 新卡
	card_inventory.append({ "id": card_id, "name": card_id, "icon": "❓", "count": count, "color": Color(0.5, 0.5, 0.5), "category": "其他" })


func remove_card(card_id: String, count: int = 1) -> bool:
	for card in card_inventory:
		if card["id"] == card_id:
			if card["count"] < count:
				return false
			card["count"] -= count
			return true
	return false


func add_gongfa(gongfa_id: String) -> void:
	for card in card_inventory:
		if card["category"] == "功法":
			# 检查是否已有该功法
			for g in card["gongfa_list"]:
				if g["id"] == gongfa_id:
					# 已有，只加经验
					g["exp"] += g["gain_exp"]
					while g["exp"] >= g["max_exp"]:
						g["exp"] -= g["max_exp"]
						g["level"] += 1
						g["max_exp"] = int(g["max_exp"] * 1.5)
						g["base_damage"] = int(g["base_damage"] * 1.3)
					_add_wudao_exp(g["gain_exp"])
					return
			# 没有，从定义中查表创建
			var def: Dictionary = card["gongfa_defs"].get(gongfa_id, {})
			if def.is_empty():
				return
			card["gongfa_list"].append({
				"id": def["id"],
				"name": def["name"],
				"icon": def["icon"],
				"level": 1,
				"exp": 0,
				"max_exp": 100,
				"base_damage": def["base_damage"],
				"gain_exp": def["gain_exp"],
			})
			_add_wudao_exp(def["gain_exp"])
			return


func add_gongfa_exp(gongfa_id: String, exp: int) -> void:
	for card in card_inventory:
		if card["category"] == "功法":
			for g in card["gongfa_list"]:
				if g["id"] == gongfa_id:
					g["exp"] += exp
					while g["exp"] >= g["max_exp"]:
						g["exp"] -= g["max_exp"]
						g["level"] += 1
						g["max_exp"] = int(g["max_exp"] * 1.5)
						g["base_damage"] = int(g["base_damage"] * 1.3)
					# 同时提升武道境界经验
					_add_wudao_exp(exp)
					return


func get_gongfa_damage(gongfa_id: String) -> int:
	for card in card_inventory:
		if card["category"] == "功法":
			for g in card["gongfa_list"]:
				if g["id"] == gongfa_id:
					return g["base_damage"]
	return 0


func _add_wudao_exp(exp: int) -> void:
	for card in card_inventory:
		if card["category"] == "武道":
			card["exp"] += exp
			var req: Array = card["realm_exp_required"]
			while card["realm_index"] < req.size() and card["exp"] >= req[card["realm_index"]]:
				card["exp"] -= req[card["realm_index"]]
				card["realm_index"] += 1
			return


func get_wudao_realm() -> String:
	for card in card_inventory:
		if card["category"] == "武道":
			var realms: Array = card["realms"]
			var idx: int = card["realm_index"]
			if idx < realms.size():
				return realms[idx]
			return realms[-1]
	return "普通人"


func _refresh_cards() -> void:
	for child in card_grid.get_children():
		child.queue_free()

	# 按 category 排序
	var sorted := []
	for cat in CATEGORY_ORDER:
		for card in card_inventory:
			if card["category"] == cat:
				sorted.append(card)

	for card in sorted:
		if card["category"] == "功法":
			for g in card["gongfa_list"]:
				var display: CardDisplay = CardDisplayScene.instantiate()
				card_grid.add_child(display)
				display.setup(g["icon"], g["name"] + " " + get_level_name(g["level"]), g["exp"], card["color"], false)
		elif card["category"] == "武道":
			var display: CardDisplay = CardDisplayScene.instantiate()
			card_grid.add_child(display)
			var realms: Array = card["realms"]
			var realm_name: String = realms[card["realm_index"]] if card["realm_index"] < realms.size() else realms[-1]
			var req: Array = card["realm_exp_required"]
			var max_exp: int = req[card["realm_index"]] if card["realm_index"] < req.size() else req[-1]
			display.setup(card["icon"], realm_name, card["exp"], card["color"], false, "", str(card["exp"]) + "/" + str(max_exp))
		else:
			var display: CardDisplay = CardDisplayScene.instantiate()
			card_grid.add_child(display)
			display.setup(card.get("icon_path", card["icon"]), card["name"], card["count"], card["color"], false, card.get("unit", ""))


func _on_close_pressed() -> void:
	hide_panel()
	closed.emit()


func _on_overlay_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		hide_panel()
		closed.emit()


func get_save_data() -> Dictionary:
	var result := {}
	for card in card_inventory:
		if card["category"] == "功法":
			var gongfa_arr := []
			for g in card["gongfa_list"]:
				gongfa_arr.append({
					"id": g["id"],
					"name": g["name"],
					"level": g["level"],
					"exp": g["exp"],
					"max_exp": g["max_exp"],
					"base_damage": g["base_damage"],
				})
			result["gongfa_list"] = gongfa_arr
		elif card["category"] == "武道":
			result["wudao"] = {
				"realm_index": card["realm_index"],
				"exp": card["exp"],
			}
		else:
			result[card["id"]] = card["count"]
	return result


func load_save_data(data: Dictionary) -> void:
	for card in card_inventory:
		if card["category"] == "功法":
			var gongfa_arr: Array = data.get("gongfa_list", [])
			card["gongfa_list"].clear()
			for g in gongfa_arr:
				var def: Dictionary = card["gongfa_defs"].get(g.get("id", ""), {})
				card["gongfa_list"].append({
					"id": g.get("id", ""),
					"name": g.get("name", "") if not g.get("name", "").is_empty() else (def.get("name", "") if not def.is_empty() else ""),
					"icon": def.get("icon", "👊") if not def.is_empty() else "👊",
					"level": g.get("level", 1),
					"exp": g.get("exp", 0),
					"max_exp": g.get("max_exp", 100),
					"base_damage": g.get("base_damage", 10),
					"gain_exp": def.get("gain_exp", 30) if not def.is_empty() else 30,
				})
		elif card["category"] == "武道":
			var wudao: Dictionary = data.get("wudao", {})
			card["realm_index"] = wudao.get("realm_index", 0)
			card["exp"] = wudao.get("exp", 0)
		else:
			if data.has(card["id"]):
				card["count"] = data[card["id"]]


func reset_inventory() -> void:
	card_inventory.clear()
	_init_inventory_from_json()


func inherit_cards(inherit_list: Array) -> void:
	for item in inherit_list:
		var card_id: String = item.get("id", "")
		if card_id == "功法":
			for g in item.get("gongfa_list", []):
				add_gongfa(g.get("id", ""))
		elif card_id == "武道":
			var wudao_data: Array = item.get("gongfa_list", [])
			if wudao_data.size() > 0:
				var w: Dictionary = wudao_data[0]
				for card in card_inventory:
					if card["category"] == "武道":
						card["realm_index"] = w.get("realm_index", 0)
						card["exp"] = w.get("exp", 0)
		else:
			add_card(card_id, item.get("count", 0))


func _apply_panel_style() -> void:
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.08, 0.08, 0.08, 0.95)
	bg.border_color = Color(0.5, 0.5, 0.5, 0.4)
	bg.border_width_bottom = 2
	bg.border_width_top = 2
	bg.border_width_left = 2
	bg.border_width_right = 2
	bg.corner_radius_top_left = 12
	bg.corner_radius_top_right = 12
	bg.corner_radius_bottom_left = 12
	bg.corner_radius_bottom_right = 12
	bg.content_margin_top = 20
	bg.content_margin_bottom = 20
	bg.content_margin_left = 24
	bg.content_margin_right = 24
	panel.add_theme_stylebox_override("panel", bg)
