extends Control

# UI挂接的战斗控制层：负责把按钮与管理器连接起来
const BattleManager = preload("../modules/battle_manager.gd")
const Card = preload("../modules/card.gd")

@onready var battle_manager: BattleManager = $BattleManager
@onready var hand_container: HBoxContainer = $Hand
@onready var info_label: Label = $Info
@onready var intents_label: Label = $Intents
@onready var end_turn_button: Button = $EndTurn

var _pending_card = null
var _target_self_btn: Button
var _target_enemy_btn: Button
var _is_targeting := false

## 绑定信号，生成起始牌组并开始战斗
func _ready():
	battle_manager.state_changed.connect(_refresh_ui)
	battle_manager.battle_end.connect(_on_battle_end)

	var starter = load("res://scripts/cards/starter_cards.gd").new()
	var cards = starter.make_starter_deck()
	battle_manager.start_battle(cards)
	_make_target_buttons()
	_refresh_ui()

func _make_target_buttons() -> void:
	_target_enemy_btn = Button.new()
	_target_enemy_btn.name = "TargetEnemy"
	_target_enemy_btn.text = "攻击敌方"
	_target_enemy_btn.visible = false
	add_child(_target_enemy_btn)
	_target_enemy_btn.pressed.connect(func(): _on_pick_target("enemy"))

	_target_self_btn = Button.new()
	_target_self_btn.name = "TargetSelf"
	_target_self_btn.text = "作用己方"
	_target_self_btn.visible = false
	add_child(_target_self_btn)
	_target_self_btn.pressed.connect(func(): _on_pick_target("self"))

	# 简单布局：放在界面右侧
	_target_enemy_btn.anchor_right = 1.0
	_target_enemy_btn.anchor_top = 0.2
	_target_enemy_btn.anchor_bottom = 0.2
	_target_enemy_btn.offset_right = -20
	_target_enemy_btn.offset_top = 40

	_target_self_btn.anchor_right = 1.0
	_target_self_btn.anchor_top = 0.35
	_target_self_btn.anchor_bottom = 0.35
	_target_self_btn.offset_right = -20
	_target_self_btn.offset_top = 40

## 刷新面板：生命/护甲/能量、敌人意图、手牌按钮
func _refresh_ui() -> void:
	# info
	var s = battle_manager.state
	info_label.text = "我方: %d/%d 护甲:%d  能量:%d/%d\n敌方: %d/%d 护甲:%d" % [
		s.player_hp, s.player_hp_max, s.player_block, s.player_energy, s.player_energy_max,
		s.enemy_hp, s.enemy_hp_max, s.enemy_block
	]

	# intents
	var peek = battle_manager.enemy_ai.peek_visible_intents()
	var intent_texts: Array[String] = []
	for it in peek:
		intent_texts.append("%s(%d)" % [it["type"], int(it.get("value", 0))])
	intents_label.text = "敌方意图: " + ", ".join(intent_texts)

	# hand：清空并重建所有手牌按钮
	for c in hand_container.get_children():
		c.queue_free()
	for card in battle_manager.deck.hand:
		var b := Button.new()
		b.text = "%s [%d]" % [card.name if card.name != "" else str(card.id), card.cost]
		b.pressed.connect(func():
			_enter_targeting(card)
		)
		hand_container.add_child(b)

	# 目标选择提示
	_target_enemy_btn.visible = _is_targeting
	_target_self_btn.visible = _is_targeting

## 进入目标选择模式
func _enter_targeting(card) -> void:
	_pending_card = card
	_is_targeting = true
	_target_enemy_btn.visible = true
	_target_self_btn.visible = true
	intents_label.text = "请选择目标：点击右侧按钮（敌方/己方）"
	# 可选：禁用结束回合，避免误触
	end_turn_button.disabled = true

## 退出目标选择模式
func _exit_targeting() -> void:
	_pending_card = null
	_is_targeting = false
	_target_enemy_btn.visible = false
	_target_self_btn.visible = false
	end_turn_button.disabled = false

func _on_pick_target(target: String) -> void:
	if _pending_card == null:
		_exit_targeting()
		return
	battle_manager.play_card_with_target(_pending_card, target)
	_exit_targeting()
	_refresh_ui()

## 战斗结束时：禁用交互并提示结果
func _on_battle_end(victory: bool) -> void:
	var msg = ""
	if victory:
		msg = "胜利! +%d金币" % battle_manager.state.coins_reward
	else:
		msg = "失败"
	info_label.text += "\n" + msg
	end_turn_button.disabled = true
	for c in hand_container.get_children():
		c.disabled = true

## 结束回合按钮回调
func _on_EndTurn_pressed() -> void:
	battle_manager.end_turn()