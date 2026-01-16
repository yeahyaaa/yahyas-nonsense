extends Node2D
class_name EnemySpawner
## EnemySpawner - Handles spawning enemies based on stage and time

signal elite_spawned(enemy: EnemyBase)
signal boss_spawned(boss: EnemyBase)

@export var spawn_radius_min: float = 400.0
@export var spawn_radius_max: float = 600.0
@export var max_enemies: int = 150
@export var elite_spawn_interval: float = 30.0  # Seconds between elite spawns

var player: Node2D
var spawn_timer: float = 0.0
var elite_timer: float = 0.0
var current_enemy_count: int = 0
var difficulty_multiplier: float = 1.0

# Enemy pools per stage theme
var enemy_pools: Dictionary = {
	"undead": [
		{"scene": "res://scenes/enemies/skeleton.tscn", "weight": 10, "min_time": 0},
		{"scene": "res://scenes/enemies/zombie.tscn", "weight": 5, "min_time": 30},
		{"scene": "res://scenes/enemies/wraith.tscn", "weight": 3, "min_time": 60},
	],
	"monsters": [
		{"scene": "res://scenes/enemies/goblin.tscn", "weight": 10, "min_time": 0},
		{"scene": "res://scenes/enemies/orc.tscn", "weight": 5, "min_time": 30},
		{"scene": "res://scenes/enemies/troll.tscn", "weight": 2, "min_time": 90},
	],
	"demons": [
		{"scene": "res://scenes/enemies/imp.tscn", "weight": 10, "min_time": 0},
		{"scene": "res://scenes/enemies/hellhound.tscn", "weight": 6, "min_time": 30},
		{"scene": "res://scenes/enemies/demon_knight.tscn", "weight": 2, "min_time": 60},
	]
}

var boss_scenes: Dictionary = {
	1: "res://scenes/enemies/bosses/lich_king.tscn",
	2: "res://scenes/enemies/bosses/troll_warlord.tscn",
	3: "res://scenes/enemies/bosses/arch_demon.tscn"
}

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	GameManager.boss_spawned.connect(_on_boss_spawn_requested)

func _process(delta: float) -> void:
	if GameManager.current_state != GameManager.GameState.PLAYING:
		return

	if not player:
		player = get_tree().get_first_node_in_group("player")
		return

	_update_difficulty()
	_handle_spawning(delta)
	_handle_elite_spawning(delta)

func _update_difficulty() -> void:
	# Increase difficulty over time
	var game_time = GameManager.game_time
	difficulty_multiplier = 1.0 + (game_time / 60.0) * 0.2  # +20% per minute

func _handle_spawning(delta: float) -> void:
	spawn_timer -= delta

	if spawn_timer <= 0 and current_enemy_count < max_enemies:
		var spawn_count = _calculate_spawn_count()
		for i in spawn_count:
			_spawn_enemy()
		spawn_timer = _calculate_spawn_interval()

func _handle_elite_spawning(delta: float) -> void:
	elite_timer += delta

	if elite_timer >= elite_spawn_interval:
		_spawn_elite()
		elite_timer = 0.0

func _calculate_spawn_count() -> int:
	var base_count = 2
	var time_bonus = int(GameManager.game_time / 30)  # +1 every 30 seconds
	return base_count + time_bonus

func _calculate_spawn_interval() -> float:
	var base_interval = 2.0
	var reduction = GameManager.game_time / 300.0  # Faster over time
	return max(0.5, base_interval - reduction)

func _spawn_enemy() -> void:
	var stage_data = GameManager.get_current_stage_data()
	var theme = stage_data["enemy_theme"]
	var pool = enemy_pools.get(theme, enemy_pools["undead"])

	# Filter by time
	var available = pool.filter(func(e): return GameManager.game_time >= e["min_time"])
	if available.is_empty():
		available = [pool[0]]

	# Weighted random selection
	var enemy_data = _weighted_random(available)
	var scene = load(enemy_data["scene"])

	if not scene:
		# Fallback to skeleton if scene doesn't exist
		scene = load("res://scenes/enemies/skeleton.tscn")
		if not scene:
			return

	var enemy = scene.instantiate()
	enemy.global_position = _get_spawn_position()
	enemy.scale_stats(difficulty_multiplier)
	enemy.enemy_died.connect(_on_enemy_died)

	get_tree().current_scene.add_child(enemy)
	current_enemy_count += 1

func _spawn_elite() -> void:
	var stage_data = GameManager.get_current_stage_data()
	var theme = stage_data["enemy_theme"]
	var pool = enemy_pools.get(theme, enemy_pools["undead"])

	# Pick a stronger enemy type for elite
	var available = pool.filter(func(e): return GameManager.game_time >= e["min_time"])
	if available.size() > 1:
		available.sort_custom(func(a, b): return a["weight"] < b["weight"])
		available = [available[0]]  # Pick rarest

	var enemy_data = available[0]
	var scene = load(enemy_data["scene"])

	if not scene:
		scene = load("res://scenes/enemies/skeleton.tscn")
		if not scene:
			return

	var enemy = scene.instantiate()
	enemy.is_elite = true
	enemy.global_position = _get_spawn_position()
	enemy.scale_stats(difficulty_multiplier)
	enemy.enemy_died.connect(_on_enemy_died)

	get_tree().current_scene.add_child(enemy)
	current_enemy_count += 1
	elite_spawned.emit(enemy)

func _spawn_boss_internal() -> void:
	var boss_scene_path = boss_scenes.get(GameManager.current_stage)
	if not boss_scene_path:
		return

	var scene = load(boss_scene_path)
	if not scene:
		# Create a generic powerful elite as fallback
		var fallback = load("res://scenes/enemies/skeleton.tscn")
		if fallback:
			var boss = fallback.instantiate()
			boss.is_elite = true
			boss.elite_health_mult = 20.0
			boss.elite_damage_mult = 3.0
			boss.elite_size_mult = 2.5
			boss.global_position = _get_spawn_position()
			boss.enemy_died.connect(_on_boss_died)
			get_tree().current_scene.add_child(boss)
			boss_spawned.emit(boss)
		return

	var boss = scene.instantiate()
	boss.global_position = _get_spawn_position()
	boss.enemy_died.connect(_on_boss_died)
	get_tree().current_scene.add_child(boss)
	boss_spawned.emit(boss)

func _get_spawn_position() -> Vector2:
	if not player:
		return Vector2.ZERO

	var angle = randf() * TAU
	var distance = randf_range(spawn_radius_min, spawn_radius_max)
	return player.global_position + Vector2.from_angle(angle) * distance

func _weighted_random(pool: Array) -> Dictionary:
	var total_weight = 0
	for item in pool:
		total_weight += item["weight"]

	var roll = randf() * total_weight
	var cumulative = 0

	for item in pool:
		cumulative += item["weight"]
		if roll <= cumulative:
			return item

	return pool[0]

func _on_enemy_died(enemy: EnemyBase, is_elite: bool) -> void:
	current_enemy_count -= 1

func _on_boss_died(enemy: EnemyBase, is_elite: bool) -> void:
	GameManager.trigger_game_over(true)  # Victory!

func _on_boss_spawn_requested(boss_name: String) -> void:
	_spawn_boss_internal()
