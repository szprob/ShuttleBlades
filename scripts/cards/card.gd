extends Resource

# 卡牌基础数据资源：用于描述一张可被使用的卡
# 典型字段：id、名称、描述、能量消耗、类型与数值（power）等
class_name Card

# 卡牌类型：
# ATTACK 攻击；BLOCK 防御（获得护甲）；HEAL 治疗；UTILITY 功能类（如控制/增益）
enum CardType { ATTACK, BLOCK, HEAL, UTILITY }

# 唯一标识（用于存档/升级/商店引用）
@export var id: String = ""
# 展示名称
@export var name: String = ""
# 详细描述（UI用）
@export var description: String = ""
# 使用成本（占用玩家能量）
@export var cost: int = 1
# 卡牌类型（见上方枚举）
@export var type: int = CardType.ATTACK
# 主数值（例如攻击伤害/获得护甲/治疗量）
@export var power: int = 0
# 附加状态关键字（原型中暂不实现持续效果）
@export var status: String = ""

# 复制当前卡牌数据，便于将卡池模板克隆到实际牌堆
func clone() -> Card:
	var c := Card.new()
	c.id = id
	c.name = name
	c.description = description
	c.cost = cost
	c.type = type
	c.power = power
	c.status = status
	return c


