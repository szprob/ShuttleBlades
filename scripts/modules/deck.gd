extends Node

# 牌库管理：负责抽牌、弃牌、洗牌以及手牌上限
class_name Deck

# 抽牌堆（面朝下），弃牌堆（面朝上），手牌（可打出）
@export var draw_pile: Array = []
@export var discard_pile: Array = []
@export var hand: Array = []
# 手牌上限（达到后不再继续抽）
@export var hand_limit: int = 5

## 使用一组卡牌（模板）初始化牌库
func setup_from_cards(cards: Array) -> void:
	draw_pile = []
	for c in cards:
		draw_pile.append(c.clone())
	discard_pile.clear()
	hand.clear()
	_shuffle(draw_pile)

## 从抽牌堆抽取指定数量的卡至手牌
func draw(num: int) -> void:
	for i in num:
		if draw_pile.is_empty():
			if discard_pile.is_empty():
				return
			_reshuffle()
		hand.append(draw_pile.pop_back())
		if hand.size() >= hand_limit:
			return

## 将一张手牌移动到弃牌堆
func discard(card) -> void:
	if card in hand:
		hand.erase(card)
		discard_pile.append(card)

## 将弃牌堆全部洗回抽牌堆
func _reshuffle() -> void:
	for c in discard_pile:
		draw_pile.append(c)
	discard_pile.clear()
	_shuffle(draw_pile)

## 原地打乱一个数组（Fisher–Yates）
func _shuffle(arr: Array) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j = randi() % (i + 1)
		var tmp = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp


