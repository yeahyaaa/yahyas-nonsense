extends Node
## GameManager - Core game state and flow control

signal game_started
signal game_paused
signal game_resumed
signal game_over(victory: bool)
signal wave_started(wave_number: int)
signal boss_spawned(boss_name: String)

enum GameState { MENU, PLAYING, PAUSED, GAME_OVER, VICTORY }

var current_state: GameState = GameState.MENU
var current_stage: int = 1
var current_wave: int = 0
var game_time: float = 0.0
var is_boss_active: bool = false

# Stage definitions
var stages: Dictionary = {
	1: {
		"name": "Haunted Graveyard",
		"enemy_theme": "undead",
		"boss": "Lich King",
		"duration": 300.0,  # 5 minutes
		"waves": 10
	},
	2: {
		"name": "Goblin Forest",
		"enemy_theme": "monsters",
		"boss": "Troll Warlord",
		"duration": 360.0,
		"waves": 12
	},
	3: {
		"name": "Demon Rift",
		"enemy_theme": "demons",
		"boss": "Arch Demon",
		"duration": 420.0,
		"waves": 15
	}
}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta: float) -> void:
	if current_state == GameState.PLAYING:
		game_time += delta

func start_game(stage: int = 1) -> void:
	current_stage = stage
	current_wave = 0
	game_time = 0.0
	is_boss_active = false
	current_state = GameState.PLAYING
	PlayerStats.reset_run_stats()
	game_started.emit()

func pause_game() -> void:
	if current_state == GameState.PLAYING:
		current_state = GameState.PAUSED
		get_tree().paused = true
		game_paused.emit()

func resume_game() -> void:
	if current_state == GameState.PAUSED:
		current_state = GameState.PLAYING
		get_tree().paused = false
		game_resumed.emit()

func trigger_game_over(victory: bool = false) -> void:
	if victory:
		current_state = GameState.VICTORY
	else:
		current_state = GameState.GAME_OVER
	game_over.emit(victory)

func start_wave(wave_num: int) -> void:
	current_wave = wave_num
	wave_started.emit(wave_num)

func spawn_boss() -> void:
	is_boss_active = true
	var boss_name = stages[current_stage]["boss"]
	boss_spawned.emit(boss_name)

func get_current_stage_data() -> Dictionary:
	return stages.get(current_stage, stages[1])

func get_formatted_time() -> String:
	var minutes = int(game_time) / 60
	var seconds = int(game_time) % 60
	return "%02d:%02d" % [minutes, seconds]
