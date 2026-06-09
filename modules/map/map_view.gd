extends Control
## 网状关卡选择图主界面

const MapNodeScene := preload("res://modules/map/map_node.tscn")

var _map_data: Dictionary = {}
var _node_instances: Dictionary = {}  # id -> MapNode
var _current_node_id: String = ""
var _visited_ids: Dictionary = {}  # id -> bool

# 连线数据: [{ from: Vector2, to: Vector2, from_id: String, to_id: String }]
var _line_data: Array = []
var _pending_node: MapNode = null
var _pending_consume_cards: Array = []
var _pending_produce_cards: Array = []
var _life_number: int = 1
var _center_offset_x: float = 0.0
var _chapter_index: int = 0
var _chapters: Array = []




@onready var bg_rect: TextureRect = $BgRect
@onready var scroll_container: ScrollContainer = $ScrollContainer
@onready var map_container: Control = $ScrollContainer/MapContainer
@onready var btn_settings: Button = $UI/SysButtons/BtnSettings
@onready var btn_save: Button = $UI/SysButtons/BtnSave
@onready var btn_card_inventory: Button = $UI/SysButtons/BtnCardInventory
@onready var btn_reincarnate: Button = $UI/SysButtons/BtnReincarnate
@onready var btn_chapter_preview: Button = $UI/SysButtons/BtnChapterPreview
@onready var life_label: Label = $UI/LifeLabel
@onready var dojo_panel: DojoPanel = $DojoPanel
@onready var card_inventory_panel = $CardInventoryPanel
@onready var work_panel = $WorkPanel
@onready var battle_scene = $BattleScene
@onready var inherit_panel = $InheritPanel
@onready var chapter_clear_panel = $ChapterClearPanel
@onready var event_panel = $EventPanel
@onready var shop_panel = $ShopPanel
@onready var chapter_preview_panel = $ChapterPreviewPanel

# 布局参数
var _node_size: float = 64.0
var _floor_spacing: float = 100.0
var _node_spacing: float = 120.0
var _margin_x: float = 80.0
var _margin_bottom: float = 60.0


func _ready() -> void:
	map_container.map_view = self
	btn_settings.pressed.connect(_on_settings_pressed)
	btn_save.pressed.connect(_on_save_pressed)
	btn_card_inventory.pressed.connect(_on_card_inventory_pressed)
	btn_reincarnate.pressed.connect(_on_reincarnate_pressed)
	btn_chapter_preview.pressed.connect(_on_chapter_preview_pressed)
	dojo_panel.confirmed.connect(_on_dojo_confirmed)
	dojo_panel.skipped.connect(_on_dojo_skipped)
	dojo_panel.cancelled.connect(_on_dojo_cancelled)
	work_panel.confirmed.connect(_on_work_confirmed)
	work_panel.skipped.connect(_on_work_skipped)
	work_panel.cancelled.connect(_on_work_cancelled)
	battle_scene.battle_won.connect(_on_battle_won)
	battle_scene.battle_lost.connect(_on_battle_lost)
	battle_scene.battle_fled.connect(_on_battle_fled)
	card_inventory_panel.closed.connect(_on_card_inventory_closed)
	inherit_panel.confirmed.connect(_on_inherit_confirmed)
	inherit_panel.cancelled.connect(_on_inherit_cancelled)
	chapter_clear_panel.confirmed.connect(_on_chapter_confirmed)
	event_panel.confirmed.connect(_on_event_confirmed)
	shop_panel.confirmed.connect(_on_shop_confirmed)
	_load_chapters()
	_update_life_label()


func _load_chapters() -> void:
	var path := "res://data/chapters.json"
	if not FileAccess.file_exists(path):
		_chapters = []
		_load_map()
		return
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		_chapters = []
		_load_map()
		return
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		_chapters = []
		_load_map()
		return
	_chapters = json.data
	_load_map()


func _load_map() -> void:
	var loader := MapLoader.new()
	var restore_data: Dictionary = {}

	# 检查存档，先恢复章节索引
	if SaveManager.has_save():
		var save_data := SaveManager.load_game()
		if not save_data.is_empty():
			restore_data = save_data
			_chapter_index = save_data.get("chapter_index", 0)

	# 从当前章节加载地图数据
	var map_data_raw: Dictionary = {}
	if _chapters.size() > 0 and _chapter_index < _chapters.size():
		map_data_raw = _chapters[_chapter_index].get("map", {})

	# 加载章节背景图
	_update_chapter_bg()

	if not map_data_raw.is_empty():
		_map_data = loader._parse_raw_map(map_data_raw)
		if not _map_data.is_empty():
			_setup_from_data(restore_data)


func _setup_from_data(restore_data: Dictionary = {}) -> void:
	await _resize_container()
	_create_node_instances()
	_build_line_data()

	if restore_data.is_empty():
		_current_node_id = _map_data.start_id
		_visited_ids[_current_node_id] = true
	else:
		_apply_save_data(restore_data)

	_update_reachability()
	map_container.queue_redraw()

	await get_tree().process_frame
	scroll_container.scroll_vertical = 99999


func _resize_container() -> void:
	var min_y: float = INF
	var max_y: float = -INF
	var min_x: float = INF
	var max_x: float = -INF

	var all_nodes: Dictionary = _map_data.all_nodes
	for id in all_nodes:
		var node_data: MapLoader.MapNodeData = all_nodes[id]
		var pos: Vector2 = node_data.position
		min_y = minf(min_y, pos.y)
		max_y = maxf(max_y, pos.y)
		min_x = minf(min_x, pos.x)
		max_x = maxf(max_x, pos.x)

	var content_width: float = max_x - min_x + _node_size
	var content_height: float = max_y - min_y + _node_size
	var total_width: float = content_width + _margin_x * 2
	var total_height: float = content_height + _margin_bottom + _floor_spacing

	map_container.custom_minimum_size = Vector2(total_width, total_height)

	# 计算居中偏移
	await get_tree().process_frame
	var viewport_width: float = scroll_container.size.x
	var offset_x: float = 0.0
	if total_width < viewport_width:
		offset_x = (viewport_width - total_width) / 2.0
		map_container.custom_minimum_size.x = viewport_width

	# 居中偏移量存起来，给节点和连线用
	_center_offset_x = offset_x - min_x + _margin_x


func _reload_map() -> void:
	_clear_map()
	_load_map()


func _clear_map() -> void:
	for child in map_container.get_children():
		if child is MapNode:
			child.queue_free()
	_node_instances.clear()
	_visited_ids.clear()
	_current_node_id = ""
	_line_data.clear()


func _create_node_instances() -> void:
	var all_nodes: Dictionary = _map_data.all_nodes

	for id in all_nodes:
		var node_data: MapLoader.MapNodeData = all_nodes[id]
		var instance: MapNode = MapNodeScene.instantiate()
		instance.setup(node_data.node_type, node_data.floor_index, node_data.column_index, node_data.id)
		instance.position = node_data.position + Vector2(_center_offset_x - _node_size / 2.0, -_node_size / 2.0)
		instance.node_clicked.connect(_on_node_clicked)
		map_container.add_child(instance)
		_node_instances[id] = instance


func _build_line_data() -> void:
	var all_nodes: Dictionary = _map_data.all_nodes
	_line_data.clear()

	for id in all_nodes:
		var node_data: MapLoader.MapNodeData = all_nodes[id]
		var from_pos: Vector2 = node_data.position

		for target_id in node_data.connections:
			var target_data: MapLoader.MapNodeData = all_nodes[target_id]
			var to_pos: Vector2 = target_data.position
			_line_data.append({
				"from": from_pos,
				"to": to_pos,
				"from_id": id,
				"to_id": target_id,
			})


func _on_node_clicked(node: MapNode) -> void:
	if not node.reachable or node.visited:
		return

	if node.node_type == MapNode.NodeType.DOJO:
		_pending_node = node
		var node_data: MapLoader.MapNodeData = _map_data.all_nodes.get(node.node_id, null)
		var dojo_name: String = ""
		if node_data:
			dojo_name = node_data.dojo_name
			_pending_consume_cards = node_data.consume_cards
			_pending_produce_cards = node_data.produce_cards
		dojo_panel.show_panel(dojo_name, _pending_produce_cards, _pending_consume_cards)
		return

	if node.node_type == MapNode.NodeType.WORK:
		_pending_node = node
		var node_data: MapLoader.MapNodeData = _map_data.all_nodes.get(node.node_id, null)
		var work_name: String = ""
		if node_data:
			work_name = node_data.work_name
			_pending_consume_cards = node_data.consume_cards
			_pending_produce_cards = node_data.produce_cards
		work_panel.show_panel(work_name, _pending_produce_cards, _pending_consume_cards)
		return

	if node.node_type == MapNode.NodeType.COMBAT or node.node_type == MapNode.NodeType.ELITE:
		_pending_node = node
		var enemy_name: String = "山贼"
		var enemy_hp: int = 30
		var enemy_attack: int = 5
		if node.node_type == MapNode.NodeType.ELITE:
			enemy_name = "匪首"
			enemy_hp = 60
			enemy_attack = 10
		battle_scene.start_battle(card_inventory_panel, enemy_name, enemy_hp, enemy_attack)
		return

	if node.node_type == MapNode.NodeType.EVENT:
		_pending_node = node
		event_panel.show_panel()
		return

	if node.node_type == MapNode.NodeType.SHOP:
		_pending_node = node
		shop_panel.show_panel(card_inventory_panel)
		return

	_visit_node(node)


func _visit_node(node: MapNode) -> void:
	_visited_ids[node.node_id] = true
	_current_node_id = node.node_id
	_lock_floor_nodes(node)
	_update_reachability()
	map_container.queue_redraw()

	if node.node_type == MapNode.NodeType.BOSS:
		print("到达Boss！")


func _lock_floor_nodes(node: MapNode) -> void:
	var current_floor: int = node.floor_index
	for id in _node_instances:
		if id != node.node_id and not _visited_ids.has(id):
			var data: MapLoader.MapNodeData = _map_data.all_nodes.get(id, null)
			if data and data.floor_index == current_floor:
				_visited_ids[id] = true
				_node_instances[id].set_visited(true)


func _update_reachability() -> void:
	for id in _visited_ids:
		if id in _node_instances:
			_node_instances[id].set_visited(true)

	var all_nodes: Dictionary = _map_data.all_nodes
	var current_data: MapLoader.MapNodeData = all_nodes.get(_current_node_id, null)

	for id in _node_instances:
		_node_instances[id].set_reachable(false)

	if current_data:
		for target_id in current_data.connections:
			if target_id in _node_instances and not _visited_ids.has(target_id):
				_node_instances[target_id].set_reachable(true)


func _on_dojo_confirmed() -> void:
	if _pending_node:
		for c in _pending_consume_cards:
			var card_type: String = c.get("type", "")
			var count: int = c.get("count", 0)
			card_inventory_panel.remove_card(card_type, count)
		for c in _pending_produce_cards:
			var card_type: String = c.get("type", "")
			if card_type == "功法":
				card_inventory_panel.add_gongfa(c.get("gongfaId", ""))
			else:
				card_inventory_panel.add_card(card_type, c.get("count", 0))
		_lock_floor_nodes(_pending_node)


func _on_dojo_skipped() -> void:
	if _pending_node:
		_visit_node(_pending_node)
		_pending_node = null
		_pending_consume_cards = []
		_pending_produce_cards = []


func _on_dojo_cancelled() -> void:
	_pending_node = null


func _on_work_confirmed() -> void:
	if _pending_node:
		for c in _pending_consume_cards:
			var card_type: String = c.get("type", "")
			var count: int = c.get("count", 0)
			card_inventory_panel.remove_card(card_type, count)
		for c in _pending_produce_cards:
			var card_type: String = c.get("type", "")
			if card_type == "功法":
				card_inventory_panel.add_gongfa(c.get("gongfaId", ""))
			else:
				card_inventory_panel.add_card(card_type, c.get("count", 0))
		_lock_floor_nodes(_pending_node)


func _on_work_skipped() -> void:
	if _pending_node:
		_visit_node(_pending_node)
		_pending_node = null
		_pending_consume_cards = []
		_pending_produce_cards = []


func _on_work_cancelled() -> void:
	_pending_node = null


func _on_event_confirmed() -> void:
	if _pending_node:
		# 处理消耗卡
		for c in event_panel.get_consume_cards():
			var card_type: String = c.get("type", "")
			var count: int = c.get("count", 0)
			card_inventory_panel.remove_card(card_type, count)
		# 处理产出卡
		for c in event_panel.get_produce_cards():
			var card_type: String = c.get("type", "")
			if card_type == "功法":
				card_inventory_panel.add_gongfa(c.get("gongfaId", ""))
			else:
				card_inventory_panel.add_card(card_type, c.get("count", 0))
		_visit_node(_pending_node)
		_pending_node = null


func _on_shop_confirmed() -> void:
	if _pending_node:
		# 已购物品的消耗在购买时已扣除，这里只处理产出
		for item in shop_panel.get_bought_items():
			for c in item.get("produceCards", []):
				var card_type: String = c.get("type", "")
				if card_type == "功法":
					card_inventory_panel.add_gongfa(c.get("gongfaId", ""))
				else:
					card_inventory_panel.add_card(card_type, c.get("count", 0))
		_visit_node(_pending_node)
		_pending_node = null



func _on_battle_won() -> void:
	if _pending_node:
		var was_boss: bool = _pending_node.node_type == MapNode.NodeType.BOSS
		_visit_node(_pending_node)
		_pending_node = null
		if was_boss:
			_on_boss_defeated()


func _on_battle_lost() -> void:
	_pending_node = null
	print("战败！")


func _on_battle_fled() -> void:
	_pending_node = null


func _on_card_inventory_pressed() -> void:
	card_inventory_panel.show_panel()


func _on_card_inventory_closed() -> void:
	pass


func _on_settings_pressed() -> void:
	print("打开系统设置")


func _on_reincarnate_pressed() -> void:
	inherit_panel.show_panel(card_inventory_panel)


func _on_inherit_confirmed(inherit_list: Array) -> void:
	# 转世：重置卡牌仓库并继承选中的卡牌
	card_inventory_panel.reset_inventory()
	card_inventory_panel.inherit_cards(inherit_list)
	# 世数+1
	_life_number += 1
	_update_life_label()
	# 章节重置
	_chapter_index = 0
	# 删除旧存档，避免重载时恢复旧地图进度
	SaveManager.delete_save()
	# 重置地图进度
	_reload_map()
	# 自动保存
	SaveManager.save_game(card_inventory_panel, self)
	print("转世重修！第" + str(_life_number) + "世")


func _on_inherit_cancelled() -> void:
	pass


func _update_life_label() -> void:
	var chapter_name: String = ""
	if _chapters.size() > 0 and _chapter_index < _chapters.size():
		chapter_name = _chapters[_chapter_index].get("name", "")
	life_label.text = "第" + str(_life_number) + "世" + ("  " + chapter_name if chapter_name != "" else "")


func _update_chapter_bg() -> void:
	if not bg_rect:
		return
	var bg_path: String = ""
	if _chapters.size() > 0 and _chapter_index < _chapters.size():
		bg_path = _chapters[_chapter_index].get("bg", "")
	if bg_path != "" and ResourceLoader.exists(bg_path):
		bg_rect.texture = load(bg_path)
	else:
		bg_rect.texture = null


func _on_boss_defeated() -> void:
	if _chapters.size() == 0 or _chapter_index >= _chapters.size():
		return
	var chapter: Dictionary = _chapters[_chapter_index]
	var is_final: bool = _chapter_index >= _chapters.size() - 1
	chapter_clear_panel.show_panel(
		chapter.get("name", ""),
		chapter.get("description", ""),
		is_final
	)


func _on_chapter_confirmed() -> void:
	if _chapter_index >= _chapters.size() - 1:
		# 最后一章通关
		print("全部章节通关！")
		return
	# 进入下一章
	_chapter_index += 1
	_update_life_label()
	SaveManager.delete_save()
	_reload_map()
	SaveManager.save_game(card_inventory_panel, self)


func _on_chapter_preview_pressed() -> void:
	chapter_preview_panel.show_panel(_chapters, _chapter_index)


func _on_save_pressed() -> void:
	if SaveManager.save_game(card_inventory_panel, self):
		print("保存成功")
	else:
		print("保存失败")


func get_current_node_id() -> String:
	return _current_node_id


func get_visited_ids() -> Array:
	return _visited_ids.keys()


func get_life_number() -> int:
	return _life_number


func get_chapter_index() -> int:
	return _chapter_index


func _apply_save_data(data: Dictionary) -> void:
	# 恢复卡牌仓库
	var cards_data: Dictionary = data.get("cards", {})
	card_inventory_panel.load_save_data(cards_data)

	# 恢复世数
	_life_number = data.get("life_number", 1)
	_chapter_index = data.get("chapter_index", 0)
	_update_life_label()

	# 恢复地图进度
	_current_node_id = data.get("current_node_id", _current_node_id)
	var visited: Array = data.get("visited_ids", [])
	_visited_ids.clear()
	for id in visited:
		_visited_ids[id] = true

	_update_reachability()
	map_container.queue_redraw()

	await get_tree().process_frame
	scroll_container.scroll_vertical = 99999
