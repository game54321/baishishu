extends Control
## MapContainer 的绘制脚本，负责画连线

var map_view: Control = null

func _draw() -> void:
	if not map_view:
		return

	var line_data: Array = map_view._line_data
	var visited_ids: Dictionary = map_view._visited_ids
	var current_node_id: String = map_view._current_node_id

	# 先画线（在节点之下）
	for ld in line_data:
		var offset_x: float = map_view._center_offset_x
		var from_pos: Vector2 = ld["from"] + Vector2(offset_x, 0)
		var to_pos: Vector2 = ld["to"] + Vector2(offset_x, 0)
		var from_id: String = ld["from_id"]
		var to_id: String = ld["to_id"]

		var from_visited: bool = visited_ids.has(from_id)
		var to_visited: bool = visited_ids.has(to_id)
		var is_reachable: bool = (from_id == current_node_id and not to_visited)

		var color: Color
		var width: float

		if from_visited and to_visited:
			color = Color(0.4, 0.7, 0.4, 0.8)
			width = 3.0
		elif is_reachable:
			color = Color(1.0, 0.9, 0.3, 0.9)
			width = 3.0
		else:
			color = Color(0.4, 0.4, 0.4, 0.5)
			width = 2.0

		draw_line(from_pos, to_pos, color, width, true)
