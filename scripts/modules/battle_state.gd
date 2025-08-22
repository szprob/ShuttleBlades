extends Resource

# 战斗状态：仅存储数值，不含UI逻辑
class_name BattleState

# 玩家属性
@export var player_hp: int = 50
@export var player_hp_max: int = 50
@export var player_block: int = 0
@export var player_energy: int = 3
@export var player_energy_max: int = 3

# 敌人属性
@export var enemy_hp: int = 40
@export var enemy_hp_max: int = 40
@export var enemy_block: int = 0

# 奖励（用于胜利结算）
@export var coins_reward: int = 10

# 回合开始时的重置：能量、护甲等
func reset_turn() -> void:
	player_energy = player_energy_max
	player_block = 0
	enemy_block = 0

# 判定玩家死亡
func is_player_dead() -> bool:
	return player_hp <= 0

# 判定敌人死亡
func is_enemy_dead() -> bool:
	return enemy_hp <= 0


