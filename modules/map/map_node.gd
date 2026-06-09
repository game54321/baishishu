class_name MapNode
extends Control

signal node_clicked(node: MapNode)

enum NodeType {
	COMBAT,
	ELITE,
	REST,
	SHOP,
	EVENT,
	BOSS,
	START,
	DOJO,       # 武馆学武
	WORK,       # 打工（酒馆/码头等）
	TEMPLE,     # 古刹参禅
	BLACKSMITH, # 铁匠铺
	HERMIT,     # 隐士指点
}

@export var node_type: NodeType = NodeType.COMBAT
@export var floor_index: int = 0
@export var column_index: int = 0
@export var node_id: String = ""

var reachable: bool = false
var visited: bool = false
var connections: Array[String] = []  # 连接的下一个节点ID列表

@onready var icon: TextureRect = $Icon
@onready var label: Label = $Label

const NODE_ICONS: Dictionary = {
	NodeType.COMBAT: "res://assets/icons/战斗.png",
	NodeType.ELITE: "res://assets/icons/强敌.png",
	NodeType.REST: "res://assets/icons/休息.png",
	NodeType.SHOP: "res://assets/icons/商店.png",
	NodeType.EVENT: "res://assets/icons/奇遇.png",
	NodeType.BOSS: "res://assets/icons/boss.png",
	NodeType.START: "res://assets/icons/起点.png",
	NodeType.DOJO: "res://assets/icons/武馆.png",
	NodeType.WORK: "res://assets/icons/打工.png",
	NodeType.TEMPLE: "res://assets/icons/剧情.png",
	NodeType.BLACKSMITH: "res://assets/icons/剧情.png",
	NodeType.HERMIT: "res://assets/icons/剧情.png",
}

const NODE_LABELS: Dictionary = {
	NodeType.COMBAT: "战",
	NodeType.ELITE: "精",
	NodeType.REST: "休",
	NodeType.SHOP: "店",
	NodeType.EVENT: "?",
	NodeType.BOSS: "BOSS",
	NodeType.START: "起",
	NodeType.DOJO: "武",
	NodeType.WORK: "工",
	NodeType.TEMPLE: "禅",
	NodeType.BLACKSMITH: "铁",
	NodeType.HERMIT: "隐",
}


func _ready() -> void:
	_update_appearance()


func setup(type: NodeType, floor: int, column: int, id: String) -> void:
	node_type = type
	floor_index = floor
	column_index = column
	node_id = id
	_update_appearance()


func _update_appearance() -> void:
	var icon_path: String = NODE_ICONS.get(node_type, "")
	if icon and icon_path != "":
		icon.texture = load(icon_path)
	if label:
		label.text = NODE_LABELS.get(node_type, "?")
	_update_state_visual()


func _update_state_visual() -> void:
	if visited:
		modulate = Color(0.4, 0.4, 0.4, 0.7)
	elif reachable:
		modulate = Color.WHITE
	else:
		modulate = Color(0.7, 0.7, 0.7, 0.75)


func set_reachable(value: bool) -> void:
	reachable = value
	_update_state_visual()


func set_visited(value: bool) -> void:
	visited = value
	_update_state_visual()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if reachable and not visited:
			node_clicked.emit(self)
