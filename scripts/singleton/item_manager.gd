extends Node

var inventory = {}
var temp_inventory = {}

func _ready() -> void:
	init_state() # 确保这是第一个调用的函数

func init_state():
	inventory['cards'] = {'attack1':{"name": "attack", "level": 1},
	 			'block1':{"name": "block", "level": 1},
				'heal1':{"name": "heal", "level": 1}}
	inventory['items'] = {'apple1':{"name": "apple", "count": 1},
				'banana1':{"name": "banana", "count": 1}}
	temp_inventory['cards'] = {}
	temp_inventory['items'] = {}

func add_item(item_id:StringName, item:Dictionary, item_type:StringName)->void:
	inventory[item_type][item_id] = item

func delete_item(item_id:StringName, item_type:StringName) -> void:
	inventory[item_type].erase(item_id)


