extends Control

const CARD_SCENE := preload("res://scenes/modules/cards/Card.tscn")
const CardRes := preload("res://scripts/cards/card.gd")

@onready var grid: GridContainer = %Grid

# 进入背包时传入（或在 _ready 里从某管理器读取）
@export var cards: Array = [] # Array[Card]

# 可选：一次性注入类型图标和边框
@export var type_icons := {}
@export var type_frames := {}

func _ready() -> void:
	_refresh()

func set_cards(list: Array) -> void:
	cards = list
	_refresh()

func _refresh() -> void:
	if not is_instance_valid(grid):
		return
	for c in grid.get_children():
		c.queue_free()
	if cards.is_empty():
		return

	for c in cards:
		var ui: Control = CARD_SCENE.instantiate()
		# 注入资源映射（如有）
		if type_icons.size() > 0:
			ui.type_icons = type_icons
		if type_frames.size() > 0:
			ui.type_frames = type_frames

		ui.set_card(c)
		# 可选：按类型给出基础战斗数值（用于徽章显示）
		var dmg := (c.type == CardRes.CardType.ATTACK) ? c.power : 0
		var blk := (c.type == CardRes.CardType.BLOCK) ? c.power : 0
		ui.set_combat_values(dmg, blk)

		# 示例：描述变量（例如物品剩余数量，若没有就忽略）
		ui.set_context({
			"item_left": (c.has_method("get_left") ? c.get_left() : 0)
		})
		grid.add_child(ui)