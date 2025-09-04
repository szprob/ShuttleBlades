extends Resource

class_name Card

# 卡牌类型枚举
enum CardType {
	ATTACK,   # 攻击卡
	BLOCK,    # 防御卡
	UTILITY,  # 技能卡
	ITEM,     # 物品卡
}

# 基本属性
@export var id: String = ""
@export var name: String = ""
@export var description: String = ""
@export var type: CardType = CardType.ATTACK
@export var cost: int = 1
@export var damage: int = 0

# 可选属性
@export var rarity: String = "common"  # common, uncommon, rare, legendary
@export var upgradable: bool = true
@export var upgraded: bool = false

# 初始化方法
func _init(card_id: String = "", card_name: String = "", card_type: CardType = CardType.ATTACK, card_cost: int = 1, card_power: int = 0):
	id = card_id
	name = card_name
	type = card_type
	cost = card_cost
	power = card_power

# 获取显示名称（升级后可能有后缀）
func get_display_name() -> String:
	return name + ("+" if upgraded else "")

# 获取实际消耗（可能受到修改器影响）
func get_actual_cost() -> int:
	# 这里可以添加修改器逻辑
	return cost

# 获取实际威力（可能受到修改器影响）
func get_actual_power() -> int:
	# 这里可以添加修改器逻辑
	return power

# 克隆卡牌（用于升级或变体）
func duplicate_card() -> Card:
	var new_card = Card.new()
	new_card.id = id
	new_card.name = name
	new_card.description = description
	new_card.type = type
	new_card.cost = cost
	new_card.power = power
	new_card.rarity = rarity
	new_card.upgradable = upgradable
	new_card.upgraded = upgraded
	return new_card

# 升级卡牌
func upgrade() -> void:
	if not upgradable or upgraded:
		return
	
	upgraded = true
	# 根据卡牌类型进行不同的升级
	match type:
		CardType.ATTACK:
			power += 3  # 攻击卡增加伤害
		CardType.BLOCK:
			power += 3  # 防御卡增加防御
		CardType.HEAL:
			power += 2  # 治疗卡增加治疗量
		CardType.UTILITY:
			cost = max(0, cost - 1)  # 技能卡降低消耗
		CardType.ITEM:
			cost = max(0, cost - 1)  # 物品卡降低消耗

# 检查是否可以使用（基于能量）
func can_afford(current_energy: int) -> bool:
	return current_energy >= get_actual_cost()

# 获取卡牌颜色（用于UI显示）
func get_type_color() -> Color:
	match type:
		CardType.ATTACK:
			return Color(1.0, 0.4, 0.4)  # 红色
		CardType.BLOCK:
			return Color(0.4, 0.7, 1.0)  # 蓝色
		CardType.HEAL:
			return Color(0.4, 1.0, 0.4)  # 绿色
		CardType.UTILITY:
			return Color(1.0, 0.9, 0.3)  # 黄色
		CardType.ITEM:
			return Color(0.8, 0.6, 1.0)  # 紫色
		_:
			return Color.WHITE

# 获取稀有度颜色
func get_rarity_color() -> Color:
	match rarity:
		"common":
			return Color.WHITE
		"uncommon":
			return Color(0.3, 1.0, 0.3)  # 绿色
		"rare":
			return Color(0.3, 0.3, 1.0)  # 蓝色
		"legendary":
			return Color(1.0, 0.8, 0.0)  # 金色
		_:
			return Color.WHITE



