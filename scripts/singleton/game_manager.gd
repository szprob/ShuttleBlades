extends Node

# 添加背景音乐预加载
var bgm_player: AudioStreamPlayer

signal camera_shake_requested(strength: float, duration: float)
signal die_requested()


var state = {}
var temp_state = {}

func init_state():
	var state2 = {
		'need_instruction': true, # 是否需要教程
	}
	state = state2.duplicate(true) # 深度复制默认状态



func _ready() -> void:
	init_state() # 确保这是第一个调用的函数
	

	
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
	temp_state['bmg_set'] = true
	
# # 修改 play_bgm 函数，支持通过名称播放 BGM
# func play_bgm(bgm_name: String) -> void:
# 	if not state['settings']['bgm_enabled']:
# 		return
		
# 	if not bgm_resources.has(bgm_name):
# 		push_error("BGM 资源未找到：" + bgm_name)
# 		return
		
# 	var stream = bgm_resources[bgm_name]
# 	if bgm_player.stream != stream or not bgm_player.playing:
# 		bgm_player.stream = stream
# 		bgm_player.play()

		
func stop_bgm() -> void:
	if bgm_player:
		bgm_player.stop()
		bgm_player.queue_free()
		temp_state['bmg_set'] = false

func set_bgm_volume(volume: float) -> void:
	state['settings']['bgm_volume'] = volume
	bgm_player.volume_db = linear_to_db(volume)



#func on_music_volume_slider_value_changed(value: float) -> void:
	#AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), value)
#
#func on_sfx_volume_slider_value_changed(value: float) -> void:
	#AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), value)


func apply_settings() -> void:
	get_tree().paused = true
	
	# 应用全屏设置
	if state['settings']['full_screen']:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	
	get_tree().paused = false
	

func save():
	# 确保存档目录存在
	var dir = DirAccess.open("user://")
	if not dir.dir_exists("save"):
		dir.make_dir("save")
	
	var archive_index = str(state['archive_index'])
	var file_path = "user://save/save_game" + archive_index + ".json"
	
	# 在保存之前转换 Vector2
	var save_data = state.duplicate(true)
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data))
		file.close()

func load():
	var archive_index = str(state['archive_index'])
	var file_path = "user://save/save_game" + archive_index + ".json"
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file:
		var save_text = file.get_as_text()
		var json = JSON.new()
		var result = json.parse(save_text)
		if result == OK:
			state = json.data
			# pipeline_manager.sync_state(state)
		else:
			# 加载失败时初始化默认状态
			init_state()
		file.close()
	else:
		init_state()


var get_current_scene: Callable = func():
	var current_scene: Node = get_tree().current_scene
	if current_scene == null:
		current_scene = get_tree().root.get_child(get_tree().root.get_child_count() - 1)
	return current_scene

