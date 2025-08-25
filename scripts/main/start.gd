extends Node2D

# @export var transition_scene: String = "res://scenes/modules/checkpoints/transition.tscn"  # 添加过渡场景路径
# @export var target_scene: String = "res://scenes/dreams/bigworldv2/intro.tscn"

var buttons = []
var current_index = 0

@onready var new_button: Button = $new
@onready var load_button: Button = $load
@onready var settings_button: Button = $settings
@onready var staff_button: Button = $staff
@onready var quit_button: Button = $quit
@onready var logo: Sprite2D = $Sprite
@onready var sfx_click: AudioStreamPlayer2D = $click
@onready var sfx_focus: AudioStreamPlayer2D = $focus

func _ready():
	# if not GameManager.game_state_cache['bmg_set']:
	# 	GameManager.setup_bgm_player()
	# 	GameManager.play_bgm('bgm')
	buttons = [new_button, load_button, settings_button, staff_button, quit_button]

	new_button.pressed.connect(_on_new_pressed)
	load_button.pressed.connect(_on_load_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	staff_button.pressed.connect(_on_staff_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	# 为每个按钮添加焦点效果
	for button in buttons:
		button.focus_entered.connect(func(): _on_button_focus(button))
		button.focus_exited.connect(func(): _on_button_unfocus(button))
		button.mouse_entered.connect(func(): button.grab_focus())

	
func play_click():
	if sfx_click:
		sfx_click.play()

func play_focus():
	if sfx_focus:
		sfx_focus.play()

func _on_new_pressed() -> void:
	play_click()
	GameManager.init_state()
	GameManager.save()
	get_tree().change_scene_to_file("res://scenes/main/intro.tscn")


func _on_load_pressed() -> void:
	play_click()
	GameManager.load()
	GameManager.apply_settings()
	# 创建过渡场景实例
	get_tree().change_scene_to_file("res://scenes/main/intro.tscn")

func _on_quit_pressed() -> void:
	play_click()
	get_tree().quit()


func _on_settings_pressed() -> void:
	play_click()
	get_tree().change_scene_to_file("res://scenes/main/ins.tscn")

func _on_staff_pressed() -> void:
	play_click()
	get_tree().change_scene_to_file("res://scenes/main/staff.tscn")

# 添加这些新函数
func _on_button_focus(button: Button) -> void:
	play_focus()
	var tween = create_tween()
	tween.set_parallel(true)
	
	# 放大效果
	tween.tween_property(button, "scale", Vector2(1.1, 1.1), 0.1)
	# 高亮效果
	tween.tween_property(button, "modulate", Color(1.2, 1.2, 1.2), 0.1)
	
	# 添加粗边框
	var stylebox = StyleBoxFlat.new()
	stylebox.set_border_width_all(4)  # 设置边框宽度
	stylebox.border_color = Color(1, 1, 1)  # 设置边框颜色为白色
	stylebox.bg_color = Color(0, 0, 0, 0)  # 背景透明
	button.add_theme_stylebox_override("focus", stylebox)

func _on_button_unfocus(button: Button) -> void:
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.1)
	tween.tween_property(button, "modulate", Color(1, 1, 1), 0.1)
	
	# 移除边框
	button.remove_theme_stylebox_override("focus")


