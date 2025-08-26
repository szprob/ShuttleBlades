# scripts/cards/card_ui.gd
extends Control

@export var card: Card

# 类型->图标/边框，可在派生场景或运行时注入资源
@export var type_icons := {
	Card.CardType.ATTACK: null,
	Card.CardType.BLOCK: null,
	Card.CardType.UTILITY: null,
	Card.CardType.ITEM: null
}
@export var type_frames := {
	Card.CardType.ATTACK: null,
	Card.CardType.BLOCK: null,
	Card.CardType.UTILITY: null,
	Card.CardType.ITEM: null
}

# 变量上下文，用于描述文本占位符，例：{item_left}, {bonus}, {cost}
var context: Dictionary = {}

# 当前可造成伤害/消耗体力（受外部加成或战斗状态影响）
@export var current_damage: int = 0
@export var current_cost: int = 0

# 自定义插画（每张卡可不同）
@export var art_texture: Texture2D

signal ui_updated(card: Card)

func _ready() -> void:
	_update_all()

func set_card(c: Card) -> void:
	card = c
	_update_all()

func set_context(ctx: Dictionary) -> void:
	context = ctx
	_update_desc()
	_update_badges()
	emit_signal("ui_updated", card)

func set_combat_values(damage: int, cost: int) -> void:
	current_damage = max(0, damage)
	current_cost = max(0, cost)
	_update_badges()
	emit_signal("ui_updated", card)

func set_art(t: Texture2D) -> void:
	art_texture = t
	_update_art()

func _update_all() -> void:
	_update_frame()
	_update_icon()
	_update_art()
	_update_name()
	_update_desc()
	_update_badges()
	emit_signal("ui_updated", card)

func _update_frame() -> void:
	var frame: NinePatchRect = %Frame
	if card and type_frames.has(card.type) and type_frames[card.type]:
		frame.texture = type_frames[card.type]
	else:
		frame.texture = null

func _update_icon() -> void:
	var icon: TextureRect = %TypeIcon
	if card and type_icons.has(card.type):
		icon.texture = type_icons[card.type]
	else:
		icon.texture = null

func _update_art() -> void:
	var art: TextureRect = %Art
	art.texture = art_texture

func _update_name() -> void:
	var name_label: Label = %Name
	name_label.text = card.name if card else "—"

func _update_desc() -> void:
	var desc: RichTextLabel = %Desc
	if not card:
		desc.text = ""
		return
	# 描述字符串支持 {key} 占位（Godot 4 的 String.format）
	# 预置一些常用变量：name、power、cost、damage、block 等
	var vars := {
		"name": card.name,
		"power": card.power,
		"cost": card.cost,
		"type": card.type,
		"damage": current_damage,
		"block": current_block
	}
	for k in context.keys():
		vars[k] = context[k]
	var text := card.description
	# 若使用 BBCode，可将换行/加粗等写在 description 中
	desc.text = text.format(vars)

func _update_badges() -> void:
	# 获取徽章UI节点引用
	var cost_badge: Control = %Badges.get_node("CostBadge") if %Badges.has_node("CostBadge") else null
	var cost_label: Label = cost_badge.get_node("CostLabel") if cost_badge else null
	var show_damage := (current_damage > 0)
	var show_cost := (current_cost > 0)

	# 默认：攻击卡优先显示左上角伤害，防御卡优先显示右上角格挡
	if card:
		match card.type:
			Card.CardType.ATTACK:
				show_damage = current_damage > 0
			Card.CardType.BLOCK:
				show_cost = current_cost > 0
			Card.CardType.HEAL, Card.CardType.UTILITY, Card.CardType.ITEM:
				# 这些类型一般不显示，除非外部传入>0
				pass

	var dmg_badge: Control = %DamageBadge
	var blk_badge: Control = %BlockBadge
	var dmg_label: Label = %DamageLabel
	var blk_label: Label = %BlockLabel

	dmg_badge.visible = show_damage
	cost_badge.visible = show_cost

	if show_damage:
		dmg_label.text = str(current_damage)
		_pulse_badge(dmg_badge)
	if show_cost:
		cost_label.text = str(current_cost)
		_pulse_badge(cost_badge)

func _pulse_badge(node: Node) -> void:
	# 为徽章添加脉冲动画效果，让数值变化时更加明显
	var ap: AnimationPlayer = %AnimationPlayer
	if not ap.has_animation(node.name):
		var anim := Animation.new()
		anim.length = 0.25
		anim.track_set_path(anim.add_track(Animation.TYPE_VALUE), node.get_path().path + ":scale")
		anim.track_insert_key(0, 0.0, Vector2.ONE * 1.0)
		anim.track_insert_key(0, 0.12, Vector2.ONE * 1.15)
		anim.track_insert_key(0, 0.25, Vector2.ONE * 1.0)
		ap.add_animation(node.name, anim)
	ap.play(node.name)