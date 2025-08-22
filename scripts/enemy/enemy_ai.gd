extends Resource

# 敌人AI：维护“可见的意图序列”并在每次玩家出牌后推进
class_name EnemyAI

# 可见的前4步意图（之后无限长，使用生成规则补齐）
# 每个意图字典格式：{"type": String, "value": int}
@export var intent_queue: Array = []

# 初始化一个基础意图序列（示例：攻-防-强攻-挂机）
func setup_basic() -> void:
	intent_queue = [
		{"type": "attack", "value": 8},
		{"type": "defend", "value": 6},
		{"type": "attack", "value": 10},
		{"type": "idle", "value": 0},
	]

# 查看可见的意图（前4个）用于UI展示
func peek_visible_intents() -> Array:
	return intent_queue.slice(0, 4)

# 取出并推进一个意图，同时生成并补到队列末尾
func next_intent() -> Dictionary:
	var intent = intent_queue.pop_front()
	intent_queue.append(_generate_next_intent())
	return intent

# 随机生成下一个意图：攻击/防御/闪避/挂机
func _generate_next_intent() -> Dictionary:
	var r = randi() % 4
	match r:
		0:
			return {"type": "attack", "value": 6 + int(randi() % 6)}
		1:
			return {"type": "defend", "value": 5 + int(randi() % 6)}
		2:
			return {"type": "evade", "value": 0}
		_:
			return {"type": "idle", "value": 0}


