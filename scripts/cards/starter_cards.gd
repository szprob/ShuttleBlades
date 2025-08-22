extends Node

const CardRes = preload("res://scripts/cards/card.gd")

## 构建一套新手起始牌组（示例：3攻2防1奶）
func make_starter_deck() -> Array:
	var res: Array = []
	res.append(_attack(6))
	res.append(_attack(6))
	res.append(_attack(6))
	res.append(_block(5))
	res.append(_block(5))
	res.append(_heal(4))
	return res

## 便捷构造：攻击卡
func _attack(p: int):
	var c = CardRes.new()
	c.id = "atk_" + str(p)
	c.name = "攻击" + str(p)
	c.type = Card.CardType.ATTACK
	c.power = p
	return c

## 便捷构造：防御卡（获得护甲）
func _block(p: int):
	var c = CardRes.new()
	c.id = "blk_" + str(p)
	c.name = "防御" + str(p)
	c.type = Card.CardType.BLOCK
	c.power = p
	return c

## 便捷构造：治疗卡
func _heal(p: int):
	var c = CardRes.new()
	c.id = "heal_" + str(p)
	c.name = "疗伤" + str(p)
	c.type = Card.CardType.HEAL
	c.power = p
	return c


