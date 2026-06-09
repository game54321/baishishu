class_name MapLoader
extends RefCounted
## 从JSON文件加载地图
## 返回: { floors: [[MapNodeData, ...], ...], all_nodes: {id: MapNodeData}, start_id: "", boss_id: "" }

## type_id字符串 -> MapNode.NodeType 枚举的映射
const TYPE_MAP: Dictionary = {
	"combat": MapNode.NodeType.COMBAT,
	"elite": MapNode.NodeType.ELITE,
	"shop": MapNode.NodeType.SHOP,
	"event": MapNode.NodeType.EVENT,
	"boss": MapNode.NodeType.BOSS,
	"start": MapNode.NodeType.START,
	"dojo": MapNode.NodeType.DOJO,
	"work": MapNode.NodeType.WORK,
	"tavern": MapNode.NodeType.WORK,
	"temple": MapNode.NodeType.TEMPLE,
	"blacksmith": MapNode.NodeType.BLACKSMITH,
	"hermit": MapNode.NodeType.HERMIT,
}


## 从JSON文件加载地图，返回与MapGenerator.generate()相同格式的字典
## 返回: { floors: [[MapNodeData, ...], ...], all_nodes: {id: MapNodeData}, start_id: "", boss_id: "" }
func load_map(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("地图文件不存在: " + path)
		return {}

	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("无法打开地图文件: " + path)
		return {}

	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	if err != OK:
		push_error("JSON解析错误: " + json.error_message)
		return {}

	var data: Dictionary = json.data

	var floors: Array = []
	var all_nodes: Dictionary = {}
	var start_id: String = ""
	var boss_id: String = ""

	for floor_array in data.get("floors", []):
		var floor_nodes: Array = []
		for node_dict in floor_array:
			var node := _parse_node(node_dict)
			if node:
				floor_nodes.append(node)
				all_nodes[node.id] = node
				if node.node_type == MapNode.NodeType.START:
					start_id = node.id
				elif node.node_type == MapNode.NodeType.BOSS:
					boss_id = node.id
		floors.append(floor_nodes)

	# 如果floors为空，尝试从all_nodes构建
	if floors.is_empty() and data.has("all_nodes"):
		var raw_nodes: Dictionary = data["all_nodes"]
		var floor_map: Dictionary = {}
		for id in raw_nodes:
			var node := _parse_node(raw_nodes[id])
			if node:
				all_nodes[id] = node
				if not floor_map.has(node.floor_index):
					floor_map[node.floor_index] = []
				floor_map[node.floor_index].append(node)
				if node.node_type == MapNode.NodeType.START:
					start_id = id
				elif node.node_type == MapNode.NodeType.BOSS:
					boss_id = id
		var sorted_floors := floor_map.keys()
		sorted_floors.sort()
		for fi in sorted_floors:
			floors.append(floor_map[fi])

	# 从顶层字段覆盖start_id/boss_id
	if data.has("start_id") and data["start_id"] != "":
		start_id = data["start_id"]
	if data.has("boss_id") and data["boss_id"] != "":
		boss_id = data["boss_id"]

	return {
		"floors": floors,
		"all_nodes": all_nodes,
		"start_id": start_id,
		"boss_id": boss_id,
	}


## 查找data/maps/目录下第一个可用的地图文件
func find_first_map() -> String:
	var map_dir := "res://data/maps"

	# 优先用DirAccess遍历
	if DirAccess.dir_exists_absolute(map_dir):
		var dir := DirAccess.open(map_dir)
		if dir:
			dir.list_dir_begin()
			var file_name := dir.get_next()
			while file_name != "":
				if not dir.current_is_dir() and file_name.ends_with("_godot.json"):
					var full_path := map_dir + "/" + file_name
					dir.list_dir_end()
					if FileAccess.file_exists(full_path):
						return full_path
				file_name = dir.get_next()
			dir.list_dir_end()

	# DirAccess失败时，尝试已知文件
	var fallbacks := [
		"res://data/maps/2f8c8c7e_godot.json",
	]
	for p in fallbacks:
		if FileAccess.file_exists(p):
			return p

	return ""


## 从chapters.json内嵌的原始字典解析地图
func _parse_raw_map(data: Dictionary) -> Dictionary:
	var floors: Array = []
	var all_nodes: Dictionary = {}
	var start_id: String = ""
	var boss_id: String = ""

	# 先从all_nodes解析
	if data.has("all_nodes"):
		var raw_nodes: Dictionary = data["all_nodes"]
		var floor_map: Dictionary = {}
		for id in raw_nodes:
			var node := _parse_node(raw_nodes[id])
			if node:
				all_nodes[id] = node
				if not floor_map.has(node.floor_index):
					floor_map[node.floor_index] = []
				floor_map[node.floor_index].append(node)
				if node.node_type == MapNode.NodeType.START:
					start_id = id
				elif node.node_type == MapNode.NodeType.BOSS:
					boss_id = id
		var sorted_floors := floor_map.keys()
		sorted_floors.sort()
		for fi in sorted_floors:
			floors.append(floor_map[fi])

	# 从floors数组解析（备选）
	if floors.is_empty() and data.has("floors"):
		for floor_array in data.get("floors", []):
			var floor_nodes: Array = []
			for node_dict in floor_array:
				var node := _parse_node(node_dict)
				if node:
					floor_nodes.append(node)
					all_nodes[node.id] = node
					if node.node_type == MapNode.NodeType.START:
						start_id = node.id
					elif node.node_type == MapNode.NodeType.BOSS:
						boss_id = node.id
			floors.append(floor_nodes)

	if data.has("start_id") and data["start_id"] != "":
		start_id = data["start_id"]
	if data.has("boss_id") and data["boss_id"] != "":
		boss_id = data["boss_id"]

	return {
		"floors": floors,
		"all_nodes": all_nodes,
		"start_id": start_id,
		"boss_id": boss_id,
	}


func _parse_node(d: Dictionary) -> MapNodeData:
	var node := MapNodeData.new()
	node.id = d.get("id", "")
	node.node_type = _type_id_to_enum(d.get("type_id", "combat"))
	node.floor_index = int(d.get("floor_index", 0))
	node.column_index = int(d.get("column_index", 0))
	node.dojo_name = d.get("dojo_name", "")
	node.work_name = d.get("work_name", "")
	node.node_name = d.get("name", "")
	node.enemy_realm = d.get("enemy_realm", "")
	node.enemy_count = int(d.get("enemy_count", 1))
	node.produce_cards = d.get("produce_cards", [])
	node.consume_cards = d.get("consume_cards", [])

	# 连接
	var conns = d.get("connections", [])
	for c in conns:
		node.connections.append(str(c))

	# 位置
	var pos = d.get("position", {})
	if pos.has("x") and pos.has("y"):
		node.position = Vector2(float(pos["x"]), float(pos["y"]))

	return node


func _type_id_to_enum(type_id: String) -> MapNode.NodeType:
	if TYPE_MAP.has(type_id):
		return TYPE_MAP[type_id]
	push_warning("未知节点类型: " + type_id + "，默认为COMBAT")
	return MapNode.NodeType.COMBAT


class MapNodeData:
	extends RefCounted
	var id: String = ""
	var node_type: MapNode.NodeType = MapNode.NodeType.COMBAT
	var floor_index: int = 0
	var column_index: int = 0
	var connections: Array[String] = []
	var position: Vector2 = Vector2.ZERO
	var dojo_name: String = ""
	var work_name: String = ""
	var node_name: String = ""
	var enemy_realm: String = ""
	var enemy_count: int = 1
	var produce_cards: Array = []
	var consume_cards: Array = []
