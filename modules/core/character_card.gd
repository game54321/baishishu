class_name CharacterCard
extends PanelContainer
## 角色卡牌组件：玩家和敌人共用

@onready var name_label: Label = $VBox/NameLabel
@onready var portrait: TextureRect = $VBox/Portrait
@onready var card_area: HBoxContainer = $VBox/CardArea
@onready var hp_bar: ColorRect = $VBox/HPBarWrapper/HPBarBg/HPBar
@onready var hp_label: Label = $VBox/HPBarWrapper/HPLabel
