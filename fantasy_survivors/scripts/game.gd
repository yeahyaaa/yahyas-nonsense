extends Node2D
class_name GameScene

# Nodes
var player: Player
var spawner: EnemySpawner
var camera: Camera2D

# UI Nodes
var hud_layer: CanvasLayer
var health_bar: ProgressBar
var health_label: Label
var xp_bar: ProgressBar
var level_label: Label
var timer_label: Label
var kills_label: Label
var gold_label: Label
var move_joystick: VirtualJoystick
var aim_joystick: VirtualJoystick
var pause_btn: Button

var level_up_layer: CanvasLayer
var level_up_panel: Control
var upgrade_buttons: Array[Button] = []

var pause_layer: CanvasLayer
var pause_panel: Control

var game_over_layer: CanvasLayer
var game_over_panel: Control
var game_over_title: Label

func _ready() -> void:
	_create_world()
	_create_player()
	_create_spawner()
	_create_camera()
	_create_hud()
	_create_level_up_ui()
	_create_pause_ui()
	_create_game_over_ui()
	_connect_signals()

	Global.start_game()

func _create_world() -> void:
	# Ground
	var ground = ColorRect.new()
	ground.size = Vector2(8000, 8000)
	ground.position = Vector2(-4000, -4000)
	ground.color = Color(0.12, 0.14, 0.1)
	ground.z_index = -100
	add_child(ground)

	# Grid pattern
	for i in range(-20, 21):
		for j in range(-20, 21):
			if (i + j) % 2 == 0:
				var tile = ColorRect.new()
				tile.size = Vector2(200, 200)
				tile.position = Vector2(i * 200, j * 200)
				tile.color = Color(0.13, 0.15, 0.11)
				tile.z_index = -99
				add_child(tile)

func _create_player() -> void:
	player = Player.new()
	player.position = Vector2.ZERO
	add_child(player)

func _create_spawner() -> void:
	spawner = EnemySpawner.new()
	add_child(spawner)

func _create_camera() -> void:
	camera = Camera2D.new()
	camera.zoom = Vector2(1.2, 1.2)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8.0
	player.add_child(camera)

func _create_hud() -> void:
	hud_layer = CanvasLayer.new()
	hud_layer.layer = 10
	add_child(hud_layer)

	# Top bar background
	var top_bg = ColorRect.new()
	top_bg.size = Vector2(1080, 120)
	top_bg.color = Color(0, 0, 0, 0.5)
	hud_layer.add_child(top_bg)

	# Health bar
	health_bar = ProgressBar.new()
	health_bar.position = Vector2(20, 20)
	health_bar.size = Vector2(300, 30)
	health_bar.max_value = 100
	health_bar.value = 100
	health_bar.show_percentage = false
	hud_layer.add_child(health_bar)

	health_label = Label.new()
	health_label.position = Vector2(20, 55)
	health_label.text = "100 / 100"
	health_label.add_theme_font_size_override("font_size", 20)
	hud_layer.add_child(health_label)

	# XP bar
	xp_bar = ProgressBar.new()
	xp_bar.position = Vector2(20, 85)
	xp_bar.size = Vector2(200, 20)
	xp_bar.max_value = 10
	xp_bar.value = 0
	xp_bar.show_percentage = false
	hud_layer.add_child(xp_bar)

	level_label = Label.new()
	level_label.position = Vector2(230, 80)
	level_label.text = "Lv. 1"
	level_label.add_theme_font_size_override("font_size", 24)
	hud_layer.add_child(level_label)

	# Timer
	timer_label = Label.new()
	timer_label.position = Vector2(480, 40)
	timer_label.text = "00:00"
	timer_label.add_theme_font_size_override("font_size", 36)
	hud_layer.add_child(timer_label)

	# Kills
	kills_label = Label.new()
	kills_label.position = Vector2(700, 30)
	kills_label.text = "Kills: 0"
	kills_label.add_theme_font_size_override("font_size", 20)
	hud_layer.add_child(kills_label)

	# Gold
	gold_label = Label.new()
	gold_label.position = Vector2(700, 60)
	gold_label.text = "Gold: 0"
	gold_label.add_theme_font_size_override("font_size", 20)
	gold_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	hud_layer.add_child(gold_label)

	# Pause button
	pause_btn = Button.new()
	pause_btn.position = Vector2(980, 20)
	pause_btn.size = Vector2(80, 80)
	pause_btn.text = "| |"
	pause_btn.add_theme_font_size_override("font_size", 28)
	pause_btn.pressed.connect(_on_pause_pressed)
	hud_layer.add_child(pause_btn)

	# Move joystick (left side)
	move_joystick = VirtualJoystick.new()
	move_joystick.position = Vector2(20, 1680)
	move_joystick.joystick_type = "move"
	move_joystick.joystick_input.connect(_on_move_input)
	hud_layer.add_child(move_joystick)

	# Aim joystick (right side)
	aim_joystick = VirtualJoystick.new()
	aim_joystick.position = Vector2(860, 1680)
	aim_joystick.joystick_type = "aim"
	aim_joystick.joystick_input.connect(_on_aim_input)
	hud_layer.add_child(aim_joystick)

func _create_level_up_ui() -> void:
	level_up_layer = CanvasLayer.new()
	level_up_layer.layer = 20
	level_up_layer.visible = false
	add_child(level_up_layer)

	# Dim background
	var bg = ColorRect.new()
	bg.size = Vector2(1080, 1920)
	bg.color = Color(0, 0, 0, 0.8)
	level_up_layer.add_child(bg)

	level_up_panel = Control.new()
	level_up_layer.add_child(level_up_panel)

	# Title
	var title = Label.new()
	title.position = Vector2(400, 300)
	title.text = "LEVEL UP!"
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	level_up_panel.add_child(title)

	# Create 3 upgrade buttons
	for i in 3:
		var btn = Button.new()
		btn.position = Vector2(140, 450 + i * 280)
		btn.size = Vector2(800, 240)
		btn.add_theme_font_size_override("font_size", 24)
		btn.pressed.connect(_on_upgrade_selected.bind(i))
		level_up_panel.add_child(btn)
		upgrade_buttons.append(btn)

func _create_pause_ui() -> void:
	pause_layer = CanvasLayer.new()
	pause_layer.layer = 25
	pause_layer.visible = false
	add_child(pause_layer)

	var bg = ColorRect.new()
	bg.size = Vector2(1080, 1920)
	bg.color = Color(0, 0, 0, 0.85)
	pause_layer.add_child(bg)

	pause_panel = Control.new()
	pause_layer.add_child(pause_panel)

	var title = Label.new()
	title.position = Vector2(420, 600)
	title.text = "PAUSED"
	title.add_theme_font_size_override("font_size", 48)
	pause_panel.add_child(title)

	var resume_btn = Button.new()
	resume_btn.position = Vector2(340, 800)
	resume_btn.size = Vector2(400, 100)
	resume_btn.text = "RESUME"
	resume_btn.add_theme_font_size_override("font_size", 28)
	resume_btn.pressed.connect(_on_resume_pressed)
	pause_panel.add_child(resume_btn)

	var quit_btn = Button.new()
	quit_btn.position = Vector2(340, 950)
	quit_btn.size = Vector2(400, 100)
	quit_btn.text = "QUIT"
	quit_btn.add_theme_font_size_override("font_size", 28)
	quit_btn.pressed.connect(_on_quit_pressed)
	pause_panel.add_child(quit_btn)

func _create_game_over_ui() -> void:
	game_over_layer = CanvasLayer.new()
	game_over_layer.layer = 30
	game_over_layer.visible = false
	add_child(game_over_layer)

	var bg = ColorRect.new()
	bg.size = Vector2(1080, 1920)
	bg.color = Color(0, 0, 0, 0.9)
	game_over_layer.add_child(bg)

	game_over_panel = Control.new()
	game_over_layer.add_child(game_over_panel)

	game_over_title = Label.new()
	game_over_title.position = Vector2(350, 500)
	game_over_title.text = "GAME OVER"
	game_over_title.add_theme_font_size_override("font_size", 56)
	game_over_panel.add_child(game_over_title)

	# Stats
	var stats = Label.new()
	stats.name = "Stats"
	stats.position = Vector2(340, 650)
	stats.add_theme_font_size_override("font_size", 24)
	game_over_panel.add_child(stats)

	var retry_btn = Button.new()
	retry_btn.position = Vector2(340, 1000)
	retry_btn.size = Vector2(400, 100)
	retry_btn.text = "RETRY"
	retry_btn.add_theme_font_size_override("font_size", 28)
	retry_btn.pressed.connect(_on_retry_pressed)
	game_over_panel.add_child(retry_btn)

	var menu_btn = Button.new()
	menu_btn.position = Vector2(340, 1150)
	menu_btn.size = Vector2(400, 100)
	menu_btn.text = "MENU"
	menu_btn.add_theme_font_size_override("font_size", 28)
	menu_btn.pressed.connect(_on_menu_pressed)
	game_over_panel.add_child(menu_btn)

func _connect_signals() -> void:
	Global.health_changed.connect(_on_health_changed)
	Global.xp_changed.connect(_on_xp_changed)
	Global.level_up.connect(_on_level_up)
	Global.gold_changed.connect(_on_gold_changed)
	Global.game_over.connect(_on_game_over)
	Global.enemy_killed.connect(_on_enemy_killed)

func _process(delta: float) -> void:
	if Global.state == Global.State.PLAYING:
		timer_label.text = Global.get_formatted_time()

# ============ UI UPDATES ============

func _on_health_changed(current: float, maximum: float) -> void:
	health_bar.max_value = maximum
	health_bar.value = current
	health_label.text = "%d / %d" % [int(current), int(maximum)]

func _on_xp_changed(current: int, needed: int) -> void:
	xp_bar.max_value = needed
	xp_bar.value = current

func _on_level_up(new_level: int) -> void:
	level_label.text = "Lv. %d" % new_level
	_show_level_up_ui()

func _on_gold_changed(amount: int) -> void:
	gold_label.text = "Gold: %d" % amount

func _on_enemy_killed(enemy_type: String, is_elite: bool) -> void:
	kills_label.text = "Kills: %d" % Global.kills

func _on_game_over(victory: bool) -> void:
	game_over_title.text = "VICTORY!" if victory else "GAME OVER"
	game_over_title.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3) if victory else Color(0.9, 0.3, 0.3))

	var stats = game_over_panel.get_node("Stats")
	stats.text = "Time: %s\nLevel: %d\nKills: %d\nGold: %d" % [
		Global.get_formatted_time(),
		Global.current_level,
		Global.kills,
		Global.run_gold
	]

	game_over_layer.visible = true

# ============ LEVEL UP ============

var current_upgrades: Array[Dictionary] = []

func _show_level_up_ui() -> void:
	current_upgrades = Global.get_upgrade_options()

	for i in 3:
		if i < current_upgrades.size():
			var upgrade = current_upgrades[i]
			upgrade_buttons[i].text = upgrade["name"] + "\n\n" + upgrade["desc"]
			upgrade_buttons[i].visible = true
			upgrade_buttons[i].modulate = upgrade["color"]
		else:
			upgrade_buttons[i].visible = false

	level_up_layer.visible = true

func _on_upgrade_selected(index: int) -> void:
	if index < current_upgrades.size():
		Global.apply_upgrade(current_upgrades[index])
		player.refresh_weapons()

	level_up_layer.visible = false
	Global.resume_game()

# ============ INPUT ============

func _on_move_input(direction: Vector2) -> void:
	if is_instance_valid(player):
		player.set_move_input(direction)

func _on_aim_input(direction: Vector2) -> void:
	if is_instance_valid(player):
		player.set_aim_input(direction)

# ============ PAUSE ============

func _on_pause_pressed() -> void:
	Global.pause_game()
	pause_layer.visible = true

func _on_resume_pressed() -> void:
	pause_layer.visible = false
	Global.resume_game()

func _on_quit_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

# ============ GAME OVER ============

func _on_retry_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
