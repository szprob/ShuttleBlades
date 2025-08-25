extends Node

# 添加背景音乐预加载
var bgm_player: AudioStreamPlayer

signal camera_shake_requested(strength: float, duration: float)
signal die_requested()


var game_state = {}
var game_state_cache = {}

func init_default_state():
	var game_state2 = {
		'play_time_seconds': 0, # 添加游戏时间记录（秒）
	}
	game_state = game_state2.duplicate(true) # 深度复制默认状态

var _skill_cache := {}

func set_skill_enabled(skill_name: StringName, value: bool) -> void:
	game_state['skills'][skill_name] = value
	_skill_cache[skill_name] = value

func is_skill_enabled(skill_name: StringName) -> bool:
	if skill_name in _skill_cache:
		return _skill_cache[skill_name]
	var value = game_state['skills'].get(skill_name, false)
	_skill_cache[skill_name] = value
	return value

func add_item(item_name: StringName) -> void:
	print("获得物品： ", item_name)
	game_state['inventory'].append(item_name)
	print("当前物品栏： ", game_state['inventory'])
	print("是否包含物品[", item_name, "]: ", has_item(item_name))

func use_item(item_name: StringName) -> void:
	game_state['inventory'].erase(item_name)

func has_item(item_name: StringName) -> bool:
	return game_state['inventory'].has(item_name)

func get_items() -> Array[StringName]:
	return Array(game_state['inventory'], TYPE_STRING_NAME, &"", null)


func _ready() -> void:
	init_default_state() # 确保这是第一个调用的函数
	
	# 创建 ItemManager 实例时传入 self 作为参数
	item_manager = ItemManager.new(self)
	pipeline_manager = PipelineManagerScript.new(self)
	
	# 确保场景已被正确加载
	if not scan_lines_scene:
		push_error("扫描线场景未设置！请在检查器中设置scan_lines_scene")
		return
		
	# 添加场景树信号连接
	get_tree().node_added.connect(_on_node_added)
	
	apply_settings()

func setup_bgm_player() -> void:
	bgm_player = AudioStreamPlayer.new()
	bgm_player.bus = "Music" # 确保你的项目中有名为"Music"的音频总线
	bgm_player.stream_paused = false
	# 设置音量为原来的25%（-12分贝）
	bgm_player.volume_db = -12
	# 添加这一行来设置循环播放
	bgm_player.finished.connect(func(): bgm_player.play())
	add_child(bgm_player)
	game_state_cache['bmg_set'] = true
	
# 修改 play_bgm 函数，支持通过名称播放 BGM
func play_bgm(bgm_name: String) -> void:
	if not game_state['settings']['bgm_enabled']:
		return
		
	if not bgm_resources.has(bgm_name):
		push_error("BGM 资源未找到：" + bgm_name)
		return
		
	var stream = bgm_resources[bgm_name]
	if bgm_player.stream != stream or not bgm_player.playing:
		bgm_player.stream = stream
		bgm_player.play()

		
func stop_bgm() -> void:
	if bgm_player:
		bgm_player.stop()
		bgm_player.queue_free()
		game_state_cache['bmg_set'] = false

func set_bgm_volume(volume: float) -> void:
	game_state['settings']['bgm_volume'] = volume
	bgm_player.volume_db = linear_to_db(volume)

func add_scan_lines_to_node(node: Node) -> void:
	# 防止重复添加和无限递归
	var parent = node.get_parent()
	# 检查节点及其所有父节点是否已经有扫描线
	var current_node = node
	while current_node:
		if current_node.get_node_or_null("ScanLines"):
			return # 如果任何父节点已有扫描线，就不再添加
		current_node = current_node.get_parent()
	
	if not node.name == "ScanLines" and (not parent or parent.name != "ScanLines"):
		var scan_lines_instance = scan_lines_scene.instantiate()
		scan_lines_instance.name = "ScanLines"
		
		# 如果扫描线是 CanvasLayer，设置其 layer 属性
		if scan_lines_instance is CanvasLayer:
			scan_lines_instance.layer = 100
			
		node.add_child(scan_lines_instance)

func _on_node_added(node: Node) -> void:
	# 当新节点被添加到场景树时，自动检查并添加扫描线
	if game_state['settings']['scan_lines']:
		# 跳过扫描线相关的节点
		var parent = node.get_parent()
		if node.name == "ScanLines" or (parent and parent.name == "ScanLines"):
			return
			
		# 只为根节点或特定组的节点添加扫描线
		if node.is_in_group("scan_lines"):
			add_scan_lines_to_node(node)

func on_fullscreen_toggled(toggled_on: bool) -> void:
	game_state['settings']['full_screen'] = toggled_on
	apply_settings()

#func on_music_volume_slider_value_changed(value: float) -> void:
	#AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), value)
#
#func on_sfx_volume_slider_value_changed(value: float) -> void:
	#AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), value)

func on_scan_lines_toggled(toggled_on: bool) -> void:
	game_state['settings']['scan_lines'] = toggled_on
	apply_settings()

func apply_settings() -> void:
	get_tree().paused = true
	
	# 应用全屏设置
	if game_state['settings']['full_screen']:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	
	get_tree().paused = false
	
	# 应用扫描线设置
	var scanline_nodes = get_tree().get_nodes_in_group("scan_lines")
	if game_state['settings']['scan_lines']:
		# 如果启用扫描线，确保所有需要的节点都有扫描线
		for node in scanline_nodes:
			add_scan_lines_to_node(node)
	else:
		# 如果禁用扫描线，移除所有现有的扫描线
		for node in scanline_nodes:
			var scan_lines = node.get_node_or_null("ScanLines")
			if scan_lines:
				scan_lines.queue_free()

func save_game_state():
	# 确保存档目录存在
	var dir = DirAccess.open("user://")
	if not dir.dir_exists("save"):
		dir.make_dir("save")
	
	var archive_index = str(game_state['archive_index'])
	var file_path = "user://save/save_game" + archive_index + ".json"
	
	# 在保存之前转换 Vector2
	var save_data = game_state.duplicate(true)
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data))
		file.close()

func load_game_state():
	var archive_index = str(game_state['archive_index'])
	var file_path = "user://save/save_game" + archive_index + ".json"
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file:
		var save_text = file.get_as_text()
		var json = JSON.new()
		var result = json.parse(save_text)
		if result == OK:
			game_state = json.data
			# pipeline_manager.sync_game_state(game_state)
		else:
			# 加载失败时初始化默认状态
			init_default_state()
		file.close()
		_skill_cache.clear()
		if game_state['last_scene_path'] != '':
			game_state['target_scene'] = game_state['last_scene_path']
	else:
		init_default_state()


var get_current_scene: Callable = func():
	var current_scene: Node = get_tree().current_scene
	if current_scene == null:
		current_scene = get_tree().root.get_child(get_tree().root.get_child_count() - 1)
	return current_scene


# 添加暂停相关的方法
func _input(event: InputEvent) -> void:
	# 确保只在按键事件时调用 is_action_just_pressed
	if event.is_pressed():
		if Input.is_action_just_pressed("esc") and not game_state_cache['inventory_visible'] and not is_chatting():
			if not get_tree().current_scene.is_in_group("no_pause"):
				toggle_pause_menu()
			else:
				print("当前场景不允许暂停")
	

func toggle_pause_menu() -> void:
	if not game_state.has("is_paused"):
		game_state["is_paused"] = false
		
	if game_state['is_paused']:
		resume_game()
	else:
		pause_game()

func pause_game() -> void:

	# 先检查是否已经存在暂停菜单
	var current_scene = get_tree().current_scene
	var existing_pause = current_scene.get_node_or_null("PauseMenu")
	if existing_pause:
		print("暂停菜单已存在，跳过创建")
		return
		
	game_state['is_paused'] = true
	get_tree().paused = true
	
	var pause_scene_instance = pause_scene.instantiate()
	pause_scene_instance.name = "PauseMenu"
	
	var canvas_layer = CanvasLayer.new()
	canvas_layer.name = "PauseMenu" # 给 CanvasLayer 也设置相同的名称
	canvas_layer.layer = 99
	canvas_layer.add_child(pause_scene_instance)
	current_scene.add_child(canvas_layer)

func resume_game() -> void:
	print("正在恢复游戏...")
	game_state['is_paused'] = false
	
	# 查找并删除所有暂停菜单实例
	var current_scene = get_tree().current_scene
	var pause_menu = current_scene.get_node_or_null("PauseMenu")
	if pause_menu:
		pause_menu.queue_free()
	
	get_tree().paused = false
	print("游戏已恢复")


