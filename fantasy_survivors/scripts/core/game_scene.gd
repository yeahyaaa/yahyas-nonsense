extends Node2D
class_name GameScene
## GameScene - Main gameplay scene controller

@export var player_scene: PackedScene
@export var enemy_spawner: EnemySpawner
@export var hud: GameHUD
@export var level_up_ui: LevelUpUI
@export var pause_menu: Control
@export var game_over_ui: Control
@export var victory_ui: Control
@export var camera: Camera2D

var player: Player
var stage_timer: float = 0.0
var boss_spawned: bool = false

func _ready() -> void:
	_connect_signals()
	_start_stage()

func _connect_signals() -> void:
	GameManager.game_over.connect(_on_game_over)
	GameManager.game_paused.connect(_on_game_paused)
	GameManager.game_resumed.connect(_on_game_resumed)

func _start_stage() -> void:
	# Spawn player
	if player_scene:
		player = player_scene.instantiate()
	else:
		player = load("res://scenes/characters/player.tscn").instantiate()

	player.global_position = Vector2.ZERO
	add_child(player)

	# Setup camera to follow player
	if camera:
		camera.get_parent().remove_child(camera)
		player.add_child(camera)
		camera.position = Vector2.ZERO

	# Start the game
	GameManager.start_game(1)

func _process(delta: float) -> void:
	if GameManager.current_state != GameManager.GameState.PLAYING:
		return

	_check_boss_spawn()
	_update_pickup_magnetism()

func _check_boss_spawn() -> void:
	if boss_spawned:
		return

	var stage_data = GameManager.get_current_stage_data()
	if GameManager.game_time >= stage_data["duration"]:
		boss_spawned = true
		GameManager.spawn_boss()

func _update_pickup_magnetism() -> void:
	if not player:
		return

	var pickup_range = PlayerStats.get_stat("pickup_range")
	var pickups = get_tree().get_nodes_in_group("pickups")

	for pickup in pickups:
		if pickup.has_method("magnetize"):
			var distance = player.global_position.distance_to(pickup.global_position)
			if distance <= pickup_range:
				pickup.magnetize(player)

func _on_game_over(victory: bool) -> void:
	if victory:
		_show_victory()
	else:
		_show_game_over()

func _show_game_over() -> void:
	if game_over_ui:
		game_over_ui.visible = true

func _show_victory() -> void:
	if victory_ui:
		victory_ui.visible = true

func _on_game_paused() -> void:
	if pause_menu:
		pause_menu.visible = true

func _on_game_resumed() -> void:
	if pause_menu:
		pause_menu.visible = false

func restart_stage() -> void:
	get_tree().reload_current_scene()

func return_to_menu() -> void:
	PlayerStats.end_run()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
