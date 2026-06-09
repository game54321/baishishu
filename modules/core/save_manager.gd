extends Node
## 存档管理器：负责保存/加载游戏进度

const SAVE_PATH := "user://save.sav"
const SAVE_VERSION := 1


func save_game(inventory_panel, map_view) -> bool:
	var data := {
		"version": SAVE_VERSION,
		"current_node_id": map_view.get_current_node_id(),
		"visited_ids": map_view.get_visited_ids(),
		"life_number": map_view.get_life_number(),
		"chapter_index": map_view.get_chapter_index(),
		"cards": inventory_panel.get_save_data(),
	}

	var json_str := JSON.stringify(data, "\t")
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if not file:
		push_error("保存失败: 无法写入文件")
		return false
	file.store_string(json_str)
	file.close()
	return true


func load_game() -> Dictionary:
	if not has_save():
		return {}
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		push_error("加载失败: 无法读取文件")
		return {}
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		push_error("加载失败: JSON解析错误")
		return {}
	file.close()
	var data: Dictionary = json.data
	if data.get("version", 0) != SAVE_VERSION:
		push_warning("存档版本不匹配")
	return data


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func delete_save() -> bool:
	if not has_save():
		return true
	var err := DirAccess.remove_absolute(SAVE_PATH)
	return err == OK
