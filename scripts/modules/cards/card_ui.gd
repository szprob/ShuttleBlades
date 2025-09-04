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

@export var badge_frames := {
	'damage': null,
	'cost': null,
}

# 默认值（用于判断是否需要脉冲）
@export var default_damage: int = 0
@export var default_cost: int = 0

# 变量上下文，用于描述文本占位符，例：{item_left}, {bonus}, {cost}
var context: Dictionary = {}

# 当前可造成伤害/消耗体力（受外部加成或战斗状态影响）
@export var current_damage: int = 0
@export var current_cost: int = 0

# 自定义插画（每张卡可不同）
@export var art_texture: Texture2D

signal ui_updated(card: Card)

func _ready() -> void:
	_init_default_type_assets()
	_setup_badge_fonts()
	_update_all()

func _init_default_type_assets() -> void:
	# 若未在导出中指定，为不同类型预置一个基础UI图像（可在编辑器覆盖）
	var attack_frame := preload("res://assets/sprites/card/ui/attack.png")
	var block_frame := preload("res://assets/sprites/card/ui/block.png")
	var utility_frame := preload("res://assets/sprites/card/ui/utility.png")
	var item_frame := preload("res://assets/sprites/card/ui/item.png")
	if not type_frames[Card.CardType.ATTACK]:
		type_frames[Card.CardType.ATTACK] = attack_frame
	if not type_frames[Card.CardType.BLOCK]:
		type_frames[Card.CardType.BLOCK] = block_frame
	if not type_frames[Card.CardType.UTILITY]:
		type_frames[Card.CardType.UTILITY] = utility_frame
	if not type_frames[Card.CardType.ITEM]:
		type_frames[Card.CardType.ITEM] = item_frame

func _setup_badge_fonts() -> void:
	var bold_font: FontFile = load("res://assets/sts/font/Kreon-Bold.ttf")
	# 伤害
	var dmg_label: Label = %DamageLabel
	dmg_label.add_theme_font_override("font", bold_font)
	dmg_label.add_theme_font_size_override("font_size", 26)
	dmg_label.add_theme_color_override("font_color", Color(1, 0.2, 0.2))
	dmg_label.add_theme_constant_override("outline_size", 2)
	dmg_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	# 消耗
	var cost_label: Label = %CostLabel
	cost_label.add_theme_font_override("font", bold_font)
	cost_label.add_theme_font_size_override("font_size", 26)
	cost_label.add_theme_color_override("font_color", Color(1, 0.85, 0.2))
	cost_label.add_theme_constant_override("outline_size", 2)
	cost_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))



func set_card(c: Card) -> void:
	card = c
	# 如卡上有基础数值（若你的 Card 有对应字段，可在此同步默认值）
	# default_damage = card.base_damage
	# default_cost = card.cost
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
	var vars := {
		"name": card.name,
		"power": card.power,
		"cost": default_cost if default_cost != 0 else card.cost,
		"type": card.type,
		"damage": current_damage,
	}
	for k in context.keys():
		vars[k] = context[k]
	var text := card.description
	desc.text = text.format(vars)

func _update_badges() -> void:
	var show_damage := (current_damage > 0)
	var show_cost := (current_cost > 0)

	if card:
		match card.type:
			Card.CardType.ATTACK:
				show_damage = current_damage > 0
			Card.CardType.BLOCK:
				show_cost = current_cost > 0
			Card.CardType.UTILITY, Card.CardType.ITEM:
				pass

	var dmg_badge: Control = %DamageBadge
	var cost_badge: Control = %CostBadge
	var dmg_bg: TextureRect = %DamageBG
	var cost_bg: TextureRect = %CostBG
	var dmg_label: Label = %DamageLabel
	var cost_label: Label = %CostLabel

	# 底图使用导出可覆盖的贴图
	if badge_frames.get('damage'):
		dmg_bg.texture = badge_frames['damage']
	else:
		dmg_bg.texture = null
		dmg_bg.modulate = Color(1, 0.4, 0.4, 1)

	if badge_frames.get('cost'):
		cost_bg.texture = badge_frames['cost']
	else:
		cost_bg.texture = null
		cost_bg.modulate = Color(1, 0.9, 0.3, 1)

	dmg_badge.visible = show_damage
	cost_badge.visible = show_cost

	if show_damage:
		dmg_label.text = str(current_damage)
		if default_damage != 0 and current_damage != default_damage:
			_pulse_badge(dmg_badge)
	if show_cost:
		cost_label.text = str(current_cost)
		if default_cost != 0 and current_cost != default_cost:
			_pulse_badge(cost_badge)

func _pulse_badge(node: Node) -> void:
	var ap: AnimationPlayer = %AnimationPlayer
	if not ap.has_animation(node.name):
		var anim := Animation.new()
		anim.length = 0.25
		anim.loop_mode = Animation.LOOP_NONE
		var track := anim.add_track(Animation.TYPE_VALUE)
		anim.track_set_path(track, node.get_path().path + ":scale")
		anim.track_insert_key(track, 0.0, Vector2.ONE * 1.0)
		anim.track_insert_key(track, 0.12, Vector2.ONE * 1.15)
		anim.track_insert_key(track, 0.25, Vector2.ONE * 1.0)
		ap.add_animation(node.name, anim)
	ap.play(node.name)