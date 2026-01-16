extends CanvasLayer
class_name GameHUD
## GameHUD - Main game UI with health, XP, timer, and controls

@export var health_bar: ProgressBar
@export var health_label: Label
@export var xp_bar: ProgressBar
@export var level_label: Label
@export var timer_label: Label
@export var kill_label: Label
@export var gold_label: Label
@export var move_joystick: VirtualJoystick
@export var aim_joystick: VirtualJoystick
@export var pause_button: Button
@export var weapon_icons_container: HBoxContainer

var player: Player

func _ready() -> void:
	_connect_signals()
	_setup_ui()

func _connect_signals() -> void:
	PlayerStats.health_changed.connect(_on_health_changed)
	PlayerStats.xp_gained.connect(_on_xp_changed)
	PlayerStats.level_up.connect(_on_level_up)
	PlayerStats.gold_gained.connect(_on_gold_changed)
	GameManager.game_started.connect(_on_game_started)
	GameManager.game_paused.connect(_on_game_paused)
	GameManager.game_resumed.connect(_on_game_resumed)

	if move_joystick:
		move_joystick.joystick_input.connect(_on_move_input)
	if aim_joystick:
		aim_joystick.joystick_input.connect(_on_aim_input)
	if pause_button:
		pause_button.pressed.connect(_on_pause_pressed)

func _setup_ui() -> void:
	_update_health_display()
	_update_xp_display()
	_update_gold_display()
	_update_kill_display()

func _process(delta: float) -> void:
	if GameManager.current_state == GameManager.GameState.PLAYING:
		_update_timer()

func _update_timer() -> void:
	if timer_label:
		timer_label.text = GameManager.get_formatted_time()

func _update_health_display() -> void:
	var current = PlayerStats.current_health
	var maximum = PlayerStats.get_stat("max_health")

	if health_bar:
		health_bar.max_value = maximum
		health_bar.value = current
	if health_label:
		health_label.text = "%d / %d" % [int(current), int(maximum)]

func _update_xp_display() -> void:
	if xp_bar:
		xp_bar.max_value = PlayerStats.xp_to_next_level
		xp_bar.value = PlayerStats.current_xp
	if level_label:
		level_label.text = "Lv. %d" % PlayerStats.current_level

func _update_gold_display() -> void:
	if gold_label:
		gold_label.text = str(PlayerStats.run_gold)

func _update_kill_display() -> void:
	if kill_label:
		kill_label.text = str(PlayerStats.kills)

func _on_health_changed(current: float, maximum: float) -> void:
	_update_health_display()

func _on_xp_changed(amount: int) -> void:
	_update_xp_display()

func _on_level_up(new_level: int) -> void:
	_update_xp_display()

func _on_gold_changed(amount: int) -> void:
	_update_gold_display()

func _on_game_started() -> void:
	player = get_tree().get_first_node_in_group("player")
	_setup_ui()

func _on_game_paused() -> void:
	if move_joystick:
		move_joystick.visible = false
	if aim_joystick:
		aim_joystick.visible = false

func _on_game_resumed() -> void:
	if move_joystick:
		move_joystick.visible = true
	if aim_joystick:
		aim_joystick.visible = true

func _on_move_input(direction: Vector2) -> void:
	if player:
		player.set_move_input(direction)

func _on_aim_input(direction: Vector2) -> void:
	if player:
		player.set_aim_input(direction)

func _on_pause_pressed() -> void:
	if GameManager.current_state == GameManager.GameState.PLAYING:
		GameManager.pause_game()
	elif GameManager.current_state == GameManager.GameState.PAUSED:
		GameManager.resume_game()

func update_weapon_icons() -> void:
	if not weapon_icons_container or not player:
		return

	for child in weapon_icons_container.get_children():
		child.queue_free()

	for weapon in player.get_all_weapons():
		var icon = ColorRect.new()
		icon.custom_minimum_size = Vector2(40, 40)
		icon.color = Color(0.3, 0.3, 0.4)

		var level_text = Label.new()
		level_text.text = str(weapon.level)
		level_text.add_theme_font_size_override("font_size", 12)
		icon.add_child(level_text)

		weapon_icons_container.add_child(icon)
