extends Node

class_name BattleManager

const BattleState = preload("./battle_state.gd")
const Deck = preload("./deck.gd")
const EnemyAI = preload("./enemy_ai.gd")
const Card = preload("./card.gd")

## 战斗管理器：串联牌库、状态与敌人AI，负责结算/推进
var state
var deck
var enemy_ai

signal state_changed
signal battle_end(victory: bool)

## 初始化：若未注入依赖，则自行创建默认实例
func _ready():
	if state == null:
		state = BattleState.new()
	if deck == null:
		deck = Deck.new()
	if enemy_ai == null:
		enemy_ai = EnemyAI.new()
	enemy_ai.setup_basic()

## 开始战斗：设置牌库、重置回合、抽起始手牌
func start_battle(start_cards: Array) -> void:
	deck.setup_from_cards(start_cards)
	state.reset_turn()
	deck.draw(5)
	emit_signal("state_changed")

## 使用一张手牌（无目标旧接口，保留兼容）
func play_card(card) -> void:
	if state.player_energy < card.cost:
		return
	state.player_energy -= card.cost
	match card.type:
		Card.CardType.ATTACK:
			_resolve_player_attack(card.power)
		Card.CardType.BLOCK:
			state.player_block += card.power
		Card.CardType.HEAL:
			state.player_hp = min(state.player_hp + card.power, state.player_hp_max)
		_:
			# utility 简化：给敌人添加虚弱/定身（本原型忽略持续效果）
			pass
	deck.discard(card)
	_process_enemy_turn()
	emit_signal("state_changed")
	_check_end()

## 新增：使用一张手牌并指定目标（"enemy" 或 "self"）
func play_card_with_target(card, target: String) -> void:
	if state.player_energy < card.cost:
		return
	state.player_energy -= card.cost
	match card.type:
		Card.CardType.ATTACK:
			# 攻击仅对敌人有效
			if target == "enemy":
				_resolve_player_attack(card.power)
		Card.CardType.BLOCK:
			# 防御通常作用在自己
			if target == "self":
				state.player_block += card.power
		Card.CardType.HEAL:
			# 治疗通常作用在自己
			if target == "self":
				state.player_hp = min(state.player_hp + card.power, state.player_hp_max)
		_:
			# 其他类型默认作用己方（示例）
			if target == "self":
				pass
	deck.discard(card)
	_process_enemy_turn()
	emit_signal("state_changed")
	_check_end()

## 敌人执行一个意图，并将新意图补入队列
func _process_enemy_turn() -> void:
	var intent = enemy_ai.next_intent()
	match intent["type"]:
		"attack":
			_apply_damage_to_player(intent["value"])
		"defend":
			state.enemy_block += int(intent["value"]) 
		"evade":
			# 本原型：闪避让下一次受到的伤害-50%
			state.enemy_block += 999  # 粗暴实现，等价于本回合免伤
		_:
			pass

## 结算玩家的攻击：护甲先吸收，剩余进入生命
func _resolve_player_attack(power: int) -> void:
	var damage = max(0, power - state.enemy_block)
	state.enemy_block = max(0, state.enemy_block - power)
	state.enemy_hp -= damage

## 敌方对玩家造成伤害：同样先结算护甲
func _apply_damage_to_player(amount: int) -> void:
	var damage = max(0, amount - state.player_block)
	state.player_block = max(0, state.player_block - amount)
	state.player_hp -= damage

## 检查战斗是否结束（胜/负）
func _check_end() -> void:
	if state.is_enemy_dead():
		emit_signal("battle_end", true)
	elif state.is_player_dead():
		emit_signal("battle_end", false)